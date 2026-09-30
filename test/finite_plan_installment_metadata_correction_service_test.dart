import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/finance/finite_plan_installment_metadata_correction_service.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/balance_posting_mode.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('complete legacy snapshot is SAFE UPDATE', () async {
    final harness = await _Harness.create();

    final preview = harness.service.preview(harness.request);

    expect(
      preview.classification,
      FinitePlanInstallmentMetadataCorrectionClassification.safeUpdate,
    );
    expect(preview.changedFields, hasLength(4));
  });

  test('complete corrected snapshot is NO-OP', () async {
    final harness = await _Harness.create(financeModern: true, expenseModern: true);

    final preview = harness.service.preview(harness.request);

    expect(
      preview.classification,
      FinitePlanInstallmentMetadataCorrectionClassification.noOp,
    );
    expect(preview.changedFields, isEmpty);
  });

  test('different protected economic field is CONFLICT', () async {
    final harness = await _Harness.create(mainAmount: 99);

    expect(
      harness.service.preview(harness.request).classification,
      FinitePlanInstallmentMetadataCorrectionClassification.conflict,
    );
  });

  test('missing record is CONFLICT', () async {
    final harness = await _Harness.create(omitAccessoryExpense: true);

    expect(
      harness.service.preview(harness.request).classification,
      FinitePlanInstallmentMetadataCorrectionClassification.conflict,
    );
  });

  test('duplicate or colliding identity is CONFLICT', () async {
    final harness = await _Harness.create(duplicateMainTransaction: true);

    expect(
      harness.service.preview(harness.request).classification,
      FinitePlanInstallmentMetadataCorrectionClassification.conflict,
    );
  });

  test('unexpected metadata is CONFLICT', () async {
    final harness = await _Harness.create(unexpectedMetadata: true);

    expect(
      harness.service.preview(harness.request).classification,
      FinitePlanInstallmentMetadataCorrectionClassification.conflict,
    );
  });

  test('partially modernized pair in one store is CONFLICT', () async {
    final harness = await _Harness.create(modernMainExpenseOnly: true);

    expect(
      harness.service.preview(harness.request).classification,
      FinitePlanInstallmentMetadataCorrectionClassification.conflict,
    );
  });

  test('modern Finance plus legacy Expense is recoverable SAFE UPDATE', () async {
    final harness = await _Harness.create(financeModern: true);

    final preview = harness.service.preview(harness.request);

    expect(
      preview.classification,
      FinitePlanInstallmentMetadataCorrectionClassification.safeUpdate,
    );
    expect(preview.changedFields, [
      'RealExpense main.operationMetadata',
      'RealExpense fee.operationMetadata',
    ]);
  });

  test('modern Expense plus legacy Finance is recoverable SAFE UPDATE', () async {
    final harness = await _Harness.create(expenseModern: true);

    final preview = harness.service.preview(harness.request);

    expect(
      preview.classification,
      FinitePlanInstallmentMetadataCorrectionClassification.safeUpdate,
    );
    expect(preview.changedFields, [
      'FinanceTransaction main.operationMetadata',
      'FinanceTransaction fee.operationMetadata',
    ]);
  });

  test('apply changes only operationMetadata and retry is NO-OP', () async {
    final harness = await _Harness.create();
    final expenseBefore = harness.expenseStore.all.map(_withoutMetadata).toList();
    final financeBefore = harness.financeStore.transactions
        .map(_withoutTransactionMetadata)
        .toList();

    final result = await harness.service.apply(harness.request);

    expect(
      result.status,
      FinitePlanInstallmentMetadataCorrectionApplyStatus.updated,
    );
    expect(harness.expenseStore.all.map(_withoutMetadata), expenseBefore);
    expect(
      harness.financeStore.transactions.map(_withoutTransactionMetadata),
      financeBefore,
    );
    expect(harness.expenseStore.all[0].operationMetadata!.role, OperationRole.main);
    expect(
      harness.expenseStore.all[1].operationMetadata!.accessoryCostType,
      AccessoryCostType.bankCommission,
    );
    expect(
      (await harness.service.apply(harness.request)).status,
      FinitePlanInstallmentMetadataCorrectionApplyStatus.alreadyCoherent,
    );
  });

  test('Finance read-back mismatch does not publish unverified state', () async {
    final harness = await _Harness.create(failFinanceReadBack: true);
    final before = harness.financeStore.transactions
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    final result = await harness.service.apply(harness.request);

    expect(
      result.status,
      FinitePlanInstallmentMetadataCorrectionApplyStatus.writerFailed,
    );
    expect(
      harness.financeStore.transactions.map((item) => jsonEncode(item.toJson())),
      before,
    );
    expect(harness.expenseStore.all.every((item) => item.operationMetadata == null), isTrue);
  });

  test('Expense read-back mismatch does not publish Expense candidate', () async {
    final harness = await _Harness.create(
      financeModern: true,
      failExpenseReadBack: true,
    );

    final result = await harness.service.apply(harness.request);

    expect(
      result.status,
      FinitePlanInstallmentMetadataCorrectionApplyStatus.writerFailed,
    );
    expect(harness.expenseStore.all.every((item) => item.operationMetadata == null), isTrue);
  });
}

class _Harness {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final FinitePlanInstallmentMetadataCorrectionService service;
  final FinitePlanInstallmentMetadataCorrectionRequest request;

  _Harness({
    required this.financeStore,
    required this.expenseStore,
    required this.service,
    required this.request,
  });

  static Future<_Harness> create({
    bool financeModern = false,
    bool expenseModern = false,
    bool modernMainExpenseOnly = false,
    bool unexpectedMetadata = false,
    bool omitAccessoryExpense = false,
    bool duplicateMainTransaction = false,
    bool failFinanceReadBack = false,
    bool failExpenseReadBack = false,
    double mainAmount = 10,
  }) async {
    const operationId = 'finite_plan_installment:encoded-plan:3';
    final mainMetadata = EconomicOperationMetadata(
      operationId: operationId,
      role: OperationRole.main,
      context: OperationContext.financialPlanInstallment,
    );
    final accessoryMetadata = EconomicOperationMetadata(
      operationId: operationId,
      role: OperationRole.accessory,
      context: OperationContext.financialPlanInstallment,
      accessoryCostType: AccessoryCostType.bankCommission,
    );
    final alienMetadata = EconomicOperationMetadata(
      operationId: 'another-operation',
      role: OperationRole.main,
      context: OperationContext.financialPlanInstallment,
    );
    final expectedMainExpense = _expense(role: 'main', amount: 10);
    final expectedAccessoryExpense = _expense(role: 'fee', amount: 1);
    final expectedMainTransaction = _transaction(role: 'main', amount: 10);
    final expectedAccessoryTransaction = _transaction(role: 'fee', amount: 1);
    final expenses = <RealExpense>[
      _expense(
        role: 'main',
        amount: mainAmount,
        metadata: unexpectedMetadata
            ? alienMetadata
            : (expenseModern || modernMainExpenseOnly ? mainMetadata : null),
      ),
      if (!omitAccessoryExpense)
        _expense(
          role: 'fee',
          amount: 1,
          metadata: expenseModern ? accessoryMetadata : null,
        ),
    ];
    final transactions = <FinanceTransaction>[
      _transaction(
        role: 'main',
        amount: 10,
        metadata: financeModern ? mainMetadata : null,
      ),
      _transaction(
        role: 'fee',
        amount: 1,
        metadata: financeModern ? accessoryMetadata : null,
      ),
      if (duplicateMainTransaction)
        _transaction(
          role: 'main',
          amount: 10,
          id: 'duplicate-id',
        ),
    ];
    String expenseRaw = jsonEncode(expenses.map((item) => item.toJson()).toList());
    final expenseStore = ExpenseStore(
      load: (_) async => expenseRaw,
      saveVerified: (_, value) async {
        if (!failExpenseReadBack) expenseRaw = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: failExpenseReadBack ? '[]' : value,
        );
      },
    );
    await expenseStore.load();
    final financeStore = FinanceStore(
      initialBalances: [_balance()],
      initialTransactions: transactions,
      portfolioV3Writer: FinancePortfolioV3Writer(
        saveVerified: (_, value) async => PersistenceWriteVerification(
          backendAccepted: true,
          readBack: failFinanceReadBack ? '{}' : value,
        ),
      ),
    );
    final request = FinitePlanInstallmentMetadataCorrectionRequest(
      operationId: operationId,
      accessoryCostType: AccessoryCostType.bankCommission,
      expectedMainExpense: expectedMainExpense,
      expectedAccessoryExpense: expectedAccessoryExpense,
      expectedMainTransaction: expectedMainTransaction,
      expectedAccessoryTransaction: expectedAccessoryTransaction,
    );
    final service = FinitePlanInstallmentMetadataCorrectionService(
      financeStore: financeStore,
      expenseStore: expenseStore,
    );
    return _Harness(
      financeStore: financeStore,
      expenseStore: expenseStore,
      service: service,
      request: request,
    );
  }
}

RealExpense _expense({
  required String role,
  required double amount,
  EconomicOperationMetadata? metadata,
}) => RealExpense(
  id: 'real_expense:finite_plan_installment:encoded-plan:3:$role',
  balanceId: 'balance',
  balanceName: 'Bank',
  amount: amount,
  description: 'Installment',
  category: 'Legal',
  date: DateTime(2026, 9, 16),
  subject: FinanceSubject.matteo,
  economicFactId: 'economic_fact:finite_plan_installment:encoded-plan:3:$role',
  operationMetadata: metadata,
  balancePostingMode: BalancePostingMode.alreadyIncludedInCurrentBalance,
);

FinanceTransaction _transaction({
  required String role,
  required double amount,
  String? id,
  EconomicOperationMetadata? metadata,
}) => FinanceTransaction(
  id: id ?? 'finance_transaction:finite_plan_installment:encoded-plan:3:$role',
  balanceId: 'balance',
  amount: amount,
  date: DateTime(2026, 9, 16),
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: 'Installment',
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  notes: 'Legal',
  economicFactId: 'economic_fact:finite_plan_installment:encoded-plan:3:$role',
  operationMetadata: metadata,
  balancePostingMode: BalancePostingMode.alreadyIncludedInCurrentBalance,
);

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'balance',
  name: 'Bank',
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime(2026, 9, 16),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

String _withoutMetadata(RealExpense expense) {
  final json = expense.toJson()..remove('operationMetadata');
  return jsonEncode(json);
}

String _withoutTransactionMetadata(FinanceTransaction transaction) {
  final json = transaction.toJson()..remove('operationMetadata');
  return jsonEncode(json);
}
