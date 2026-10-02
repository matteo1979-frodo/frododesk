import '../../models/income.dart';
import '../../models/income_forecast_presentation.dart';
import '../../models/projected_expense_cycle.dart';

class IncomeForecastReader {
  const IncomeForecastReader();

  IncomeForecastOverview read({
    required IncomeAggregate aggregate,
    required ExpenseProjectionHorizon horizon,
  }) {
    final relationshipById = {
      for (final relationship in aggregate.relationships)
        relationship.relationshipId: relationship,
    };
    final result = <IncomeForecastPresentation>[];
    final materialized = <String>{};
    for (final occurrence in aggregate.occurrences) {
      if (occurrence.cycleSequence != null) {
        materialized.add(
          '${occurrence.relationshipId}#${occurrence.cycleSequence}',
        );
      }
      if (occurrence.status != ExpectedIncomeStatus.pending &&
          occurrence.status != ExpectedIncomeStatus.partiallyReconciled) {
        continue;
      }
      if (!horizon.contains(occurrence.expectedDate)) continue;
      final relationship = relationshipById[occurrence.relationshipId];
      if (relationship == null) {
        throw StateError('Missing income relationship');
      }
      final reconciled = _reconciledAmount(aggregate, occurrence);
      final remaining = occurrence.expectedAmount - reconciled;
      if (remaining <= 0.005) continue;
      result.add(
        IncomeForecastPresentation(
          identity: occurrence.structuralIdentity,
          relationshipId: occurrence.relationshipId,
          occurrenceId: occurrence.occurrenceId,
          cycleSequence: occurrence.cycleSequence,
          label: relationship.label,
          amount: remaining,
          economicDate: occurrence.expectedDate,
          subject: relationship.subject,
          destinationBalanceId: relationship.destinationBalanceId,
          provenance: occurrence.provenance,
          knowledge: occurrence.knowledge,
          evidenceEconomicFactIds: occurrence.evidenceEconomicFactIds,
          projected: false,
        ),
      );
    }

    for (final relationship in aggregate.relationships.where(
      (item) => item.active,
    )) {
      if (relationship.periodicity == IncomePeriodicity.oneTime) continue;
      var sequence = 1;
      var date = relationship.firstExpectedDate;
      while (date.isBefore(horizon.start)) {
        sequence++;
        date = _next(date, relationship);
      }
      while (!date.isAfter(horizon.end)) {
        final lineage = '${relationship.relationshipId}#$sequence';
        if (!materialized.contains(lineage)) {
          final historyEvidence = _previousYearEvidence(
            aggregate,
            relationship,
            date,
          );
          final useHistory =
              relationship.historyBasedForecastEnabled &&
              historyEvidence.total > 0;
          result.add(
            IncomeForecastPresentation(
              identity: 'income-cycle:$lineage',
              relationshipId: relationship.relationshipId,
              occurrenceId: null,
              cycleSequence: sequence,
              label: relationship.label,
              amount: useHistory
                  ? historyEvidence.total
                  : relationship.expectedOrdinaryAmount,
              economicDate: date,
              subject: relationship.subject,
              destinationBalanceId: relationship.destinationBalanceId,
              provenance: useHistory
                  ? IncomeProvenance.previousYearPeriod
                  : IncomeProvenance.recurringRelationship,
              knowledge: useHistory
                  ? IncomeKnowledge.estimated
                  : IncomeKnowledge.predicted,
              evidenceEconomicFactIds: historyEvidence.factIds,
              projected: true,
            ),
          );
        }
        sequence++;
        date = _next(date, relationship);
      }
    }
    result.sort((left, right) {
      final date = left.economicDate.compareTo(right.economicDate);
      return date != 0 ? date : left.identity.compareTo(right.identity);
    });
    return IncomeForecastOverview(result);
  }

  double _reconciledAmount(
    IncomeAggregate aggregate,
    ExpectedIncomeOccurrence occurrence,
  ) => aggregate.reconciliations
      .where(
        (item) => occurrence.reconciliationIds.contains(item.reconciliationId),
      )
      .expand((item) => item.allocations)
      .where((item) => item.occurrenceId == occurrence.occurrenceId)
      .fold(0, (sum, item) => sum + item.amount);

  _HistoryEvidence _previousYearEvidence(
    IncomeAggregate aggregate,
    IncomeRelationship relationship,
    DateTime target,
  ) {
    final facts = <String>[];
    var total = 0.0;
    for (final reconciliation in aggregate.reconciliations) {
      if (reconciliation.relationshipId != relationship.relationshipId ||
          reconciliation.occurredAt.year != target.year - 1 ||
          reconciliation.occurredAt.month != target.month) {
        continue;
      }
      final ordinary = reconciliation.allocations
          .where((item) => item.contributesToOrdinaryBaseline)
          .fold<double>(0, (sum, item) => sum + item.amount);
      if (ordinary > 0) {
        total += ordinary;
        facts.add(reconciliation.economicFactId);
      }
    }
    return _HistoryEvidence(total, List.unmodifiable(facts));
  }

  DateTime _next(DateTime source, IncomeRelationship relationship) {
    final months = switch (relationship.periodicity) {
      IncomePeriodicity.monthly => 1,
      IncomePeriodicity.yearly => 12,
      IncomePeriodicity.customMonths => relationship.customIntervalMonths!,
      IncomePeriodicity.oneTime => throw StateError(
        'One-time is not projected',
      ),
    };
    final first = DateTime(source.year, source.month + months);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    return DateTime(first.year, first.month, source.day.clamp(1, lastDay));
  }
}

class _HistoryEvidence {
  final double total;
  final List<String> factIds;
  const _HistoryEvidence(this.total, this.factIds);
}
