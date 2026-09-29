import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/balance_posting_mode.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ordinary expense defaults to current-balance posting', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _openOrdinaryExpense(tester, fixture);

    final choice = find.byKey(const ValueKey('historical-posting-choice'));
    expect(tester.widget<SwitchListTile>(choice).value, isFalse);

    await _fillAndSubmit(tester);

    expect(fixture.financeStore.balances.single.currentAmount, 970);
    expect(
      fixture.financeStore.transactions.single.balancePostingMode,
      BalancePostingMode.affectsCurrentBalance,
    );
    expect(
      fixture.expenseStore.all.single.balancePostingMode,
      BalancePostingMode.affectsCurrentBalance,
    );
  });

  testWidgets('ordinary historical expense preserves current balance', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _openOrdinaryExpense(tester, fixture);

    final choice = find.byKey(const ValueKey('historical-posting-choice'));
    await tester.tap(choice);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(choice).value, isTrue);

    await _fillAndSubmit(tester);

    expect(fixture.financeStore.balances.single.currentAmount, 1000);
    expect(
      fixture.financeStore.transactions.single.balancePostingMode,
      BalancePostingMode.alreadyIncludedInCurrentBalance,
    );
    expect(
      fixture.expenseStore.all.single.balancePostingMode,
      BalancePostingMode.alreadyIncludedInCurrentBalance,
    );
  });
}

class _Fixture {
  final FinanceStore financeStore = FinanceStore(
    initialBalances: [
      FinanceBalance(
        personId: 'matteo',
        balanceId: 'account',
        name: 'Conto test',
        initialAmount: 1000,
        currentAmount: 1000,
        updatedAt: DateTime(2026, 9, 23),
        balanceType: FinanceBalanceType.bankAccount,
        operational: true,
        active: true,
        reservedAmount: 0,
        warningThreshold: 0,
        persistentStressDays: 0,
        recoveryDays: 0,
      ),
    ],
  );
  final ExpenseStore expenseStore = ExpenseStore();
  final CashWalletStore cashWalletStore = CashWalletStore();
}

Future<void> _openOrdinaryExpense(WidgetTester tester, _Fixture fixture) async {
  await fixture.expenseStore.load();
  await tester.binding.setSurfaceSize(const Size(1200, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: SpesePage(
        financeStore: fixture.financeStore,
        expenseStore: fixture.expenseStore,
        cashWalletStore: fixture.cashWalletStore,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nuovo movimento'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Spesa reale'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Conto test'));
  await tester.pumpAndSettle();
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), '30');
  await tester.enterText(fields.at(1), 'Spesa storica test');
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Casa').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<FinanceSubject>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('👨 Matteo').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Conferma spesa'));
  await tester.pumpAndSettle();
}
