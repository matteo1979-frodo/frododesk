import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_funds_view_builder.dart';
import 'package:frododesk/logic/finance/finance_funds_coordinator.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/fund_transaction.dart';
import 'package:frododesk/models/finance_fund_mutation_plan.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:frododesk/screens/finance/finance_funds_page.dart';

void main() {
  test('funds builder groups newest transactions without mutating store', () {
    final store = FinanceStore();
    store.funds.add(
      const FinanceFund(
        id: 'f1',
        name: 'Emergenze',
        description: 'Riserva',
        amount: 500,
        protected: true,
        category: FinanceFundCategory.emergency,
      ),
    );
    store.fundTransactions.addAll([
      FundTransaction(
        id: 'old',
        fundId: 'f1',
        description: 'A',
        amount: 10,
        date: DateTime(2026, 1, 1),
        type: FundTransactionType.deposit,
      ),
      FundTransaction(
        id: 'new',
        fundId: 'f1',
        description: 'B',
        amount: 20,
        date: DateTime(2026, 2, 1),
        type: FundTransactionType.withdraw,
      ),
    ]);

    final viewData = const FinanceFundsViewBuilder().build(store);

    expect(viewData.totalAmount, 500);
    expect(viewData.funds.single.transactions.map((item) => item.id), [
      'new',
      'old',
    ]);
    expect(store.fundTransactions.map((item) => item.id), ['old', 'new']);
  });

  test(
    'funds coordinator delegates patrimonial commands and safe detail updates',
    () async {
      final store = _RecordingFundStore();
      final coordinator = FinanceFundsCoordinator(
        financeStore: store,
        clock: () => DateTime(2026, 8, 11),
      );

      await coordinator.openFund(
        name: 'Casa',
        description: 'Lavori',
        amount: 100,
        protected: false,
        category: FinanceFundCategory.home,
        preExisting: true,
        sources: const [],
      );
      final fund = store.funds.single;
      await coordinator.updateDetails(
        current: fund,
        name: 'Casa 2',
        description: 'Lavori',
        protected: true,
        category: FinanceFundCategory.home,
      );
      await coordinator.spend(fund.id, 20, 'Spesa');

      expect(store.operations, [
        'commitFundPlan',
        'commitFundPlan',
        'commitFundPlan',
      ]);
    },
  );

  test('funds coordinator commits a direct transfer between funds', () async {
    final store = _RecordingFundStore()
      ..funds.addAll([
        const FinanceFund(
          id: 'vacanze',
          name: 'Vacanze',
          description: '',
          amount: 500,
          protected: false,
          category: FinanceFundCategory.generic,
        ),
        const FinanceFund(
          id: 'auto',
          name: 'Auto',
          description: '',
          amount: 100,
          protected: false,
          category: FinanceFundCategory.auto,
        ),
      ]);
    final coordinator = FinanceFundsCoordinator(
      financeStore: store,
      clock: () => DateTime(2026, 8, 15),
    );

    await coordinator.transferBetweenFunds(
      'vacanze',
      'auto',
      150,
      'Cambio obiettivo',
    );

    expect(store.operations, ['commitFundPlan']);
    expect(store.funds.map((item) => item.amount), [350, 250]);
    expect(store.assetMovements, hasLength(2));
    expect(store.transactions, isEmpty);
  });

  testWidgets('funds page renders the recovered management entry point', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceFundsPage(
          coordinator: FinanceFundsCoordinator(financeStore: FinanceStore()),
        ),
      ),
    );

    expect(find.text('Fondi famiglia'), findsOneWidget);
    expect(find.text('Nuovo fondo'), findsOneWidget);
    expect(find.text('Nessun fondo inserito'), findsOneWidget);
  });

  testWidgets(
    'new fund guides account selection and enables save only when totals match',
    (tester) async {
      final store = FinanceStore()
        ..balances.add(_balance('matteo', 50))
        ..balances.add(_balance('chiara', 100));
      await tester.pumpWidget(
        MaterialApp(
          home: FinanceFundsPage(
            coordinator: FinanceFundsCoordinator(financeStore: store),
          ),
        ),
      );

      await tester.tap(find.text('Nuovo fondo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('fund-name')), 'Vacanze');
      await tester.enterText(
        find.byKey(const Key('fund-opening-amount')),
        '100',
      );
      await tester.tap(find.text('Saldo già esistente'));
      await tester.pumpAndSettle();

      expect(find.text('Da quali conti?'), findsOneWidget);
      expect(find.byKey(const Key('fund-amount-matteo')), findsNothing);
      await tester.tap(find.byKey(const Key('fund-account-matteo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fund-amount-matteo')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('fund-amount-matteo')), '60');
      await tester.ensureVisible(find.byKey(const Key('fund-account-chiara')));
      await tester.tap(find.byKey(const Key('fund-account-chiara')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('fund-amount-chiara')), '40');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save-fund-button')))
            .onPressed,
        isNull,
      );

      await tester.enterText(find.byKey(const Key('fund-amount-matteo')), '40');
      await tester.enterText(find.byKey(const Key('fund-amount-chiara')), '60');
      await tester.pump();
      expect(find.text('Totale movimentato'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save-fund-button')))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('move money shows account amount only after selection', (
    tester,
  ) async {
    final store = FinanceStore()
      ..balances.add(_balance('matteo', 300))
      ..funds.add(
        const FinanceFund(
          id: 'vacanze',
          name: 'Vacanze',
          description: 'Estate',
          amount: 100,
          protected: false,
          category: FinanceFundCategory.generic,
        ),
      );
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceFundsPage(
          coordinator: FinanceFundsCoordinator(financeStore: store),
        ),
      ),
    );

    await tester.tap(find.text('Vacanze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sposta denaro'));
    await tester.pumpAndSettle();

    expect(find.text('Cosa vuoi fare?'), findsNothing);
    expect(find.text('Da quali conti?'), findsOneWidget);
    expect(find.text('Saldo attuale'), findsOneWidget);
    expect(find.byKey(const Key('fund-amount-matteo')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('register-fund-operation')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('fund-account-matteo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fund-amount-matteo')), findsOneWidget);
  });

  testWidgets('move money transfers directly between two funds', (
    tester,
  ) async {
    final store = FinanceStore()
      ..funds.addAll([
        const FinanceFund(
          id: 'vacanze',
          name: 'Vacanze',
          description: 'Estate',
          amount: 500,
          protected: false,
          category: FinanceFundCategory.generic,
        ),
        const FinanceFund(
          id: 'auto',
          name: 'Fondo Auto',
          description: 'Manutenzione',
          amount: 100,
          protected: false,
          category: FinanceFundCategory.auto,
        ),
      ]);
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceFundsPage(
          coordinator: FinanceFundsCoordinator(financeStore: store),
        ),
      ),
    );

    await tester.tap(find.text('Vacanze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sposta denaro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tra fondi'));
    await tester.pumpAndSettle();

    expect(find.text('Verso quale fondo?'), findsOneWidget);
    expect(find.byKey(const Key('fund-transfer-amount')), findsOneWidget);
    await tester.tap(find.byKey(const Key('destination-fund-auto')));
    await tester.enterText(
      find.byKey(const Key('fund-transfer-amount')),
      '150',
    );
    await tester.pump();
    final register = tester.widget<FilledButton>(
      find.byKey(const Key('register-fund-operation')),
    );
    expect(register.onPressed, isNotNull);
  });

  testWidgets('fund transfer history resolves both fund names from its legs', (
    tester,
  ) async {
    final store = _RecordingFundStore()
      ..funds.addAll([
        const FinanceFund(
          id: 'vacanze',
          name: 'vacanze',
          description: 'Estate',
          amount: 500,
          protected: false,
          category: FinanceFundCategory.generic,
        ),
        const FinanceFund(
          id: 'auto',
          name: 'fondo Auto',
          description: 'Manutenzione',
          amount: 100,
          protected: false,
          category: FinanceFundCategory.auto,
        ),
      ]);
    final coordinator = FinanceFundsCoordinator(
      financeStore: store,
      clock: () => DateTime(2026, 8, 16),
    );
    await coordinator.transferBetweenFunds('vacanze', 'auto', 150, '');

    await tester.pumpWidget(
      MaterialApp(home: FinanceFundsPage(coordinator: coordinator)),
    );
    await tester.tap(find.text('Vacanze'));
    await tester.pumpAndSettle();

    expect(find.text('Vacanze  →  Fondo Auto'), findsOneWidget);
    expect(find.text('Vacanze  →  Vacanze'), findsNothing);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
  });
}

FinanceBalance _balance(String id, double amount) => FinanceBalance(
  personId: id,
  balanceId: id,
  name: 'Conto ${id[0].toUpperCase()}${id.substring(1)}',
  initialAmount: amount,
  currentAmount: amount,
  updatedAt: DateTime(2026, 8, 11),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

class _RecordingFundStore extends FinanceStore {
  final operations = <String>[];

  @override
  Future<void> updateFund(FinanceFund updatedFund) async {
    operations.add('updateFund');
    final index = funds.indexWhere((fund) => fund.id == updatedFund.id);
    funds[index] = updatedFund;
  }

  @override
  Future<void> commitFundPlan(FinanceFundMutationPlan plan) async {
    operations.add('commitFundPlan');
    balances
      ..clear()
      ..addAll(plan.balances);
    funds
      ..clear()
      ..addAll(plan.funds);
    assetMovements
      ..clear()
      ..addAll(plan.movements);
    transactions
      ..clear()
      ..addAll(plan.transactions);
  }
}
