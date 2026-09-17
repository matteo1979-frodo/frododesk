import 'dart:convert';

import '../../models/expense_replacement_intent.dart';
import '../../models/expense_replacement_metadata.dart';
import '../../models/finance_balance.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/finance_transaction.dart';
import '../../models/real_expense.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';
import '../finance/finance_portfolio_v3_contract.dart';
import 'expense_replacement_persistence.dart';

enum ExpenseReplacementState { ready, financeApplied, complete, conflict }

enum ExpenseReplacementStatus { completed, alreadyComplete, conflict, failed }

enum ExpenseReplacementReason {
  financeV3Required,
  intentNotPersisted,
  intentConflict,
  intentReadFailed,
  balanceNotFound,
  duplicateBalance,
  financeConflict,
  expenseConflict,
  financeWriteFailed,
  expenseWriteFailed,
  intentCleanupFailed,
}

class ExpenseReplacementResult {
  final ExpenseReplacementStatus status;
  final ExpenseReplacementState state;
  final ExpenseReplacementReason? reason;
  final List<String> errors;

  ExpenseReplacementResult._({
    required this.status,
    required this.state,
    required this.reason,
    Iterable<String> errors = const [],
  }) : errors = List.unmodifiable(errors);

  factory ExpenseReplacementResult.completed() => ExpenseReplacementResult._(
    status: ExpenseReplacementStatus.completed,
    state: ExpenseReplacementState.complete,
    reason: null,
  );

  factory ExpenseReplacementResult.alreadyComplete() =>
      ExpenseReplacementResult._(
        status: ExpenseReplacementStatus.alreadyComplete,
        state: ExpenseReplacementState.complete,
        reason: null,
      );

  factory ExpenseReplacementResult.conflict(
    ExpenseReplacementReason reason,
    Iterable<String> errors,
  ) => ExpenseReplacementResult._(
    status: ExpenseReplacementStatus.conflict,
    state: ExpenseReplacementState.conflict,
    reason: reason,
    errors: errors,
  );

  factory ExpenseReplacementResult.failed(
    ExpenseReplacementReason reason,
    ExpenseReplacementState state,
    Iterable<String> errors,
  ) => ExpenseReplacementResult._(
    status: ExpenseReplacementStatus.failed,
    state: state,
    reason: reason,
    errors: errors,
  );
}

class ExpenseReplacementCoordinator {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final ExpenseReplacementPersistence persistence;

  const ExpenseReplacementCoordinator({
    required this.financeStore,
    required this.expenseStore,
    required this.persistence,
  });

  Future<ExpenseReplacementResult> complete(
    ExpenseReplacementIntent intent,
  ) async {
    if (!financeStore.isPortfolioV3Authoritative) {
      return ExpenseReplacementResult.conflict(
        ExpenseReplacementReason.financeV3Required,
        const ['Finance Portfolio V3 must be authoritative'],
      );
    }

    ExpenseReplacementIntent? persisted;
    try {
      persisted = await persistence.findByReplacementId(intent.replacementId);
    } catch (error) {
      return ExpenseReplacementResult.failed(
        ExpenseReplacementReason.intentReadFailed,
        ExpenseReplacementState.conflict,
        ['Expense replacement intent cannot be read: $error'],
      );
    }
    if (persisted != null && !_sameIntent(persisted, intent)) {
      return ExpenseReplacementResult.conflict(
        ExpenseReplacementReason.intentConflict,
        const ['Persisted expense replacement intent is incompatible'],
      );
    }

    final context = _context(intent);
    if (context.failure != null) return context.failure!;
    var observed = _classify(intent, context.expected!);
    if (observed.failure != null) return observed.failure!;

    if (persisted == null) {
      return observed.state == ExpenseReplacementState.complete
          ? ExpenseReplacementResult.alreadyComplete()
          : ExpenseReplacementResult.conflict(
              ExpenseReplacementReason.intentNotPersisted,
              const ['Expense replacement intent is not persisted'],
            );
    }

    if (observed.state == ExpenseReplacementState.complete) {
      return _cleanup(intent, alreadyComplete: true);
    }

    if (observed.state == ExpenseReplacementState.ready) {
      final expectedAmounts = _expectedAmountsAfterFinance(context.expected!);
      final financeCommit = await financeStore.commitPortfolioV3Candidate(
        (current) => _financeCandidate(current, context.expected!),
      );
      if (!financeCommit.isSuccess) {
        return ExpenseReplacementResult.failed(
          ExpenseReplacementReason.financeWriteFailed,
          ExpenseReplacementState.ready,
          financeCommit.errors,
        );
      }
      observed = _classify(intent, context.expected!);
      if (observed.failure != null) return observed.failure!;
      if (observed.state != ExpenseReplacementState.financeApplied) {
        return ExpenseReplacementResult.conflict(
          ExpenseReplacementReason.financeConflict,
          const ['Finance replacement state is not verifiable after commit'],
        );
      }
      for (final entry in expectedAmounts.entries) {
        final actual = financeStore.balances
            .singleWhere((item) => item.balanceId == entry.key)
            .currentAmount;
        if (actual != entry.value) {
          return ExpenseReplacementResult.conflict(
            ExpenseReplacementReason.financeConflict,
            ['Unexpected balance after Finance commit: ${entry.key}'],
          );
        }
      }
    }

    final replacement = await expenseStore.replaceExpenseVerified(
      original: intent.originalExpense,
      replacement: context.expected!.replacementExpense,
    );
    if (!replacement.isSuccess) {
      final isConflict =
          replacement.status == VerifiedExpenseReplacementStatus.conflict;
      return isConflict
          ? ExpenseReplacementResult.conflict(
              ExpenseReplacementReason.expenseConflict,
              replacement.errors,
            )
          : ExpenseReplacementResult.failed(
              ExpenseReplacementReason.expenseWriteFailed,
              ExpenseReplacementState.financeApplied,
              replacement.errors,
            );
    }

    observed = _classify(intent, context.expected!);
    if (observed.failure != null) return observed.failure!;
    if (observed.state != ExpenseReplacementState.complete) {
      return ExpenseReplacementResult.conflict(
        ExpenseReplacementReason.expenseConflict,
        const ['Expense replacement is not complete after verified write'],
      );
    }
    return _cleanup(intent, alreadyComplete: false);
  }

  Future<ExpenseReplacementResult> _cleanup(
    ExpenseReplacementIntent intent, {
    required bool alreadyComplete,
  }) async {
    try {
      final removed = await persistence.remove(intent.replacementId);
      if (!removed) return ExpenseReplacementResult.alreadyComplete();
    } catch (error) {
      return ExpenseReplacementResult.failed(
        ExpenseReplacementReason.intentCleanupFailed,
        ExpenseReplacementState.complete,
        ['Expense replacement intent cleanup failed: $error'],
      );
    }
    return alreadyComplete
        ? ExpenseReplacementResult.alreadyComplete()
        : ExpenseReplacementResult.completed();
  }

  _ReplacementContext _context(ExpenseReplacementIntent intent) {
    final oldMatches = financeStore.balances
        .where(
          (balance) => balance.balanceId == intent.originalExpense.balanceId,
        )
        .toList();
    final newMatches = financeStore.balances
        .where(
          (balance) => balance.balanceId == intent.replacementPayload.balanceId,
        )
        .toList();
    if (oldMatches.isEmpty || newMatches.isEmpty) {
      return _ReplacementContext.failed(
        ExpenseReplacementReason.balanceNotFound,
        'Original or replacement balance was not found',
      );
    }
    if (oldMatches.length != 1 || newMatches.length != 1) {
      return _ReplacementContext.failed(
        ExpenseReplacementReason.duplicateBalance,
        'Original or replacement balance is duplicated',
      );
    }
    return _ReplacementContext.success(
      _ExpectedReplacement(intent, oldMatches.single, newMatches.single),
    );
  }

  _ObservedReplacement _classify(
    ExpenseReplacementIntent intent,
    _ExpectedReplacement expected,
  ) {
    final compensation = _matchTransaction(expected.compensationTransaction);
    final replacementFinance = _matchTransaction(
      expected.replacementTransaction,
    );
    if (compensation.conflict || replacementFinance.conflict) {
      return _ObservedReplacement.failed(
        ExpenseReplacementReason.financeConflict,
        'Deterministic Finance identity has incompatible content',
      );
    }
    if (compensation.present != replacementFinance.present) {
      return _ObservedReplacement.failed(
        ExpenseReplacementReason.financeConflict,
        'Expense replacement Finance facts are partially present',
      );
    }

    final original = _matchExpense(intent.originalExpense);
    final replacement = _matchExpense(expected.replacementExpense);
    if (original.conflict || replacement.conflict) {
      return _ObservedReplacement.failed(
        ExpenseReplacementReason.expenseConflict,
        'Original or replacement Expense has incompatible content',
      );
    }
    if (original.present == replacement.present) {
      return _ObservedReplacement.failed(
        ExpenseReplacementReason.expenseConflict,
        original.present
            ? 'Original and replacement Expense are both present'
            : 'Original and replacement Expense are both absent',
      );
    }

    final financeApplied = compensation.present;
    final expenseComplete = replacement.present;
    if (!financeApplied && expenseComplete) {
      return _ObservedReplacement.failed(
        ExpenseReplacementReason.financeConflict,
        'Replacement Expense cannot precede Finance replacement facts',
      );
    }
    if (!financeApplied) {
      return const _ObservedReplacement(ExpenseReplacementState.ready);
    }
    return expenseComplete
        ? const _ObservedReplacement(ExpenseReplacementState.complete)
        : const _ObservedReplacement(ExpenseReplacementState.financeApplied);
  }

  FinancePortfolioV3 _financeCandidate(
    FinancePortfolioV3 current,
    _ExpectedReplacement expected,
  ) {
    final balances = List<FinanceBalance>.of(current.balances);
    _applyDelta(
      balances,
      expected.originalBalance.balanceId,
      expected.intent.originalExpense.amount,
      expected.intent.replacementPayload.preparedAt,
    );
    _applyDelta(
      balances,
      expected.replacementBalance.balanceId,
      -expected.intent.replacementPayload.amount,
      expected.intent.replacementPayload.preparedAt,
    );
    return FinancePortfolioV3(
      balances: balances,
      funds: current.funds,
      assetMovements: current.assetMovements,
      transactions: [
        ...current.transactions,
        expected.compensationTransaction,
        expected.replacementTransaction,
      ],
      fundTransactions: current.fundTransactions,
      linkedItems: current.linkedItems,
    );
  }

  Map<String, double> _expectedAmountsAfterFinance(
    _ExpectedReplacement expected,
  ) {
    final amounts = {
      for (final balance in financeStore.balances)
        balance.balanceId: balance.currentAmount,
    };
    amounts[expected.originalBalance.balanceId] =
        amounts[expected.originalBalance.balanceId]! +
        expected.intent.originalExpense.amount;
    amounts[expected.replacementBalance.balanceId] =
        amounts[expected.replacementBalance.balanceId]! -
        expected.intent.replacementPayload.amount;
    return {
      expected.originalBalance.balanceId:
          amounts[expected.originalBalance.balanceId]!,
      expected.replacementBalance.balanceId:
          amounts[expected.replacementBalance.balanceId]!,
    };
  }

  void _applyDelta(
    List<FinanceBalance> balances,
    String balanceId,
    double delta,
    DateTime updatedAt,
  ) {
    final index = balances.indexWhere((item) => item.balanceId == balanceId);
    final current = balances[index];
    balances[index] = FinanceBalance(
      personId: current.personId,
      balanceId: current.balanceId,
      name: current.name,
      initialAmount: current.initialAmount,
      currentAmount: current.currentAmount + delta,
      updatedAt: updatedAt,
      balanceType: current.balanceType,
      operational: current.operational,
      active: current.active,
      reservedAmount: current.reservedAmount,
      warningThreshold: current.warningThreshold,
      persistentStressDays: current.persistentStressDays,
      recoveryDays: current.recoveryDays,
    );
  }

  _IdentityMatch _matchTransaction(FinanceTransaction expected) {
    final matches = financeStore.transactions
        .where(
          (item) =>
              item.id == expected.id ||
              item.economicFactId == expected.economicFactId,
        )
        .toList();
    if (matches.isEmpty) return const _IdentityMatch.absent();
    if (matches.length != 1 || !_sameTransaction(matches.single, expected)) {
      return const _IdentityMatch.conflict();
    }
    return const _IdentityMatch.present();
  }

  _IdentityMatch _matchExpense(RealExpense expected) {
    final matches = expenseStore.all
        .where(
          (item) =>
              item.id == expected.id ||
              (expected.economicFactId != null &&
                  item.economicFactId == expected.economicFactId),
        )
        .toList();
    if (matches.isEmpty) return const _IdentityMatch.absent();
    if (matches.length != 1 || !_sameExpense(matches.single, expected)) {
      return const _IdentityMatch.conflict();
    }
    return const _IdentityMatch.present();
  }

  static bool _sameIntent(
    ExpenseReplacementIntent left,
    ExpenseReplacementIntent right,
  ) => jsonEncode(left.toJson()) == jsonEncode(right.toJson());

  static bool _sameTransaction(
    FinanceTransaction left,
    FinanceTransaction right,
  ) =>
      left.id == right.id &&
      left.balanceId == right.balanceId &&
      left.amount == right.amount &&
      left.date == right.date &&
      left.isIncome == right.isIncome &&
      left.subject == right.subject &&
      left.description == right.description &&
      left.type == right.type &&
      left.origin == right.origin &&
      left.recurringItemId == right.recurringItemId &&
      left.notes == right.notes &&
      left.economicFactId == right.economicFactId &&
      jsonEncode(left.operationMetadata?.toJson()) ==
          jsonEncode(right.operationMetadata?.toJson()) &&
      jsonEncode(left.expenseReplacementMetadata?.toJson()) ==
          jsonEncode(right.expenseReplacementMetadata?.toJson());

  static bool _sameExpense(RealExpense left, RealExpense right) =>
      left.id == right.id &&
      left.balanceId == right.balanceId &&
      left.balanceName == right.balanceName &&
      left.amount == right.amount &&
      left.description == right.description &&
      left.category == right.category &&
      left.date == right.date &&
      left.nonTrackedCash == right.nonTrackedCash &&
      left.isCashWithdrawal == right.isCashWithdrawal &&
      left.isIncome == right.isIncome &&
      left.subject == right.subject &&
      left.cashWalletId == right.cashWalletId &&
      left.economicFactId == right.economicFactId &&
      jsonEncode(left.operationMetadata?.toJson()) ==
          jsonEncode(right.operationMetadata?.toJson());
}

class _ExpectedReplacement {
  final ExpenseReplacementIntent intent;
  final FinanceBalance originalBalance;
  final FinanceBalance replacementBalance;

  const _ExpectedReplacement(
    this.intent,
    this.originalBalance,
    this.replacementBalance,
  );

  FinanceSubject get replacementSubject => FinanceSubject.values.firstWhere(
    (subject) => subject.name == intent.replacementPayload.personId,
    orElse: () => FinanceSubject.shared,
  );

  FinanceSubject get compensationSubject => FinanceSubject.values.firstWhere(
    (subject) => subject.name == originalBalance.personId,
    orElse: () => FinanceSubject.shared,
  );

  ExpenseReplacementMetadata? _metadata(ExpenseReplacementRole role) {
    final originalEconomicFactId = intent.originalExpense.economicFactId;
    if (originalEconomicFactId == null) return null;
    return ExpenseReplacementMetadata(
      originalEconomicFactId: originalEconomicFactId,
      replacementEconomicFactId: intent.identities.replacementEconomicFactId,
      role: role,
    );
  }

  FinanceTransaction get compensationTransaction => FinanceTransaction(
    id: intent.identities.compensationTransactionId,
    balanceId: originalBalance.balanceId,
    amount: intent.originalExpense.amount,
    date: intent.replacementPayload.preparedAt,
    isIncome: true,
    subject: compensationSubject,
    description: 'Annullamento ${intent.originalExpense.description}',
    type: FinanceTransactionType.income,
    origin: FinanceTransactionOrigin.manual,
    notes: 'Ripristino movimento sostituito',
    economicFactId: intent.identities.compensationEconomicFactId,
    expenseReplacementMetadata: _metadata(ExpenseReplacementRole.compensation),
  );

  FinanceTransaction get replacementTransaction => FinanceTransaction(
    id: intent.identities.replacementTransactionId,
    balanceId: replacementBalance.balanceId,
    amount: intent.replacementPayload.amount,
    date: intent.replacementPayload.occurredAt,
    isIncome: false,
    subject: replacementSubject,
    description: intent.replacementPayload.description,
    type: FinanceTransactionType.expense,
    origin: FinanceTransactionOrigin.manual,
    notes: intent.replacementPayload.category,
    economicFactId: intent.identities.replacementEconomicFactId,
    expenseReplacementMetadata: _metadata(ExpenseReplacementRole.replacement),
  );

  RealExpense get replacementExpense => RealExpense(
    id: intent.identities.replacementCommandId,
    balanceId: intent.replacementPayload.balanceId,
    balanceName: intent.replacementPayload.balanceName,
    amount: intent.replacementPayload.amount,
    description: intent.replacementPayload.description,
    category: intent.replacementPayload.category,
    date: intent.replacementPayload.occurredAt,
    subject: replacementSubject,
    economicFactId: intent.identities.replacementEconomicFactId,
  );
}

class _ReplacementContext {
  final _ExpectedReplacement? expected;
  final ExpenseReplacementResult? failure;

  const _ReplacementContext.success(this.expected) : failure = null;
  _ReplacementContext.failed(ExpenseReplacementReason reason, String error)
    : expected = null,
      failure = ExpenseReplacementResult.conflict(reason, [error]);
}

class _ObservedReplacement {
  final ExpenseReplacementState state;
  final ExpenseReplacementResult? failure;

  const _ObservedReplacement(this.state) : failure = null;
  _ObservedReplacement.failed(ExpenseReplacementReason reason, String error)
    : state = ExpenseReplacementState.conflict,
      failure = ExpenseReplacementResult.conflict(reason, [error]);
}

class _IdentityMatch {
  final bool present;
  final bool conflict;

  const _IdentityMatch.absent() : present = false, conflict = false;
  const _IdentityMatch.present() : present = true, conflict = false;
  const _IdentityMatch.conflict() : present = false, conflict = true;
}
