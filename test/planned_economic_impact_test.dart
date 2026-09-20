import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/expected_expense_update_coordinator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/manual_payment_preference.dart';
import 'package:frododesk/models/planned_economic_impact.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  group('PlannedEconomicImpact', () {
    test('supports one date, a range, and rejects an inverted range', () {
      final date = DateTime(2026, 12, 5);
      final single = PlannedEconomicImpact(
        start: date,
        end: date,
        origin: PlannedEconomicImpactOrigin.userDecision,
      );
      final range = PlannedEconomicImpact(
        start: date,
        end: DateTime(2026, 12, 7),
        origin: PlannedEconomicImpactOrigin.userDecision,
      );

      expect(single.start, single.end);
      expect(range.end.isAfter(range.start), isTrue);
      expect(
        () => PlannedEconomicImpact(
          start: DateTime(2026, 12, 7),
          end: date,
          origin: PlannedEconomicImpactOrigin.userDecision,
        ),
        throwsArgumentError,
      );
    });

    test('round-trips the complete contract', () {
      final impact = _impact();

      final restored = PlannedEconomicImpact.fromJson(impact.toJson());

      expect(restored.toJson(), impact.toJson());
    });
  });

  group('ExpectedExpenseOccurrence planned economic impact', () {
    test(
      'coexists with an earlier due date without changing other semantics',
      () {
        final window = _paymentWindow();
        final occurrence = _occurrence(
          plannedEconomicImpact: _impact(),
          paymentWindow: window,
        );

        expect(occurrence.expectedDueDate, DateTime(2026, 11, 14));
        expect(occurrence.plannedEconomicImpact?.start, DateTime(2026, 12, 5));
        expect(
          occurrence.plannedEconomicImpact!.start.isAfter(
            occurrence.expectedDueDate!,
          ),
          isTrue,
        );
        expect(occurrence.expectedPaymentWindow, same(window));
        expect(occurrence.status, ExpectedExpenseOccurrenceStatus.pending);
        expect(
          occurrence.knowledgeState,
          ExpectedExpenseKnowledgeState.knownUnpaid,
        );
      },
    );

    test('JSON round-trip is backward-compatible with legacy records', () {
      final occurrence = _occurrence(plannedEconomicImpact: _impact());

      final restored = ExpectedExpenseOccurrence.fromJson(occurrence.toJson());
      final legacyJson = occurrence.toJson()..remove('plannedEconomicImpact');
      final legacy = ExpectedExpenseOccurrence.fromJson(legacyJson);

      expect(
        restored.plannedEconomicImpact?.toJson(),
        occurrence.plannedEconomicImpact?.toJson(),
      );
      expect(legacy.plannedEconomicImpact, isNull);
    });

    test('copyWith preserves, sets, and explicitly clears the plan', () {
      final withoutPlan = _occurrence();
      final plan = _impact();
      final withPlan = withoutPlan.copyWith(plannedEconomicImpact: plan);
      final preserved = withPlan.copyWith(expectedAmount: 101);
      final cleared = preserved.copyWith(plannedEconomicImpact: null);

      expect(withoutPlan.plannedEconomicImpact, isNull);
      expect(withPlan.plannedEconomicImpact, same(plan));
      expect(preserved.plannedEconomicImpact, same(plan));
      expect(cleared.plannedEconomicImpact, isNull);
    });

    test(
      'update coordinator persists the plan without changing identities',
      () async {
        String? raw;
        final relationship = _relationship();
        final original = _occurrence(paymentWindow: _paymentWindow());
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
        final store = FinanceStore(
          initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
            relationships: [relationship],
            occurrences: [original],
          ),
          expectedExpensePersistence: persistence,
        );
        final coordinator = ExpectedExpenseUpdateCoordinator(
          financeStore: store,
        );

        final outcome = await coordinator.updateOccurrence(
          occurrenceId: original.occurrenceId,
          candidate: original.copyWith(plannedEconomicImpact: _impact()),
        );
        final restored = await persistence.load();
        final updated = restored.occurrences.single;

        expect(outcome, ExpectedExpenseUpdateOutcome.applied);
        expect(updated.occurrenceId, original.occurrenceId);
        expect(updated.relationshipId, original.relationshipId);
        expect(updated.expectedDueDate, original.expectedDueDate);
        expect(
          updated.expectedPaymentWindow?.toJson(),
          original.expectedPaymentWindow?.toJson(),
        );
        expect(updated.status, original.status);
        expect(updated.knowledgeState, original.knowledgeState);
        expect(updated.plannedEconomicImpact?.toJson(), _impact().toJson());
        expect(
          store
              .expectedExpenseAggregate
              .relationships
              .single
              .manualPaymentPreference
              ?.preferredStartDayOfMonth,
          5,
        );
      },
    );
  });
}

PlannedEconomicImpact _impact() => PlannedEconomicImpact(
  start: DateTime(2026, 12, 5),
  end: DateTime(2026, 12, 5),
  origin: PlannedEconomicImpactOrigin.userDecision,
);

ExpectedPaymentWindow _paymentWindow() => ExpectedPaymentWindow(
  start: DateTime(2026, 11, 5),
  end: DateTime(2026, 11, 14),
  semantic: ExpectedPaymentWindowSemantic.userPreferred,
  source: ExpectedExpenseDateSource.explicit,
  confidence: ExpectedTemporalConfidence.high,
  origin: ExpectedPaymentWindowOrigin.relationshipDefault,
);

ExpenseRelationship _relationship() => ExpenseRelationship(
  relationshipId: 'relationship_1',
  service: 'Energia',
  provider: 'Provider',
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.monthly,
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.manual,
    expectedBalanceId: 'balance_1',
  ),
  manualPaymentPreference: ManualPaymentPreference(preferredStartDayOfMonth: 5),
);

ExpectedExpenseOccurrence _occurrence({
  PlannedEconomicImpact? plannedEconomicImpact,
  ExpectedPaymentWindow? paymentWindow,
}) => ExpectedExpenseOccurrence(
  occurrenceId: 'occurrence_1',
  relationshipId: 'relationship_1',
  status: ExpectedExpenseOccurrenceStatus.pending,
  knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
  knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
  expectedDueDate: DateTime(2026, 11, 14),
  expectedDueDateSource: ExpectedExpenseDateSource.explicit,
  expectedDueDateCertainty: ExpectedExpenseDateCertainty.known,
  expectedPaymentWindow: paymentWindow,
  plannedEconomicImpact: plannedEconomicImpact,
  expectedAmount: 100,
  estimationMethod: ExpenseEstimationMethod.manualEstimate,
  confidence: ExpenseEstimateConfidence.high,
  provisional: false,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.manual,
    expectedBalanceId: 'balance_1',
  ),
  expectedSubject: FinanceSubject.matteo,
);
