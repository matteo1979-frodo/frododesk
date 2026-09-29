import 'dart:collection';

import 'documentary_obligation.dart';
import 'future_expense_projection.dart';
import 'projected_expense_cycle.dart';

enum FutureOutflowAuthority {
  expectedExpense,
  projectedExpenseRelationship,
  finiteFinancialPlan,
  documentaryObligation,
}

enum FutureOutflowDatePresentation {
  plannedEconomicImpact,
  expectedDebitWindow,
  dueDateFallback,
  expectedDocumentPeriod,
  unplaced,
  finitePlanForecast,
  projectedCycle,
  documentaryDeadline,
  documentaryChoiceRequired,
}

class FutureOutflowPresentation {
  final String identity;
  final FutureOutflowAuthority authority;
  final String title;
  final String details;
  final double amount;
  final DateTime? placementStart;
  final DateTime? placementEnd;
  final ExpectedDocumentPeriod? placementPeriod;
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
  final String? obligationId;
  final String? documentaryInstallmentId;
  final String? relationshipId;
  final int? cycleSequence;

  const FutureOutflowPresentation({
    required this.identity,
    required this.authority,
    required this.title,
    required this.details,
    required this.amount,
    required this.placementStart,
    required this.placementEnd,
    this.placementPeriod,
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
    this.obligationId,
    this.documentaryInstallmentId,
    this.relationshipId,
    this.cycleSequence,
  });

  bool get isInteractive => expectedExpense != null;
}

class FutureOutflowMonthGroup {
  final ExpectedDocumentPeriod period;
  final UnmodifiableListView<FutureOutflowPresentation> items;

  FutureOutflowMonthGroup({
    required DateTime month,
    required Iterable<FutureOutflowPresentation> items,
  }) : period = ExpectedDocumentPeriod(year: month.year, month: month.month),
       items = UnmodifiableListView(List.of(items));

  FutureOutflowMonthGroup.fromPeriod({
    required this.period,
    required Iterable<FutureOutflowPresentation> items,
  }) : items = UnmodifiableListView(List.of(items));

  DateTime get month => DateTime(period.year, period.month);
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
