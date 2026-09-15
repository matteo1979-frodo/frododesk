import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/screens/finance_screen.dart';
import 'package:frododesk/screens/home_screen.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/utils/euro_formatter.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Home refreshes its Finance summary after returning from Spese', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.ensureVisible(find.text('Spese'));
    await tester.pump();
    await tester.tap(find.text('Spese'));
    await _finishNavigation(tester);

    final spesePage = tester.widget<SpesePage>(find.byType(SpesePage));
    final expectedTotal = spesePage.financeStore.totalBalance() + 121.40;
    await spesePage.financeStore.addBalance(_balance(amount: 121.40));
    expect(spesePage.financeStore.totalBalance(), expectedTotal);

    Navigator.of(tester.element(find.byType(SpesePage))).pop();
    await _finishNavigation(tester);

    expect(
      find.textContaining(
        'Saldo ${EuroFormatter.format(expectedTotal)}',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Home refreshes its Finance summary after returning from Finance', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.ensureVisible(find.text('Finanze'));
    await tester.pump();
    await tester.tap(find.text('Finanze'));
    await _finishNavigation(tester);

    final financeScreen = tester.widget<FinanceScreen>(
      find.byType(FinanceScreen),
    );
    final expectedTotal = financeScreen.financeStore.totalBalance() + 40;
    await financeScreen.financeStore.addBalance(_balance(amount: 40));
    expect(financeScreen.financeStore.totalBalance(), expectedTotal);

    Navigator.of(tester.element(find.byType(FinanceScreen))).pop();
    await _finishNavigation(tester);

    expect(
      find.textContaining(
        'Saldo ${EuroFormatter.format(expectedTotal)}',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  await initializeDateFormatting('it_IT');
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final coreStore = CoreStore(initialDate: DateTime(2026, 9, 15));
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(ipsStore: coreStore.ipsStore, coreStore: coreStore),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _finishNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

FinanceBalance _balance({required double amount}) => FinanceBalance(
  personId: 'matteo',
  balanceId: 'balance_home_refresh_test',
  name: 'Conto test refresh Home',
  initialAmount: amount,
  currentAmount: amount,
  updatedAt: DateTime(2026, 9, 15),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);
