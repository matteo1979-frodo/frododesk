import 'dart:convert';

import '../../models/economic_operation_metadata.dart';
import '../../models/finance_transaction.dart';
import '../../models/real_expense.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';
import 'finance_portfolio_v3_contract.dart';

enum FinitePlanInstallmentMetadataCorrectionClassification {
  safeUpdate,
  noOp,
  conflict,
}

class FinitePlanInstallmentMetadataCorrectionRequest {
  final String operationId;
  final AccessoryCostType accessoryCostType;
  final RealExpense expectedMainExpense;
  final RealExpense expectedAccessoryExpense;
  final FinanceTransaction expectedMainTransaction;
  final FinanceTransaction expectedAccessoryTransaction;

  const FinitePlanInstallmentMetadataCorrectionRequest({
    required this.operationId,
    required this.accessoryCostType,
    required this.expectedMainExpense,
    required this.expectedAccessoryExpense,
    required this.expectedMainTransaction,
    required this.expectedAccessoryTransaction,
  });
}

class FinitePlanInstallmentMetadataCorrectionPreview {
  final FinitePlanInstallmentMetadataCorrectionClassification classification;
  final String operationId;
  final List<String> errors;
  final List<String> changedFields;
  final List<RealExpense> expenses;
  final List<FinanceTransaction> transactions;

  FinitePlanInstallmentMetadataCorrectionPreview({
    required this.classification,
    required this.operationId,
    required Iterable<String> errors,
    required Iterable<String> changedFields,
    required Iterable<RealExpense> expenses,
    required Iterable<FinanceTransaction> transactions,
  }) : errors = List.unmodifiable(errors),
       changedFields = List.unmodifiable(changedFields),
       expenses = List.unmodifiable(expenses),
       transactions = List.unmodifiable(transactions);
}

enum FinitePlanInstallmentMetadataCorrectionApplyStatus {
  updated,
  alreadyCoherent,
  conflict,
  writerFailed,
}

class FinitePlanInstallmentMetadataCorrectionApplyResult {
  final FinitePlanInstallmentMetadataCorrectionApplyStatus status;
  final List<String> errors;

  FinitePlanInstallmentMetadataCorrectionApplyResult(
    this.status, [
    Iterable<String> errors = const [],
  ]) : errors = List.unmodifiable(errors);

  bool get isSuccess =>
      status == FinitePlanInstallmentMetadataCorrectionApplyStatus.updated ||
      status ==
          FinitePlanInstallmentMetadataCorrectionApplyStatus.alreadyCoherent;
}

class FinitePlanInstallmentMetadataCorrectionService {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;

  const FinitePlanInstallmentMetadataCorrectionService({
    required this.financeStore,
    required this.expenseStore,
  });

  FinitePlanInstallmentMetadataCorrectionPreview preview(
    FinitePlanInstallmentMetadataCorrectionRequest request,
  ) {
    final errors = <String>[];
    if (!expenseStore.isLoaded) {
      errors.add('ExpenseStore is not loaded');
    }
    if (request.operationId.trim().isEmpty) {
      errors.add('Operation identity is empty');
    }
    if (!_requestIdentitiesAreDistinct(request)) {
      errors.add('Target identities are missing or collide');
    }
    if (request.expectedMainExpense.operationMetadata != null ||
        request.expectedAccessoryExpense.operationMetadata != null ||
        request.expectedMainTransaction.operationMetadata != null ||
        request.expectedAccessoryTransaction.operationMetadata != null) {
      errors.add('The protected legacy snapshot must have null metadata');
    }

    final mainExpense = _findExpense(request.expectedMainExpense, errors);
    final accessoryExpense = _findExpense(
      request.expectedAccessoryExpense,
      errors,
    );
    final mainTransaction = _findTransaction(
      request.expectedMainTransaction,
      errors,
    );
    final accessoryTransaction = _findTransaction(
      request.expectedAccessoryTransaction,
      errors,
    );
    final expenses = [
      if (mainExpense != null) mainExpense,
      if (accessoryExpense != null) accessoryExpense,
    ];
    final transactions = [
      if (mainTransaction != null) mainTransaction,
      if (accessoryTransaction != null) accessoryTransaction,
    ];

    if (errors.isNotEmpty ||
        expenses.length != 2 ||
        transactions.length != 2) {
      return _preview(
        request,
        FinitePlanInstallmentMetadataCorrectionClassification.conflict,
        errors,
        const [],
        expenses,
        transactions,
      );
    }

    final expenseState = _pairState(
      actualMain: mainExpense!,
      actualAccessory: accessoryExpense!,
      expectedMain: request.expectedMainExpense,
      expectedAccessory: request.expectedAccessoryExpense,
      targetMain: _expenseWithMetadata(
        request.expectedMainExpense,
        _mainMetadata(request),
      ),
      targetAccessory: _expenseWithMetadata(
        request.expectedAccessoryExpense,
        _accessoryMetadata(request),
      ),
      encode: (value) => (value as RealExpense).toJson(),
    );
    final transactionState = _pairState(
      actualMain: mainTransaction!,
      actualAccessory: accessoryTransaction!,
      expectedMain: request.expectedMainTransaction,
      expectedAccessory: request.expectedAccessoryTransaction,
      targetMain: _transactionWithMetadata(
        request.expectedMainTransaction,
        _mainMetadata(request),
      ),
      targetAccessory: _transactionWithMetadata(
        request.expectedAccessoryTransaction,
        _accessoryMetadata(request),
      ),
      encode: (value) => (value as FinanceTransaction).toJson(),
    );
    if (expenseState == _PairState.conflict ||
        transactionState == _PairState.conflict) {
      errors.add(
        'A target pair differs from both the protected legacy snapshot and '
        'the complete corrected snapshot',
      );
      return _preview(
        request,
        FinitePlanInstallmentMetadataCorrectionClassification.conflict,
        errors,
        const [],
        expenses,
        transactions,
      );
    }

    if (expenseState == _PairState.modern &&
        transactionState == _PairState.modern) {
      return _preview(
        request,
        FinitePlanInstallmentMetadataCorrectionClassification.noOp,
        const [],
        const [],
        expenses,
        transactions,
      );
    }
    final changedFields = <String>[
      if (expenseState == _PairState.legacy)
        'RealExpense main.operationMetadata',
      if (expenseState == _PairState.legacy)
        'RealExpense fee.operationMetadata',
      if (transactionState == _PairState.legacy)
        'FinanceTransaction main.operationMetadata',
      if (transactionState == _PairState.legacy)
        'FinanceTransaction fee.operationMetadata',
    ];
    return _preview(
      request,
      FinitePlanInstallmentMetadataCorrectionClassification.safeUpdate,
      const [],
      changedFields,
      expenses,
      transactions,
    );
  }

  Future<FinitePlanInstallmentMetadataCorrectionApplyResult> apply(
    FinitePlanInstallmentMetadataCorrectionRequest request,
  ) async {
    var current = preview(request);
    if (current.classification ==
        FinitePlanInstallmentMetadataCorrectionClassification.conflict) {
      return FinitePlanInstallmentMetadataCorrectionApplyResult(
        FinitePlanInstallmentMetadataCorrectionApplyStatus.conflict,
        current.errors,
      );
    }
    if (current.classification ==
        FinitePlanInstallmentMetadataCorrectionClassification.noOp) {
      return FinitePlanInstallmentMetadataCorrectionApplyResult(
        FinitePlanInstallmentMetadataCorrectionApplyStatus.alreadyCoherent,
      );
    }

    if (current.changedFields.any(
      (field) => field.startsWith('FinanceTransaction'),
    )) {
      final commit = await financeStore.commitPortfolioV3Candidate((portfolio) {
        final transactions = List<FinanceTransaction>.of(
          portfolio.transactions,
        );
        _replaceTransaction(
          transactions,
          request.expectedMainTransaction,
          _transactionWithMetadata(
            request.expectedMainTransaction,
            _mainMetadata(request),
          ),
        );
        _replaceTransaction(
          transactions,
          request.expectedAccessoryTransaction,
          _transactionWithMetadata(
            request.expectedAccessoryTransaction,
            _accessoryMetadata(request),
          ),
        );
        return FinancePortfolioV3(
          balances: portfolio.balances,
          funds: portfolio.funds,
          assetMovements: portfolio.assetMovements,
          transactions: transactions,
          fundTransactions: portfolio.fundTransactions,
          linkedItems: portfolio.linkedItems,
        );
      });
      if (!commit.isSuccess) {
        return FinitePlanInstallmentMetadataCorrectionApplyResult(
          FinitePlanInstallmentMetadataCorrectionApplyStatus.writerFailed,
          commit.errors,
        );
      }
      current = preview(request);
      if (current.classification ==
          FinitePlanInstallmentMetadataCorrectionClassification.conflict) {
        return FinitePlanInstallmentMetadataCorrectionApplyResult(
          FinitePlanInstallmentMetadataCorrectionApplyStatus.conflict,
          current.errors,
        );
      }
    }

    if (current.changedFields.any((field) => field.startsWith('RealExpense'))) {
      final expectedCurrent = expenseStore.all;
      final candidate = expectedCurrent.map((expense) {
        if (_sameIdentity(expense, request.expectedMainExpense)) {
          return _expenseWithMetadata(expense, _mainMetadata(request));
        }
        if (_sameIdentity(expense, request.expectedAccessoryExpense)) {
          return _expenseWithMetadata(expense, _accessoryMetadata(request));
        }
        return expense;
      }).toList();
      final commit = await expenseStore.commitRecoveryCandidateVerified(
        expectedCurrent: expectedCurrent,
        candidate: candidate,
      );
      if (!commit.isSuccess) {
        return FinitePlanInstallmentMetadataCorrectionApplyResult(
          commit.status == VerifiedExpenseRecoveryStatus.conflict
              ? FinitePlanInstallmentMetadataCorrectionApplyStatus.conflict
              : FinitePlanInstallmentMetadataCorrectionApplyStatus.writerFailed,
          commit.errors,
        );
      }
    }

    final finalPreview = preview(request);
    if (finalPreview.classification !=
        FinitePlanInstallmentMetadataCorrectionClassification.noOp) {
      return FinitePlanInstallmentMetadataCorrectionApplyResult(
        FinitePlanInstallmentMetadataCorrectionApplyStatus.writerFailed,
        ['Post-write verification is not coherent', ...finalPreview.errors],
      );
    }
    return FinitePlanInstallmentMetadataCorrectionApplyResult(
      FinitePlanInstallmentMetadataCorrectionApplyStatus.updated,
    );
  }

  FinitePlanInstallmentMetadataCorrectionPreview _preview(
    FinitePlanInstallmentMetadataCorrectionRequest request,
    FinitePlanInstallmentMetadataCorrectionClassification classification,
    Iterable<String> errors,
    Iterable<String> changedFields,
    Iterable<RealExpense> expenses,
    Iterable<FinanceTransaction> transactions,
  ) => FinitePlanInstallmentMetadataCorrectionPreview(
    classification: classification,
    operationId: request.operationId,
    errors: errors,
    changedFields: changedFields,
    expenses: expenses,
    transactions: transactions,
  );

  RealExpense? _findExpense(RealExpense expected, List<String> errors) {
    final matches = expenseStore.all
        .where(
          (item) =>
              item.id == expected.id ||
              item.economicFactId == expected.economicFactId,
        )
        .toList();
    if (matches.length != 1 || !_sameIdentity(matches.single, expected)) {
      errors.add(
        'Expense identity is missing, duplicated, or colliding: ${expected.id}',
      );
      return null;
    }
    return matches.single;
  }

  FinanceTransaction? _findTransaction(
    FinanceTransaction expected,
    List<String> errors,
  ) {
    final matches = financeStore.transactions
        .where(
          (item) =>
              item.id == expected.id ||
              item.economicFactId == expected.economicFactId,
        )
        .toList();
    if (matches.length != 1 || !_sameIdentity(matches.single, expected)) {
      errors.add(
        'Finance transaction identity is missing, duplicated, or colliding: '
        '${expected.id}',
      );
      return null;
    }
    return matches.single;
  }

  bool _requestIdentitiesAreDistinct(
    FinitePlanInstallmentMetadataCorrectionRequest request,
  ) {
    final ids = <String>{
      request.expectedMainExpense.id,
      request.expectedAccessoryExpense.id,
      request.expectedMainTransaction.id,
      request.expectedAccessoryTransaction.id,
    };
    final facts = <String?>{
      request.expectedMainExpense.economicFactId,
      request.expectedAccessoryExpense.economicFactId,
      request.expectedMainTransaction.economicFactId,
      request.expectedAccessoryTransaction.economicFactId,
    };
    return ids.length == 4 &&
        !ids.contains('') &&
        facts.length == 2 &&
        !facts.contains(null) &&
        !facts.contains('') &&
        request.expectedMainExpense.economicFactId ==
            request.expectedMainTransaction.economicFactId &&
        request.expectedAccessoryExpense.economicFactId ==
            request.expectedAccessoryTransaction.economicFactId;
  }

  _PairState _pairState<T>({
    required T actualMain,
    required T actualAccessory,
    required T expectedMain,
    required T expectedAccessory,
    required T targetMain,
    required T targetAccessory,
    required Map<String, dynamic> Function(T value) encode,
  }) {
    final mainLegacy = _sameJson(encode(actualMain), encode(expectedMain));
    final accessoryLegacy = _sameJson(
      encode(actualAccessory),
      encode(expectedAccessory),
    );
    final mainModern = _sameJson(encode(actualMain), encode(targetMain));
    final accessoryModern = _sameJson(
      encode(actualAccessory),
      encode(targetAccessory),
    );
    if (mainLegacy && accessoryLegacy) return _PairState.legacy;
    if (mainModern && accessoryModern) return _PairState.modern;
    return _PairState.conflict;
  }

  EconomicOperationMetadata _mainMetadata(
    FinitePlanInstallmentMetadataCorrectionRequest request,
  ) => EconomicOperationMetadata(
    operationId: request.operationId,
    role: OperationRole.main,
    context: OperationContext.financialPlanInstallment,
  );

  EconomicOperationMetadata _accessoryMetadata(
    FinitePlanInstallmentMetadataCorrectionRequest request,
  ) => EconomicOperationMetadata(
    operationId: request.operationId,
    role: OperationRole.accessory,
    context: OperationContext.financialPlanInstallment,
    accessoryCostType: request.accessoryCostType,
  );

  RealExpense _expenseWithMetadata(
    RealExpense source,
    EconomicOperationMetadata metadata,
  ) => RealExpense(
    id: source.id,
    balanceId: source.balanceId,
    balanceName: source.balanceName,
    amount: source.amount,
    description: source.description,
    category: source.category,
    date: source.date,
    nonTrackedCash: source.nonTrackedCash,
    isCashWithdrawal: source.isCashWithdrawal,
    isIncome: source.isIncome,
    subject: source.subject,
    cashWalletId: source.cashWalletId,
    economicFactId: source.economicFactId,
    operationMetadata: metadata,
    balancePostingMode: source.balancePostingMode,
  );

  FinanceTransaction _transactionWithMetadata(
    FinanceTransaction source,
    EconomicOperationMetadata metadata,
  ) => FinanceTransaction(
    id: source.id,
    balanceId: source.balanceId,
    amount: source.amount,
    date: source.date,
    isIncome: source.isIncome,
    subject: source.subject,
    description: source.description,
    type: source.type,
    origin: source.origin,
    recurringItemId: source.recurringItemId,
    notes: source.notes,
    economicFactId: source.economicFactId,
    operationMetadata: metadata,
    expenseReplacementMetadata: source.expenseReplacementMetadata,
    balancePostingMode: source.balancePostingMode,
  );

  void _replaceTransaction(
    List<FinanceTransaction> transactions,
    FinanceTransaction expected,
    FinanceTransaction replacement,
  ) {
    final index = transactions.indexWhere(
      (item) => _sameIdentity(item, expected),
    );
    if (index < 0 || !_sameJson(transactions[index].toJson(), expected.toJson())) {
      throw StateError('Finance transaction changed after correction preview');
    }
    transactions[index] = replacement;
  }

  bool _sameIdentity(dynamic left, dynamic right) =>
      left.id == right.id && left.economicFactId == right.economicFactId;

  bool _sameJson(Map<String, dynamic> left, Map<String, dynamic> right) =>
      jsonEncode(left) == jsonEncode(right);
}

enum _PairState { legacy, modern, conflict }
