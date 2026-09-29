import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/logic/spese/expense_replacement_persistence.dart';
import 'package:frododesk/logic/spese/spese_mutation_coordinator.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/balance_posting_mode.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/models/spese_command.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ordinary expense persists one coherent economic fact', () async {
    final harness = await _Harness.create();
    final command = _command();

    await harness.coordinator.execute(command);

    expect(harness.finance.balances.single.currentAmount, 75);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, hasLength(1));
    final transaction = harness.finance.transactions.single;
    final expense = harness.expenses.all.single;
    expect(transaction.economicFactId, expense.economicFactId);
    expect(transaction.date, command.occurredAt);
    expect(expense.date, command.occurredAt);
    expect(transaction.operationMetadata, isNull);
    expect(await ExpenseReplacementPersistence().load(), isEmpty);

    final events = const EconomicEventCorrelator().correlate(
      const EconomicEventCollector().collect(
        transactions: harness.finance.transactions,
        assetMovements: [],
        realExpenses: harness.expenses.all,
        observedAt: DateTime(2026, 9, 16),
      ),
    );
    expect(events, hasLength(1));
    expect(events.single.sourceLinks, hasLength(2));
  });

  test('retry completes Finance-only state without a second debit', () async {
    var expenseWrites = 0;
    final expenses = ExpenseStore(
      saveVerified: (key, value) async {
        expenseWrites++;
        if (expenseWrites == 1) {
          return const PersistenceWriteVerification(
            backendAccepted: false,
            readBack: null,
          );
        }
        final prefs = await SharedPreferences.getInstance();
        final accepted = await prefs.setString('frododesk_$key', value);
        return PersistenceWriteVerification(
          backendAccepted: accepted,
          readBack: prefs.getString('frododesk_$key'),
        );
      },
    );
    final harness = await _Harness.create(expenses: expenses);
    final command = _command();

    await expectLater(harness.coordinator.execute(command), throwsStateError);
    expect(harness.finance.balances.single.currentAmount, 75);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, isEmpty);

    final restored = await _Harness.reload(expenses: expenses);
    await restored.coordinator.execute(command);
    expect(restored.finance.balances.single.currentAmount, 75);
    expect(restored.finance.transactions, hasLength(1));
    expect(restored.expenses.all, hasLength(1));
  });

  test('retry of a complete operation is inert', () async {
    final harness = await _Harness.create();
    final command = _command();

    await harness.coordinator.execute(command);
    await harness.coordinator.execute(command);

    expect(harness.finance.balances.single.currentAmount, 75);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, hasLength(1));
  });

  test(
    'historical ordinary expense preserves balance and economic fact',
    () async {
      final harness = await _Harness.create();
      final command = _command(
        balancePostingMode: BalancePostingMode.alreadyIncludedInCurrentBalance,
      );

      await harness.coordinator.execute(command);

      expect(harness.finance.balances.single.currentAmount, 100);
      expect(harness.finance.transactions, hasLength(1));
      expect(harness.expenses.all, hasLength(1));
      expect(
        harness.finance.transactions.single.balancePostingMode,
        BalancePostingMode.alreadyIncludedInCurrentBalance,
      );
      expect(
        harness.expenses.all.single.balancePostingMode,
        BalancePostingMode.alreadyIncludedInCurrentBalance,
      );
      expect(harness.finance.transactions.single.date, command.occurredAt);
      expect(
        FinanceTransaction.fromJson(
          harness.finance.transactions.single.toJson(),
        ).balancePostingMode,
        BalancePostingMode.alreadyIncludedInCurrentBalance,
      );
      expect(
        RealExpense.fromJson(
          harness.expenses.all.single.toJson(),
        ).balancePostingMode,
        BalancePostingMode.alreadyIncludedInCurrentBalance,
      );
      final events = const EconomicEventCorrelator().correlate(
        const EconomicEventCollector().collect(
          transactions: harness.finance.transactions,
          assetMovements: [],
          realExpenses: harness.expenses.all,
          observedAt: DateTime(2026, 9, 16),
        ),
      );
      expect(events, hasLength(1));
      expect(events.single.sourceLinks, hasLength(2));
    },
  );

  test('historical ordinary retry is inert', () async {
    final harness = await _Harness.create();
    final command = _command(
      balancePostingMode: BalancePostingMode.alreadyIncludedInCurrentBalance,
    );
    await harness.coordinator.execute(command);
    await harness.coordinator.execute(command);
    expect(harness.finance.balances.single.currentAmount, 100);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, hasLength(1));
  });

  test('historical ordinary recovers after Expense write failure', () async {
    var expenseWrites = 0;
    final expenses = ExpenseStore(
      saveVerified: (key, value) async {
        expenseWrites++;
        if (expenseWrites == 1) {
          return const PersistenceWriteVerification(
            backendAccepted: false,
            readBack: null,
          );
        }
        final prefs = await SharedPreferences.getInstance();
        final accepted = await prefs.setString('frododesk_$key', value);
        return PersistenceWriteVerification(
          backendAccepted: accepted,
          readBack: prefs.getString('frododesk_$key'),
        );
      },
    );
    final harness = await _Harness.create(expenses: expenses);
    final command = _command(
      balancePostingMode: BalancePostingMode.alreadyIncludedInCurrentBalance,
    );
    await expectLater(harness.coordinator.execute(command), throwsStateError);
    expect(harness.finance.balances.single.currentAmount, 100);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, isEmpty);

    final restored = await _Harness.reload(expenses: expenses);
    await restored.coordinator.execute(command);
    expect(restored.finance.balances.single.currentAmount, 100);
    expect(restored.finance.transactions, hasLength(1));
    expect(restored.expenses.all, hasLength(1));
  });

  test('legacy records default to affecting the current balance', () {
    final transaction = FinanceTransaction.fromJson({
      'id': 'legacy',
      'balanceId': 'account',
      'amount': 1,
      'date': '2026-01-01T00:00:00.000',
      'isIncome': false,
      'subject': 'matteo',
      'description': 'Legacy',
      'type': 'expense',
      'origin': 'manual',
    });
    final expense = RealExpense.fromJson({
      'id': 'legacy',
      'balanceId': 'account',
      'balanceName': 'Account',
      'amount': 1,
      'description': 'Legacy',
      'category': 'Altro',
      'date': '2026-01-01T00:00:00.000',
    });
    expect(
      transaction.balancePostingMode,
      BalancePostingMode.affectsCurrentBalance,
    );
    expect(
      expense.balancePostingMode,
      BalancePostingMode.affectsCurrentBalance,
    );
  });

  test('conflicting Expense identity fails before Finance mutation', () async {
    final harness = await _Harness.create();
    await harness.expenses.addExpense(
      RealExpense(
        id: 'ordinary-command',
        balanceId: 'account',
        balanceName: 'Account',
        amount: 99,
        description: 'Conflitto',
        category: 'Altro',
        date: DateTime(2026, 1, 1),
        subject: FinanceSubject.matteo,
        economicFactId: 'economic_fact_spese_ordinary-command',
      ),
    );

    await expectLater(
      harness.coordinator.execute(_command()),
      throwsA(isA<StateError>()),
    );
    expect(harness.finance.balances.single.currentAmount, 100);
    expect(harness.finance.transactions, isEmpty);
    expect(harness.expenses.all.single.amount, 99);
  });

  test('conflicting Finance identity fails without Expense mutation', () async {
    final harness = await _Harness.create(
      initialTransactions: [
        FinanceTransaction(
          id: 'conflicting-transaction',
          balanceId: 'account',
          amount: 99,
          date: DateTime(2026, 1, 1),
          isIncome: false,
          subject: FinanceSubject.matteo,
          description: 'Conflitto',
          type: FinanceTransactionType.expense,
          origin: FinanceTransactionOrigin.manual,
          economicFactId: 'economic_fact_spese_ordinary-command',
        ),
      ],
    );

    await expectLater(
      harness.coordinator.execute(_command()),
      throwsA(isA<StateError>()),
    );
    expect(harness.finance.balances.single.currentAmount, 100);
    expect(harness.finance.transactions, hasLength(1));
    expect(harness.expenses.all, isEmpty);
  });
}

class _Harness {
  final FinanceStore finance;
  final ExpenseStore expenses;
  final SpeseMutationCoordinator coordinator;

  const _Harness(this.finance, this.expenses, this.coordinator);

  static Future<_Harness> create({
    ExpenseStore? expenses,
    List<FinanceTransaction> initialTransactions = const [],
  }) async {
    final portfolio = FinancePortfolioV3(
      balances: [_balance()],
      funds: const [],
      assetMovements: const [],
      transactions: initialTransactions,
      fundTransactions: const [],
      linkedItems: const [],
    );
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': jsonEncode(
        FinancePortfolioV3Contract.build(portfolio),
      ),
    });
    return reload(expenses: expenses);
  }

  static Future<_Harness> reload({ExpenseStore? expenses}) async {
    final finance = FinanceStore(portfolioV3Writer: _writer());
    expect(await finance.loadSavedPortfolioV3(), isTrue);
    final expenseStore = expenses ?? ExpenseStore();
    await expenseStore.load();
    return _Harness(
      finance,
      expenseStore,
      SpeseMutationCoordinator(
        financeStore: finance,
        expenseStore: expenseStore,
        cashWalletStore: CashWalletStore(),
      ),
    );
  }
}

FinancePortfolioV3Writer _writer() => FinancePortfolioV3Writer(
  saveVerified: (key, value) async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = await prefs.setString('frododesk_$key', value);
    return PersistenceWriteVerification(
      backendAccepted: accepted,
      readBack: prefs.getString('frododesk_$key'),
    );
  },
);

SpeseCommand _command({
  BalancePostingMode balancePostingMode =
      BalancePostingMode.affectsCurrentBalance,
}) => SpeseCommand(
  id: 'ordinary-command',
  kind: SpeseCommandKind.expense,
  action: SpeseCommandAction.create,
  preparedAt: DateTime(2026, 9, 16, 12),
  occurredAt: DateTime(2025, 2, 3, 10, 30),
  origin: const SpeseCommandEndpoint(
    kind: EconomicEndpointKind.account,
    referenceId: 'account',
    label: 'Account',
  ),
  destination: const SpeseCommandEndpoint(
    kind: EconomicEndpointKind.external,
    label: 'Esterno',
  ),
  amount: 25,
  category: 'Alimentazione',
  personId: 'matteo',
  description: 'Spesa ordinaria',
  balancePostingMode: balancePostingMode,
);

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'account',
  name: 'Account',
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
