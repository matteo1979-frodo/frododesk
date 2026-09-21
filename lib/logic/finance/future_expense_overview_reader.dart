import '../../models/future_expense_overview.dart';
import '../../models/future_expense_projection.dart';

class FutureExpenseOverviewReader {
  const FutureExpenseOverviewReader();

  FutureExpenseOverview read({
    required Iterable<FutureExpenseProjection> expenses,
    required DateTime referenceTime,
  }) {
    final referenceMonth = _month(referenceTime);
    final current = <FutureExpenseProjection>[];
    final past = <FutureExpenseProjection>[];
    final unplaced = <FutureExpenseProjection>[];
    final future = <DateTime, List<FutureExpenseProjection>>{};

    for (final expense in expenses) {
      final start = expense.displayStart;
      if (start == null) {
        unplaced.add(expense);
        continue;
      }
      final month = _month(start);
      if (month == referenceMonth) {
        current.add(expense);
      } else if (month.isBefore(referenceMonth)) {
        past.add(expense);
      } else {
        future.putIfAbsent(month, () => []).add(expense);
      }
    }

    final months = future.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return FutureExpenseOverview(
      currentMonth: current,
      overdueFromPastMonths: past,
      futureMonths: months.map(
        (entry) =>
            FutureExpenseMonthGroup(month: entry.key, expenses: entry.value),
      ),
      unplaced: unplaced,
    );
  }

  DateTime _month(DateTime value) => DateTime(value.year, value.month);
}
