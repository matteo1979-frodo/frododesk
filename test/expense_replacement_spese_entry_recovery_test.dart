import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/logic/spese/expense_replacement_coordinator.dart';
import 'package:frododesk/logic/spese/expense_replacement_persistence.dart';
import 'package:frododesk/models/expense_replacement_intent.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('entry without intents is inert and rebuild is single-flight', (
    tester,
  ) async {
    var loads = 0;
    final persistence = ExpenseReplacementPersistence(
      load: (key) async {
        loads++;
        return PersistenceStore.loadString(key);
      },
    );
    final harness = await _Harness.create(persistence: persistence);
    final beforeBalance = harness.finance.balances.single.currentAmount;

    await _pumpPage(tester, harness);
    expect(loads, 1);
    expect(harness.finance.balances.single.currentAmount, beforeBalance);
    expect(harness.finance.transactions, isEmpty);
    expect(harness.expenses.all, isEmpty);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(loads, 1);
  });

  testWidgets('READY intent completes exactly once on entry', (tester) async {
    final intent = _intent('one', 'account', oldAmount: 10, newAmount: 15);
    final harness = await _Harness.create(intents: [intent]);

    await _pumpPage(tester, harness);

    expect(harness.finance.balances.single.currentAmount, 95);
    expect(harness.finance.transactions, hasLength(2));
    expect(
      harness.expenses.all.single.id,
      intent.identities.replacementCommandId,
    );
    expect(await harness.persistence.load(), isEmpty);
  });

  testWidgets(
    'FINANCE_APPLIED intent resumes Expense without duplicate Finance',
    (tester) async {
      final intent = _intent('one', 'account', oldAmount: 10, newAmount: 15);
      var rejectExpense = true;
      final harness = await _Harness.create(
        intents: [intent],
        expenseSave: (key, value) async {
          if (rejectExpense) {
            return const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            );
          }
          return _save(key, value);
        },
      );
      final precondition = await harness.replacementCoordinator.complete(
        intent,
      );
      expect(precondition.reason, ExpenseReplacementReason.expenseWriteFailed);
      expect(harness.finance.transactions, hasLength(2));
      rejectExpense = false;

      await _pumpPage(tester, harness);

      expect(harness.finance.balances.single.currentAmount, 95);
      expect(harness.finance.transactions, hasLength(2));
      expect(
        harness.expenses.all.single.id,
        intent.identities.replacementCommandId,
      );
      expect(await harness.persistence.load(), isEmpty);
    },
  );

  testWidgets('COMPLETE intent performs cleanup only on entry', (tester) async {
    final intent = _intent('one', 'account', oldAmount: 10, newAmount: 15);
    var rejectCleanup = true;
    String? storage;
    final persistence = ExpenseReplacementPersistence(
      load: (_) async => storage,
      saveVerified: (_, value) async {
        final intents = (jsonDecode(value) as Map)['intents'] as List;
        if (rejectCleanup && intents.isEmpty) {
          return const PersistenceWriteVerification(
            backendAccepted: false,
            readBack: null,
          );
        }
        storage = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );
    final harness = await _Harness.create(
      intents: [intent],
      persistence: persistence,
    );
    final precondition = await harness.replacementCoordinator.complete(intent);
    expect(precondition.reason, ExpenseReplacementReason.intentCleanupFailed);
    final transactionIds = harness.finance.transactions
        .map((item) => item.id)
        .toList();
    rejectCleanup = false;

    await _pumpPage(tester, harness);

    expect(harness.finance.balances.single.currentAmount, 95);
    expect(harness.finance.transactions.map((item) => item.id), transactionIds);
    expect(
      harness.expenses.all.single.id,
      intent.identities.replacementCommandId,
    );
    expect(await persistence.load(), isEmpty);
  });

  testWidgets('multiple intents are completed serially once', (tester) async {
    final first = _intent('one', 'account-a', oldAmount: 10, newAmount: 15);
    final second = _intent('two', 'account-b', oldAmount: 20, newAmount: 25);
    final harness = await _Harness.create(intents: [first, second]);

    await _pumpPage(tester, harness);

    expect(harness.finance.balances.map((item) => item.currentAmount), [
      95,
      95,
    ]);
    expect(harness.finance.transactions.map((item) => item.id), [
      first.identities.compensationTransactionId,
      first.identities.replacementTransactionId,
      second.identities.compensationTransactionId,
      second.identities.replacementTransactionId,
    ]);
    expect(await harness.persistence.load(), isEmpty);
  });

  testWidgets('conflict remains pending while a later intent recovers', (
    tester,
  ) async {
    final conflict = _intent('one', 'account-a', oldAmount: 10, newAmount: 15);
    final recoverable = _intent(
      'two',
      'account-b',
      oldAmount: 20,
      newAmount: 25,
    );
    final harness = await _Harness.create(
      intents: [conflict, recoverable],
      storedExpenses: [
        _oldExpense('account-a', amount: 11),
        recoverable.originalExpense,
      ],
    );

    await _pumpPage(tester, harness);

    expect(harness.finance.balances[0].currentAmount, 100);
    expect(harness.finance.balances[1].currentAmount, 95);
    expect(harness.finance.transactions, hasLength(2));
    final pending = await harness.persistence.load();
    expect(pending.single.replacementId, conflict.replacementId);
    expect(find.byType(SpesePage), findsOneWidget);
  });

  testWidgets('dispose during asynchronous load never calls setState', (
    tester,
  ) async {
    final load = Completer<String?>();
    final persistence = ExpenseReplacementPersistence(load: (_) => load.future);
    final harness = await _Harness.create(persistence: persistence);

    await _pumpPage(tester, harness, settle: false);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    load.complete(null);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('corrupt persistence is reported once and page remains usable', (
    tester,
  ) async {
    var loads = 0;
    final persistence = ExpenseReplacementPersistence(
      load: (_) async {
        loads++;
        return '{broken';
      },
    );
    final harness = await _Harness.create(persistence: persistence);

    await _pumpPage(tester, harness);
    await tester.pump();

    expect(loads, 1);
    expect(find.byType(SpesePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a newly opened SpesePage performs a new persistence check', (
    tester,
  ) async {
    var loads = 0;
    final persistence = ExpenseReplacementPersistence(
      load: (key) async {
        loads++;
        return PersistenceStore.loadString(key);
      },
    );
    final harness = await _Harness.create(persistence: persistence);

    await _pumpPage(tester, harness);
    expect(loads, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    await _pumpPage(tester, harness);
    expect(loads, 2);
  });

  test('production ordinary edit path persists and completes replacement', () {
    final source = _readSpeseSourceForStructuralAssertion();
    expect(source, contains('findByOriginalExpenseId('));
    expect(source, contains('ExpenseReplacementIntent('));
    expect(source, contains('await replacementPersistence.add(intent)'));
    expect(source, contains('replacementCoordinator.complete(intent)'));
  });
}

String _readSpeseSourceForStructuralAssertion() =>
    File('lib/screens/spese_page.dart').readAsStringSync();

class _Harness {
  final FinanceStore finance;
  final ExpenseStore expenses;
  final ExpenseReplacementPersistence persistence;
  final ExpenseReplacementCoordinator replacementCoordinator;

  const _Harness({
    required this.finance,
    required this.expenses,
    required this.persistence,
    required this.replacementCoordinator,
  });

  static Future<_Harness> create({
    List<ExpenseReplacementIntent> intents = const [],
    List<RealExpense>? storedExpenses,
    ExpenseReplacementPersistence? persistence,
    ExpenseVerifiedSave? expenseSave,
  }) async {
    final balances = <FinanceBalance>[
      for (final balanceId in {
        if (intents.isEmpty)
          'account'
        else
          ...intents.map((item) => item.originalExpense.balanceId),
      })
        _balance(balanceId),
    ];
    final expenses =
        storedExpenses ?? intents.map((item) => item.originalExpense).toList();
    final portfolio = FinancePortfolioV3(
      balances: balances,
      funds: const [],
      assetMovements: const [],
      transactions: const [],
      fundTransactions: const [],
      linkedItems: const [],
    );
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': jsonEncode(
        FinancePortfolioV3Contract.build(portfolio),
      ),
      'frododesk_real_expenses_v1': jsonEncode(
        expenses.map((item) => item.toJson()).toList(),
      ),
    });
    final finance = FinanceStore(
      portfolioV3Writer: FinancePortfolioV3Writer(saveVerified: _save),
    );
    expect(await finance.loadSavedPortfolioV3(), isTrue);
    final expenseStore = ExpenseStore(saveVerified: expenseSave);
    await expenseStore.load();
    final intentPersistence = persistence ?? ExpenseReplacementPersistence();
    for (final intent in intents) {
      await intentPersistence.add(intent);
    }
    final replacementCoordinator = ExpenseReplacementCoordinator(
      financeStore: finance,
      expenseStore: expenseStore,
      persistence: intentPersistence,
    );
    return _Harness(
      finance: finance,
      expenses: expenseStore,
      persistence: intentPersistence,
      replacementCoordinator: replacementCoordinator,
    );
  }
}

Future<void> _pumpPage(
  WidgetTester tester,
  _Harness harness, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: SpesePage(
        financeStore: harness.finance,
        expenseStore: harness.expenses,
        cashWalletStore: CashWalletStore(),
        expenseReplacementPersistence: harness.persistence,
        expenseReplacementCoordinator: harness.replacementCoordinator,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<PersistenceWriteVerification> _save(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  final accepted = await prefs.setString('frododesk_$key', value);
  return PersistenceWriteVerification(
    backendAccepted: accepted,
    readBack: prefs.getString('frododesk_$key'),
  );
}

ExpenseReplacementIntent _intent(
  String suffix,
  String balanceId, {
  required double oldAmount,
  required double newAmount,
}) => ExpenseReplacementIntent(
  replacementId: 'replacement-$suffix',
  originalExpense: _oldExpense(balanceId, amount: oldAmount),
  replacementPayload: ExpenseReplacementPayload(
    balanceId: balanceId,
    balanceName: 'Account $balanceId',
    amount: newAmount,
    description: 'New $suffix',
    category: 'Food',
    preparedAt: DateTime(2026, 9, 16, 12),
    occurredAt: DateTime(2026, 9, 15, 11),
    personId: 'matteo',
  ),
);

RealExpense _oldExpense(String balanceId, {required double amount}) =>
    RealExpense(
      id: 'old-$balanceId',
      balanceId: balanceId,
      balanceName: 'Account $balanceId',
      amount: amount,
      description: 'Old $balanceId',
      category: 'Food',
      date: DateTime(2026, 9, 14, 10),
      subject: FinanceSubject.matteo,
      economicFactId: 'old-fact-$balanceId',
    );

FinanceBalance _balance(String balanceId) => FinanceBalance(
  personId: 'matteo',
  balanceId: balanceId,
  name: 'Account $balanceId',
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime(2026, 9, 14),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);
