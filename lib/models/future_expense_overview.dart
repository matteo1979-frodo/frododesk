import 'dart:collection';

import 'future_expense_projection.dart';

class FutureExpenseMonthGroup {
  final DateTime month;
  final UnmodifiableListView<FutureExpenseProjection> expenses;

  FutureExpenseMonthGroup({
    required this.month,
    required Iterable<FutureExpenseProjection> expenses,
  }) : expenses = UnmodifiableListView(List.of(expenses));
}

class FutureExpenseOverview {
  final UnmodifiableListView<FutureExpenseProjection> currentMonth;
  final UnmodifiableListView<FutureExpenseProjection> overdueFromPastMonths;
  final UnmodifiableListView<FutureExpenseMonthGroup> futureMonths;
  final UnmodifiableListView<FutureExpenseProjection> unplaced;

  FutureExpenseOverview({
    required Iterable<FutureExpenseProjection> currentMonth,
    required Iterable<FutureExpenseProjection> overdueFromPastMonths,
    required Iterable<FutureExpenseMonthGroup> futureMonths,
    required Iterable<FutureExpenseProjection> unplaced,
  }) : currentMonth = UnmodifiableListView(List.of(currentMonth)),
       overdueFromPastMonths = UnmodifiableListView(
         List.of(overdueFromPastMonths),
       ),
       futureMonths = UnmodifiableListView(List.of(futureMonths)),
       unplaced = UnmodifiableListView(List.of(unplaced));

  int get futureCount =>
      futureMonths.fold(0, (total, group) => total + group.expenses.length);
}
