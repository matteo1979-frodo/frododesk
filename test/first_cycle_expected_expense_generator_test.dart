import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/first_cycle_expected_expense_generator.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/first_cycle_expense_evidence.dart';

void main() {
  const generator = FirstCycleExpectedExpenseGenerator();

  group('FirstCycleExpectedExpenseGenerator', () {
    test('uses the explicit Hera issue date without adding accessories', () {
      final relationship = _relationship(
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 2,
          customIntervalUnit: 'months',
        ),
      );
      final evidence = _evidence(
        metadata: EconomicOperationMetadata(
          operationId: 'utility_operation_1',
          role: OperationRole.main,
          context: OperationContext.utilityBill,
        ),
      );

      final occurrence = generator.generate(
        relationship: relationship,
        evidence: evidence,
        occurrenceId: 'occurrence_hera_2',
        explicitNextDate: DateTime(2026, 10, 23),
      );

      expect(occurrence.occurrenceId, 'occurrence_hera_2');
      expect(occurrence.relationshipId, 'relationship_hera_acqua');
      expect(occurrence.cycleSequence, 1);
      expect(occurrence.cycleAnchor, DateTime(2026, 10, 23));
      expect(occurrence.status, ExpectedExpenseOccurrenceStatus.pending);
      expect(occurrence.expectedAmount, 59.63);
      expect(
        occurrence.estimationMethod,
        ExpenseEstimationMethod.firstAvailableFact,
      );
      expect(occurrence.evidenceEconomicFactIds, ['economic_fact_hera_1']);
      expect(occurrence.confidence, ExpenseEstimateConfidence.low);
      expect(occurrence.provisional, isTrue);
      expect(occurrence.expectedIssueDate, DateTime(2026, 10, 23));
      expect(
        occurrence.expectedIssueDateSource,
        ExpectedExpenseDateSource.explicit,
      );
      expect(occurrence.expectedDueDate, isNull);
      expect(occurrence.expectedDueDateSource, isNull);
      expect(occurrence.expectedPaymentWindow, isNull);
      expect(occurrence.resolvedEconomicFactId, isNull);
      expect(occurrence.expectedSubject, FinanceSubject.matteo);
    });

    test('calculates a bimonthly issue date when no explicit date exists', () {
      final occurrence = generator.generate(
        relationship: _relationship(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.custom,
            customInterval: 2,
            customIntervalUnit: 'months',
          ),
        ),
        evidence: _evidence(),
        occurrenceId: 'occurrence_calculated',
      );

      expect(occurrence.expectedIssueDate, DateTime(2026, 10, 24));
      expect(
        occurrence.expectedIssueDateSource,
        ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );
    });

    test('due evidence generates only a calculated due date', () {
      final occurrence = generator.generate(
        relationship: _relationship(),
        evidence: _evidence(semantic: ExpenseEvidenceDateSemantic.due),
        occurrenceId: 'occurrence_due',
      );

      expect(occurrence.expectedIssueDate, isNull);
      expect(occurrence.expectedIssueDateSource, isNull);
      expect(occurrence.expectedDueDate, DateTime(2026, 9, 24));
      expect(
        occurrence.expectedDueDateSource,
        ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );
      expect(occurrence.expectedPaymentWindow, isNull);
    });

    test('monthly calculation clamps 31 January to non-leap February', () {
      final occurrence = generator.generate(
        relationship: _relationship(),
        evidence: _evidence(referenceDate: DateTime(2027, 1, 31)),
        occurrenceId: 'occurrence_month_end',
      );

      expect(occurrence.expectedIssueDate, DateTime(2027, 2, 28));
    });

    test('monthly calculation clamps 31 January to leap February', () {
      final occurrence = generator.generate(
        relationship: _relationship(),
        evidence: _evidence(referenceDate: DateTime(2028, 1, 31)),
        occurrenceId: 'occurrence_leap_month_end',
      );

      expect(occurrence.expectedIssueDate, DateTime(2028, 2, 29));
    });

    test('yearly calculation clamps leap day to 28 February', () {
      final occurrence = generator.generate(
        relationship: _relationship(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.yearly,
          ),
        ),
        evidence: _evidence(referenceDate: DateTime(2028, 2, 29)),
        occurrenceId: 'occurrence_yearly',
      );

      expect(occurrence.expectedIssueDate, DateTime(2029, 2, 28));
    });

    test('explicit date takes precedence over relationship periodicity', () {
      final occurrence = generator.generate(
        relationship: _relationship(),
        evidence: _evidence(),
        occurrenceId: 'occurrence_explicit',
        explicitNextDate: DateTime(2026, 12, 3),
      );

      expect(occurrence.expectedIssueDate, DateTime(2026, 12, 3));
      expect(
        occurrence.expectedIssueDateSource,
        ExpectedExpenseDateSource.explicit,
      );
    });

    test('rejects explicit dates equal to or before the evidence date', () {
      for (final date in [DateTime(2026, 8, 24), DateTime(2026, 8, 23)]) {
        expect(
          () => generator.generate(
            relationship: _relationship(),
            evidence: _evidence(),
            occurrenceId: 'occurrence_invalid_date',
            explicitNextDate: date,
          ),
          throwsArgumentError,
        );
      }
    });

    test('supports custom day and year units from the canonical cadence', () {
      final days = generator.generate(
        relationship: _relationship(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.custom,
            customInterval: 2,
            customIntervalUnit: 'days',
          ),
        ),
        evidence: _evidence(),
        occurrenceId: 'occurrence_days',
      );
      final years = generator.generate(
        relationship: _relationship(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.custom,
            customInterval: 2,
            customIntervalUnit: 'years',
          ),
        ),
        evidence: _evidence(),
        occurrenceId: 'occurrence_years',
      );

      expect(days.cycleAnchor, DateTime(2026, 8, 26));
      expect(years.cycleAnchor, DateTime(2028, 8, 24));
    });

    test('snapshots the current payment configuration', () {
      final payment = ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.rid,
        expectedBalanceId: 'balance_matteo',
      );
      final occurrence = generator.generate(
        relationship: _relationship(paymentConfiguration: payment),
        evidence: _evidence(),
        occurrenceId: 'occurrence_payment',
      );

      expect(occurrence.expectedPaymentConfiguration, isNot(same(payment)));
      expect(
        occurrence.expectedPaymentConfiguration.method,
        FinancePaymentMethod.rid,
      );
      expect(
        occurrence.expectedPaymentConfiguration.expectedBalanceId,
        'balance_matteo',
      );
    });

    test(
      'delegates explicit occurrence identity validation to the contract',
      () {
        expect(
          () => generator.generate(
            relationship: _relationship(),
            evidence: _evidence(),
            occurrenceId: '   ',
          ),
          throwsArgumentError,
        );
      },
    );

    test('terminated relationships cannot generate a new occurrence', () {
      expect(
        () => generator.generate(
          relationship: _relationship(
            status: ExpenseRelationshipStatus.terminated,
          ),
          evidence: _evidence(),
          occurrenceId: 'occurrence_after_termination',
        ),
        throwsStateError,
      );
    });
  });
}

ExpenseRelationship _relationship({
  ExpenseRelationshipPeriodicity? periodicity,
  ExpenseRelationshipPaymentConfiguration? paymentConfiguration,
  ExpenseRelationshipStatus status = ExpenseRelationshipStatus.active,
}) => ExpenseRelationship(
  relationshipId: 'relationship_hera_acqua',
  service: 'Acqua',
  provider: 'Hera',
  subject: FinanceSubject.matteo,
  status: status,
  periodicity:
      periodicity ??
      ExpenseRelationshipPeriodicity(type: FinanceRecurringType.monthly),
  paymentConfiguration:
      paymentConfiguration ??
      ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.rid,
        expectedBalanceId: 'balance_matteo',
      ),
);

FirstCycleExpenseEvidence _evidence({
  DateTime? referenceDate,
  ExpenseEvidenceDateSemantic semantic = ExpenseEvidenceDateSemantic.issue,
  EconomicOperationMetadata? metadata,
}) => FirstCycleExpenseEvidence(
  economicFactId: 'economic_fact_hera_1',
  amount: 59.63,
  referenceDate: referenceDate ?? DateTime(2026, 8, 24),
  referenceDateSemantic: semantic,
  operationMetadata: metadata,
);
