import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_reader.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/first_cycle_expected_expense_generator.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/first_cycle_expense_evidence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/planned_economic_impact.dart';

void main() {
  group('PaymentExecutionMode contract', () {
    test('exposes exactly the four approved states', () {
      expect(PaymentExecutionMode.values, [
        PaymentExecutionMode.unknown,
        PaymentExecutionMode.requiresUserAction,
        PaymentExecutionMode.automatic,
        PaymentExecutionMode.scheduled,
      ]);
    });

    test('relationship defaults to unknown and round-trips', () {
      final relationship = _relationship();
      expect(relationship.paymentExecutionMode, PaymentExecutionMode.unknown);

      final restored = ExpenseRelationship.fromJson(relationship.toJson());
      expect(restored.paymentExecutionMode, PaymentExecutionMode.unknown);
      expect(
        relationship.copyWith(
          paymentExecutionMode: PaymentExecutionMode.automatic,
        ).paymentExecutionMode,
        PaymentExecutionMode.automatic,
      );
    });

    test('legacy relationship and occurrence default to unknown', () {
      final relationshipJson = _relationship().toJson()
        ..remove('paymentExecutionMode');
      final occurrenceJson = _occurrence().toJson()
        ..remove('paymentExecutionMode');

      expect(
        ExpenseRelationship.fromJson(relationshipJson).paymentExecutionMode,
        PaymentExecutionMode.unknown,
      );
      expect(
        ExpectedExpenseOccurrence.fromJson(
          occurrenceJson,
        ).paymentExecutionMode,
        PaymentExecutionMode.unknown,
      );
    });

    test('unknown persisted values are rejected explicitly', () {
      final relationshipJson = _relationship().toJson()
        ..['paymentExecutionMode'] = 'robotic';
      final occurrenceJson = _occurrence().toJson()
        ..['paymentExecutionMode'] = 'robotic';

      expect(
        () => ExpenseRelationship.fromJson(relationshipJson),
        throwsFormatException,
      );
      expect(
        () => ExpectedExpenseOccurrence.fromJson(occurrenceJson),
        throwsFormatException,
      );
    });

    test('occurrence round-trips and can change independently', () {
      final relationship = _relationship(
        mode: PaymentExecutionMode.requiresUserAction,
      );
      final occurrence = _occurrence(
        mode: PaymentExecutionMode.requiresUserAction,
      );
      final scheduled = occurrence.copyWith(
        paymentExecutionMode: PaymentExecutionMode.scheduled,
      );

      expect(relationship.paymentExecutionMode,
          PaymentExecutionMode.requiresUserAction);
      expect(scheduled.paymentExecutionMode, PaymentExecutionMode.scheduled);
      expect(scheduled.occurrenceId, occurrence.occurrenceId);
      expect(scheduled.relationshipId, occurrence.relationshipId);
      expect(scheduled.expectedDueDate, occurrence.expectedDueDate);
      expect(
        ExpectedExpenseOccurrence.fromJson(
          scheduled.toJson(),
        ).paymentExecutionMode,
        PaymentExecutionMode.scheduled,
      );
    });

    test('changing relationship does not rewrite an existing occurrence', () {
      final existing = _occurrence(
        mode: PaymentExecutionMode.requiresUserAction,
      );
      final changedRelationship = _relationship(
        mode: PaymentExecutionMode.requiresUserAction,
      ).copyWith(paymentExecutionMode: PaymentExecutionMode.automatic);

      expect(changedRelationship.paymentExecutionMode,
          PaymentExecutionMode.automatic);
      expect(existing.paymentExecutionMode,
          PaymentExecutionMode.requiresUserAction);
    });

    for (final method in FinancePaymentMethod.values) {
      test('does not infer execution mode from ${method.name}', () {
        expect(
          _relationship(method: method).paymentExecutionMode,
          PaymentExecutionMode.unknown,
        );
        expect(
          _occurrence(method: method).paymentExecutionMode,
          PaymentExecutionMode.unknown,
        );
      });
    }
  });

  group('generation and projection', () {
    test('generator snapshots the current relationship mode explicitly', () {
      final generator = const FirstCycleExpectedExpenseGenerator();
      final manual = _relationship(
        mode: PaymentExecutionMode.requiresUserAction,
      );
      final automatic = manual.copyWith(
        paymentExecutionMode: PaymentExecutionMode.automatic,
      );

      final first = generator.generate(
        relationship: manual,
        evidence: _evidence(),
        occurrenceId: 'occurrence_manual',
      );
      final next = generator.generate(
        relationship: automatic,
        evidence: _evidence(),
        occurrenceId: 'occurrence_automatic',
      );

      expect(first.paymentExecutionMode,
          PaymentExecutionMode.requiresUserAction);
      expect(next.paymentExecutionMode, PaymentExecutionMode.automatic);
      expect(first.paymentExecutionMode,
          isNot(next.paymentExecutionMode));
    });

    test('reader exposes relationship and occurrence modes without fallback', () {
      final relationship = _relationship(
        mode: PaymentExecutionMode.automatic,
      );
      final occurrence = _occurrence(mode: PaymentExecutionMode.unknown);

      final projection = const ExpectedExpenseReader().read(
        ExpectedExpenseAggregate(
          relationships: [relationship],
          occurrences: [occurrence],
        ),
      ).single;

      expect(projection.relationshipPaymentExecutionMode,
          PaymentExecutionMode.automatic);
      expect(projection.occurrencePaymentExecutionMode,
          PaymentExecutionMode.unknown);
    });

    test('execution mode is independent from window and planned impact', () {
      final impact = PlannedEconomicImpact(
        start: DateTime(2026, 10, 20),
        end: DateTime(2026, 10, 20),
        origin: PlannedEconomicImpactOrigin.userDecision,
      );
      final occurrence = _occurrence(
        mode: PaymentExecutionMode.automatic,
        paymentWindow: ExpectedPaymentWindow(
          start: DateTime(2026, 10, 5),
          end: DateTime(2026, 10, 10),
          semantic: ExpectedPaymentWindowSemantic.userPreferred,
        ),
        plannedImpact: impact,
      );
      final scheduled = occurrence.copyWith(
        paymentExecutionMode: PaymentExecutionMode.scheduled,
        plannedEconomicImpact: null,
      );

      expect(occurrence.paymentExecutionMode, PaymentExecutionMode.automatic);
      expect(occurrence.expectedPaymentWindow!.semantic,
          ExpectedPaymentWindowSemantic.userPreferred);
      expect(occurrence.plannedEconomicImpact, same(impact));
      expect(scheduled.paymentExecutionMode, PaymentExecutionMode.scheduled);
      expect(scheduled.plannedEconomicImpact, isNull);
      expect(scheduled.expectedPaymentWindow, same(occurrence.expectedPaymentWindow));
    });
  });
}

ExpenseRelationship _relationship({
  PaymentExecutionMode mode = PaymentExecutionMode.unknown,
  FinancePaymentMethod method = FinancePaymentMethod.manual,
}) => ExpenseRelationship(
  relationshipId: 'relationship_1',
  service: 'Energia',
  provider: 'Provider',
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.monthly,
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(method: method),
  paymentExecutionMode: mode,
);

ExpectedExpenseOccurrence _occurrence({
  PaymentExecutionMode mode = PaymentExecutionMode.unknown,
  FinancePaymentMethod method = FinancePaymentMethod.manual,
  ExpectedPaymentWindow? paymentWindow,
  PlannedEconomicImpact? plannedImpact,
}) => ExpectedExpenseOccurrence(
  occurrenceId: 'occurrence_1',
  relationshipId: 'relationship_1',
  status: ExpectedExpenseOccurrenceStatus.pending,
  expectedDueDate: DateTime(2026, 10, 15),
  expectedDueDateSource: ExpectedExpenseDateSource.explicit,
  expectedPaymentWindow: paymentWindow,
  plannedEconomicImpact: plannedImpact,
  expectedAmount: 100,
  estimationMethod: ExpenseEstimationMethod.manualEstimate,
  confidence: ExpenseEstimateConfidence.medium,
  provisional: false,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: method,
  ),
  paymentExecutionMode: mode,
  expectedSubject: FinanceSubject.matteo,
);

FirstCycleExpenseEvidence _evidence() => FirstCycleExpenseEvidence(
  economicFactId: 'fact_1',
  amount: 100,
  referenceDate: DateTime(2026, 9, 15),
  referenceDateSemantic: ExpenseEvidenceDateSemantic.due,
);
