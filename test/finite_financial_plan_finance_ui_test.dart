import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  FinanceBalance bank() => FinanceBalance(
    personId: 'matteo',
    balanceId: 'balance_banca_imola',
    name: 'Banca di Imola',
    initialAmount: 2749.28,
    currentAmount: 2749.28,
    updatedAt: DateTime(2026, 9, 15),
    balanceType: FinanceBalanceType.bankAccount,
    operational: true,
    active: true,
    reservedAmount: 0,
    warningThreshold: 0,
    persistentStressDays: 0,
    recoveryDays: 0,
  );

  FiniteFinancialPlan inps({int completed = 2}) => FiniteFinancialPlan(
    id: 'finite_plan_inps',
    name: 'INPS',
    creditor: 'INPS',
    subject: FinanceSubject.matteo,
    debitBalanceId: 'balance_banca_imola',
    totalInstallments: 12,
    expectedInstallmentAmount: 386,
    firstInstallmentDate: DateTime(2026, 7, 15),
    scheduledDayOfMonth: 15,
    completedInstallments: completed,
  );

  Future<void> pumpScreen(WidgetTester tester, FinanceStore store) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceScreen(
          financeStore: store,
          expenseStore: ExpenseStore(),
          cashWalletStore: CashWalletStore(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the finite plan section and dedicated minimal form', (
    tester,
  ) async {
    await pumpScreen(tester, FinanceStore(initialBalances: [bank()]));

    expect(find.text('Piani finanziari'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-finite-financial-plan')));
    await tester.pumpAndSettle();

    expect(find.text('Nuovo piano finanziario'), findsOneWidget);
    expect(find.text('Nome piano'), findsOneWidget);
    expect(find.text('Creditore'), findsOneWidget);
    expect(find.text('Soggetto'), findsOneWidget);
    expect(find.text('Conto di addebito'), findsOneWidget);
    expect(find.text('Numero totale rate'), findsOneWidget);
    expect(find.text('Importo previsto rata'), findsOneWidget);
    expect(find.text('Data prima rata'), findsOneWidget);
    expect(find.text('Rate già completate'), findsOneWidget);
    expect(find.text('ID'), findsNothing);
    expect(find.text('Banca di Imola'), findsOneWidget);
  });

  testWidgets('renders the derived INPS installment without economic changes', (
    tester,
  ) async {
    final store = FinanceStore(
      initialBalances: [bank()],
      initialFiniteFinancialPlans: [inps()],
    );
    await pumpScreen(tester, store);

    expect(find.text('INPS'), findsOneWidget);
    expect(find.text('Rata 3 di 12'), findsOneWidget);
    expect(find.text('€386,00 • 15/09/2026'), findsOneWidget);
    expect(find.text('Matteo • Banca di Imola'), findsOneWidget);
    expect(store.balances.single.currentAmount, 2749.28);
    expect(store.transactions, isEmpty);
    expect(store.recurringItems, isEmpty);
  });

  testWidgets('valid form saves by balance id and immediately shows the card', (
    tester,
  ) async {
    final persistence = FiniteFinancialPlanPersistence(
      saveVerified: (key, value) async =>
          PersistenceWriteVerification(backendAccepted: true, readBack: value),
    );
    final store = FinanceStore(
      initialBalances: [bank()],
      finiteFinancialPlanPersistence: persistence,
    );
    await pumpScreen(tester, store);
    await tester.tap(find.byKey(const Key('add-finite-financial-plan')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('finite-plan-name')), 'INPS');
    await tester.enterText(
      find.byKey(const Key('finite-plan-creditor')),
      'INPS',
    );
    await tester.tap(find.byKey(const Key('finite-plan-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matteo').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('finite-plan-total')), '12');
    await tester.enterText(find.byKey(const Key('finite-plan-amount')), '386');
    await tester.enterText(find.byKey(const Key('finite-plan-completed')), '2');
    await tester.tap(find.byKey(const Key('finite-plan-first-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('save-finite-financial-plan')),
    );
    await tester.tap(find.byKey(const Key('save-finite-financial-plan')));
    await tester.pumpAndSettle();

    expect(store.finiteFinancialPlans, hasLength(1));
    final saved = store.finiteFinancialPlans.single;
    expect(saved.name, 'INPS');
    expect(saved.subject, FinanceSubject.matteo);
    expect(saved.debitBalanceId, 'balance_banca_imola');
    expect(saved.frequency, FiniteFinancialPlanFrequency.monthly);
    expect(saved.completedInstallments, 2);
    expect(find.text('INPS'), findsOneWidget);
    expect(find.text('Rata 3 di 12'), findsOneWidget);
    expect(find.text('Matteo • Banca di Imola'), findsOneWidget);
    expect(store.balances.single.currentAmount, 2749.28);
    expect(store.transactions, isEmpty);
    expect(store.recurringItems, isEmpty);
  });

  testWidgets('completed plan shows no invented future installment', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      FinanceStore(
        initialBalances: [bank()],
        initialFiniteFinancialPlans: [inps(completed: 12)],
      ),
    );

    expect(find.text('Completato'), findsOneWidget);
    expect(find.textContaining('Rata 13'), findsNothing);
    expect(find.textContaining('15/07/2027'), findsNothing);
  });

  testWidgets('persistence failure keeps dialog open and adds no false card', (
    tester,
  ) async {
    final persistence = FiniteFinancialPlanPersistence(
      saveVerified: (key, value) async => const PersistenceWriteVerification(
        backendAccepted: false,
        readBack: null,
      ),
    );
    final store = FinanceStore(
      initialBalances: [bank()],
      finiteFinancialPlanPersistence: persistence,
    );
    await pumpScreen(tester, store);
    await tester.tap(find.byKey(const Key('add-finite-financial-plan')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('finite-plan-name')), 'INPS');
    await tester.enterText(
      find.byKey(const Key('finite-plan-creditor')),
      'INPS',
    );
    await tester.enterText(find.byKey(const Key('finite-plan-total')), '12');
    await tester.enterText(find.byKey(const Key('finite-plan-amount')), '386');
    await tester.enterText(find.byKey(const Key('finite-plan-completed')), '2');
    await tester.tap(find.byKey(const Key('finite-plan-first-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-finite-financial-plan')));
    await tester.pumpAndSettle();

    expect(find.text('Nuovo piano finanziario'), findsOneWidget);
    expect(find.byKey(const Key('finite-plan-error')), findsOneWidget);
    expect(store.finiteFinancialPlans, isEmpty);
    expect(
      find.byKey(const Key('finite-financial-plan-finite_plan_inps')),
      findsNothing,
    );
    expect(store.balances.single.currentAmount, 2749.28);
    expect(store.transactions, isEmpty);
    expect(store.recurringItems, isEmpty);
  });
}
