import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/spese/real_expense_history_reader.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/screens/spese_page.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const reader = RealExpenseHistoryReader();

  test('groups only populated years and months in descending order', () {
    final result = reader.read([
      _expense('jan-new', DateTime(2027, 1, 20)),
      _expense('dec', DateTime(2026, 12, 31)),
      _expense('jan-old', DateTime(2027, 1, 2)),
      _expense('march', DateTime(2027, 3, 1)),
      _expense('historic', DateTime(2024, 6, 15)),
    ]);

    expect(result.map((item) => item.year), [2027, 2026, 2024]);
    expect(result.first.months.map((item) => item.month), [3, 1]);
    expect(result.first.months.last.expenses.map((item) => item.id), [
      'jan-new',
      'jan-old',
    ]);
    expect(result[1].months.single.month, 12);
    expect(result.last.months.single.month, 6);
  });

  test('empty input does not invent years or months', () {
    expect(reader.read(const []), isEmpty);
  });

  test('results and nested collections are immutable', () {
    final expense = _expense('one', DateTime(2026, 9, 1));
    final result = reader.read([expense]);

    expect(
      () => result.add(
        RealExpenseHistoryYear(year: 2025, months: const []),
      ),
      throwsUnsupportedError,
    );
    expect(
      () => result.single.months.add(
        RealExpenseHistoryMonth(year: 2026, month: 8, expenses: const []),
      ),
      throwsUnsupportedError,
    );
    expect(
      () => result.single.months.single.expenses.add(expense),
      throwsUnsupportedError,
    );
  });

  test('does not mutate the input or distinguish recovered expenses', () {
    final input = [
      _expense('older', DateTime(2026, 5, 1)),
      _expense('recovered', DateTime(2026, 5, 20)),
    ];
    final originalOrder = input.map((item) => item.id).toList();

    final result = reader.read(input);

    expect(input.map((item) => item.id), originalOrder);
    expect(result.single.months.single.expenses.map((item) => item.id), [
      'recovered',
      'older',
    ]);
  });

  testWidgets('history remains reachable and explains an empty store', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: SpesePage(
          financeStore: FinanceStore(),
          expenseStore: ExpenseStore(),
          cashWalletStore: CashWalletStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final access = find.byKey(const Key('real-expense-history-open'));
    expect(access, findsOneWidget);
    await tester.ensureVisible(access);
    await tester.tap(access);
    await tester.pumpAndSettle();

    expect(find.text('Storico spese'), findsOneWidget);
    expect(find.byKey(const Key('real-expense-history-empty')), findsOneWidget);
    expect(find.text('Non ci sono ancora spese nello storico.'), findsOneWidget);
  });

  testWidgets('history opens the newest real month with its movements', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = ExpenseStore();
    await store.load();
    await store.addExpense(_expense('old-year', DateTime(2024, 12, 5)));
    await store.addExpense(_expense('new-year', DateTime(2025, 2, 10)));

    await tester.pumpWidget(
      MaterialApp(
        home: SpesePage(
          financeStore: FinanceStore(),
          expenseStore: store,
          cashWalletStore: CashWalletStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final access = find.byKey(const Key('real-expense-history-open'));
    await tester.ensureVisible(access);
    await tester.tap(access);
    await tester.pumpAndSettle();

    expect(find.text('2025'), findsWidgets);
    final february = find.byKey(
      const Key('real-expense-history-month-2025-2'),
    );
    expect(february, findsOneWidget);
    await tester.tap(february);
    await tester.pumpAndSettle();

    expect(find.text('Storico mese'), findsOneWidget);
    expect(find.text('Febbraio 2025'), findsOneWidget);
    expect(find.text('new-year'), findsOneWidget);
  });
}

RealExpense _expense(String id, DateTime date) => RealExpense(
  id: id,
  balanceId: 'balance',
  balanceName: 'Conto',
  amount: 10,
  description: id,
  category: 'Generica',
  date: date,
);
