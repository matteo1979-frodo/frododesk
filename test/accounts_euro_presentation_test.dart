import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/screens/account_detail_screen.dart';
import 'package:frododesk/screens/person_finance_screen.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:frododesk/widgets/finance/finance_accounts_panel.dart';

void main() {
  testWidgets('person finance formats total and every account balance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final balances = [
      _balance('integer', 100),
      _balance('cents', 100.25),
      _balance('negative', -100.25),
      _balance('thousands', 1234.56),
      _balance('zero', -0.0),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PersonFinanceScreen(
          financeStore: FinanceStore(initialBalances: balances),
          personId: 'matteo',
          personName: 'Matteo',
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('€1.334,56'), findsOneWidget);
    expect(find.text('€100,00'), findsOneWidget);
    expect(find.text('€100,25'), findsOneWidget);
    expect(find.text('-€100,25'), findsOneWidget);
    expect(find.text('€1.234,56'), findsOneWidget);
    expect(find.text('€0,00'), findsOneWidget);
  });

  testWidgets('account detail formats movements by structural direction', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final balance = _balance('account', -100.25);
    final transactions = [
      _transaction('income', 10, isIncome: true),
      _transaction('expense', 10, isIncome: false),
      _transaction(
        'adjustment-in',
        5.25,
        isIncome: true,
        origin: FinanceTransactionOrigin.adjustment,
      ),
      _transaction(
        'adjustment-out',
        4.75,
        isIncome: false,
        origin: FinanceTransactionOrigin.adjustment,
      ),
      _transaction(
        'transfer-in',
        1234.56,
        isIncome: true,
        type: FinanceTransactionType.transfer,
      ),
      _transaction(
        'transfer-out',
        1234.56,
        isIncome: false,
        type: FinanceTransactionType.transfer,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AccountDetailScreen(
          financeStore: FinanceStore(
            initialBalances: [balance],
            initialTransactions: transactions,
          ),
          balance: balance,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('-€100,25'), findsOneWidget);
    expect(find.text('+€10,00'), findsOneWidget);
    expect(find.text('-€10,00'), findsOneWidget);
    expect(find.text('+€5,25'), findsOneWidget);
    expect(find.text('-€4,75'), findsOneWidget);

    await tester.tap(find.text('Vedi tutti'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('+€1.234,56'), findsWidgets);
    expect(find.text('-€1.234,56'), findsWidgets);
  });

  testWidgets('shared accounts panel formats large and signed balances', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinanceAccountsPanel(
            financeStore: FinanceStore(
              initialBalances: [
                _balance('integer', 100),
                _balance('negative', -100.25),
                _balance('millions', 1234567.89),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('€100,00'), findsOneWidget);
    expect(find.text('-€100,25'), findsOneWidget);
    expect(find.text('€1.234.567,89'), findsOneWidget);
  });
}

FinanceBalance _balance(String id, double amount) {
  return FinanceBalance(
    personId: 'matteo',
    balanceId: id,
    name: id,
    initialAmount: amount,
    currentAmount: amount,
    updatedAt: DateTime(2026, 8, 21),
    balanceType: FinanceBalanceType.bankAccount,
    operational: true,
    active: true,
    reservedAmount: 0,
    warningThreshold: 0,
    persistentStressDays: 0,
    recoveryDays: 0,
  );
}

FinanceTransaction _transaction(
  String id,
  double amount, {
  required bool isIncome,
  FinanceTransactionType? type,
  FinanceTransactionOrigin origin = FinanceTransactionOrigin.manual,
}) {
  return FinanceTransaction(
    id: id,
    balanceId: 'account',
    amount: amount,
    date: DateTime(2026, 8, 21),
    isIncome: isIncome,
    subject: FinanceSubject.matteo,
    description: id,
    type: type ??
        (isIncome
            ? FinanceTransactionType.income
            : FinanceTransactionType.expense),
    origin: origin,
  );
}
