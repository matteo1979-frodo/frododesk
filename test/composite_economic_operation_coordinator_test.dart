import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/composite_economic_operation_coordinator.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/composite_economic_operation.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('records synthetic utility operation with one Finance commit', () async {
    var financeWrites = 0;
    final harness = await _Harness.create(
      financeWriter: FinancePortfolioV3Writer(
        saveVerified: (key, value) async {
          financeWrites++;
          return PersistenceStore.saveStringVerified(key, value);
        },
      ),
    );

    final result = await harness.coordinator.record(_posting());

    expect(result.status, CompositeEconomicOperationStatus.completed);
    expect(financeWrites, 1);
    expect(
      harness.finance.balances.single.currentAmount,
      closeTo(937.37, 1e-9),
    );
    expect(harness.finance.transactions, hasLength(3));
    expect(harness.expenses.all, hasLength(3));
    expect(harness.finance.transactions.map((item) => item.amount), [
      59.63,
      2,
      1,
    ]);
    expect(
      harness.finance.transactions.map((item) => item.economicFactId).toSet(),
      {'fact-main', 'fact-bank-fee', 'fact-postal-fee'},
    );
    expect(harness.expenses.all.map((item) => item.economicFactId).toSet(), {
      'fact-main',
      'fact-bank-fee',
      'fact-postal-fee',
    });
    expect(
      harness.finance.transactions
          .map((item) => item.operationMetadata?.operationId)
          .toSet(),
      {'operation-utility'},
    );
    expect(
      harness.expenses.all
          .map((item) => item.operationMetadata?.operationId)
          .toSet(),
      {'operation-utility'},
    );
    for (final records in [
      harness.finance.transactions
          .map((item) => item.operationMetadata!)
          .toList(),
      harness.expenses.all.map((item) => item.operationMetadata!).toList(),
    ]) {
      expect(records[0].role, OperationRole.main);
      expect(records[0].accessoryCostType, isNull);
      expect(records[1].role, OperationRole.accessory);
      expect(records[1].accessoryCostType, AccessoryCostType.bankCommission);
      expect(records[2].role, OperationRole.accessory);
      expect(
        records[2].accessoryCostType,
        AccessoryCostType.postalAcceptanceCharge,
      );
      expect(records.map((metadata) => metadata.context).toSet(), {
        OperationContext.utilityBill,
      });
    }

    final events = const EconomicEventCorrelator().correlate(
      const EconomicEventCollector().collect(
        transactions: harness.finance.transactions,
        assetMovements: const [],
        realExpenses: harness.expenses.all,
        observedAt: DateTime(2026, 9, 16, 12),
      ),
    );
    expect(events, hasLength(3));
    expect(events.every((event) => event.sourceLinks.length == 2), isTrue);
    expect(
      events.map((event) => event.operationMetadata?.operationId).toSet(),
      {'operation-utility'},
    );
  });

  test('complete retry is inert and reports alreadyComplete', () async {
    final harness = await _Harness.create();
    expect(
      (await harness.coordinator.record(_posting())).status,
      CompositeEconomicOperationStatus.completed,
    );
    final balance = harness.finance.balances.single.currentAmount;

    final retry = await harness.coordinator.record(_posting());

    expect(retry.status, CompositeEconomicOperationStatus.alreadyComplete);
    expect(harness.finance.balances.single.currentAmount, balance);
    expect(harness.finance.transactions, hasLength(3));
    expect(harness.expenses.all, hasLength(3));
  });

  test('Finance writer failure leaves every store unchanged', () async {
    final harness = await _Harness.create(
      financeWriter: FinancePortfolioV3Writer(
        saveVerified: (key, value) async => const PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      ),
    );

    final result = await harness.coordinator.record(_posting());

    expect(result.status, CompositeEconomicOperationStatus.failed);
    expect(result.reason, CompositeEconomicOperationReason.financeWriteFailed);
    expect(harness.finance.balances.single.currentAmount, 1000);
    expect(harness.finance.transactions, isEmpty);
    expect(harness.expenses.all, isEmpty);
  });

  for (final failureAt in [1, 2, 3]) {
    test('recovers after Expense write $failureAt fails', () async {
      var expenseWrites = 0;
      final expenses = ExpenseStore(
        saveVerified: (key, value) async {
          expenseWrites++;
          if (expenseWrites == failureAt) {
            return const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            );
          }
          return PersistenceStore.saveStringVerified(key, value);
        },
      );
      final harness = await _Harness.create(expenses: expenses);

      final failed = await harness.coordinator.record(_posting());
      expect(failed.status, CompositeEconomicOperationStatus.failed);
      expect(
        failed.reason,
        CompositeEconomicOperationReason.expenseWriteFailed,
      );
      expect(
        harness.finance.balances.single.currentAmount,
        closeTo(937.37, 1e-9),
      );
      expect(harness.finance.transactions, hasLength(3));
      expect(harness.expenses.all, hasLength(failureAt - 1));

      final retry = await harness.coordinator.record(_posting());

      expect(retry.status, CompositeEconomicOperationStatus.completed);
      expect(
        harness.finance.balances.single.currentAmount,
        closeTo(937.37, 1e-9),
      );
      expect(harness.finance.transactions, hasLength(3));
      expect(harness.expenses.all, hasLength(3));
    });
  }

  test('partial Finance state is inconsistent and never decremented', () async {
    final posting = _posting();
    final harness = await _Harness.create(
      transactions: [_expectedTransaction(posting, posting.operation.main)],
    );

    final result = await harness.coordinator.record(posting);

    expect(result.status, CompositeEconomicOperationStatus.inconsistent);
    expect(
      result.reason,
      CompositeEconomicOperationReason.financeFactsConflict,
    );
    expect(harness.finance.balances.single.currentAmount, 1000);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, isEmpty);
  });

  test('conflicting Finance fact is rejected without mutation', () async {
    final posting = _posting();
    final expected = _expectedTransaction(posting, posting.operation.main);
    final harness = await _Harness.create(
      transactions: [
        FinanceTransaction(
          id: expected.id,
          balanceId: expected.balanceId,
          amount: 999,
          date: expected.date,
          isIncome: expected.isIncome,
          subject: expected.subject,
          description: expected.description,
          type: expected.type,
          origin: expected.origin,
          notes: expected.notes,
          economicFactId: expected.economicFactId,
          operationMetadata: expected.operationMetadata,
        ),
      ],
    );

    final result = await harness.coordinator.record(posting);

    expect(result.status, CompositeEconomicOperationStatus.inconsistent);
    expect(
      result.reason,
      CompositeEconomicOperationReason.financeFactsConflict,
    );
    expect(harness.finance.balances.single.currentAmount, 1000);
    expect(harness.expenses.all, isEmpty);
  });

  test(
    'conflicting Expense fact is rejected before Finance mutation',
    () async {
      final harness = await _Harness.create();
      await harness.expenses.addExpense(
        RealExpense(
          id: 'conflicting-expense',
          balanceId: 'balance-bank',
          balanceName: 'Banca',
          amount: 999,
          description: 'Conflitto',
          category: 'Utenze',
          date: DateTime(2026, 9, 16),
          subject: FinanceSubject.matteo,
          economicFactId: 'fact-main',
          operationMetadata: _posting().operation.main.operationMetadata,
        ),
      );

      final result = await harness.coordinator.record(_posting());

      expect(result.status, CompositeEconomicOperationStatus.inconsistent);
      expect(
        result.reason,
        CompositeEconomicOperationReason.expenseFactsConflict,
      );
      expect(harness.finance.balances.single.currentAmount, 1000);
      expect(harness.finance.transactions, isEmpty);
    },
  );
}

class _Harness {
  final FinanceStore finance;
  final ExpenseStore expenses;

  const _Harness(this.finance, this.expenses);

  CompositeEconomicOperationCoordinator get coordinator =>
      CompositeEconomicOperationCoordinator(
        financeStore: finance,
        expenseStore: expenses,
      );

  static Future<_Harness> create({
    FinancePortfolioV3Writer? financeWriter,
    ExpenseStore? expenses,
    Iterable<FinanceTransaction> transactions = const [],
  }) async {
    final seed = FinancePortfolioV3(
      balances: [_balance()],
      funds: const [],
      assetMovements: const [],
      transactions: transactions,
      fundTransactions: const [],
      linkedItems: const [],
    );
    expect((await FinancePortfolioV3Writer().write(seed)).isSuccess, isTrue);
    final finance = FinanceStore(portfolioV3Writer: financeWriter);
    await finance.loadSavedPortfolioV3();
    final expenseStore = expenses ?? ExpenseStore();
    await expenseStore.load();
    return _Harness(finance, expenseStore);
  }
}

CompositeEconomicOperationPosting _posting() =>
    CompositeEconomicOperationPosting(
      operation: CompositeEconomicOperation(
        operationId: 'operation-utility',
        context: OperationContext.utilityBill,
        mainEconomicFactId: 'fact-main',
        mainAmount: 59.63,
        accessories: const [
          (
            economicFactId: 'fact-bank-fee',
            amount: 2,
            accessoryCostType: AccessoryCostType.bankCommission,
          ),
          (
            economicFactId: 'fact-postal-fee',
            amount: 1,
            accessoryCostType: AccessoryCostType.postalAcceptanceCharge,
          ),
        ],
      ),
      debitBalanceId: 'balance-bank',
      subject: FinanceSubject.matteo,
      economicDate: DateTime(2026, 9, 16),
      description: 'Operazione sintetica utenza',
      category: 'Utenze',
    );

FinanceBalance _balance() => FinanceBalance(
  balanceId: 'balance-bank',
  personId: 'matteo',
  name: 'Banca',
  initialAmount: 1000,
  currentAmount: 1000,
  updatedAt: DateTime(2026, 9, 15),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceTransaction _expectedTransaction(
  CompositeEconomicOperationPosting posting,
  CompositeEconomicFact fact,
) => FinanceTransaction(
  id: 'finance_transaction:composite:${base64Url.encode(utf8.encode(fact.economicFactId))}',
  balanceId: posting.debitBalanceId,
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
);
