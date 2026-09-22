import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/legacy_expense_cycle_identity_coordinator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test(
    'explicit assignment persists identity and preserves all other data',
    () async {
      final occurrence = _occurrence('legacy');
      final harness = _Harness([occurrence]);

      final outcome = await harness.coordinator.assign(
        relationshipId: 'relationship',
        occurrenceId: 'legacy',
        cycleSequence: 1,
        cycleAnchor: DateTime(2026, 11, 15),
      );

      expect(outcome, LegacyExpenseCycleIdentityOutcome.assigned);
      expect(harness.writes, 1);
      final assigned =
          harness.store.expectedExpenseAggregate.occurrences.single;
      expect(assigned.cycleSequence, 1);
      expect(assigned.cycleAnchor, DateTime(2026, 11, 15));
      final expected = occurrence.toJson()
        ..['cycleSequence'] = 1
        ..['cycleAnchor'] = DateTime(2026, 11, 15).toIso8601String();
      expect(assigned.toJson(), expected);
    },
  );

  test(
    'same assignment is idempotent but incompatible reassignment fails',
    () async {
      final harness = _Harness([
        _occurrence(
          'identified',
          cycleSequence: 2,
          cycleAnchor: DateTime(2027, 1, 15),
        ),
      ]);

      expect(
        await harness.coordinator.assign(
          relationshipId: 'relationship',
          occurrenceId: 'identified',
          cycleSequence: 2,
          cycleAnchor: DateTime(2027, 1, 15),
        ),
        LegacyExpenseCycleIdentityOutcome.unchanged,
      );
      await expectLater(
        harness.coordinator.assign(
          relationshipId: 'relationship',
          occurrenceId: 'identified',
          cycleSequence: 3,
          cycleAnchor: DateTime(2027, 3, 15),
        ),
        throwsA(isA<LegacyExpenseCycleIdentityConflict>()),
      );
      expect(harness.writes, 0);
    },
  );

  test(
    'invalid sequence and sequence or anchor collisions are rejected',
    () async {
      final existing = _occurrence(
        'existing',
        cycleSequence: 1,
        cycleAnchor: DateTime(2026, 11, 15),
      );
      final harness = _Harness([existing, _occurrence('legacy')]);

      await expectLater(
        harness.coordinator.assign(
          relationshipId: 'relationship',
          occurrenceId: 'legacy',
          cycleSequence: 0,
          cycleAnchor: DateTime(2027, 1, 15),
        ),
        throwsArgumentError,
      );
      for (final identity in [
        (sequence: 1, anchor: DateTime(2027, 1, 15)),
        (sequence: 2, anchor: DateTime(2026, 11, 15)),
      ]) {
        await expectLater(
          harness.coordinator.assign(
            relationshipId: 'relationship',
            occurrenceId: 'legacy',
            cycleSequence: identity.sequence,
            cycleAnchor: identity.anchor,
          ),
          throwsA(isA<LegacyExpenseCycleIdentityConflict>()),
        );
      }
      expect(harness.writes, 0);
    },
  );

  test(
    'write failure leaves legacy occurrence unchanged and emits no notify',
    () async {
      final initial = ExpectedExpenseAggregate(
        relationships: [_relationship()],
        occurrences: [_occurrence('legacy')],
      );
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
        LegacyExpenseCycleIdentityCoordinator(financeStore: store).assign(
          relationshipId: 'relationship',
          occurrenceId: 'legacy',
          cycleSequence: 1,
          cycleAnchor: DateTime(2026, 11, 15),
        ),
        throwsStateError,
      );
      expect(store.expectedExpenseAggregate, same(initial));
      expect(notifications, 0);
    },
  );
}

class _Harness {
  late final FinanceStore store;
  late final LegacyExpenseCycleIdentityCoordinator coordinator;
  int writes = 0;

  _Harness(List<ExpectedExpenseOccurrence> occurrences) {
    store = FinanceStore(
      initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
        relationships: [_relationship()],
        occurrences: occurrences,
      ),
      expectedExpensePersistence: ExpectedExpensePersistence(
        saveVerified: (_, value) async {
          writes++;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      ),
    );
    coordinator = LegacyExpenseCycleIdentityCoordinator(financeStore: store);
  }
}

ExpenseRelationship _relationship() => ExpenseRelationship(
  relationshipId: 'relationship',
  service: 'Gas',
  provider: 'Provider',
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.custom,
    customInterval: 2,
    customIntervalUnit: 'months',
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance',
  ),
);

ExpectedExpenseOccurrence _occurrence(
  String id, {
  int? cycleSequence,
  DateTime? cycleAnchor,
}) => ExpectedExpenseOccurrence(
  occurrenceId: id,
  relationshipId: 'relationship',
  cycleSequence: cycleSequence,
  cycleAnchor: cycleAnchor,
  status: ExpectedExpenseOccurrenceStatus.pending,
  expectedDueDate: DateTime(2026, 11, 20),
  expectedDueDateSource: ExpectedExpenseDateSource.explicit,
  expectedAmount: 50,
  estimationMethod: ExpenseEstimationMethod.manualEstimate,
  confidence: ExpenseEstimateConfidence.medium,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance',
  ),
  expectedSubject: FinanceSubject.matteo,
);
