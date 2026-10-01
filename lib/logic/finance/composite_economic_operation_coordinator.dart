import 'dart:convert';

import '../../models/composite_economic_operation.dart';
import '../../models/balance_posting_mode.dart';
import '../../models/economic_operation_metadata.dart';
import '../../models/finance_balance.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/finance_transaction.dart';
import '../../models/real_expense.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';
import 'finance_portfolio_v3_contract.dart';

enum CompositeEconomicOperationStatus {
  completed,
  alreadyComplete,
  inconsistent,
  failed,
}

enum CompositeEconomicOperationReason {
  financeV3Required,
  balanceNotFound,
  duplicateBalance,
  inactiveBalance,
  unsupportedSharedSubject,
  subjectBalanceMismatch,
  financeFactsConflict,
  expenseFactsConflict,
  financeWriteFailed,
  expenseWriteFailed,
}

class CompositeEconomicOperationResult {
  final CompositeEconomicOperationStatus status;
  final CompositeEconomicOperationReason? reason;
  final List<String> errors;

  CompositeEconomicOperationResult._({
    required this.status,
    required this.reason,
    Iterable<String> errors = const [],
  }) : errors = List.unmodifiable(errors);

  factory CompositeEconomicOperationResult.completed() =>
      CompositeEconomicOperationResult._(
        status: CompositeEconomicOperationStatus.completed,
        reason: null,
      );

  factory CompositeEconomicOperationResult.alreadyComplete() =>
      CompositeEconomicOperationResult._(
        status: CompositeEconomicOperationStatus.alreadyComplete,
        reason: null,
      );

  factory CompositeEconomicOperationResult.inconsistent(
    CompositeEconomicOperationReason reason,
    Iterable<String> errors,
  ) => CompositeEconomicOperationResult._(
    status: CompositeEconomicOperationStatus.inconsistent,
    reason: reason,
    errors: errors,
  );

  factory CompositeEconomicOperationResult.failed(
    CompositeEconomicOperationReason reason,
    Iterable<String> errors,
  ) => CompositeEconomicOperationResult._(
    status: CompositeEconomicOperationStatus.failed,
    reason: reason,
    errors: errors,
  );
}

class CompositeEconomicOperationPosting {
  final CompositeEconomicOperation operation;
  final String debitBalanceId;
  final FinanceSubject subject;
  final DateTime economicDate;
  final String description;
  final String category;
  final BalancePostingMode balancePostingMode;

  CompositeEconomicOperationPosting({
    required this.operation,
    required String debitBalanceId,
    required this.subject,
    required this.economicDate,
    required String description,
    required String category,
    this.balancePostingMode = BalancePostingMode.affectsCurrentBalance,
  }) : debitBalanceId = _requiredText(debitBalanceId, 'debitBalanceId'),
       description = _requiredText(description, 'description'),
       category = _requiredText(category, 'category');

  static String _requiredText(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be empty');
    }
    return normalized;
  }
}

class CompositeEconomicOperationCoordinator {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;

  const CompositeEconomicOperationCoordinator({
    required this.financeStore,
    required this.expenseStore,
  });

  Future<CompositeEconomicOperationResult> record(
    CompositeEconomicOperationPosting posting,
  ) async {
    final context = _validateContext(posting);
    if (context.failure != null) return context.failure!;
    final expected = _ExpectedRecords(posting, context.balance!);
    final finance = _classifyFinance(expected);
    final expenses = _classifyExpenses(expected);

    if (finance.conflict != null) return finance.conflict!;
    if (expenses.conflict != null) return expenses.conflict!;
    if (!finance.complete && expenses.anyPresent) {
      return CompositeEconomicOperationResult.inconsistent(
        CompositeEconomicOperationReason.expenseFactsConflict,
        const ['Expense facts cannot precede their Finance facts'],
      );
    }
    if (finance.complete && expenses.complete) {
      return CompositeEconomicOperationResult.alreadyComplete();
    }

    if (!finance.complete) {
      final candidateBalances = List<FinanceBalance>.of(financeStore.balances);
      final balanceIndex = candidateBalances.indexWhere(
        (item) => item.balanceId == context.balance!.balanceId,
      );
      if (posting.balancePostingMode ==
          BalancePostingMode.affectsCurrentBalance) {
        candidateBalances[balanceIndex] = _balanceAfterOutflow(
          context.balance!,
          posting.operation.totalAmount,
          posting.economicDate,
        );
      }
      final candidateTransactions = List<FinanceTransaction>.of(
        financeStore.transactions,
      )..addAll(expected.transactions);
      final commit = await financeStore.commitPortfolioV3Candidate(
        (current) => FinancePortfolioV3(
          balances: candidateBalances,
          funds: current.funds,
          assetMovements: current.assetMovements,
          transactions: candidateTransactions,
          fundTransactions: current.fundTransactions,
          linkedItems: current.linkedItems,
        ),
      );
      if (!commit.isSuccess) {
        return CompositeEconomicOperationResult.failed(
          CompositeEconomicOperationReason.financeWriteFailed,
          commit.errors,
        );
      }
    }

    for (var index = 0; index < expected.expenses.length; index++) {
      if (expenses.present[index]) continue;
      final addition = await expenseStore.addExpenseVerified(
        expected.expenses[index],
      );
      if (!addition.isSuccess) {
        final reason = addition.status == VerifiedExpenseAddStatus.conflict
            ? CompositeEconomicOperationReason.expenseFactsConflict
            : CompositeEconomicOperationReason.expenseWriteFailed;
        final errors = addition.errors.isEmpty
            ? ['Expense write failed at index $index']
            : addition.errors;
        return addition.status == VerifiedExpenseAddStatus.conflict
            ? CompositeEconomicOperationResult.inconsistent(reason, errors)
            : CompositeEconomicOperationResult.failed(reason, errors);
      }
    }

    return CompositeEconomicOperationResult.completed();
  }

  _ContextValidation _validateContext(
    CompositeEconomicOperationPosting posting,
  ) {
    if (!financeStore.isPortfolioV3Authoritative) {
      return _ContextValidation.failed(
        CompositeEconomicOperationReason.financeV3Required,
        'Finance Portfolio V3 must be authoritative',
      );
    }
    final balances = financeStore.balances
        .where((item) => item.balanceId == posting.debitBalanceId)
        .toList();
    if (balances.isEmpty) {
      return _ContextValidation.failed(
        CompositeEconomicOperationReason.balanceNotFound,
        'Debit balance not found: ${posting.debitBalanceId}',
      );
    }
    if (balances.length != 1) {
      return _ContextValidation.failed(
        CompositeEconomicOperationReason.duplicateBalance,
        'Duplicate debit balance: ${posting.debitBalanceId}',
      );
    }
    final balance = balances.single;
    if (!balance.active) {
      return _ContextValidation.failed(
        CompositeEconomicOperationReason.inactiveBalance,
        'Debit balance is inactive: ${balance.balanceId}',
      );
    }
    if (posting.subject == FinanceSubject.shared) {
      return _ContextValidation.failed(
        CompositeEconomicOperationReason.unsupportedSharedSubject,
        'Shared subject has no structural balance ownership rule',
      );
    }
    if (balance.personId != posting.subject.name) {
      return _ContextValidation.failed(
        CompositeEconomicOperationReason.subjectBalanceMismatch,
        'Operation subject does not own the debit balance',
      );
    }
    return _ContextValidation.success(balance);
  }

  _FinanceClassification _classifyFinance(_ExpectedRecords expected) {
    final matches = expected.transactions
        .map(_matchTransaction)
        .toList(growable: false);
    if (matches.any((match) => match.conflict)) {
      return _FinanceClassification.conflict(
        'Finance fact identity exists with incompatible content',
      );
    }
    final presentCount = matches.where((match) => match.present).length;
    if (presentCount != 0 && presentCount != matches.length) {
      return _FinanceClassification.conflict(
        'Composite Finance facts are only partially present',
      );
    }
    return _FinanceClassification(complete: presentCount == matches.length);
  }

  _ExpenseClassification _classifyExpenses(_ExpectedRecords expected) {
    final matches = expected.expenses
        .map(_matchExpense)
        .toList(growable: false);
    if (matches.any((match) => match.conflict)) {
      return _ExpenseClassification.conflict(
        'Expense fact identity exists with incompatible content',
      );
    }
    final present = matches.map((match) => match.present).toList();
    var missingSeen = false;
    for (final isPresent in present) {
      if (!isPresent) {
        missingSeen = true;
      } else if (missingSeen) {
        return _ExpenseClassification.conflict(
          'Composite Expense facts are not a recoverable prefix',
        );
      }
    }
    return _ExpenseClassification(present);
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
              item.economicFactId == expected.economicFactId,
        )
        .toList();
    if (matches.isEmpty) return const _IdentityMatch.absent();
    if (matches.length != 1 || !_sameExpense(matches.single, expected)) {
      return const _IdentityMatch.conflict();
    }
    return const _IdentityMatch.present();
  }

  static FinanceBalance _balanceAfterOutflow(
    FinanceBalance balance,
    double amount,
    DateTime economicDate,
  ) => FinanceBalance(
    personId: balance.personId,
    balanceId: balance.balanceId,
    name: balance.name,
    initialAmount: balance.initialAmount,
    currentAmount: balance.currentAmount - amount,
    updatedAt: economicDate,
    balanceType: balance.balanceType,
    operational: balance.operational,
    active: balance.active,
    reservedAmount: balance.reservedAmount,
    warningThreshold: balance.warningThreshold,
    persistentStressDays: balance.persistentStressDays,
    recoveryDays: balance.recoveryDays,
  );

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
      left.balancePostingMode == right.balancePostingMode &&
      _sameMetadata(left.operationMetadata, right.operationMetadata);

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
      left.balancePostingMode == right.balancePostingMode &&
      _sameMetadata(left.operationMetadata, right.operationMetadata);

  static bool _sameMetadata(
    EconomicOperationMetadata? left,
    EconomicOperationMetadata? right,
  ) {
    if (left == null || right == null) return left == right;
    return left.operationId == right.operationId &&
        left.role == right.role &&
        left.context == right.context &&
        left.accessoryCostType == right.accessoryCostType &&
        left.documentaryObligationId == right.documentaryObligationId &&
        left.documentHolder == right.documentHolder;
  }
}

class _ExpectedRecords {
  final CompositeEconomicOperationPosting posting;
  final FinanceBalance balance;
  late final List<FinanceTransaction> transactions = _facts
      .map(_transaction)
      .toList(growable: false);
  late final List<RealExpense> expenses = _facts
      .map(_expense)
      .toList(growable: false);

  _ExpectedRecords(this.posting, this.balance);

  List<CompositeEconomicFact> get _facts => [
    posting.operation.main,
    ...posting.operation.accessories,
  ];

  String _encodedFactId(CompositeEconomicFact fact) =>
      base64Url.encode(utf8.encode(fact.economicFactId));

  FinanceTransaction _transaction(CompositeEconomicFact fact) =>
      FinanceTransaction(
        id: 'finance_transaction:composite:${_encodedFactId(fact)}',
        balanceId: balance.balanceId,
        amount: fact.amount,
        date: posting.economicDate,
        isIncome: false,
        subject: posting.subject,
        description: posting.description,
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
        notes: posting.category,
        economicFactId: fact.economicFactId,
        operationMetadata: fact.operationMetadata,
        balancePostingMode: posting.balancePostingMode,
      );

  RealExpense _expense(CompositeEconomicFact fact) => RealExpense(
    id: 'real_expense:composite:${_encodedFactId(fact)}',
    balanceId: balance.balanceId,
    balanceName: balance.name,
    amount: fact.amount,
    description: posting.description,
    category: posting.category,
    date: posting.economicDate,
    subject: posting.subject,
    economicFactId: fact.economicFactId,
    operationMetadata: fact.operationMetadata,
    balancePostingMode: posting.balancePostingMode,
  );
}

class _ContextValidation {
  final FinanceBalance? balance;
  final CompositeEconomicOperationResult? failure;

  const _ContextValidation.success(this.balance) : failure = null;
  _ContextValidation.failed(
    CompositeEconomicOperationReason reason,
    String error,
  ) : balance = null,
      failure = CompositeEconomicOperationResult.inconsistent(reason, [error]);
}

class _FinanceClassification {
  final bool complete;
  final CompositeEconomicOperationResult? conflict;

  const _FinanceClassification({required this.complete}) : conflict = null;
  _FinanceClassification.conflict(String error)
    : complete = false,
      conflict = CompositeEconomicOperationResult.inconsistent(
        CompositeEconomicOperationReason.financeFactsConflict,
        [error],
      );
}

class _ExpenseClassification {
  final List<bool> present;
  final CompositeEconomicOperationResult? conflict;

  _ExpenseClassification(Iterable<bool> present)
    : present = List.unmodifiable(present),
      conflict = null;
  _ExpenseClassification.conflict(String error)
    : present = const [],
      conflict = CompositeEconomicOperationResult.inconsistent(
        CompositeEconomicOperationReason.expenseFactsConflict,
        [error],
      );

  bool get complete => present.isNotEmpty && present.every((item) => item);
  bool get anyPresent => present.any((item) => item);
}

class _IdentityMatch {
  final bool present;
  final bool conflict;

  const _IdentityMatch.absent() : present = false, conflict = false;
  const _IdentityMatch.present() : present = true, conflict = false;
  const _IdentityMatch.conflict() : present = false, conflict = true;
}
