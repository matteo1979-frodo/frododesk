import 'dart:collection';

import 'future_expense_projection.dart';
import 'projected_expense_cycle.dart';

enum FutureOutflowAuthority {
  expectedExpense,
  projectedExpenseRelationship,
  finiteFinancialPlan,
}

enum FutureOutflowDatePresentation {
  plannedEconomicImpact,
  expectedDebitWindow,
  dueDateFallback,
  unplaced,
  finitePlanForecast,
  projectedCycle,
}

class FutureOutflowPresentation {
  final String identity;
  final FutureOutflowAuthority authority;
  final String title;
  final String details;
  final double amount;
  final DateTime? placementStart;
  final DateTime? placementEnd;
  final FutureOutflowDatePresentation datePresentation;
  final bool requiresPlanning;
  final bool provisional;
  final bool requiresUserAction;
  final bool overdue;
  final FutureExpenseProjection? expectedExpense;
  final ProjectedExpenseCycle? projectedExpenseCycle;
  final String? planId;
  final int? installmentNumber;
  final int? totalInstallments;

  const FutureOutflowPresentation({
    required this.identity,
    required this.authority,
    required this.title,
    required this.details,
    required this.amount,
    required this.placementStart,
    required this.placementEnd,
    required this.datePresentation,
    required this.requiresPlanning,
    required this.provisional,
    required this.requiresUserAction,
    required this.overdue,
    this.expectedExpense,
    this.projectedExpenseCycle,
    this.planId,
    this.installmentNumber,
    this.totalInstallments,
  });

  bool get isInteractive => expectedExpense != null;
}

class FutureOutflowMonthGroup {
  final DateTime month;
  final UnmodifiableListView<FutureOutflowPresentation> items;

  FutureOutflowMonthGroup({
    required this.month,
    required Iterable<FutureOutflowPresentation> items,
  }) : items = UnmodifiableListView(List.of(items));
}

class FutureOutflowOverview {
  final UnmodifiableListView<FutureOutflowPresentation> currentMonth;
  final UnmodifiableListView<FutureOutflowPresentation> pastMonths;
  final UnmodifiableListView<FutureOutflowMonthGroup> futureMonths;
  final UnmodifiableListView<FutureOutflowPresentation> unplaced;

  FutureOutflowOverview({
    required Iterable<FutureOutflowPresentation> currentMonth,
    required Iterable<FutureOutflowPresentation> pastMonths,
    required Iterable<FutureOutflowMonthGroup> futureMonths,
    required Iterable<FutureOutflowPresentation> unplaced,
  }) : currentMonth = UnmodifiableListView(List.of(currentMonth)),
       pastMonths = UnmodifiableListView(List.of(pastMonths)),
       futureMonths = UnmodifiableListView(List.of(futureMonths)),
       unplaced = UnmodifiableListView(List.of(unplaced));

  int get futureCount =>
      futureMonths.fold(0, (total, group) => total + group.items.length);
}
