import '../../models/real_expense.dart';

class RealExpenseHistoryMonth {
  final int year;
  final int month;
  final List<RealExpense> expenses;

  RealExpenseHistoryMonth({
    required this.year,
    required this.month,
    required Iterable<RealExpense> expenses,
  }) : expenses = List<RealExpense>.unmodifiable(expenses);
}

class RealExpenseHistoryYear {
  final int year;
  final List<RealExpenseHistoryMonth> months;

  RealExpenseHistoryYear({
    required this.year,
    required Iterable<RealExpenseHistoryMonth> months,
  }) : months = List<RealExpenseHistoryMonth>.unmodifiable(months);
}

class RealExpenseHistoryReader {
  const RealExpenseHistoryReader();

  List<RealExpenseHistoryYear> read(Iterable<RealExpense> expenses) {
    final grouped = <int, Map<int, List<RealExpense>>>{};
    for (final expense in expenses) {
      grouped
          .putIfAbsent(expense.date.year, () => <int, List<RealExpense>>{})
          .putIfAbsent(expense.date.month, () => <RealExpense>[])
          .add(expense);
    }

    final years = grouped.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    return List<RealExpenseHistoryYear>.unmodifiable(
      years.map((year) {
        final byMonth = grouped[year]!;
        final months = byMonth.keys.toList()
          ..sort((left, right) => right.compareTo(left));
        return RealExpenseHistoryYear(
          year: year,
          months: months.map((month) {
            final monthExpenses = List<RealExpense>.of(byMonth[month]!)
              ..sort((left, right) => right.date.compareTo(left.date));
            return RealExpenseHistoryMonth(
              year: year,
              month: month,
              expenses: monthExpenses,
            );
          }),
        );
      }),
    );
  }
}
