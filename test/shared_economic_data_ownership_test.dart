import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/screens/finance_screen.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Finance and Spese receive the same required store instances', () {
    final financeStore = FinanceStore();
    final expenseStore = ExpenseStore();
    final cashWalletStore = CashWalletStore();
    final finance = FinanceScreen(
      financeStore: financeStore,
      expenseStore: expenseStore,
      cashWalletStore: cashWalletStore,
    );
    final spese = SpesePage(
      financeStore: financeStore,
      expenseStore: expenseStore,
      cashWalletStore: cashWalletStore,
    );

    expect(identical(finance.expenseStore, spese.expenseStore), isTrue);
    expect(identical(finance.cashWalletStore, spese.cashWalletStore), isTrue);
  });

  test('ExpenseStore notifies once after completed state changes', () async {
    final store = ExpenseStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    expect(store.all, isEmpty);
    expect(notifications, 0);
    await store.load();
    expect(notifications, 1);
    await store.addExpense(_expense());
    expect(notifications, 2);
    expect(store.all.single.id, 'expense');
    await store.removeExpense('expense');
    expect(notifications, 3);
    expect(store.all, isEmpty);
  });

  test('CashWalletStore notifies once after completed state changes', () async {
    final store = CashWalletStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    expect(store.all, hasLength(2));
    expect(notifications, 0);
    await store.load();
    expect(notifications, 1);
    await store.addCash(walletId: 'wallet_matteo', amount: 10);
    expect(notifications, 2);
    await store.removeCash(walletId: 'wallet_matteo', amount: 10);
    expect(notifications, 3);
    await store.addCash(walletId: 'missing', amount: 10);
    expect(notifications, 3);
  });

  test(
    'pages cannot create silent fallback stores and Finance wires Ledger 2.0',
    () {
      final spese = File('lib/screens/spese_page.dart').readAsStringSync();
      final finance = File(
        'lib/screens/finance_screen.dart',
      ).readAsStringSync();
      final ledger = File(
        'lib/screens/finance/finance_ledger_page.dart',
      ).readAsStringSync();

      expect(spese, isNot(contains('ExpenseStore()')));
      expect(spese, isNot(contains('CashWalletStore()')));
      expect(finance, isNot(contains('ExpenseStore()')));
      expect(finance, isNot(contains('CashWalletStore()')));
      expect(ledger, contains('FinanceLedgerPresentationCoordinator'));
      expect(ledger, isNot(contains('FinanceLedgerCoordinator')));
    },
  );
}

RealExpense _expense() => RealExpense(
  id: 'expense',
  balanceId: 'account',
  balanceName: 'Conto',
  amount: 10,
  description: 'Spesa',
  category: 'Casa',
  date: DateTime(2026, 8, 18),
);
