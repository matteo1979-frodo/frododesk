import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/projected_expense_cycle.dart';
import 'expected_expense_persistence.dart';

/// Pure multicyle projection. It never persists or materializes occurrences.
class ExpenseRelationshipProjectionAdapter {
  const ExpenseRelationshipProjectionAdapter();

  List<ProjectedExpenseCycle> project({
    required ExpectedExpenseAggregate aggregate,
    required ExpenseProjectionHorizon horizon,
  }) {
    final result = <ProjectedExpenseCycle>[];
    for (final relationship in aggregate.relationships) {
      if (relationship.status != ExpenseRelationshipStatus.active) continue;
      final occurrences = aggregate.occurrences
          .where((item) => item.relationshipId == relationship.relationshipId)
          .toList();
      if (occurrences.any(
        (item) =>
            item.status == ExpectedExpenseOccurrenceStatus.pending &&
            item.cycleSequence == null,
      )) {
        continue;
      }
      final identified =
          occurrences
              .where(
                (item) =>
                    item.cycleSequence != null && item.cycleAnchor != null,
              )
              .toList()
            ..sort(
              (left, right) =>
                  left.cycleSequence!.compareTo(right.cycleSequence!),
            );
      if (identified.isEmpty) continue;

      final base = identified.first;
      final source = identified.last;
      final materializedSequences = identified
          .map((item) => item.cycleSequence!)
          .toSet();
      final firstOffset = _firstOffsetOnOrAfter(
        base.cycleAnchor!,
        relationship.periodicity,
        horizon.start,
      );
      var sequence = base.cycleSequence! + firstOffset;
      while (true) {
        final anchor = _anchorFor(
          base.cycleAnchor!,
          relationship.periodicity,
          sequence - base.cycleSequence!,
        );
        if (anchor.isAfter(horizon.end)) break;
        if (horizon.contains(anchor) &&
            !materializedSequences.contains(sequence)) {
          result.add(
            ProjectedExpenseCycle(
              identity: ExpenseCycleIdentity(
                relationshipId: relationship.relationshipId,
                cycleSequence: sequence,
              ),
              cycleAnchor: anchor,
              sourceOccurrenceId: source.occurrenceId,
              service: relationship.service,
              provider: relationship.provider,
              expectedAmount: source.expectedAmount,
              expectedSubject: relationship.subject,
              expectedPaymentConfiguration: relationship.paymentConfiguration,
              paymentExecutionMode: relationship.paymentExecutionMode,
              provisional: true,
            ),
          );
        }
        sequence++;
      }
    }
    result.sort((left, right) {
      final date = left.cycleAnchor.compareTo(right.cycleAnchor);
      return date != 0
          ? date
          : left.identity.value.compareTo(right.identity.value);
    });
    return List.unmodifiable(result);
  }

  int _firstOffsetOnOrAfter(
    DateTime base,
    ExpenseRelationshipPeriodicity periodicity,
    DateTime start,
  ) {
    if (!_anchorFor(base, periodicity, 0).isBefore(start)) return 0;

    var lower = 0;
    var upper = 1;
    while (_anchorFor(base, periodicity, upper).isBefore(start)) {
      lower = upper;
      upper *= 2;
    }

    while (lower + 1 < upper) {
      final middle = lower + ((upper - lower) ~/ 2);
      if (_anchorFor(base, periodicity, middle).isBefore(start)) {
        lower = middle;
      } else {
        upper = middle;
      }
    }
    return upper;
  }

  DateTime _anchorFor(
    DateTime base,
    ExpenseRelationshipPeriodicity periodicity,
    int cycleOffset,
  ) {
    if (cycleOffset == 0) return base;
    return switch (periodicity.type) {
      FinanceRecurringType.monthly => _addMonths(base, cycleOffset),
      FinanceRecurringType.yearly => _addMonths(base, cycleOffset * 12),
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'months' =>
        _addMonths(base, cycleOffset * periodicity.customInterval!),
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'years' =>
        _addMonths(base, cycleOffset * periodicity.customInterval! * 12),
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'days' =>
        base.add(Duration(days: cycleOffset * periodicity.customInterval!)),
      FinanceRecurringType.custom => throw UnsupportedError(
        'Unsupported custom periodicity unit: '
        '${periodicity.customIntervalUnit}',
      ),
      FinanceRecurringType.oneShot => throw StateError(
        'One-shot relationships cannot be projected',
      ),
    };
  }

  DateTime _addMonths(DateTime source, int months) {
    final monthStart = source.isUtc
        ? DateTime.utc(source.year, source.month + months)
        : DateTime(source.year, source.month + months);
    final following = source.isUtc
        ? DateTime.utc(monthStart.year, monthStart.month + 1)
        : DateTime(monthStart.year, monthStart.month + 1);
    final lastDay = following.subtract(const Duration(days: 1)).day;
    final day = source.day <= lastDay ? source.day : lastDay;
    return source.isUtc
        ? DateTime.utc(monthStart.year, monthStart.month, day)
        : DateTime(monthStart.year, monthStart.month, day);
  }
}
