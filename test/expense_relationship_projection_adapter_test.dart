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
