import '../../models/expense_relationship.dart';
import '../../models/finite_financial_plan.dart';
import '../../models/future_expense_projection.dart';
import '../../models/future_outflow_presentation.dart';
import '../../models/projected_expense_cycle.dart';
import 'finite_financial_plan_forecast_adapter.dart';

class FutureOutflowPresentationComposer {
  final FiniteFinancialPlanForecastAdapter finitePlanAdapter;

  const FutureOutflowPresentationComposer({
    this.finitePlanAdapter = const FiniteFinancialPlanForecastAdapter(),
  });

  FutureOutflowOverview compose({
    required Iterable<FutureExpenseProjection> expectedExpenses,
    Iterable<ProjectedExpenseCycle> projectedCycles = const [],
    required Iterable<FiniteFinancialPlan> finitePlans,
    required DateTime referenceTime,
  }) {
    final materialized = expectedExpenses.toList();
    return _compose(
      expectedExpenses: materialized,
      projectedCycles: projectedCycles,
      materializedCycleIds: _materializedCycleIds(materialized),
      finitePlanItems: [
        for (final plan in finitePlans)
          for (final item in finitePlanAdapter.remainingItems(plan))
            _fromFinitePlan(plan, item),
      ],
      referenceTime: referenceTime,
    );
  }

  FutureOutflowOverview composeInRange({
    required Iterable<FutureExpenseProjection> expectedExpenses,
    Iterable<ProjectedExpenseCycle> projectedCycles = const [],
    required Iterable<FiniteFinancialPlan> finitePlans,
    required DateTime start,
    required DateTime end,
    required DateTime referenceTime,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'must not be before start');
    }
    final materialized = expectedExpenses.toList();
    return _compose(
      expectedExpenses: materialized.where((item) {
        final date = item.displayStart;
        return date != null && _isInRange(date, start, end);
      }),
      projectedCycles: projectedCycles.where(
        (item) => _isInRange(item.cycleAnchor, start, end),
      ),
      materializedCycleIds: _materializedCycleIds(materialized),
      finitePlanItems: [
        for (final plan in finitePlans)
          for (final item in finitePlanAdapter.itemsInRange(
            plan: plan,
            start: start,
            end: end,
          ))
            _fromFinitePlan(plan, item),
      ],
      referenceTime: referenceTime,
    );
  }

  FutureOutflowOverview _compose({
    required Iterable<FutureExpenseProjection> expectedExpenses,
    required Iterable<ProjectedExpenseCycle> projectedCycles,
    required Set<String> materializedCycleIds,
    required Iterable<FutureOutflowPresentation> finitePlanItems,
    required DateTime referenceTime,
  }) {
    final items = <FutureOutflowPresentation>[
      ...expectedExpenses.map(_fromExpectedExpense),
      ...projectedCycles
          .where((item) => !materializedCycleIds.contains(item.identity.value))
          .map(_fromProjectedCycle),
      ...finitePlanItems,
    ];
    items.sort(_compare);

    final referenceMonth = _month(referenceTime);
    final current = <FutureOutflowPresentation>[];
    final past = <FutureOutflowPresentation>[];
    final unplaced = <FutureOutflowPresentation>[];
    final future = <DateTime, List<FutureOutflowPresentation>>{};
    for (final item in items) {
      final date = item.placementStart;
      if (date == null) {
        unplaced.add(item);
        continue;
      }
      final month = _month(date);
      if (month == referenceMonth) {
        current.add(item);
      } else if (month.isBefore(referenceMonth)) {
        past.add(item);
      } else {
        future.putIfAbsent(month, () => []).add(item);
      }
    }
    final months = future.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return FutureOutflowOverview(
      currentMonth: current,
      pastMonths: past,
      futureMonths: months.map(
        (entry) =>
            FutureOutflowMonthGroup(month: entry.key, items: entry.value),
      ),
      unplaced: unplaced,
    );
  }

  Set<String> _materializedCycleIds(
    Iterable<FutureExpenseProjection> expectedExpenses,
  ) => expectedExpenses
      .where((item) => item.source.cycleSequence != null)
      .map((item) => '${item.relationshipId}#${item.source.cycleSequence}')
      .toSet();

  bool _isInRange(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(start) && !value.isAfter(end);

  FutureOutflowPresentation _fromFinitePlan(
    FiniteFinancialPlan plan,
    FiniteFinancialPlanForecastItem item,
  ) => FutureOutflowPresentation(
    identity: item.identity,
    authority: FutureOutflowAuthority.finiteFinancialPlan,
    title: item.name,
    details: 'Rata ${item.installmentNumber} di ${plan.totalInstallments}',
    amount: item.expectedAmount,
    placementStart: item.date,
    placementEnd: item.date,
    datePresentation: FutureOutflowDatePresentation.finitePlanForecast,
    requiresPlanning: false,
    provisional: false,
    requiresUserAction: false,
    overdue: false,
    planId: item.planId,
    installmentNumber: item.installmentNumber,
    totalInstallments: plan.totalInstallments,
  );

  FutureOutflowPresentation _fromExpectedExpense(
    FutureExpenseProjection expense,
  ) => FutureOutflowPresentation(
    identity: expense.occurrenceId,
    authority: FutureOutflowAuthority.expectedExpense,
    title: '${expense.source.service} · ${expense.source.provider}',
    details: '',
    amount: expense.source.expectedAmount,
    placementStart: expense.displayStart,
    placementEnd: expense.displayEnd,
    datePresentation: switch (expense.displayPlacement) {
      FutureExpenseDisplayPlacement.plannedEconomicImpact =>
        FutureOutflowDatePresentation.plannedEconomicImpact,
      FutureExpenseDisplayPlacement.expectedDebitWindow =>
        FutureOutflowDatePresentation.expectedDebitWindow,
      FutureExpenseDisplayPlacement.dueDateFallback =>
        FutureOutflowDatePresentation.dueDateFallback,
      FutureExpenseDisplayPlacement.unplaced =>
        FutureOutflowDatePresentation.unplaced,
    },
    requiresPlanning: expense.requiresPlanning,
    provisional: expense.source.provisional,
    requiresUserAction:
        expense.source.occurrencePaymentExecutionMode ==
        PaymentExecutionMode.requiresUserAction,
    overdue:
        expense.overdueQualification !=
        FutureExpenseOverdueQualification.notOverdue,
    expectedExpense: expense,
  );

  FutureOutflowPresentation _fromProjectedCycle(ProjectedExpenseCycle cycle) =>
      FutureOutflowPresentation(
        identity: cycle.identity.value,
        authority: FutureOutflowAuthority.projectedExpenseRelationship,
        title: '${cycle.service} · ${cycle.provider}',
        details: 'Ciclo previsto',
        amount: cycle.expectedAmount,
        placementStart: cycle.cycleAnchor,
        placementEnd: cycle.cycleAnchor,
        datePresentation: FutureOutflowDatePresentation.projectedCycle,
        requiresPlanning: false,
        provisional: cycle.provisional,
        requiresUserAction:
            cycle.paymentExecutionMode ==
            PaymentExecutionMode.requiresUserAction,
        overdue: false,
        projectedExpenseCycle: cycle,
      );

  int _compare(
    FutureOutflowPresentation left,
    FutureOutflowPresentation right,
  ) {
    final leftDate = left.placementStart;
    final rightDate = right.placementStart;
    if (leftDate == null && rightDate != null) return 1;
    if (leftDate != null && rightDate == null) return -1;
    final dateComparison = leftDate == null
        ? 0
        : leftDate.compareTo(rightDate!);
    return dateComparison != 0
        ? dateComparison
        : left.identity.compareTo(right.identity);
  }

  DateTime _month(DateTime value) => DateTime(value.year, value.month);
}
