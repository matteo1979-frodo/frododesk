import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/finance/finite_financial_plan_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finite_financial_plan.dart';
import 'package:frododesk/screens/finance_screen.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('it_IT'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('active plan opens the derived installment dialog', (
    tester,
  ) async {
    final harness = await _Harness.create();
    await harness.pump(tester);

    expect(find.text('Registra rata 3'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('confirm-finite-plan-installment-plan-inps')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Piano: INPS'), findsOneWidget);
    expect(find.text('Rata: 3 di 12'), findsOneWidget);
    expect(find.text('Conto: Banca di Imola'), findsOneWidget);
    expect(find.text('Soggetto: Matteo'), findsOneWidget);
    expect(find.text('Importo previsto: €386,00'), findsOneWidget);
    expect(find.text('Data pianificata: 15/09/2026'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('finite-installment-amount')))
          .controller!
          .text,
      '386.00',
    );
    expect(find.textContaining('planId'), findsNothing);
    expect(find.textContaining('balanceId'), findsNothing);
    expect(find.textContaining('economicFactId'), findsNothing);
    expect(
      find.byKey(const Key('finite-installment-fee-category')),
      findsNothing,
    );
  });

  testWidgets('completed plan exposes no registration action', (tester) async {
    final harness = await _Harness.create(completedInstallments: 12);
    await harness.pump(tester);

    expect(find.text('Completato'), findsOneWidget);
    expect(find.textContaining('Registra rata'), findsNothing);
  });

  testWidgets('INPS confirmation uses structural context and advances once', (
    tester,
  ) async {
    final harness = await _Harness.create();
    await harness.pump(tester);
    await _openDialog(tester);

    await tester.enterText(
      find.byKey(const Key('finite-installment-description')),
      'pagamento pratica legale TFR 30-23 05 45 93, Giovannini, rata terza',
    );
    await _selectCategory(tester, 'finite-installment-main-category');
    await tester.enterText(
      find.byKey(const Key('finite-installment-fee')),
      '1',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('finite-installment-fee-category')),
      findsOneWidget,
    );
    await _selectCategory(tester, 'finite-installment-fee-category');
    await _selectDate(tester, 16);
    await tester.tap(find.byKey(const Key('confirm-finite-plan-installment')));
    await tester.pumpAndSettle();

    expect(find.text('Registra rata 4'), findsOneWidget);
    expect(
      harness.finance.finiteFinancialPlans.single.completedInstallments,
      3,
    );
    expect(harness.finance.balances.single.currentAmount, 613);
    expect(harness.finance.transactions, hasLength(2));
    expect(harness.expenses.all, hasLength(2));
    expect(harness.finance.transactions.map((item) => item.amount), [386, 1]);
    expect(
      harness.finance.transactions.every(
        (item) => item.balanceId == 'balance-banca-imola',
      ),
      isTrue,
    );
    expect(
      harness.finance.transactions.every(
        (item) => item.subject == FinanceSubject.matteo,
      ),
      isTrue,
    );
    expect(
      harness.finance.transactions.every(
        (item) => item.date == DateTime(2026, 9, 16),
      ),
      isTrue,
    );
    expect(
      harness.finance.finiteFinancialPlans.single.nextInstallment!.dueDate,
      DateTime(2026, 10, 15),
    );
    expect(harness.finance.recurringItems, isEmpty);
  });

  testWidgets(
    'validation keeps dialog open and positive fee requires category',
    (tester) async {
      final harness = await _Harness.create();
      await harness.pump(tester);
      await _openDialog(tester);

      await tester.enterText(
        find.byKey(const Key('finite-installment-fee')),
        '1',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('confirm-finite-plan-installment')),
      );
      await tester.pump();

      expect(find.text('Registra rata 3'), findsWidgets);
      expect(find.byKey(const Key('finite-installment-error')), findsOneWidget);
      expect(harness.finance.transactions, isEmpty);
      expect(harness.expenses.all, isEmpty);
    },
  );

  testWidgets(
    'single-flight blocks a second submit while Finance write waits',
    (tester) async {
      final gate = Completer<void>();
      var writes = 0;
      final harness = await _Harness.create(
        writer: FinancePortfolioV3Writer(
          saveVerified: (key, value) async {
            writes++;
            await gate.future;
            return PersistenceWriteVerification(
              backendAccepted: true,
              readBack: value,
            );
          },
        ),
      );
      await harness.pump(tester);
      await _openDialog(tester);
      await tester.enterText(
        find.byKey(const Key('finite-installment-description')),
        'Rata INPS 3/12',
      );
      await _selectCategory(tester, 'finite-installment-main-category');
      await _selectDate(tester, 16);

      final confirm = find.byKey(const Key('confirm-finite-plan-installment'));
      await tester.tap(confirm);
      await tester.pump();
      expect(writes, 1);
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.tap(confirm, warnIfMissed: false);
      await tester.pump();
      expect(writes, 1);

      gate.complete();
      await tester.pumpAndSettle();
      expect(harness.finance.transactions, hasLength(1));
    },
  );
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const Key('confirm-finite-plan-installment-plan-inps')),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectCategory(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Generica').last);
  await tester.pumpAndSettle();
}

Future<void> _selectDate(WidgetTester tester, int day) async {
  await tester.tap(find.byKey(const Key('finite-installment-economic-date')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('$day').last);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

class _Harness {
  final FinanceStore finance;
  final ExpenseStore expenses;

  const _Harness(this.finance, this.expenses);

  static Future<_Harness> create({
    int completedInstallments = 2,
    FinancePortfolioV3Writer? writer,
  }) async {
    final portfolio = FinancePortfolioV3(
      balances: [_bank()],
      funds: const [],
      assetMovements: const [],
      transactions: const [],
      fundTransactions: const [],
      linkedItems: const [],
    );
    expect(
      (await FinancePortfolioV3Writer().write(portfolio)).isSuccess,
      isTrue,
    );
    expect(
      (await FiniteFinancialPlanPersistence().write([
        _plan(completedInstallments),
      ])).isSuccess,
      isTrue,
    );
    final finance = FinanceStore(portfolioV3Writer: writer);
    await finance.loadSavedPortfolioV3();
    await finance.loadSavedFiniteFinancialPlans();
    final expenses = ExpenseStore(
      saveVerified: (key, value) async =>
          PersistenceWriteVerification(backendAccepted: true, readBack: value),
    );
    await expenses.load();
    return _Harness(finance, expenses);
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceScreen(
          financeStore: finance,
          expenseStore: expenses,
          cashWalletStore: CashWalletStore(),
        ),
      ),
    );
    await tester.pump();
  }
}

FiniteFinancialPlan _plan(int completedInstallments) => FiniteFinancialPlan(
  id: 'plan-inps',
  name: 'INPS',
  subject: FinanceSubject.matteo,
  creditor: 'INPS',
  debitBalanceId: 'balance-banca-imola',
  totalInstallments: 12,
  expectedInstallmentAmount: 386,
  firstInstallmentDate: DateTime(2026, 7, 15),
  scheduledDayOfMonth: 15,
  completedInstallments: completedInstallments,
);

FinanceBalance _bank() => FinanceBalance(
  balanceId: 'balance-banca-imola',
  personId: 'matteo',
  name: 'Banca di Imola',
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
