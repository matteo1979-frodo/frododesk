import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/spese/builders/spese_month_snapshot_builder.dart';
import 'package:frododesk/logic/spese/spese_coordinator.dart';
import 'package:frododesk/models/cash_wallet.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/frodo_observation.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_category_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('monthly builder reproduces the current deterministic aggregations', () {
    final observedAt = DateTime(2026, 8, 17, 12);
    final expenses = [
      _expense('latest', 30, 'Casa', DateTime(2026, 8, 16)),
      _expense('older', 20, 'Auto', DateTime(2026, 8, 11)),
      _expense('top-tie', 10, 'Auto', DateTime(2026, 8, 1)),
      _expense('previous', 40, 'Casa', DateTime(2026, 7, 20)),
    ];
    final observations = [_observation(observedAt)];

    final snapshot = const SpeseMonthSnapshotBuilder().build(
      expenses: expenses,
      cashWallets: const [
        CashWallet(
          id: 'wallet',
          personId: 'matteo',
          name: 'Portafoglio',
          currentAmount: 75,
        ),
      ],
      balances: const [],
      categories: const [],
      observations: observations,
      observedAt: observedAt,
    );

    expect(snapshot.monthTitle, 'Agosto 2026');
    expect(snapshot.currentMonthExpenses.map((item) => item.id), [
      'latest',
      'older',
      'top-tie',
    ]);
    expect(snapshot.previousMonthExpenses.single.id, 'previous');
    expect(snapshot.currentMonthTotal, 60);
    expect(snapshot.last7DaysTotal, 50);
    expect(snapshot.cashWalletTotal, 75);
    expect(snapshot.movementCount, 3);
    expect(snapshot.mainCategory, 'Casa / Auto');
    expect(snapshot.categoryTotals, {'Casa': 30, 'Auto': 30});
    expect(snapshot.monthObservations, orderedEquals(observations));
  });

  test('snapshot owns immutable copies and builder does not mutate inputs', () {
    final expenses = [_expense('one', 10, 'Casa', DateTime(2026, 8, 10))];
    final originalOrder = List<RealExpense>.of(expenses);
    final snapshot = const SpeseMonthSnapshotBuilder().build(
      expenses: expenses,
      cashWallets: const [],
      balances: const [],
      categories: const [],
      observations: const [],
      observedAt: DateTime(2026, 8, 17),
    );

    expenses.add(_expense('two', 20, 'Auto', DateTime(2026, 8, 11)));

    expect(originalOrder.single.id, 'one');
    expect(snapshot.currentMonthExpenses.single.id, 'one');
    expect(
      () => snapshot.currentMonthExpenses.add(originalOrder.single),
      throwsUnsupportedError,
    );
    expect(() => snapshot.categoryTotals['Altro'] = 1, throwsUnsupportedError);
  });

  test('coordinator orchestrates stores and delegates aggregation', () async {
    final operations = <String>[];
    final expenseStore = _RecordingExpenseStore(operations)
      ..expenses.add(_expense('one', 25, 'Casa', DateTime(2026, 8, 12)));
    final categoryStore = _RecordingCategoryStore(operations);
    final walletStore = _RecordingCashWalletStore(operations);
    final coordinator = SpeseCoordinator(
      financeStore: FinanceStore(),
      expenseStore: expenseStore,
      categoryStore: categoryStore,
      cashWalletStore: walletStore,
    );

    final snapshot = await coordinator.initialize(
      observedAt: DateTime(2026, 8, 17),
    );

    expect(operations, ['expenses.load', 'categories.load', 'wallets.load']);
    expect(snapshot.currentMonthTotal, 25);
    expect(snapshot.monthObservations, isNotEmpty);
  });

  testWidgets('Spese page preserves its visible baseline through snapshot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SpesePage(financeStore: FinanceStore())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spese'), findsOneWidget);
    expect(find.text('Controllo Spese Reali'), findsOneWidget);
    expect(find.text('Nuovo movimento'), findsOneWidget);
    expect(find.text('Lettura del mese'), findsOneWidget);
  });

  test(
    'page no longer owns monthly transformations or observation side effects',
    () {
      final page = File('lib/screens/spese_page.dart').readAsStringSync();
      final coordinator = File(
        'lib/logic/spese/spese_coordinator.dart',
      ).readAsStringSync();
      final builder = File(
        'lib/logic/spese/builders/spese_month_snapshot_builder.dart',
      ).readAsStringSync();

      expect(page, isNot(contains('ObservationEngine')));
      expect(page, isNot(contains('FrodoDeskBootstrap')));
      expect(page, isNot(contains('categoryTotals')));
      expect(page, isNot(contains('.where(')));
      expect(page, isNot(contains('SpeseCommandRegistry(')));
      expect(page, isNot(contains('.take(')));
      expect(coordinator, contains('snapshotBuilder.build('));
      expect(builder, contains('activeBalances'));
      expect(builder, contains('commandRegistry'));
      expect(builder, isNot(contains('DateTime.now')));
      expect(builder, isNot(contains('package:flutter')));
      expect(builder, isNot(contains('PersistenceStore')));
    },
  );
}

RealExpense _expense(
  String id,
  double amount,
  String category,
  DateTime date,
) => RealExpense(
  id: id,
  balanceId: 'conto',
  balanceName: 'Conto',
  amount: amount,
  description: id,
  category: category,
  date: date,
  subject: FinanceSubject.shared,
);

FrodoObservation _observation(DateTime createdAt) => FrodoObservation(
  id: 'observation',
  module: 'spese',
  category: FrodoObservationCategory.expenses,
  title: 'Titolo',
  message: 'Messaggio',
  priority: 1,
  level: FrodoObservationLevel.info,
  createdAt: createdAt,
);

class _RecordingExpenseStore extends ExpenseStore {
  final List<String> operations;

  _RecordingExpenseStore(this.operations);

  @override
  Future<void> load() async => operations.add('expenses.load');
}

class _RecordingCategoryStore extends ExpenseCategoryStore {
  final List<String> operations;

  _RecordingCategoryStore(this.operations);

  @override
  Future<void> load() async => operations.add('categories.load');
}

class _RecordingCashWalletStore extends CashWalletStore {
  final List<String> operations;

  _RecordingCashWalletStore(this.operations);

  @override
  Future<void> load() async => operations.add('wallets.load');
}
