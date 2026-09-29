import '../../models/expense_relationship.dart';
import '../../models/documentary_obligation.dart';
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
    Iterable<FutureOutflowPresentation> documentaryInstallments = const [],
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
      documentaryInstallments: documentaryInstallments,
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
    Iterable<FutureOutflowPresentation> documentaryInstallments = const [],
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'must not be before start');
    }
    final materialized = expectedExpenses.toList();
    return _compose(
      expectedExpenses: materialized.where((item) {
        final date = item.displayStart;
        return date != null
            ? _isInRange(date, start, end)
            : item.displayPeriod != null &&
                _periodInRange(item.displayPeriod!, start, end);
      }),
      projectedCycles: projectedCycles.where(
        (item) => item.cycleAnchor != null
            ? _isInRange(item.cycleAnchor!, start, end)
            : _periodInRange(item.expectedPeriod!, start, end),
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
      documentaryInstallments: documentaryInstallments.where((item) {
        final date = item.placementStart;
        return date != null && _isInRange(date, start, end);
      }),
      referenceTime: referenceTime,
    );
  }

  FutureOutflowOverview _compose({
    required Iterable<FutureExpenseProjection> expectedExpenses,
    required Iterable<ProjectedExpenseCycle> projectedCycles,
    required Set<String> materializedCycleIds,
    required Iterable<FutureOutflowPresentation> finitePlanItems,
    required Iterable<FutureOutflowPresentation> documentaryInstallments,
    required DateTime referenceTime,
  }) {
    final documentaryItems = documentaryInstallments.toList();
    final documentaryCycleIds = documentaryItems
        .where((item) => item.relationshipId != null && item.cycleSequence != null)
        .map((item) => '${item.relationshipId}#${item.cycleSequence}')
        .toSet();
    final items = <FutureOutflowPresentation>[
      ...expectedExpenses
          .where((item) {
            final sequence = item.source.cycleSequence;
            return sequence == null ||
                !documentaryCycleIds.contains(
                  '${item.relationshipId}#$sequence',
                );
          })
          .map(_fromExpectedExpense),
      ...projectedCycles
          .where(
            (item) =>
                !materializedCycleIds.contains(item.identity.value) &&
                !documentaryCycleIds.contains(item.identity.value),
          )
          .map(_fromProjectedCycle),
      ...finitePlanItems,
      ...documentaryItems,
    ];
    items.sort(_compare);

    final referenceMonth = _month(referenceTime);
    final current = <FutureOutflowPresentation>[];
    final past = <FutureOutflowPresentation>[];
    final unplaced = <FutureOutflowPresentation>[];
    final future = <int, List<FutureOutflowPresentation>>{};
    for (final item in items) {
      final date = item.placementStart;
      final period = item.placementPeriod;
      if (date == null && period == null) {
        unplaced.add(item);
        continue;
      }
      final monthIndex = date != null
          ? date.year * 12 + date.month - 1
          : period!.year * 12 + period.month - 1;
      final referenceIndex =
          referenceMonth.year * 12 + referenceMonth.month - 1;
      if (monthIndex == referenceIndex) {
        current.add(item);
      } else if (monthIndex < referenceIndex) {
        past.add(item);
      } else {
        future.putIfAbsent(monthIndex, () => []).add(item);
      }
    }
    final months = future.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return FutureOutflowOverview(
      currentMonth: current,
      pastMonths: past,
      futureMonths: months.map(
        (entry) => FutureOutflowMonthGroup.fromPeriod(
          period: ExpectedDocumentPeriod(
            year: entry.key ~/ 12,
            month: entry.key % 12 + 1,
          ),
          items: entry.value,
        ),
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

  bool _periodInRange(
    ExpectedDocumentPeriod period,
    DateTime start,
    DateTime end,
  ) {
    final value = period.year * 12 + period.month - 1;
    final first = start.year * 12 + start.month - 1;
    final last = end.year * 12 + end.month - 1;
    return value >= first && value <= last;
  }

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
    placementPeriod: expense.displayPeriod,
    datePresentation: switch (expense.displayPlacement) {
      FutureExpenseDisplayPlacement.plannedEconomicImpact =>
        FutureOutflowDatePresentation.plannedEconomicImpact,
      FutureExpenseDisplayPlacement.expectedDebitWindow =>
        FutureOutflowDatePresentation.expectedDebitWindow,
      FutureExpenseDisplayPlacement.dueDateFallback =>
        FutureOutflowDatePresentation.dueDateFallback,
      FutureExpenseDisplayPlacement.expectedDocumentPeriod =>
        FutureOutflowDatePresentation.expectedDocumentPeriod,
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
        placementPeriod: cycle.expectedPeriod,
        datePresentation: cycle.expectedPeriod == null
            ? FutureOutflowDatePresentation.projectedCycle
            : FutureOutflowDatePresentation.expectedDocumentPeriod,
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
    final leftPeriod = leftDate == null ? left.placementPeriod : null;
    final rightPeriod = rightDate == null ? right.placementPeriod : null;
    if (leftDate == null && leftPeriod == null &&
        (rightDate != null || rightPeriod != null)) {
      return 1;
    }
    if (rightDate == null && rightPeriod == null &&
        (leftDate != null || leftPeriod != null)) {
      return -1;
    }
    final leftIndex = leftDate != null
        ? leftDate.year * 12 + leftDate.month - 1
        : leftPeriod == null
        ? null
        : leftPeriod.year * 12 + leftPeriod.month - 1;
    final rightIndex = rightDate != null
        ? rightDate.year * 12 + rightDate.month - 1
        : rightPeriod == null
        ? null
        : rightPeriod.year * 12 + rightPeriod.month - 1;
    final dateComparison = leftIndex == null
        ? 0
        : leftIndex.compareTo(rightIndex!);
    return dateComparison != 0
        ? dateComparison
        : left.identity.compareTo(right.identity);
  }

  DateTime _month(DateTime value) => DateTime(value.year, value.month);
}
