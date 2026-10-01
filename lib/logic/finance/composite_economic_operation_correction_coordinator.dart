import 'dart:convert';

import '../../models/balance_posting_mode.dart';
import '../../models/composite_correction_intent.dart';
import '../../models/composite_correction_metadata.dart';
import '../../models/economic_operation_metadata.dart';
import '../../models/finance_balance.dart';
import '../../models/finance_transaction.dart';
import '../../models/real_expense.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';
import 'composite_correction_intent_persistence.dart';
import 'documentary_obligation_coordinator.dart';
import 'finance_portfolio_v3_commit.dart';
import 'finance_portfolio_v3_contract.dart';

enum CompositeCorrectionStatus { completed, alreadyComplete, conflict, failed }

enum CompositeCorrectionState {
  ready,
  financeApplied,
  expensesApplied,
  documentaryApplied,
  complete,
  conflict,
}

class CompositeCorrectionResult {
  final CompositeCorrectionStatus status;
  final CompositeCorrectionState state;
  final List<String> errors;
  const CompositeCorrectionResult(
    this.status,
    this.state, [
    this.errors = const [],
  ]);
  bool get isSuccess =>
      status == CompositeCorrectionStatus.completed ||
      status == CompositeCorrectionStatus.alreadyComplete;
}

class CompositeEconomicOperationCorrectionCoordinator {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CompositeCorrectionIntentPersistence persistence;

  const CompositeEconomicOperationCorrectionCoordinator({
    required this.financeStore,
    required this.expenseStore,
    required this.persistence,
  });

  Future<CompositeCorrectionResult> resume(CompositeCorrectionIntent intent) =>
      _complete(intent);

  Future<CompositeCorrectionResult> correct({
    required String operationId,
    required String correctionId,
    required CompositeCorrectionPayload payload,
  }) async {
    CompositeCorrectionIntent? intent;
    try {
      intent = await persistence.findByOperationId(operationId);
      intent ??= _buildIntent(operationId, correctionId, payload);
      if (jsonEncode(intent.payload.toJson()) != jsonEncode(payload.toJson())) {
        return const CompositeCorrectionResult(
          CompositeCorrectionStatus.conflict,
          CompositeCorrectionState.conflict,
          ['A pending correction exists with a different payload'],
        );
      }
      if (intent.phase == CompositeCorrectionIntentPhase.completed) {
        await persistence.remove(intent.correctionId);
        return const CompositeCorrectionResult(
          CompositeCorrectionStatus.alreadyComplete,
          CompositeCorrectionState.complete,
        );
      }
      await persistence.put(intent);
    } catch (error) {
      return CompositeCorrectionResult(
        CompositeCorrectionStatus.conflict,
        CompositeCorrectionState.conflict,
        ['$error'],
      );
    }
    return _complete(intent);
  }

  CompositeCorrectionIntent _buildIntent(
    String operationId,
    String correctionId,
    CompositeCorrectionPayload payload,
  ) {
    if (!financeStore.isPortfolioV3Authoritative)
      throw StateError('Finance Portfolio V3 must be authoritative');
    final expenses = expenseStore.all
        .where((item) => item.operationMetadata?.operationId == operationId)
        .toList();
    if (expenses.isEmpty)
      throw StateError('Composite Expense operation not found');
    final revision =
        expenses
            .map((item) => item.compositeCorrectionMetadata?.revision ?? 0)
            .fold<int>(0, (a, b) => a > b ? a : b) +
        1;
    final activeFinance = financeStore.transactions.where((item) {
      if (item.operationMetadata?.operationId != operationId) return false;
      final correction = item.compositeCorrectionMetadata;
      return revision == 1
          ? correction == null
          : correction?.role == CompositeCorrectionFactRole.replacement &&
                correction?.revision == revision - 1;
    }).toList();
    _validateActive(operationId, activeFinance, expenses, payload);
    final main = activeFinance.singleWhere(
      (item) => item.operationMetadata?.role == OperationRole.main,
    );
    String? obligationId = main.operationMetadata?.documentaryObligationId;
    String? installmentId;
    if (obligationId != null) {
      final obligation = financeStore.documentaryObligationAggregate.obligations
          .where((item) => item.obligationId == obligationId)
          .toList();
      if (obligation.length != 1 || obligation.single.selectedOption == null) {
        throw StateError('Documentary obligation snapshot is unavailable');
      }
      final installments = obligation.single.selectedOption!.installments
          .where((item) => item.fulfilledEconomicFactId == main.economicFactId)
          .toList();
      if (installments.length != 1)
        throw StateError(
          'Documentary fulfillment does not identify exactly one installment',
        );
      installmentId = installments.single.installmentId;
    }
    final portfolio = _currentPortfolio();
    return CompositeCorrectionIntent(
      correctionId: correctionId,
      operationId: operationId,
      revision: revision,
      originalTransactions: activeFinance,
      originalExpenses: expenses,
      originalPortfolio: FinancePortfolioV3Contract.build(portfolio),
      documentaryObligationId: obligationId,
      documentaryInstallmentId: installmentId,
      originalFulfilledEconomicFactId: obligationId == null
          ? null
          : main.economicFactId,
      payload: payload,
    );
  }

  void _validateActive(
    String operationId,
    List<FinanceTransaction> finance,
    List<RealExpense> expenses,
    CompositeCorrectionPayload payload,
  ) {
    if (finance.isEmpty || finance.length != expenses.length)
      throw StateError('Finance and Expense component sets differ');
    for (final values in [
      finance.map((item) => item.operationMetadata),
      expenses.map((item) => item.operationMetadata),
    ]) {
      final metadata = values.whereType<EconomicOperationMetadata>().toList();
      if (metadata.length != finance.length ||
          metadata.any(
            (item) =>
                item.operationId != operationId ||
                item.context != OperationContext.utilityBill,
          )) {
        throw StateError('Composite metadata is incomplete or inconsistent');
      }
      if (metadata.where((item) => item.role == OperationRole.main).length != 1)
        throw StateError('Composite operation must have exactly one main');
      final accessoryTypes = metadata
          .where((item) => item.role == OperationRole.accessory)
          .map((item) => item.accessoryCostType)
          .toList();
      if (accessoryTypes.toSet().length != accessoryTypes.length)
        throw StateError('Duplicate accessory type');
    }
    final byFactFinance = {
      for (final item in finance) item.economicFactId: item,
    };
    final byFactExpense = {
      for (final item in expenses) item.economicFactId: item,
    };
    if (byFactFinance.length != finance.length ||
        byFactExpense.length != expenses.length ||
        !byFactFinance.keys.toSet().containsAll(byFactExpense.keys) ||
        !byFactExpense.keys.toSet().containsAll(byFactFinance.keys)) {
      throw StateError('Finance and Expense economic identities differ');
    }
    final modes = [
      ...finance.map((item) => item.balancePostingMode),
      ...expenses.map((item) => item.balancePostingMode),
    ].toSet();
    if (modes.length != 1 || modes.single != payload.balancePostingMode)
      throw StateError('BalancePostingMode is immutable');
    for (final fact in byFactFinance.keys) {
      final left = byFactFinance[fact]!.operationMetadata!;
      final right = byFactExpense[fact]!.operationMetadata!;
      if (jsonEncode(left.toJson()) != jsonEncode(right.toJson()))
        throw StateError('Finance and Expense metadata differ');
    }
    final targetBalances = financeStore.balances
        .where((item) => item.balanceId == payload.balanceId)
        .toList();
    if (targetBalances.length != 1 ||
        !targetBalances.single.active ||
        targetBalances.single.personId != payload.subject.name) {
      throw StateError(
        'Replacement balance is missing, inactive, or owned by another subject',
      );
    }
  }

  Future<CompositeCorrectionResult> _complete(
    CompositeCorrectionIntent intent,
  ) async {
    try {
      return await _completeUnsafe(intent);
    } catch (error) {
      return CompositeCorrectionResult(
        CompositeCorrectionStatus.failed,
        CompositeCorrectionState.conflict,
        ['Composite correction persistence failed: $error'],
      );
    }
  }

  Future<CompositeCorrectionResult> _completeUnsafe(
    CompositeCorrectionIntent intent,
  ) async {
    final expected = _ExpectedCorrection(intent, financeStore);
    var state = _classify(intent, expected);
    if (state == CompositeCorrectionState.conflict)
      return const CompositeCorrectionResult(
        CompositeCorrectionStatus.conflict,
        CompositeCorrectionState.conflict,
      );
    if (state == CompositeCorrectionState.ready) {
      final result = await financeStore.commitPortfolioV3CandidateVerified(
        expectedCurrent: intent.originalPortfolio,
        transform: (_) => expected.financeCandidate,
      );
      if (!result.isSuccess) {
        final conflict =
            result.failure == FinancePortfolioV3CommitFailure.snapshotConflict;
        return CompositeCorrectionResult(
          conflict
              ? CompositeCorrectionStatus.conflict
              : CompositeCorrectionStatus.failed,
          conflict ? CompositeCorrectionState.conflict : state,
          result.errors,
        );
      }
      state = _classify(intent, expected);
      if (state != CompositeCorrectionState.financeApplied)
        return const CompositeCorrectionResult(
          CompositeCorrectionStatus.conflict,
          CompositeCorrectionState.conflict,
          ['Finance result is not a recoverable prefix'],
        );
      await persistence.put(
        intent.withPhase(CompositeCorrectionIntentPhase.financeApplied),
      );
    }
    if (state == CompositeCorrectionState.financeApplied) {
      final result = await expenseStore.replaceOperationExpensesVerified(
        operationId: intent.operationId,
        expectedOriginal: intent.originalExpenses,
        replacements: expected.replacementExpenses,
      );
      if (!result.isSuccess) {
        final conflict =
            result.status == VerifiedExpenseSetReplacementStatus.conflict;
        return CompositeCorrectionResult(
          conflict
              ? CompositeCorrectionStatus.conflict
              : CompositeCorrectionStatus.failed,
          conflict ? CompositeCorrectionState.conflict : state,
          result.errors,
        );
      }
      state = _classify(intent, expected);
      if (state != CompositeCorrectionState.expensesApplied &&
          state != CompositeCorrectionState.documentaryApplied)
        return const CompositeCorrectionResult(
          CompositeCorrectionStatus.conflict,
          CompositeCorrectionState.conflict,
          ['Expense result is not a recoverable prefix'],
        );
      await persistence.put(
        intent.withPhase(CompositeCorrectionIntentPhase.expensesApplied),
      );
    }
    if (state == CompositeCorrectionState.expensesApplied &&
        intent.documentaryObligationId != null) {
      final outcome =
          await DocumentaryObligationCoordinator(
            financeStore: financeStore,
          ).replaceInstallmentFulfillmentVerified(
            obligationId: intent.documentaryObligationId!,
            installmentId: intent.documentaryInstallmentId!,
            expectedOldEconomicFactId: intent.originalFulfilledEconomicFactId!,
            replacementMain: expected.replacementMain,
            operationId: intent.operationId,
          );
      if (outcome != DocumentaryObligationOutcome.applied &&
          outcome != DocumentaryObligationOutcome.unchanged) {
        return const CompositeCorrectionResult(
          CompositeCorrectionStatus.conflict,
          CompositeCorrectionState.conflict,
          ['Documentary fulfillment conflicts with the correction'],
        );
      }
      state = _classify(intent, expected);
      if (state != CompositeCorrectionState.documentaryApplied)
        return const CompositeCorrectionResult(
          CompositeCorrectionStatus.conflict,
          CompositeCorrectionState.conflict,
        );
      await persistence.put(
        intent.withPhase(CompositeCorrectionIntentPhase.documentaryApplied),
      );
    }
    if (state == CompositeCorrectionState.expensesApplied &&
        intent.documentaryObligationId == null)
      state = CompositeCorrectionState.documentaryApplied;
    if (state == CompositeCorrectionState.documentaryApplied) {
      await persistence.put(
        intent.withPhase(CompositeCorrectionIntentPhase.completed),
      );
      await persistence.remove(intent.correctionId);
      return const CompositeCorrectionResult(
        CompositeCorrectionStatus.completed,
        CompositeCorrectionState.complete,
      );
    }
    return const CompositeCorrectionResult(
      CompositeCorrectionStatus.conflict,
      CompositeCorrectionState.conflict,
    );
  }

  CompositeCorrectionState _classify(
    CompositeCorrectionIntent intent,
    _ExpectedCorrection expected,
  ) {
    final financeMatches = expected.addedTransactions
        .map(
          (candidate) => financeStore.transactions
              .where(
                (item) =>
                    item.id == candidate.id ||
                    item.economicFactId == candidate.economicFactId,
              )
              .toList(),
        )
        .toList();
    if (financeMatches.any(
      (items) =>
          items.length > 1 ||
          (items.length == 1 &&
              jsonEncode(items.single.toJson()) !=
                  jsonEncode(
                    expected.addedTransactions[financeMatches.indexOf(items)]
                        .toJson(),
                  )),
    ))
      return CompositeCorrectionState.conflict;
    final financeCount = financeMatches
        .where((items) => items.length == 1)
        .length;
    if (financeCount != 0 && financeCount != financeMatches.length)
      return CompositeCorrectionState.conflict;
    if (financeCount == financeMatches.length &&
        jsonEncode(FinancePortfolioV3Contract.build(_currentPortfolio())) !=
            jsonEncode(
              FinancePortfolioV3Contract.build(expected.financeCandidate),
            )) {
      return CompositeCorrectionState.conflict;
    }
    final currentExpenses = expenseStore.all
        .where(
          (item) => item.operationMetadata?.operationId == intent.operationId,
        )
        .toList();
    final oldExpense =
        jsonEncode(currentExpenses.map((item) => item.toJson()).toList()) ==
        jsonEncode(
          intent.originalExpenses.map((item) => item.toJson()).toList(),
        );
    final newExpense =
        jsonEncode(currentExpenses.map((item) => item.toJson()).toList()) ==
        jsonEncode(
          expected.replacementExpenses.map((item) => item.toJson()).toList(),
        );
    if (!oldExpense && !newExpense) return CompositeCorrectionState.conflict;
    final documentaryNew =
        intent.documentaryObligationId == null ||
        _fulfilled(intent) == expected.replacementMain.economicFactId;
    final documentaryOld =
        intent.documentaryObligationId == null ||
        _fulfilled(intent) == intent.originalFulfilledEconomicFactId;
    if (financeCount == 0)
      return oldExpense && documentaryOld
          ? CompositeCorrectionState.ready
          : CompositeCorrectionState.conflict;
    if (oldExpense)
      return documentaryOld
          ? CompositeCorrectionState.financeApplied
          : CompositeCorrectionState.conflict;
    if (!documentaryOld && !documentaryNew)
      return CompositeCorrectionState.conflict;
    return documentaryNew
        ? CompositeCorrectionState.documentaryApplied
        : CompositeCorrectionState.expensesApplied;
  }

  String? _fulfilled(CompositeCorrectionIntent intent) {
    final obligations = financeStore.documentaryObligationAggregate.obligations
        .where((item) => item.obligationId == intent.documentaryObligationId)
        .toList();
    if (obligations.length != 1 || obligations.single.selectedOption == null)
      return null;
    final installments = obligations.single.selectedOption!.installments
        .where((item) => item.installmentId == intent.documentaryInstallmentId)
        .toList();
    return installments.length == 1
        ? installments.single.fulfilledEconomicFactId
        : null;
  }

  FinancePortfolioV3 _currentPortfolio() => FinancePortfolioV3(
    balances: financeStore.balances,
    funds: financeStore.funds,
    assetMovements: financeStore.assetMovements,
    transactions: financeStore.transactions,
    fundTransactions: financeStore.fundTransactions,
    linkedItems: financeStore.linkedItems,
  );
}

class _ExpectedCorrection {
  final CompositeCorrectionIntent intent;
  final FinanceStore store;
  late final Map<String, FinanceTransaction> originals = {
    for (final item in intent.originalTransactions)
      _component(item.operationMetadata!): item,
  };
  late final List<FinanceTransaction> compensations = originals.entries
      .map((entry) => _compensation(entry.key, entry.value))
      .toList();
  late final List<FinanceTransaction> replacements = _replacementTransactions();
  late final List<FinanceTransaction> addedTransactions = [
    ...compensations,
    ...replacements,
  ];
  late final List<RealExpense> replacementExpenses = replacements
      .map(_expense)
      .toList();
  late final FinanceTransaction replacementMain = replacements.singleWhere(
    (item) => item.operationMetadata?.role == OperationRole.main,
  );
  late final FinancePortfolioV3 financeCandidate = _candidate();
  _ExpectedCorrection(this.intent, this.store);

  static String _component(EconomicOperationMetadata metadata) =>
      metadata.role == OperationRole.main
      ? 'main'
      : metadata.accessoryCostType!.name;
  String _newFact(String component) => intent.factId('replacement:$component');

  FinanceTransaction _compensation(
    String component,
    FinanceTransaction original,
  ) => FinanceTransaction(
    id: intent.transactionId('compensation:$component'),
    balanceId: original.balanceId,
    amount: original.amount,
    date: intent.payload.economicDate,
    isIncome: true,
    subject: original.subject,
    description: 'Rettifica ${original.description}',
    type: FinanceTransactionType.income,
    origin: FinanceTransactionOrigin.adjustment,
    notes: 'Compensazione revisione ${intent.revision}',
    economicFactId: intent.factId('compensation:$component'),
    operationMetadata: original.operationMetadata,
    balancePostingMode: intent.payload.balancePostingMode,
    compositeCorrectionMetadata: CompositeCorrectionMetadata(
      correctionId: intent.correctionId,
      operationId: intent.operationId,
      originalEconomicFactId: original.economicFactId!,
      replacementEconomicFactId:
          component == 'main' ||
              intent.payload.accessories.keys.any(
                (item) => item.name == component,
              )
          ? _newFact(component)
          : null,
      role: CompositeCorrectionFactRole.compensation,
      revision: intent.revision,
    ),
  );

  List<FinanceTransaction> _replacementTransactions() {
    final mainMetadata = originals['main']!.operationMetadata!;
    final components = <String, double>{
      'main': intent.payload.mainAmount,
      for (final entry in intent.payload.accessories.entries)
        entry.key.name: entry.value,
    };
    return components.entries.map((entry) {
      final type = entry.key == 'main'
          ? null
          : AccessoryCostType.values.firstWhere(
              (item) => item.name == entry.key,
            );
      final metadata = EconomicOperationMetadata(
        operationId: intent.operationId,
        role: type == null ? OperationRole.main : OperationRole.accessory,
        context: OperationContext.utilityBill,
        accessoryCostType: type,
        documentaryObligationId: mainMetadata.documentaryObligationId,
        documentHolder: mainMetadata.documentHolder,
      );
      return FinanceTransaction(
        id: intent.transactionId('replacement:${entry.key}'),
        balanceId: intent.payload.balanceId,
        amount: entry.value,
        date: intent.payload.economicDate,
        isIncome: false,
        subject: intent.payload.subject,
        description: intent.payload.description,
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.adjustment,
        notes: intent.payload.category,
        economicFactId: _newFact(entry.key),
        operationMetadata: metadata,
        balancePostingMode: intent.payload.balancePostingMode,
        compositeCorrectionMetadata: CompositeCorrectionMetadata(
          correctionId: intent.correctionId,
          operationId: intent.operationId,
          originalEconomicFactId: originals[entry.key]?.economicFactId,
          replacementEconomicFactId: _newFact(entry.key),
          role: CompositeCorrectionFactRole.replacement,
          revision: intent.revision,
        ),
      );
    }).toList();
  }

  RealExpense _expense(FinanceTransaction item) => RealExpense(
    id: intent.expenseId(_component(item.operationMetadata!)),
    balanceId: item.balanceId,
    balanceName: intent.payload.balanceName,
    amount: item.amount,
    description: item.description,
    category: item.notes!,
    date: item.date,
    subject: item.subject,
    economicFactId: item.economicFactId,
    operationMetadata: item.operationMetadata,
    balancePostingMode: item.balancePostingMode,
    compositeCorrectionMetadata: item.compositeCorrectionMetadata,
  );

  FinancePortfolioV3 _candidate() {
    final original = FinancePortfolioV3Contract.parse(
      intent.originalPortfolio,
    ).value!;
    final balances = List<FinanceBalance>.of(original.balances);
    if (intent.payload.balancePostingMode ==
        BalancePostingMode.affectsCurrentBalance) {
      final oldTotal = intent.originalTransactions.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );
      final newTotal = replacements.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );
      _delta(balances, intent.originalTransactions.first.balanceId, oldTotal);
      _delta(balances, intent.payload.balanceId, -newTotal);
    }
    return FinancePortfolioV3(
      balances: balances,
      funds: original.funds,
      assetMovements: original.assetMovements,
      transactions: [...original.transactions, ...addedTransactions],
      fundTransactions: original.fundTransactions,
      linkedItems: original.linkedItems,
    );
  }

  void _delta(List<FinanceBalance> balances, String id, double delta) {
    final index = balances.indexWhere((item) => item.balanceId == id);
    if (index < 0) throw StateError('Correction balance not found: $id');
    final current = balances[index];
    balances[index] = FinanceBalance(
      personId: current.personId,
      balanceId: current.balanceId,
      name: current.name,
      initialAmount: current.initialAmount,
      currentAmount: current.currentAmount + delta,
      updatedAt: intent.payload.economicDate,
      balanceType: current.balanceType,
      operational: current.operational,
      active: current.active,
      reservedAmount: current.reservedAmount,
      warningThreshold: current.warningThreshold,
      persistentStressDays: current.persistentStressDays,
      recoveryDays: current.recoveryDays,
    );
  }
}
