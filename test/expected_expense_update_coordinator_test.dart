import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/expected_expense_update_coordinator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/manual_payment_preference.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('relationship same-ID update is applied once', () async {
    final harness = _Harness();
    final candidate = _relationship(provider: 'Updated provider');

    final outcome = await harness.coordinator.updateRelationship(
      relationshipId: 'relationship_1',
      candidate: candidate,
    );

    expect(outcome, ExpectedExpenseUpdateOutcome.applied);
    expect(harness.writes, 1);
    expect(harness.writeSawOldState, isTrue);
    expect(harness.aggregate.relationships.single.provider, 'Updated provider');
  });

  test('identical relationship is unchanged without write or notify', () async {
    final harness = _Harness();

    final outcome = await harness.coordinator.updateRelationship(
      relationshipId: 'relationship_1',
      candidate: _relationship(),
    );

    expect(outcome, ExpectedExpenseUpdateOutcome.unchanged);
    expect(harness.writes, 0);
    expect(harness.notifications, 0);
  });

  test('relationship missing and identity mismatch are classified', () async {
    final harness = _Harness();

    expect(
      await harness.coordinator.updateRelationship(
        relationshipId: 'missing',
        candidate: _relationship(id: 'missing'),
      ),
      ExpectedExpenseUpdateOutcome.missingRelationship,
    );
    expect(
      await harness.coordinator.updateRelationship(
        relationshipId: 'relationship_1',
        candidate: _relationship(id: 'relationship_other'),
      ),
      ExpectedExpenseUpdateOutcome.identityMismatch,
    );
    expect(harness.writes, 0);
  });

  test('occurrence same-ID update preserves evidence', () async {
    final harness = _Harness();
    final candidate = _occurrence(expectedAmount: 75);

    final outcome = await harness.coordinator.updateOccurrence(
      occurrenceId: 'occurrence_1',
      candidate: candidate,
    );

    expect(outcome, ExpectedExpenseUpdateOutcome.applied);
    expect(harness.aggregate.occurrences.single.expectedAmount, 75);
    expect(harness.aggregate.occurrences.single.evidenceEconomicFactIds, [
      'economic_fact_1',
    ]);
  });

  test('identical occurrence is unchanged without write', () async {
    final harness = _Harness();

    final outcome = await harness.coordinator.updateOccurrence(
      occurrenceId: 'occurrence_1',
      candidate: _occurrence(),
    );

    expect(outcome, ExpectedExpenseUpdateOutcome.unchanged);
    expect(harness.writes, 0);
  });

  test('occurrence missing and identity mismatches are classified', () async {
    final harness = _Harness();

    expect(
      await harness.coordinator.updateOccurrence(
        occurrenceId: 'missing',
        candidate: _occurrence(id: 'missing'),
      ),
      ExpectedExpenseUpdateOutcome.missingOccurrence,
    );
    expect(
      await harness.coordinator.updateOccurrence(
        occurrenceId: 'occurrence_1',
        candidate: _occurrence(id: 'occurrence_other'),
      ),
      ExpectedExpenseUpdateOutcome.identityMismatch,
    );
    expect(
      await harness.coordinator.updateOccurrence(
        occurrenceId: 'occurrence_1',
        candidate: _occurrence(relationshipId: 'relationship_other'),
      ),
      ExpectedExpenseUpdateOutcome.identityMismatch,
    );
    expect(harness.writes, 0);
  });

  test('combined update persists and publishes both changes once', () async {
    final harness = _Harness();
    final relationship = _relationship(
      preference: ManualPaymentPreference(preferredStartDayOfMonth: 5),
    );
    final occurrence = _occurrence(
      paymentWindow: _window(ExpectedPaymentWindowOrigin.relationshipDefault),
    );

    final outcome = await harness.coordinator.updateRelationshipAndOccurrence(
      relationshipId: 'relationship_1',
      relationshipCandidate: relationship,
      occurrenceId: 'occurrence_1',
      occurrenceCandidate: occurrence,
    );

    expect(outcome, ExpectedExpenseUpdateOutcome.applied);
    expect(harness.writes, 1);
    expect(harness.notifications, 1);
    expect(harness.aggregate.relationships, hasLength(1));
    expect(harness.aggregate.occurrences, hasLength(1));
    expect(
      harness.aggregate.relationships.single.relationshipId,
      'relationship_1',
    );
    expect(harness.aggregate.occurrences.single.occurrenceId, 'occurrence_1');
    expect(
      harness
          .aggregate
          .relationships
          .single
          .manualPaymentPreference
          ?.preferredStartDayOfMonth,
      5,
    );
    expect(
      harness.aggregate.occurrences.single.expectedPaymentWindow?.origin,
      ExpectedPaymentWindowOrigin.relationshipDefault,
    );
  });

  test('invalid combined identity leaves the aggregate unchanged', () async {
    final harness = _Harness();
    final initial = harness.aggregate;

    final outcome = await harness.coordinator.updateRelationshipAndOccurrence(
      relationshipId: 'relationship_1',
      relationshipCandidate: _relationship(),
      occurrenceId: 'occurrence_1',
      occurrenceCandidate: _occurrence(relationshipId: 'relationship_other'),
    );

    expect(outcome, ExpectedExpenseUpdateOutcome.identityMismatch);
    expect(harness.store.expectedExpenseAggregate, same(initial));
    expect(harness.writes, 0);
  });

  test(
    'persistence failure leaves prior aggregate and notifications unchanged',
    () async {
      final harness = _Harness(failWrites: true);
      final initial = harness.aggregate;

      await expectLater(
        harness.coordinator.updateRelationship(
          relationshipId: 'relationship_1',
          candidate: _relationship(provider: 'Updated provider'),
        ),
        throwsStateError,
      );

      expect(harness.store.expectedExpenseAggregate, same(initial));
      expect(harness.notifications, 0);
    },
  );

  test('combined persistence failure publishes neither candidate', () async {
    final harness = _Harness(failWrites: true);
    final initial = harness.aggregate;

    await expectLater(
      harness.coordinator.updateRelationshipAndOccurrence(
        relationshipId: 'relationship_1',
        relationshipCandidate: _relationship(provider: 'Updated provider'),
        occurrenceId: 'occurrence_1',
        occurrenceCandidate: _occurrence(expectedAmount: 75),
      ),
      throwsStateError,
    );

    expect(harness.store.expectedExpenseAggregate, same(initial));
    expect(harness.aggregate.relationships.single.provider, 'Provider');
    expect(harness.aggregate.occurrences.single.expectedAmount, 50);
    expect(harness.notifications, 0);
  });

  test('retry after success is unchanged without a second write', () async {
    final harness = _Harness();
    final candidate = _relationship(provider: 'Updated provider');

    expect(
      await harness.coordinator.updateRelationship(
        relationshipId: 'relationship_1',
        candidate: candidate,
      ),
      ExpectedExpenseUpdateOutcome.applied,
    );
    expect(
      await harness.coordinator.updateRelationship(
        relationshipId: 'relationship_1',
        candidate: candidate,
      ),
      ExpectedExpenseUpdateOutcome.unchanged,
    );
    expect(harness.writes, 1);
  });

  test(
    'preference can move from null to a value and remain preserved',
    () async {
      final harness = _Harness();
      final preference = ManualPaymentPreference(preferredStartDayOfMonth: 5);
      final candidate = _relationship(preference: preference);

      await harness.coordinator.updateRelationship(
        relationshipId: 'relationship_1',
        candidate: candidate,
      );
      final preserved = harness.aggregate.relationships.single.copyWith(
        provider: 'Another provider',
      );
      await harness.coordinator.updateRelationship(
        relationshipId: 'relationship_1',
        candidate: preserved,
      );

      expect(
        harness.aggregate.relationships.single.manualPaymentPreference
            ?.toJson(),
        preference.toJson(),
      );
    },
  );

  test('valid forecast to known-unpaid update preserves identity', () async {
    final harness = _Harness();
    final candidate = _occurrence(
      knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
      knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
    );

    final outcome = await harness.coordinator.updateOccurrence(
      occurrenceId: 'occurrence_1',
      candidate: candidate,
    );

    expect(outcome, ExpectedExpenseUpdateOutcome.applied);
    expect(harness.aggregate.occurrences.single.occurrenceId, 'occurrence_1');
    expect(
      harness.aggregate.occurrences.single.knowledgeState,
      ExpectedExpenseKnowledgeState.knownUnpaid,
    );
  });

  test('amount, due date and source update on the same occurrence', () async {
    final harness = _Harness();
    final candidate = _occurrence(
      expectedAmount: 80,
      dueDate: DateTime(2026, 11, 20),
    );

    await harness.coordinator.updateOccurrence(
      occurrenceId: 'occurrence_1',
      candidate: candidate,
    );

    final updated = harness.aggregate.occurrences.single;
    expect(updated.occurrenceId, 'occurrence_1');
    expect(updated.expectedAmount, 80);
    expect(updated.expectedDueDate, DateTime(2026, 11, 20));
    expect(updated.expectedDueDateSource, ExpectedExpenseDateSource.explicit);
  });

  for (final origin in [
    ExpectedPaymentWindowOrigin.relationshipDefault,
    ExpectedPaymentWindowOrigin.occurrenceOverride,
  ]) {
    test('preserves payment-window origin $origin', () async {
      final harness = _Harness();

      await harness.coordinator.updateOccurrence(
        occurrenceId: 'occurrence_1',
        candidate: _occurrence(paymentWindow: _window(origin)),
      );

      expect(
        harness.aggregate.occurrences.single.expectedPaymentWindow?.origin,
        origin,
      );
    });
  }

  test('updated aggregate survives persistence round-trip', () async {
    String? raw;
    final initial = _aggregate();
    late final FinanceStore store;
    final persistence = ExpectedExpensePersistence(
      load: (_) async => raw,
      saveVerified: (_, value) async {
        raw = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );
    store = FinanceStore(
      initialExpectedExpenseAggregate: initial,
      expectedExpensePersistence: persistence,
    );
    final coordinator = ExpectedExpenseUpdateCoordinator(financeStore: store);

    await coordinator.updateOccurrence(
      occurrenceId: 'occurrence_1',
      candidate: _occurrence(expectedAmount: 75),
    );
    final restored = await persistence.load();

    expect(
      restored.occurrences.single.toJson(),
      _occurrence(expectedAmount: 75).toJson(),
    );
    expect(restored.relationships.single.toJson(), _relationship().toJson());
  });
}

class _Harness {
  late final FinanceStore store;
  late final ExpectedExpenseUpdateCoordinator coordinator;
  int writes = 0;
  int notifications = 0;
  bool writeSawOldState = false;

  _Harness({bool failWrites = false}) {
    final initial = _aggregate();
    store = FinanceStore(
      initialExpectedExpenseAggregate: initial,
      expectedExpensePersistence: ExpectedExpensePersistence(
        saveVerified: (_, value) async {
          writes++;
          writeSawOldState = identical(store.expectedExpenseAggregate, initial);
          if (failWrites) {
            return const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            );
          }
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      ),
    );
    store.addListener(() => notifications++);
    coordinator = ExpectedExpenseUpdateCoordinator(financeStore: store);
  }

  ExpectedExpenseAggregate get aggregate => store.expectedExpenseAggregate;
}

ExpectedExpenseAggregate _aggregate() => ExpectedExpenseAggregate(
  relationships: [_relationship()],
  occurrences: [_occurrence()],
);

ExpenseRelationship _relationship({
  String id = 'relationship_1',
  String provider = 'Provider',
  ManualPaymentPreference? preference,
}) => ExpenseRelationship(
  relationshipId: id,
  service: 'Service',
  provider: provider,
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.monthly,
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.manual,
  ),
  manualPaymentPreference: preference,
);

ExpectedExpenseOccurrence _occurrence({
  String id = 'occurrence_1',
  String relationshipId = 'relationship_1',
  double expectedAmount = 50,
  DateTime? dueDate,
  ExpectedExpenseKnowledgeState knowledgeState =
      ExpectedExpenseKnowledgeState.forecast,
  ExpectedExpenseKnowledgeSource knowledgeSource =
      ExpectedExpenseKnowledgeSource.legacyUnspecified,
  ExpectedPaymentWindow? paymentWindow,
}) => ExpectedExpenseOccurrence(
  occurrenceId: id,
  relationshipId: relationshipId,
  status: ExpectedExpenseOccurrenceStatus.pending,
  knowledgeState: knowledgeState,
  knowledgeSource: knowledgeSource,
  expectedDueDate: dueDate ?? DateTime(2026, 11, 14),
  expectedDueDateSource: ExpectedExpenseDateSource.explicit,
  expectedPaymentWindow: paymentWindow,
  expectedAmount: expectedAmount,
  estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
  evidenceEconomicFactIds: const ['economic_fact_1'],
  confidence: ExpenseEstimateConfidence.low,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.manual,
  ),
  expectedSubject: FinanceSubject.matteo,
);

ExpectedPaymentWindow _window(ExpectedPaymentWindowOrigin origin) =>
    ExpectedPaymentWindow(
      start: DateTime(2026, 11, 5),
      end: DateTime(2026, 11, 14),
      semantic: ExpectedPaymentWindowSemantic.userPreferred,
      source: ExpectedExpenseDateSource.explicit,
      confidence: ExpectedTemporalConfidence.high,
      origin: origin,
    );
