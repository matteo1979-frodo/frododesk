import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expense_relationship_projection_adapter.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/projected_expense_cycle.dart';

void main() {
  const adapter = ExpenseRelationshipProjectionAdapter();

  test(
    'bimonthly projection is multicyle, horizon-bound and preserves mode',
    () {
      final aggregate = _aggregate(
        relationship: _relationship(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.custom,
            customInterval: 2,
            customIntervalUnit: 'months',
          ),
          mode: PaymentExecutionMode.requiresUserAction,
        ),
        occurrence: _occurrence(anchor: DateTime(2026, 11, 15)),
      );

      final projected = adapter.project(
        aggregate: aggregate,
        horizon: ExpenseProjectionHorizon(
          start: DateTime(2026, 11),
          end: DateTime(2027, 5, 31),
        ),
      );

      expect(projected.map((item) => item.identity.cycleSequence), [2, 3, 4]);
      expect(projected.map((item) => item.cycleAnchor), [
        DateTime(2027, 1, 15),
        DateTime(2027, 3, 15),
        DateTime(2027, 5, 15),
      ]);
      expect(
        projected.every(
          (item) =>
              item.paymentExecutionMode ==
              PaymentExecutionMode.requiresUserAction,
        ),
        isTrue,
      );
    },
  );

  test('month-end clamping returns to canonical day after February', () {
    final projected = adapter.project(
      aggregate: _aggregate(
        relationship: _relationship(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.monthly,
          ),
        ),
        occurrence: _occurrence(anchor: DateTime(2027, 1, 31)),
      ),
      horizon: ExpenseProjectionHorizon(
        start: DateTime(2027, 2),
        end: DateTime(2027, 3, 31),
      ),
    );

    expect(projected.map((item) => item.cycleAnchor), [
      DateTime(2027, 2, 28),
      DateTime(2027, 3, 31),
    ]);
  });

  test('annual and custom-day periods use explicit canonical cadence', () {
    final annual = adapter.project(
      aggregate: _aggregate(
        relationship: _relationship(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.yearly,
          ),
        ),
        occurrence: _occurrence(anchor: DateTime(2026, 2, 28)),
      ),
      horizon: ExpenseProjectionHorizon(
        start: DateTime(2027),
        end: DateTime(2028, 12, 31),
      ),
    );
    final days = adapter.project(
      aggregate: _aggregate(
        relationship: _relationship(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.custom,
            customInterval: 10,
            customIntervalUnit: 'days',
          ),
        ),
        occurrence: _occurrence(anchor: DateTime(2026, 11, 1)),
      ),
      horizon: ExpenseProjectionHorizon(
        start: DateTime(2026, 11, 2),
        end: DateTime(2026, 11, 22),
      ),
    );

    expect(annual.map((item) => item.cycleAnchor), [
      DateTime(2027, 2, 28),
      DateTime(2028, 2, 28),
    ]);
    expect(days.map((item) => item.cycleAnchor), [
      DateTime(2026, 11, 11),
      DateTime(2026, 11, 21),
    ]);
  });

  test('materialized cycle replaces projection by structural identity', () {
    final relationship = _relationship(
      periodicity: ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.monthly,
      ),
    );
    final aggregate = ExpectedExpenseAggregate(
      relationships: [relationship],
      occurrences: [
        _occurrence(anchor: DateTime(2026, 11, 15)),
        _occurrence(
          id: 'occurrence_2',
          sequence: 2,
          anchor: DateTime(2026, 12, 15),
        ),
      ],
    );

    final projected = adapter.project(
      aggregate: aggregate,
      horizon: ExpenseProjectionHorizon(
        start: DateTime(2026, 11),
        end: DateTime(2027, 1, 31),
      ),
    );

    expect(projected.map((item) => item.identity.value), ['relationship#3']);
  });

  test(
    'pending unidentified legacy occurrence blocks projections conservatively',
    () {
      final projected = adapter.project(
        aggregate: _aggregate(
          relationship: _relationship(
            periodicity: ExpenseRelationshipPeriodicity(
              type: FinanceRecurringType.monthly,
            ),
          ),
          occurrence: _occurrence(anchor: null, sequence: null),
        ),
        horizon: ExpenseProjectionHorizon(
          start: DateTime(2026, 11),
          end: DateTime(2027, 11),
        ),
      );

      expect(projected, isEmpty);
    },
  );

  test(
    'terminated relationship preserves occurrences but projects no cycles',
    () {
      final relationship = _relationship(
        status: ExpenseRelationshipStatus.terminated,
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.monthly,
        ),
      );
      final occurrence = _occurrence(anchor: DateTime(2026, 11, 15));
      final aggregate = _aggregate(
        relationship: relationship,
        occurrence: occurrence,
      );

      expect(
        adapter.project(
          aggregate: aggregate,
          horizon: ExpenseProjectionHorizon(
            start: DateTime(2026, 11),
            end: DateTime(2027, 11),
          ),
        ),
        isEmpty,
      );
      expect(aggregate.occurrences.single, same(occurrence));
    },
  );

  test('same dates and amounts across relationships never deduplicate', () {
    final first = _relationship(
      id: 'first',
      periodicity: ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.monthly,
      ),
    );
    final second = _relationship(
      id: 'second',
      periodicity: ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.monthly,
      ),
    );
    final aggregate = ExpectedExpenseAggregate(
      relationships: [first, second],
      occurrences: [
        _occurrence(id: 'first_1', relationshipId: 'first'),
        _occurrence(id: 'second_1', relationshipId: 'second'),
      ],
    );

    final projected = adapter.project(
      aggregate: aggregate,
      horizon: ExpenseProjectionHorizon(
        start: DateTime(2026, 12),
        end: DateTime(2026, 12, 31),
      ),
    );

    expect(projected.map((item) => item.identity.value).toSet(), {
      'first#2',
      'second#2',
    });
  });

  test('far horizons preserve linear-baseline output for every cadence', () {
    final cases = <({
      ExpenseRelationshipPeriodicity periodicity,
      DateTime anchor,
      int baseSequence,
    })>[
      (
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.monthly,
        ),
        anchor: DateTime(2026, 1, 31),
        baseSequence: 1,
      ),
      (
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.yearly,
        ),
        anchor: DateTime(2028, 2, 29),
        baseSequence: 7,
      ),
      (
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 2,
          customIntervalUnit: 'months',
        ),
        anchor: DateTime(2026, 1, 31),
        baseSequence: 4,
      ),
      (
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 3,
          customIntervalUnit: 'years',
        ),
        anchor: DateTime(2026, 6, 15),
        baseSequence: 3,
      ),
      (
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 1,
          customIntervalUnit: 'days',
        ),
        anchor: DateTime(2026, 1, 1),
        baseSequence: 11,
      ),
      (
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 7,
          customIntervalUnit: 'days',
        ),
        anchor: DateTime(2026, 1, 1),
        baseSequence: 20,
      ),
    ];

    for (final entry in cases) {
      final relationship = _relationship(periodicity: entry.periodicity);
      final aggregate = _aggregate(
        relationship: relationship,
        occurrence: _occurrence(
          sequence: entry.baseSequence,
          anchor: entry.anchor,
        ),
      );
      final horizon = ExpenseProjectionHorizon(
        start: DateTime(2056),
        end: DateTime(2056, 12, 31, 23, 59, 59),
      );

      expect(
        _projectionSignature(adapter.project(
          aggregate: aggregate,
          horizon: horizon,
        )),
        _projectionSignature(
          _linearProjectionBaseline(aggregate: aggregate, horizon: horizon),
        ),
        reason: '${entry.periodicity.type} ${entry.periodicity.customInterval} '
            '${entry.periodicity.customIntervalUnit}',
      );
    }
  });

  test('seek preserves inclusive horizon boundaries and non-unit base sequence', () {
    final relationship = _relationship(
      periodicity: ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.monthly,
      ),
    );
    final aggregate = _aggregate(
      relationship: relationship,
      occurrence: _occurrence(
        sequence: 8,
        anchor: DateTime(2027, 1, 31),
      ),
    );

    final exactStart = adapter.project(
      aggregate: aggregate,
      horizon: ExpenseProjectionHorizon(
        start: DateTime(2027, 3, 31),
        end: DateTime(2027, 4, 30),
      ),
    );
    expect(exactStart.map((item) => item.identity.cycleSequence), [10, 11]);
    expect(exactStart.map((item) => item.cycleAnchor), [
      DateTime(2027, 3, 31),
      DateTime(2027, 4, 30),
    ]);

    final immediatelyAfter = adapter.project(
      aggregate: aggregate,
      horizon: ExpenseProjectionHorizon(
        start: DateTime(2027, 3, 31, 0, 0, 0, 1),
        end: DateTime(2027, 4, 30),
      ),
    );
    expect(immediatelyAfter.map((item) => item.identity.cycleSequence), [11]);
    expect(immediatelyAfter.single.cycleAnchor, DateTime(2027, 4, 30));
  });

  test('horizon before base and ranges without cycles preserve prior behavior', () {
    final aggregate = _aggregate(
      relationship: _relationship(
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.monthly,
        ),
      ),
      occurrence: _occurrence(anchor: DateTime(2027, 6, 15)),
    );

    expect(
      adapter.project(
        aggregate: aggregate,
        horizon: ExpenseProjectionHorizon(
          start: DateTime(2026),
          end: DateTime(2026, 12, 31),
        ),
      ),
      isEmpty,
    );
    expect(
      adapter.project(
        aggregate: aggregate,
        horizon: ExpenseProjectionHorizon(
          start: DateTime(2027, 6, 16),
          end: DateTime(2027, 7, 14),
        ),
      ),
      isEmpty,
    );
  });

  test('annual leap-day anchors and materialized suppression survive seek', () {
    final relationship = _relationship(
      periodicity: ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.yearly,
      ),
    );
    final aggregate = ExpectedExpenseAggregate(
      relationships: [relationship],
      occurrences: [
        _occurrence(sequence: 5, anchor: DateTime(2028, 2, 29)),
        _occurrence(
          id: 'occurrence_33',
          sequence: 33,
          anchor: DateTime(2056, 2, 29),
        ),
      ],
    );
    final horizon = ExpenseProjectionHorizon(
      start: DateTime(2055),
      end: DateTime(2057, 12, 31),
    );

    final projected = adapter.project(aggregate: aggregate, horizon: horizon);

    expect(projected.map((item) => item.identity.cycleSequence), [32, 34]);
    expect(projected.map((item) => item.cycleAnchor), [
      DateTime(2055, 2, 28),
      DateTime(2057, 2, 28),
    ]);
    expect(
      _projectionSignature(projected),
      _projectionSignature(
        _linearProjectionBaseline(aggregate: aggregate, horizon: horizon),
      ),
    );
  });
}

List<String> _projectionSignature(Iterable<ProjectedExpenseCycle> items) => [
  for (final item in items)
    '${item.identity.value}|${item.cycleAnchor.toIso8601String()}|'
        '${item.sourceOccurrenceId}|${item.service}|${item.provider}|'
        '${item.expectedAmount}|${item.provisional}',
];

List<ProjectedExpenseCycle> _linearProjectionBaseline({
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
    final identified = occurrences
        .where(
          (item) => item.cycleSequence != null && item.cycleAnchor != null,
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
    var sequence = base.cycleSequence!;
    while (true) {
      final anchor = _baselineAnchorFor(
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
  return result;
}

DateTime _baselineAnchorFor(
  DateTime base,
  ExpenseRelationshipPeriodicity periodicity,
  int cycleOffset,
) {
  if (cycleOffset == 0) return base;
  return switch (periodicity.type) {
    FinanceRecurringType.monthly => _baselineAddMonths(base, cycleOffset),
    FinanceRecurringType.yearly => _baselineAddMonths(base, cycleOffset * 12),
    FinanceRecurringType.custom
        when periodicity.customIntervalUnit == 'months' =>
      _baselineAddMonths(base, cycleOffset * periodicity.customInterval!),
    FinanceRecurringType.custom
        when periodicity.customIntervalUnit == 'years' =>
      _baselineAddMonths(base, cycleOffset * periodicity.customInterval! * 12),
    FinanceRecurringType.custom
        when periodicity.customIntervalUnit == 'days' =>
      base.add(Duration(days: cycleOffset * periodicity.customInterval!)),
    FinanceRecurringType.custom => throw UnsupportedError(
      'Unsupported custom periodicity unit: '
      '${periodicity.customIntervalUnit}',
    ),
    FinanceRecurringType.oneShot =>
      throw StateError('One-shot relationships cannot be projected'),
  };
}

DateTime _baselineAddMonths(DateTime source, int months) {
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

ExpectedExpenseAggregate _aggregate({
  required ExpenseRelationship relationship,
  required ExpectedExpenseOccurrence occurrence,
}) => ExpectedExpenseAggregate(
  relationships: [relationship],
  occurrences: [occurrence],
);

ExpenseRelationship _relationship({
  String id = 'relationship',
  ExpenseRelationshipStatus status = ExpenseRelationshipStatus.active,
  required ExpenseRelationshipPeriodicity periodicity,
  PaymentExecutionMode mode = PaymentExecutionMode.automatic,
}) => ExpenseRelationship(
  relationshipId: id,
  service: 'Energia',
  provider: 'Provider',
  subject: FinanceSubject.matteo,
  status: status,
  periodicity: periodicity,
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance',
  ),
  paymentExecutionMode: mode,
);

ExpectedExpenseOccurrence _occurrence({
  String id = 'occurrence_1',
  String relationshipId = 'relationship',
  int? sequence = 1,
  DateTime? anchor,
}) => ExpectedExpenseOccurrence(
  occurrenceId: id,
  relationshipId: relationshipId,
  cycleSequence: sequence,
  cycleAnchor: sequence == null ? null : anchor ?? DateTime(2026, 11, 15),
  status: ExpectedExpenseOccurrenceStatus.pending,
  expectedDueDate: DateTime(2026, 11, 20),
  expectedDueDateSource: ExpectedExpenseDateSource.explicit,
  expectedAmount: 75,
  estimationMethod: ExpenseEstimationMethod.manualEstimate,
  confidence: ExpenseEstimateConfidence.medium,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance',
  ),
  expectedSubject: FinanceSubject.matteo,
);
