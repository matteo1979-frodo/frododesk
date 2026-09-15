import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/finance/finite_financial_plan_installment_confirmation_coordinator.dart';
import 'package:frododesk/logic/finance/finite_financial_plan_persistence.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/finite_financial_plan.dart';
import 'package:frododesk/models/finite_financial_plan_installment_confirmation.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('happy path without fee commits one fact and advances once', () async {
    final harness = await _Harness.create();
    final result = await harness.coordinator.confirm(_confirmation());

    expect(result.status, FinitePlanInstallmentConfirmationStatus.completed);
    expect(harness.finance.balances.single.currentAmount, 614);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, hasLength(1));
    expect(
      harness.finance.finiteFinancialPlans.single.completedInstallments,
      3,
    );
    final transaction = harness.finance.transactions.single;
    final expense = harness.expenses.all.single;
    expect(transaction.economicFactId, _confirmation().mainEconomicFactId);
    expect(expense.economicFactId, transaction.economicFactId);
    expect(transaction.date, DateTime(2026, 9, 16));
    expect(expense.date, DateTime(2026, 9, 16));
    expect(
      harness.finance.finiteFinancialPlans.single.installment(3)!.dueDate,
      DateTime(2026, 9, 15),
    );
    expect(harness.finance.recurringItems, isEmpty);
  });

  test(
    'fee creates two distinct correlated facts and retry is inert',
    () async {
      final harness = await _Harness.create();
      final confirmation = _confirmation(fee: 1);
      final first = await harness.coordinator.confirm(confirmation);

      expect(first.status, FinitePlanInstallmentConfirmationStatus.completed);
      expect(harness.finance.balances.single.currentAmount, 613);
      expect(harness.finance.transactions, hasLength(2));
      expect(harness.expenses.all, hasLength(2));
      expect(
        harness.finance.transactions.map((item) => item.economicFactId).toSet(),
        {confirmation.mainEconomicFactId, confirmation.feeEconomicFactId},
      );
      expect(harness.expenses.all.map((item) => item.economicFactId).toSet(), {
        confirmation.mainEconomicFactId,
        confirmation.feeEconomicFactId,
      });
      final events = const EconomicEventCorrelator().correlate(
        const EconomicEventCollector().collect(
          transactions: harness.finance.transactions,
          assetMovements: const [],
          realExpenses: harness.expenses.all,
          observedAt: DateTime(2026, 9, 16, 12),
        ),
      );
      expect(events, hasLength(2));
      expect(events.every((event) => event.sourceLinks.length == 2), isTrue);

      final beforeBalance = harness.finance.balances.single.currentAmount;
      final beforeTransactions = harness.finance.transactions.length;
      final beforeExpenses = harness.expenses.all.length;
      final second = await harness.coordinator.confirm(confirmation);
      expect(
        second.status,
        FinitePlanInstallmentConfirmationStatus.alreadyComplete,
      );
      expect(harness.finance.balances.single.currentAmount, beforeBalance);
      expect(harness.finance.transactions, hasLength(beforeTransactions));
      expect(harness.expenses.all, hasLength(beforeExpenses));
      expect(
        harness.finance.finiteFinancialPlans.single.completedInstallments,
        3,
      );
    },
  );

  test('recovers after Finance persisted and stores are recreated', () async {
    final failingExpenses = ExpenseStore(
      saveVerified: (key, value) async => const PersistenceWriteVerification(
        backendAccepted: false,
        readBack: null,
      ),
    );
    final firstHarness = await _Harness.create(expenses: failingExpenses);
    final confirmation = _confirmation(fee: 1);
    final failed = await firstHarness.coordinator.confirm(confirmation);
    expect(
      failed.reason,
      FinitePlanInstallmentConfirmationReason.expenseWriteFailed,
    );
    expect(firstHarness.finance.balances.single.currentAmount, 613);
    expect(firstHarness.finance.transactions, hasLength(2));
    expect(
      firstHarness.finance.finiteFinancialPlans.single.completedInstallments,
      2,
    );

    final restored = await _Harness.reload();
    final resumed = await restored.coordinator.confirm(confirmation);
    expect(resumed.status, FinitePlanInstallmentConfirmationStatus.completed);
    expect(restored.finance.balances.single.currentAmount, 613);
    expect(restored.finance.transactions, hasLength(2));
    expect(restored.expenses.all, hasLength(2));
    expect(
      restored.finance.finiteFinancialPlans.single.completedInstallments,
      3,
    );
  });

  test('recovers after main expense when fee expense write failed', () async {
    var writes = 0;
    final expenses = ExpenseStore(
      saveVerified: (key, value) async {
        writes++;
        if (writes == 2) {
          return const PersistenceWriteVerification(
            backendAccepted: false,
            readBack: null,
          );
        }
        return PersistenceStore.saveStringVerified(key, value);
      },
    );
    final harness = await _Harness.create(expenses: expenses);
    final confirmation = _confirmation(fee: 1);

    final failed = await harness.coordinator.confirm(confirmation);
    expect(
      failed.reason,
      FinitePlanInstallmentConfirmationReason.expenseWriteFailed,
    );
    expect(harness.expenses.all, hasLength(1));
    expect(
      harness.finance.finiteFinancialPlans.single.completedInstallments,
      2,
    );

    final restored = await _Harness.reload();
    final resumed = await restored.coordinator.confirm(confirmation);
    expect(resumed.status, FinitePlanInstallmentConfirmationStatus.completed);
    expect(restored.expenses.all, hasLength(2));
    expect(restored.finance.balances.single.currentAmount, 613);
  });

  test(
    'plan writer failure leaves facts recoverable and retry advances only plan',
    () async {
      final failingPlanPersistence = FiniteFinancialPlanPersistence(
        saveVerified: (key, value) async => const PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      );
      final harness = await _Harness.create(
        finitePlanPersistence: failingPlanPersistence,
      );
      final confirmation = _confirmation(fee: 1);

      final failed = await harness.coordinator.confirm(confirmation);
      expect(
        failed.reason,
        FinitePlanInstallmentConfirmationReason.planWriteFailed,
      );
      expect(harness.finance.balances.single.currentAmount, 613);
      expect(harness.finance.transactions, hasLength(2));
      expect(harness.expenses.all, hasLength(2));
      expect(
        harness.finance.finiteFinancialPlans.single.completedInstallments,
        2,
      );

      final restored = await _Harness.reload();
      final resumed = await restored.coordinator.confirm(confirmation);
      expect(resumed.status, FinitePlanInstallmentConfirmationStatus.completed);
      expect(restored.finance.balances.single.currentAmount, 613);
      expect(restored.finance.transactions, hasLength(2));
      expect(restored.expenses.all, hasLength(2));
      expect(
        restored.finance.finiteFinancialPlans.single.completedInstallments,
        3,
      );
    },
  );

  test('all facts with unadvanced plan advances only the plan', () async {
    final first = await _Harness.create(
      finitePlanPersistence: FiniteFinancialPlanPersistence(
        saveVerified: (key, value) async => const PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      ),
    );
    final confirmation = _confirmation(fee: 1);
    await first.coordinator.confirm(confirmation);
    final restored = await _Harness.reload();
    final balance = restored.finance.balances.single.currentAmount;

    final result = await restored.coordinator.confirm(confirmation);

    expect(result.status, FinitePlanInstallmentConfirmationStatus.completed);
    expect(restored.finance.balances.single.currentAmount, balance);
    expect(restored.finance.transactions, hasLength(2));
    expect(restored.expenses.all, hasLength(2));
  });

  test('partial Finance pair required by fee is inconsistent', () async {
    final confirmation = _confirmation(fee: 1);
    final main = _expectedTransaction(confirmation);
    final harness = await _Harness.create(
      balanceAmount: 614,
      transactions: [main],
    );

    final result = await harness.coordinator.confirm(confirmation);

    expect(result.status, FinitePlanInstallmentConfirmationStatus.inconsistent);
    expect(
      result.reason,
      FinitePlanInstallmentConfirmationReason.financeFactsConflict,
    );
    expect(harness.finance.balances.single.currentAmount, 614);
    expect(harness.expenses.all, isEmpty);
  });

  test('advanced plan with missing facts is inconsistent', () async {
    final harness = await _Harness.create(completedInstallments: 3);
    final result = await harness.coordinator.confirm(_confirmation());
    expect(result.status, FinitePlanInstallmentConfirmationStatus.inconsistent);
    expect(harness.finance.transactions, isEmpty);
    expect(harness.expenses.all, isEmpty);
  });

  test('incompatible expected identity stops without mutation', () async {
    final confirmation = _confirmation();
    final conflicting = _expectedTransaction(confirmation, amount: 999);
    final harness = await _Harness.create(transactions: [conflicting]);
    final result = await harness.coordinator.confirm(confirmation);
    expect(result.status, FinitePlanInstallmentConfirmationStatus.inconsistent);
    expect(
      result.reason,
      FinitePlanInstallmentConfirmationReason.financeFactsConflict,
    );
    expect(harness.finance.balances.single.currentAmount, 1000);
    expect(harness.expenses.all, isEmpty);
  });

  test(
    'incompatible expense identity stops without further mutation',
    () async {
      final first = await _Harness.create(
        finitePlanPersistence: FiniteFinancialPlanPersistence(
          saveVerified: (key, value) async =>
              const PersistenceWriteVerification(
                backendAccepted: false,
                readBack: null,
              ),
        ),
      );
      final confirmation = _confirmation();
      await first.coordinator.confirm(confirmation);
      final prefs = await SharedPreferences.getInstance();
      final raw =
          jsonDecode(prefs.getString('frododesk_real_expenses_v1')!)
              as List<dynamic>;
      final incompatible = Map<String, dynamic>.from(raw.single as Map)
        ..['amount'] = 999;
      SharedPreferences.setMockInitialValues({
        'frododesk_finance_portfolio_v3': prefs.getString(
          'frododesk_finance_portfolio_v3',
        )!,
        'frododesk_finance_finite_financial_plans': prefs.getString(
          'frododesk_finance_finite_financial_plans',
        )!,
        'frododesk_real_expenses_v1': jsonEncode([incompatible]),
      });
      final restored = await _Harness.reload();

      final result = await restored.coordinator.confirm(confirmation);

      expect(
        result.status,
        FinitePlanInstallmentConfirmationStatus.inconsistent,
      );
      expect(
        result.reason,
        FinitePlanInstallmentConfirmationReason.expenseFactsConflict,
      );
      expect(restored.finance.balances.single.currentAmount, 614);
      expect(
        restored.finance.finiteFinancialPlans.single.completedInstallments,
        2,
      );
    },
  );

  test(
    'invalid progression, missing balance, and subject mismatch are inert',
    () async {
      final cases = <Future<_Harness> Function()>[
        () => _Harness.create(completedInstallments: 1),
        () => _Harness.create(completedInstallments: 4),
        () => _Harness.create(balanceId: 'different'),
        () => _Harness.create(balancePersonId: 'chiara'),
        () => _Harness.create(balanceActive: false),
      ];
      for (final create in cases) {
        final harness = await create();
        final result = await harness.coordinator.confirm(_confirmation());
        expect(
          result.status,
          FinitePlanInstallmentConfirmationStatus.inconsistent,
        );
        expect(harness.finance.transactions, isEmpty);
        expect(harness.expenses.all, isEmpty);
        expect(harness.finance.balances.single.currentAmount, 1000);
      }
    },
  );

  test(
    'shared subject is rejected without invented ownership semantics',
    () async {
      final harness = await _Harness.create(
        subject: FinanceSubject.shared,
        balancePersonId: 'shared',
      );
      final result = await harness.coordinator.confirm(
        _confirmation(subject: FinanceSubject.shared),
      );
      expect(
        result.reason,
        FinitePlanInstallmentConfirmationReason.unsupportedSharedSubject,
      );
      expect(harness.finance.transactions, isEmpty);
      expect(harness.expenses.all, isEmpty);
    },
  );

  test(
    'Finance writer failure leaves every downstream state unchanged',
    () async {
      final harness = await _Harness.create(
        financeWriter: FinancePortfolioV3Writer(
          saveVerified: (key, value) async =>
              const PersistenceWriteVerification(
                backendAccepted: false,
                readBack: null,
              ),
        ),
      );
      final result = await harness.coordinator.confirm(_confirmation(fee: 1));
      expect(
        result.reason,
        FinitePlanInstallmentConfirmationReason.financeWriteFailed,
      );
      expect(harness.finance.balances.single.currentAmount, 1000);
      expect(harness.finance.transactions, isEmpty);
      expect(harness.expenses.all, isEmpty);
      expect(
        harness.finance.finiteFinancialPlans.single.completedInstallments,
        2,
      );
    },
  );

  test('zero fee follows the same one-fact path as null fee', () async {
    final harness = await _Harness.create();
    final result = await harness.coordinator.confirm(_confirmation(fee: 0));
    expect(result.status, FinitePlanInstallmentConfirmationStatus.completed);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, hasLength(1));
    expect(harness.finance.balances.single.currentAmount, 614);
  });
}

class _Harness {
  final FinanceStore finance;
  final ExpenseStore expenses;

  _Harness(this.finance, this.expenses);

  FiniteFinancialPlanInstallmentConfirmationCoordinator get coordinator =>
      FiniteFinancialPlanInstallmentConfirmationCoordinator(
        financeStore: finance,
        expenseStore: expenses,
      );

  static Future<_Harness> create({
    FinancePortfolioV3Writer? financeWriter,
    FiniteFinancialPlanPersistence? finitePlanPersistence,
    ExpenseStore? expenses,
    String balanceId = 'balance-bank',
    String balancePersonId = 'matteo',
    FinanceSubject subject = FinanceSubject.matteo,
    double balanceAmount = 1000,
    bool balanceActive = true,
    int completedInstallments = 2,
    Iterable<FinanceTransaction> transactions = const [],
  }) async {
    final portfolio = FinancePortfolioV3(
      balances: [
        _balance(
          balanceId,
          balancePersonId,
          balanceAmount,
          active: balanceActive,
        ),
      ],
      funds: const [],
      assetMovements: const [],
      transactions: transactions,
      fundTransactions: const [],
      linkedItems: const [],
    );
    expect(
      (await FinancePortfolioV3Writer().write(portfolio)).isSuccess,
      isTrue,
    );
    expect(
      (await FiniteFinancialPlanPersistence().write([
        _plan(
          subject: subject,
          debitBalanceId: 'balance-bank',
          completedInstallments: completedInstallments,
        ),
      ])).isSuccess,
      isTrue,
    );
    final finance = FinanceStore(
      portfolioV3Writer: financeWriter,
      finiteFinancialPlanPersistence: finitePlanPersistence,
    );
    await finance.loadSavedPortfolioV3();
    await finance.loadSavedFiniteFinancialPlans();
    final expenseStore = expenses ?? ExpenseStore();
    await expenseStore.load();
    return _Harness(finance, expenseStore);
  }

  static Future<_Harness> reload() async {
    final finance = FinanceStore();
    await finance.loadSavedPortfolioV3();
    await finance.loadSavedFiniteFinancialPlans();
    final expenses = ExpenseStore();
    await expenses.load();
    return _Harness(finance, expenses);
  }
}

FiniteFinancialPlanInstallmentConfirmation _confirmation({
  double? fee,
  FinanceSubject subject = FinanceSubject.matteo,
}) => FiniteFinancialPlanInstallmentConfirmation(
  planId: 'plan-inps',
  installmentNumber: 3,
  debitBalanceId: 'balance-bank',
  subject: subject,
  mainAmount: 386,
  economicDate: DateTime(2026, 9, 16),
  description: 'Rata INPS 3/12',
  mainCategory: 'Tributi',
  bankFee: fee,
  bankFeeCategory: fee == null || fee == 0 ? null : 'Commissioni bancarie',
);

FiniteFinancialPlan _plan({
  FinanceSubject subject = FinanceSubject.matteo,
  String debitBalanceId = 'balance-bank',
  int completedInstallments = 2,
}) => FiniteFinancialPlan(
  id: 'plan-inps',
  name: 'INPS',
  subject: subject,
  creditor: 'INPS',
  debitBalanceId: debitBalanceId,
  totalInstallments: 12,
  expectedInstallmentAmount: 386,
  firstInstallmentDate: DateTime(2026, 7, 15),
  completedInstallments: completedInstallments,
);

FinanceBalance _balance(
  String id,
  String personId,
  double amount, {
  bool active = true,
}) => FinanceBalance(
  balanceId: id,
  personId: personId,
  name: 'Banca di Imola',
  initialAmount: 1000,
  currentAmount: amount,
  updatedAt: DateTime(2026, 9, 15),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: active,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceTransaction _expectedTransaction(
  FiniteFinancialPlanInstallmentConfirmation confirmation, {
  double? amount,
}) => FinanceTransaction(
  id: 'finance_transaction:${confirmation.installmentIdentity}:main',
  balanceId: confirmation.debitBalanceId,
  amount: amount ?? confirmation.mainAmount,
  date: confirmation.economicDate,
  isIncome: false,
  subject: confirmation.subject,
  description: confirmation.description,
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  notes: confirmation.mainCategory,
  economicFactId: confirmation.mainEconomicFactId,
);
