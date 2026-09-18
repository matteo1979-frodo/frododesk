import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/expected_expense_registration_coordinator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/first_cycle_expense_evidence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('empty aggregate saves relationship and generated occurrence once', () async {
    final harness = _Harness();

    final outcome = await harness.coordinator.register(
      relationship: _relationship(),
      evidence: _evidence(),
      occurrenceId: 'occurrence_hera_1',
      explicitNextDate: DateTime(2026, 10, 23),
    );

    expect(outcome, ExpectedExpenseRegistrationOutcome.created);
    expect(harness.writes, 1);
    expect(harness.writeSawOldState, isTrue);
    final aggregate = harness.store.expectedExpenseAggregate;
    expect(aggregate.relationships, hasLength(1));
    expect(aggregate.occurrences, hasLength(1));
    final occurrence = aggregate.occurrences.single;
    expect(occurrence.expectedAmount, 59.63);
    expect(occurrence.expectedIssueDate, DateTime(2026, 10, 23));
    expect(occurrence.expectedIssueDateSource, ExpectedExpenseDateSource.explicit);
    expect(occurrence.expectedDueDate, isNull);
    expect(occurrence.expectedPaymentWindow, isNull);
    expect(occurrence.estimationMethod, ExpenseEstimationMethod.firstAvailableFact);
    expect(occurrence.evidenceEconomicFactIds, ['economic_fact_hera']);
    expect(occurrence.confidence, ExpenseEstimateConfidence.low);
    expect(occurrence.provisional, isTrue);
    expect(occurrence.status, ExpectedExpenseOccurrenceStatus.pending);
  });

  test('identical complete retry is idempotent without another write', () async {
    final existing = _aggregate();
    final harness = _Harness(initial: existing);

    final outcome = await harness.coordinator.register(
      relationship: _relationship(),
      evidence: _evidence(),
      occurrenceId: 'occurrence_hera_1',
      explicitNextDate: DateTime(2026, 10, 23),
    );

    expect(outcome, ExpectedExpenseRegistrationOutcome.unchanged);
    expect(harness.writes, 0);
    expect(harness.store.expectedExpenseAggregate, same(existing));
  });

  test('existing equivalent relationship recovers missing occurrence', () async {
    final preserved = _relationship(id: 'relationship_other', provider: 'Other');
    final harness = _Harness(
      initial: ExpectedExpenseAggregate(relationships: [preserved, _relationship()]),
    );

    final outcome = await harness.coordinator.register(
      relationship: _relationship(),
      evidence: _evidence(),
      occurrenceId: 'occurrence_hera_1',
      explicitNextDate: DateTime(2026, 10, 23),
    );

    expect(outcome, ExpectedExpenseRegistrationOutcome.recovered);
    expect(harness.writes, 1);
    expect(harness.store.expectedExpenseAggregate.relationships, hasLength(2));
    expect(harness.store.expectedExpenseAggregate.relationships.first, same(preserved));
    expect(harness.store.expectedExpenseAggregate.occurrences, hasLength(1));
  });

  test('incompatible relationship is an explicit conflict', () async {
    final harness = _Harness(
      initial: ExpectedExpenseAggregate(relationships: [_relationship(provider: 'Different')]),
    );

    await expectLater(
      harness.coordinator.register(
        relationship: _relationship(),
        evidence: _evidence(),
        occurrenceId: 'occurrence_hera_1',
      ),
      throwsA(isA<ExpectedExpenseRegistrationConflict>()),
    );
    expect(harness.writes, 0);
  });

  test('incompatible occurrence is an explicit conflict', () async {
    final incompatible = _generated(amount: 60);
    final harness = _Harness(
      initial: ExpectedExpenseAggregate(
        relationships: [_relationship()],
        occurrences: [incompatible],
      ),
    );

    await expectLater(
      harness.coordinator.register(
        relationship: _relationship(),
        evidence: _evidence(),
        occurrenceId: 'occurrence_hera_1',
        explicitNextDate: DateTime(2026, 10, 23),
      ),
      throwsA(isA<ExpectedExpenseRegistrationConflict>()),
    );
    expect(harness.writes, 0);
  });

  test('occurrence without relationship fails explicitly', () async {
    final harness = _Harness(
      initial: ExpectedExpenseAggregate(occurrences: [_generated()]),
    );

    await expectLater(
      harness.coordinator.register(
        relationship: _relationship(),
        evidence: _evidence(),
        occurrenceId: 'occurrence_hera_1',
      ),
      throwsA(isA<ExpectedExpenseRegistrationConflict>()),
    );
    expect(harness.writes, 0);
  });

  test('write failure leaves aggregate and economic state unchanged', () async {
    final initial = ExpectedExpenseAggregate.empty();
    final store = FinanceStore(
      initialExpectedExpenseAggregate: initial,
      expectedExpensePersistence: ExpectedExpensePersistence(
        saveVerified: (_, _) async => const PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      ),
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await expectLater(
      ExpectedExpenseRegistrationCoordinator(financeStore: store).register(
        relationship: _relationship(),
        evidence: _evidence(),
        occurrenceId: 'occurrence_hera_1',
      ),
      throwsStateError,
    );

    expect(store.expectedExpenseAggregate, same(initial));
    expect(notifications, 0);
    expect(store.balances, isEmpty);
    expect(store.transactions, isEmpty);
    expect(store.funds, isEmpty);
    expect(store.assetMovements, isEmpty);
    expect(store.recurringItems, isEmpty);
    expect(store.itemsForProjectionMonth(DateTime(2026, 10)), isEmpty);
  });

  test('preserves all pre-existing occurrences', () async {
    final otherRelationship = _relationship(id: 'relationship_other', provider: 'Other');
    final otherOccurrence = _generated(
      occurrenceId: 'occurrence_other',
      relationshipId: 'relationship_other',
    );
    final harness = _Harness(
      initial: ExpectedExpenseAggregate(
        relationships: [otherRelationship],
        occurrences: [otherOccurrence],
      ),
    );

    await harness.coordinator.register(
      relationship: _relationship(),
      evidence: _evidence(),
      occurrenceId: 'occurrence_hera_1',
      explicitNextDate: DateTime(2026, 10, 23),
    );

    expect(harness.store.expectedExpenseAggregate.occurrences, hasLength(2));
    expect(harness.store.expectedExpenseAggregate.occurrences.first, same(otherOccurrence));
  });
}

class _Harness {
  late final FinanceStore store;
  late final ExpectedExpenseRegistrationCoordinator coordinator;
  int writes = 0;
  bool writeSawOldState = false;

  _Harness({ExpectedExpenseAggregate? initial}) {
    final initialAggregate = initial ?? ExpectedExpenseAggregate.empty();
    store = FinanceStore(
      initialExpectedExpenseAggregate: initialAggregate,
      expectedExpensePersistence: ExpectedExpensePersistence(
        saveVerified: (_, value) async {
          writes++;
          writeSawOldState = identical(store.expectedExpenseAggregate, initialAggregate);
          return PersistenceWriteVerification(backendAccepted: true, readBack: value);
        },
      ),
    );
    coordinator = ExpectedExpenseRegistrationCoordinator(financeStore: store);
  }
}

ExpenseRelationship _relationship({
  String id = 'relationship_hera',
  String provider = 'Hera',
}) => ExpenseRelationship(
  relationshipId: id,
  service: 'Acqua',
  provider: provider,
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.custom,
    customInterval: 2,
    customIntervalUnit: 'months',
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance_matteo',
  ),
);

FirstCycleExpenseEvidence _evidence({double amount = 59.63}) =>
    FirstCycleExpenseEvidence(
      amount: amount,
      referenceDate: DateTime(2026, 8, 24),
      referenceDateSemantic: ExpenseEvidenceDateSemantic.issue,
      economicFactId: 'economic_fact_hera',
    );

ExpectedExpenseAggregate _aggregate() => ExpectedExpenseAggregate(
  relationships: [_relationship()],
  occurrences: [_generated()],
);

ExpectedExpenseOccurrence _generated({
  double amount = 59.63,
  String occurrenceId = 'occurrence_hera_1',
  String relationshipId = 'relationship_hera',
}) => ExpectedExpenseOccurrence(
  occurrenceId: occurrenceId,
  relationshipId: relationshipId,
  status: ExpectedExpenseOccurrenceStatus.pending,
  expectedIssueDate: DateTime(2026, 10, 23),
  expectedIssueDateSource: ExpectedExpenseDateSource.explicit,
  expectedAmount: amount,
  estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
  evidenceEconomicFactIds: const ['economic_fact_hera'],
  confidence: ExpenseEstimateConfidence.low,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance_matteo',
  ),
  expectedSubject: FinanceSubject.matteo,
);
