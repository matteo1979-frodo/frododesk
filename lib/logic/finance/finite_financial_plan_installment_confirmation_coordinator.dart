import '../../models/economic_operation_metadata.dart';
import '../../models/finance_balance.dart';
import '../../models/finance_transaction.dart';
import '../../models/finite_financial_plan.dart';
import '../../models/finite_financial_plan_installment_confirmation.dart';
import '../../models/real_expense.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';
import 'finance_portfolio_v3_contract.dart';

enum FinitePlanInstallmentConfirmationStatus {
  completed,
  alreadyComplete,
  inconsistent,
  failed,
}

enum FinitePlanInstallmentConfirmationReason {
  financeV3Required,
  planNotFound,
  duplicatePlan,
  invalidProgression,
  planMismatch,
  balanceNotFound,
  duplicateBalance,
  inactiveBalance,
  unsupportedSharedSubject,
  subjectBalanceMismatch,
  financeFactsConflict,
  expenseFactsConflict,
  financeWriteFailed,
  expenseWriteFailed,
  planWriteFailed,
}

class FinitePlanInstallmentConfirmationResult {
  final FinitePlanInstallmentConfirmationStatus status;
  final FinitePlanInstallmentConfirmationReason? reason;
  final List<String> errors;

  FinitePlanInstallmentConfirmationResult._({
    required this.status,
    required this.reason,
    Iterable<String> errors = const [],
  }) : errors = List.unmodifiable(errors);

  factory FinitePlanInstallmentConfirmationResult.completed() =>
      FinitePlanInstallmentConfirmationResult._(
        status: FinitePlanInstallmentConfirmationStatus.completed,
        reason: null,
      );

  factory FinitePlanInstallmentConfirmationResult.alreadyComplete() =>
      FinitePlanInstallmentConfirmationResult._(
        status: FinitePlanInstallmentConfirmationStatus.alreadyComplete,
        reason: null,
      );

  factory FinitePlanInstallmentConfirmationResult.inconsistent(
    FinitePlanInstallmentConfirmationReason reason,
    Iterable<String> errors,
  ) => FinitePlanInstallmentConfirmationResult._(
    status: FinitePlanInstallmentConfirmationStatus.inconsistent,
    reason: reason,
    errors: errors,
  );

  factory FinitePlanInstallmentConfirmationResult.failed(
    FinitePlanInstallmentConfirmationReason reason,
    Iterable<String> errors,
  ) => FinitePlanInstallmentConfirmationResult._(
    status: FinitePlanInstallmentConfirmationStatus.failed,
    reason: reason,
    errors: errors,
  );
}

class FiniteFinancialPlanInstallmentConfirmationCoordinator {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;

  const FiniteFinancialPlanInstallmentConfirmationCoordinator({
    required this.financeStore,
    required this.expenseStore,
  });

  Future<FinitePlanInstallmentConfirmationResult> confirm(
    FiniteFinancialPlanInstallmentConfirmation confirmation,
  ) async {
    final context = _validateContext(confirmation);
    if (context.failure != null) return context.failure!;
    final plan = context.plan!;
    final balance = context.balance!;
    final expected = _ExpectedRecords(confirmation, balance);
    final finance = _classifyFinance(expected);
    final expenses = _classifyExpenses(expected);

    if (finance.conflict != null) return finance.conflict!;
    if (expenses.conflict != null) return expenses.conflict!;

    final progression = _classifyProgression(
      plan: plan,
      confirmation: confirmation,
      allFactsComplete: finance.complete && expenses.complete,
    );
    if (progression != null) return progression;

    if (!finance.complete) {
      if (expenses.anyPresent) {
        return FinitePlanInstallmentConfirmationResult.inconsistent(
          FinitePlanInstallmentConfirmationReason.expenseFactsConflict,
          const ['Expense facts cannot precede their Finance facts'],
        );
      }
      final candidateBalances = List<FinanceBalance>.of(financeStore.balances);
      final balanceIndex = candidateBalances.indexWhere(
        (item) => item.balanceId == balance.balanceId,
      );
      candidateBalances[balanceIndex] = _balanceAfterOutflow(
        balance,
        confirmation.totalAccountOutflow,
        confirmation.economicDate,
      );
      final candidateTransactions = List<FinanceTransaction>.of(
        financeStore.transactions,
      )..add(expected.mainTransaction);
      if (expected.feeTransaction != null) {
        candidateTransactions.add(expected.feeTransaction!);
      }
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
        return FinitePlanInstallmentConfirmationResult.failed(
          FinitePlanInstallmentConfirmationReason.financeWriteFailed,
          commit.errors,
        );
      }
    }

    final mainExpense = await expenseStore.addExpenseVerified(
      expected.mainExpense,
    );
    final mainFailure = _expenseFailure(mainExpense, 'main');
    if (mainFailure != null) return mainFailure;

    if (expected.feeExpense != null) {
      final feeExpense = await expenseStore.addExpenseVerified(
        expected.feeExpense!,
      );
      final feeFailure = _expenseFailure(feeExpense, 'fee');
      if (feeFailure != null) return feeFailure;
    }

    if (plan.completedInstallments == confirmation.installmentNumber) {
      return FinitePlanInstallmentConfirmationResult.alreadyComplete();
    }

    try {
      final updated = await financeStore.updateFiniteFinancialPlan(
        _advancePlan(plan, confirmation.installmentNumber),
      );
      if (!updated) {
        return FinitePlanInstallmentConfirmationResult.failed(
          FinitePlanInstallmentConfirmationReason.planWriteFailed,
          const ['Finite financial plan was not advanced'],
        );
      }
    } catch (error) {
      return FinitePlanInstallmentConfirmationResult.failed(
        FinitePlanInstallmentConfirmationReason.planWriteFailed,
        ['Finite financial plan persistence failed: $error'],
      );
    }
    return FinitePlanInstallmentConfirmationResult.completed();
  }

  _ContextValidation _validateContext(
    FiniteFinancialPlanInstallmentConfirmation confirmation,
  ) {
    if (!financeStore.isPortfolioV3Authoritative) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.financeV3Required,
        'Finance Portfolio V3 must be authoritative',
      );
    }
    final plans = financeStore.finiteFinancialPlans
        .where((item) => item.id == confirmation.planId)
        .toList();
    if (plans.isEmpty) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.planNotFound,
        'Finite financial plan not found: ${confirmation.planId}',
      );
    }
    if (plans.length != 1) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.duplicatePlan,
        'Duplicate finite financial plan: ${confirmation.planId}',
      );
    }
    final plan = plans.single;
    if (confirmation.installmentNumber > plan.totalInstallments ||
        confirmation.installmentNumber < 1) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.invalidProgression,
        'Installment is outside the plan bounds',
      );
    }
    if (plan.debitBalanceId != confirmation.debitBalanceId ||
        plan.subject != confirmation.subject) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.planMismatch,
        'Confirmation does not match plan subject or debit balance',
      );
    }
    final balances = financeStore.balances
        .where((item) => item.balanceId == confirmation.debitBalanceId)
        .toList();
    if (balances.isEmpty) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.balanceNotFound,
        'Debit balance not found: ${confirmation.debitBalanceId}',
      );
    }
    if (balances.length != 1) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.duplicateBalance,
        'Duplicate debit balance: ${confirmation.debitBalanceId}',
      );
    }
    final balance = balances.single;
    if (!balance.active) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.inactiveBalance,
        'Debit balance is inactive: ${balance.balanceId}',
      );
    }
    if (confirmation.subject.name == 'shared') {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.unsupportedSharedSubject,
        'Shared subject has no structural balance ownership rule',
      );
    }
    if (balance.personId != confirmation.subject.name) {
      return _ContextValidation.failed(
        FinitePlanInstallmentConfirmationReason.subjectBalanceMismatch,
        'Confirmation subject does not own the debit balance',
      );
    }
    return _ContextValidation.success(plan, balance);
  }

  _FactsClassification _classifyFinance(_ExpectedRecords expected) {
    final main = _matchTransaction(expected.mainTransaction);
    final fee = _matchTransactionIdentity(
      expected.feeTransactionId,
      expected.feeEconomicFactId,
      expected.feeTransaction,
    );
    if (main.conflict || fee.conflict) {
      return _FactsClassification.conflict(
        FinitePlanInstallmentConfirmationReason.financeFactsConflict,
        'Finance fact identity exists with incompatible content',
      );
    }
    if (expected.hasFee && main.present != fee.present) {
      return _FactsClassification.conflict(
        FinitePlanInstallmentConfirmationReason.financeFactsConflict,
        'Main and fee Finance facts are only partially present',
      );
    }
    if (!expected.hasFee && fee.present) {
      return _FactsClassification.conflict(
        FinitePlanInstallmentConfirmationReason.financeFactsConflict,
        'Unexpected fee Finance fact exists',
      );
    }
    return _FactsClassification(
      complete: main.present && (!expected.hasFee || fee.present),
      anyPresent: main.present || fee.present,
    );
  }

  _FactsClassification _classifyExpenses(_ExpectedRecords expected) {
    final main = _matchExpense(expected.mainExpense);
    final fee = _matchExpenseIdentity(
      expected.feeExpenseId,
      expected.feeEconomicFactId,
      expected.feeExpense,
    );
    if (main.conflict || fee.conflict) {
      return _FactsClassification.conflict(
        FinitePlanInstallmentConfirmationReason.expenseFactsConflict,
        'Expense fact identity exists with incompatible content',
      );
    }
    if (!expected.hasFee && fee.present) {
      return _FactsClassification.conflict(
        FinitePlanInstallmentConfirmationReason.expenseFactsConflict,
        'Unexpected fee expense fact exists',
      );
    }
    if (expected.hasFee && fee.present && !main.present) {
      return _FactsClassification.conflict(
        FinitePlanInstallmentConfirmationReason.expenseFactsConflict,
        'Fee expense cannot precede the main expense',
      );
    }
    return _FactsClassification(
      complete: main.present && (!expected.hasFee || fee.present),
      anyPresent: main.present || fee.present,
    );
  }

  FinitePlanInstallmentConfirmationResult? _classifyProgression({
    required FiniteFinancialPlan plan,
    required FiniteFinancialPlanInstallmentConfirmation confirmation,
    required bool allFactsComplete,
  }) {
    final target = confirmation.installmentNumber;
    if (plan.completedInstallments > target ||
        plan.completedInstallments < target - 1) {
      return FinitePlanInstallmentConfirmationResult.inconsistent(
        FinitePlanInstallmentConfirmationReason.invalidProgression,
        ['Plan progression is incompatible with installment $target'],
      );
    }
    if (plan.completedInstallments == target) {
      return allFactsComplete
          ? FinitePlanInstallmentConfirmationResult.alreadyComplete()
          : FinitePlanInstallmentConfirmationResult.inconsistent(
              FinitePlanInstallmentConfirmationReason.invalidProgression,
              const ['Plan is advanced but required facts are incomplete'],
            );
    }
    return null;
  }

  _IdentityMatch _matchTransaction(FinanceTransaction expected) =>
      _matchTransactionIdentity(
        expected.id,
        expected.economicFactId!,
        expected,
      );

  _IdentityMatch _matchTransactionIdentity(
    String id,
    String factId,
    FinanceTransaction? expected,
  ) {
    final matches = financeStore.transactions
        .where((item) => item.id == id || item.economicFactId == factId)
        .toList();
    if (matches.isEmpty) return const _IdentityMatch.absent();
    if (matches.length != 1 ||
        expected == null ||
        !_sameTransaction(matches.single, expected)) {
      return const _IdentityMatch.conflict();
    }
    return const _IdentityMatch.present();
  }

  _IdentityMatch _matchExpense(RealExpense expected) =>
      _matchExpenseIdentity(expected.id, expected.economicFactId!, expected);

  _IdentityMatch _matchExpenseIdentity(
    String id,
    String factId,
    RealExpense? expected,
  ) {
    final matches = expenseStore.all
        .where((item) => item.id == id || item.economicFactId == factId)
        .toList();
    if (matches.isEmpty) return const _IdentityMatch.absent();
    if (matches.length != 1 ||
        expected == null ||
        !_sameExpense(matches.single, expected)) {
      return const _IdentityMatch.conflict();
    }
    return const _IdentityMatch.present();
  }

  FinitePlanInstallmentConfirmationResult? _expenseFailure(
    VerifiedExpenseAddResult result,
    String role,
  ) {
    if (result.isSuccess) return null;
    final reason = result.status == VerifiedExpenseAddStatus.conflict
        ? FinitePlanInstallmentConfirmationReason.expenseFactsConflict
        : FinitePlanInstallmentConfirmationReason.expenseWriteFailed;
    final message = result.errors.isEmpty
        ? '$role expense write failed'
        : result.errors.join('; ');
    return result.status == VerifiedExpenseAddStatus.conflict
        ? FinitePlanInstallmentConfirmationResult.inconsistent(reason, [
            message,
          ])
        : FinitePlanInstallmentConfirmationResult.failed(reason, [message]);
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

  static FiniteFinancialPlan _advancePlan(
    FiniteFinancialPlan plan,
    int completedInstallments,
  ) => FiniteFinancialPlan(
    id: plan.id,
    name: plan.name,
    description: plan.description,
    subject: plan.subject,
    creditor: plan.creditor,
    debitBalanceId: plan.debitBalanceId,
    totalInstallments: plan.totalInstallments,
    frequency: plan.frequency,
    expectedInstallmentAmount: plan.expectedInstallmentAmount,
    installmentAmountOverrides: plan.installmentAmountOverrides,
    firstInstallmentDate: plan.firstInstallmentDate,
    scheduledDayOfMonth: plan.scheduledDayOfMonth,
    completedInstallments: completedInstallments,
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
      left.economicFactId == right.economicFactId;

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
      left.economicFactId == right.economicFactId;
}

class _ExpectedRecords {
  final FiniteFinancialPlanInstallmentConfirmation confirmation;
  final FinanceBalance balance;

  const _ExpectedRecords(this.confirmation, this.balance);

  bool get hasFee => confirmation.hasBankFee;
  String get mainTransactionId =>
      'finance_transaction:${confirmation.installmentIdentity}:main';
  String get feeTransactionId =>
      'finance_transaction:${confirmation.installmentIdentity}:fee';
  String get mainExpenseId =>
      'real_expense:${confirmation.installmentIdentity}:main';
  String get feeExpenseId =>
      'real_expense:${confirmation.installmentIdentity}:fee';
  String get feeEconomicFactId =>
      'economic_fact:${confirmation.installmentIdentity}:fee';
  String get operationId => confirmation.installmentIdentity;

  EconomicOperationMetadata get mainOperationMetadata =>
      EconomicOperationMetadata(
        operationId: operationId,
        role: OperationRole.main,
        context: OperationContext.financialPlanInstallment,
      );

  EconomicOperationMetadata get feeOperationMetadata =>
      EconomicOperationMetadata(
        operationId: operationId,
        role: OperationRole.accessory,
        context: OperationContext.financialPlanInstallment,
        accessoryCostType: AccessoryCostType.bankCommission,
      );

  FinanceTransaction get mainTransaction => _transaction(
    id: mainTransactionId,
    amount: confirmation.mainAmount,
    economicFactId: confirmation.mainEconomicFactId,
    category: confirmation.mainCategory,
    operationMetadata: mainOperationMetadata,
  );

  FinanceTransaction? get feeTransaction => hasFee
      ? _transaction(
          id: feeTransactionId,
          amount: confirmation.bankFee!,
          economicFactId: confirmation.feeEconomicFactId!,
          category: confirmation.bankFeeCategory!,
          operationMetadata: feeOperationMetadata,
        )
      : null;

  RealExpense get mainExpense => _expense(
    id: mainExpenseId,
    amount: confirmation.mainAmount,
    economicFactId: confirmation.mainEconomicFactId,
    category: confirmation.mainCategory,
    operationMetadata: mainOperationMetadata,
  );

  RealExpense? get feeExpense => hasFee
      ? _expense(
          id: feeExpenseId,
          amount: confirmation.bankFee!,
          economicFactId: confirmation.feeEconomicFactId!,
          category: confirmation.bankFeeCategory!,
          operationMetadata: feeOperationMetadata,
        )
      : null;

  FinanceTransaction _transaction({
    required String id,
    required double amount,
    required String economicFactId,
    required String category,
    required EconomicOperationMetadata operationMetadata,
  }) => FinanceTransaction(
    id: id,
    balanceId: confirmation.debitBalanceId,
    amount: amount,
    date: confirmation.economicDate,
    isIncome: false,
    subject: confirmation.subject,
    description: confirmation.description,
    type: FinanceTransactionType.expense,
    origin: FinanceTransactionOrigin.manual,
    notes: category,
    economicFactId: economicFactId,
    operationMetadata: operationMetadata,
  );

  RealExpense _expense({
    required String id,
    required double amount,
    required String economicFactId,
    required String category,
    required EconomicOperationMetadata operationMetadata,
  }) => RealExpense(
    id: id,
    balanceId: balance.balanceId,
    balanceName: balance.name,
    amount: amount,
    description: confirmation.description,
    category: category,
    date: confirmation.economicDate,
    subject: confirmation.subject,
    economicFactId: economicFactId,
    operationMetadata: operationMetadata,
  );
}

class _ContextValidation {
  final FiniteFinancialPlan? plan;
  final FinanceBalance? balance;
  final FinitePlanInstallmentConfirmationResult? failure;

  const _ContextValidation.success(this.plan, this.balance) : failure = null;
  _ContextValidation.failed(
    FinitePlanInstallmentConfirmationReason reason,
    String error,
  ) : plan = null,
      balance = null,
      failure = FinitePlanInstallmentConfirmationResult.inconsistent(reason, [
        error,
      ]);
}

class _FactsClassification {
  final bool complete;
  final bool anyPresent;
  final FinitePlanInstallmentConfirmationResult? conflict;

  const _FactsClassification({required this.complete, required this.anyPresent})
    : conflict = null;

  _FactsClassification.conflict(
    FinitePlanInstallmentConfirmationReason reason,
    String error,
  ) : complete = false,
      anyPresent = false,
      conflict = FinitePlanInstallmentConfirmationResult.inconsistent(reason, [
        error,
      ]);
}

class _IdentityMatch {
  final bool present;
  final bool conflict;

  const _IdentityMatch.absent() : present = false, conflict = false;
  const _IdentityMatch.present() : present = true, conflict = false;
  const _IdentityMatch.conflict() : present = false, conflict = true;
}
