import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';

void main() {
  group('ExpectedExpenseOccurrence', () {
    test('builds a valid pending occurrence linked to a relationship', () {
      final occurrence = _occurrence();

      expect(occurrence.occurrenceId, 'occurrence_1');
      expect(occurrence.relationshipId, 'relationship_1');
      expect(occurrence.status, ExpectedExpenseOccurrenceStatus.pending);
      expect(occurrence.resolvedEconomicFactId, isNull);
    });

    test('can know only the expected issue date', () {
      final occurrence = _occurrence(expectedIssueDate: DateTime(2026, 10, 23));

      expect(occurrence.expectedIssueDate, DateTime(2026, 10, 23));
      expect(
        occurrence.expectedIssueDateSource,
        ExpectedExpenseDateSource.explicit,
      );
      expect(occurrence.expectedDueDate, isNull);
      expect(occurrence.expectedPaymentWindow, isNull);
    });

    test('supports distinct issue and due dates', () {
      final occurrence = _occurrence(
        expectedIssueDate: DateTime(2026, 10, 23),
        expectedDueDate: DateTime(2026, 11, 14),
        expectedDueDateSource: ExpectedExpenseDateSource.explicit,
      );

      expect(occurrence.expectedIssueDate, DateTime(2026, 10, 23));
      expect(occurrence.expectedDueDate, DateTime(2026, 11, 14));
    });

    test('supports calculated issue and due dates independently', () {
      final issue = _occurrence(
        issueDateSource: ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );
      final due = _occurrence(
        expectedIssueDate: null,
        omitDefaultIssueDate: true,
        expectedDueDate: DateTime(2026, 11, 14),
        expectedDueDateSource:
            ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );

      expect(
        issue.expectedIssueDateSource,
        ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );
      expect(
        due.expectedDueDateSource,
        ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );
    });

    test('issue and due date sources remain independent', () {
      final occurrence = _occurrence(
        issueDateSource: ExpectedExpenseDateSource.explicit,
        expectedDueDate: DateTime(2026, 11, 14),
        expectedDueDateSource:
            ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );

      expect(
        occurrence.expectedIssueDateSource,
        ExpectedExpenseDateSource.explicit,
      );
      expect(
        occurrence.expectedDueDateSource,
        ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );
    });

    test('supports a valid expected payment window', () {
      final occurrence = _occurrence(
        paymentWindow: ExpectedPaymentWindow(
          start: DateTime(2026, 11, 12),
          end: DateTime(2026, 11, 16),
        ),
      );

      expect(occurrence.expectedPaymentWindow!.start, DateTime(2026, 11, 12));
      expect(occurrence.expectedPaymentWindow!.end, DateTime(2026, 11, 16));
      expect(
        occurrence.expectedPaymentWindow!.semantic,
        ExpectedPaymentWindowSemantic.legacyUnspecified,
      );
    });

    test('round-trips a multi-day explicit user-preferred window', () {
      final window = ExpectedPaymentWindow(
        start: DateTime(2026, 11, 5),
        end: DateTime(2026, 11, 14),
        semantic: ExpectedPaymentWindowSemantic.userPreferred,
        source: ExpectedExpenseDateSource.explicit,
        confidence: ExpectedTemporalConfidence.high,
      );

      final restored = ExpectedPaymentWindow.fromJson(window.toJson());

      expect(restored.start, DateTime(2026, 11, 5));
      expect(restored.end, DateTime(2026, 11, 14));
      expect(restored.semantic, ExpectedPaymentWindowSemantic.userPreferred);
      expect(restored.source, ExpectedExpenseDateSource.explicit);
      expect(restored.confidence, ExpectedTemporalConfidence.high);
    });

    test('round-trips a single-day calculated expected-debit window', () {
      final window = ExpectedPaymentWindow(
        start: DateTime(2026, 11, 14),
        end: DateTime(2026, 11, 14),
        semantic: ExpectedPaymentWindowSemantic.expectedDebit,
        source: ExpectedExpenseDateSource.calculatedFromPeriodicity,
        confidence: ExpectedTemporalConfidence.medium,
      );

      final restored = ExpectedPaymentWindow.fromJson(window.toJson());

      expect(restored.start, restored.end);
      expect(restored.semantic, ExpectedPaymentWindowSemantic.expectedDebit);
      expect(
        restored.source,
        ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );
      expect(restored.confidence, ExpectedTemporalConfidence.medium);
    });

    test('supports every temporal confidence independently from amount', () {
      for (final confidence in const [
        ExpectedTemporalConfidence.low,
        ExpectedTemporalConfidence.medium,
        ExpectedTemporalConfidence.high,
      ]) {
        final occurrence = _occurrence(
          paymentWindow: ExpectedPaymentWindow(
            start: DateTime(2026, 11, 5),
            end: DateTime(2026, 11, 14),
            semantic: ExpectedPaymentWindowSemantic.userPreferred,
            source: ExpectedExpenseDateSource.explicit,
            confidence: confidence,
          ),
          confidence: ExpenseEstimateConfidence.low,
        );

        expect(occurrence.expectedPaymentWindow!.confidence, confidence);
        expect(occurrence.confidence, ExpenseEstimateConfidence.low);
      }
    });

    test('parses legacy payment-window JSON without inventing metadata', () {
      final restored = ExpectedPaymentWindow.fromJson({
        'start': DateTime(2026, 11, 5).toIso8601String(),
        'end': DateTime(2026, 11, 14).toIso8601String(),
      });

      expect(
        restored.semantic,
        ExpectedPaymentWindowSemantic.legacyUnspecified,
      );
      expect(restored.source, ExpectedExpenseDateSource.legacyUnspecified);
      expect(restored.confidence, ExpectedTemporalConfidence.legacyUnspecified);
    });

    test('rejects invalid payment-window metadata explicitly', () {
      final valid = ExpectedPaymentWindow(
        start: DateTime(2026, 11, 5),
        end: DateTime(2026, 11, 14),
      ).toJson();

      for (final invalid in [
        {...valid, 'semantic': 'payment'},
        {...valid, 'source': 'forecast'},
        {...valid, 'confidence': 'certain'},
        {...valid, 'semantic': 1},
      ]) {
        expect(
          () => ExpectedPaymentWindow.fromJson(invalid),
          throwsFormatException,
        );
      }
    });

    test('rejects an inverted expected payment window', () {
      expect(
        () => ExpectedPaymentWindow(
          start: DateTime(2026, 11, 16),
          end: DateTime(2026, 11, 12),
        ),
        throwsArgumentError,
      );
    });

    test('requires a finite positive expected amount', () {
      expect(_occurrence().expectedAmount, 59.63);
      for (final invalid in [0.0, -1.0, double.infinity, double.nan]) {
        expect(() => _occurrence(expectedAmount: invalid), throwsArgumentError);
      }
    });

    test('supports first available fact with structured evidence', () {
      final occurrence = _occurrence(
        estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
        evidence: const ['economic_fact_first'],
      );

      expect(
        occurrence.estimationMethod,
        ExpenseEstimationMethod.firstAvailableFact,
      );
      expect(occurrence.evidenceEconomicFactIds, ['economic_fact_first']);
    });

    test('supports previous comparable period evidence', () {
      final occurrence = _occurrence(
        estimationMethod: ExpenseEstimationMethod.previousComparablePeriod,
        evidence: const ['economic_fact_previous_period'],
      );

      expect(
        occurrence.estimationMethod,
        ExpenseEstimationMethod.previousComparablePeriod,
      );
    });

    test('supports a manual estimate without fabricated evidence', () {
      final occurrence = _occurrence(
        estimationMethod: ExpenseEstimationMethod.manualEstimate,
        evidence: const [],
      );

      expect(
        occurrence.estimationMethod,
        ExpenseEstimationMethod.manualEstimate,
      );
      expect(occurrence.evidenceEconomicFactIds, isEmpty);
    });

    test('represents a low-confidence provisional first estimate', () {
      final occurrence = _occurrence(
        confidence: ExpenseEstimateConfidence.low,
        provisional: true,
      );

      expect(occurrence.confidence, ExpenseEstimateConfidence.low);
      expect(occurrence.provisional, isTrue);
    });

    test('resolved occurrence requires and preserves its economic fact', () {
      final occurrence = _occurrence(
        status: ExpectedExpenseOccurrenceStatus.resolved,
        resolvedEconomicFactId: 'economic_fact_real',
      );

      expect(occurrence.status, ExpectedExpenseOccurrenceStatus.resolved);
      expect(occurrence.resolvedEconomicFactId, 'economic_fact_real');
    });

    test('rejects resolved occurrence without an economic fact', () {
      expect(
        () => _occurrence(status: ExpectedExpenseOccurrenceStatus.resolved),
        throwsArgumentError,
      );
    });

    test('rejects a resolved economic fact on a pending occurrence', () {
      expect(
        () => _occurrence(resolvedEconomicFactId: 'economic_fact_real'),
        throwsArgumentError,
      );
    });

    test('cancelled occurrence carries no real economic fact', () {
      final occurrence = _occurrence(
        status: ExpectedExpenseOccurrenceStatus.cancelled,
      );

      expect(occurrence.status, ExpectedExpenseOccurrenceStatus.cancelled);
      expect(occurrence.resolvedEconomicFactId, isNull);
    });

    test('snapshots the expected payment configuration and subject', () {
      final occurrence = _occurrence(
        payment: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.rid,
          expectedBalanceId: 'balance_matteo',
        ),
        subject: FinanceSubject.matteo,
      );

      expect(
        occurrence.expectedPaymentConfiguration.method,
        FinancePaymentMethod.rid,
      );
      expect(
        occurrence.expectedPaymentConfiguration.expectedBalanceId,
        'balance_matteo',
      );
      expect(occurrence.expectedSubject, FinanceSubject.matteo);
    });

    test('round-trips the complete contract through JSON', () {
      final source = _occurrence(
        expectedIssueDate: DateTime.utc(2026, 10, 23),
        expectedDueDate: DateTime.utc(2026, 11, 14),
        expectedDueDateSource: ExpectedExpenseDateSource.explicit,
        paymentWindow: ExpectedPaymentWindow(
          start: DateTime.utc(2026, 11, 12),
          end: DateTime.utc(2026, 11, 16),
          semantic: ExpectedPaymentWindowSemantic.expectedDebit,
          source: ExpectedExpenseDateSource.calculatedFromPeriodicity,
          confidence: ExpectedTemporalConfidence.medium,
        ),
        estimationMethod: ExpenseEstimationMethod.personalHistory,
        evidence: const ['economic_fact_1', 'economic_fact_2'],
        confidence: ExpenseEstimateConfidence.medium,
        provisional: false,
        payment: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.rid,
          expectedBalanceId: 'balance_matteo',
        ),
      );

      final json = source.toJson();
      final restored = ExpectedExpenseOccurrence.fromJson(json);

      expect(restored.toJson(), json);
      expect(json['occurrenceId'], 'occurrence_1');
      expect(json['relationshipId'], 'relationship_1');
      expect(json['estimationMethod'], 'personalHistory');
      expect(json['confidence'], 'medium');
      expect(json['expectedIssueDateSource'], 'explicit');
      expect(json['expectedDueDateSource'], 'explicit');
      expect(
        (json['expectedPaymentWindow'] as Map<String, dynamic>)['semantic'],
        'expectedDebit',
      );
    });

    test('supports issue, due and qualified payment window together', () {
      final occurrence = _occurrence(
        expectedIssueDate: DateTime(2026, 10, 23),
        expectedDueDate: DateTime(2026, 11, 14),
        expectedDueDateSource: ExpectedExpenseDateSource.explicit,
        paymentWindow: ExpectedPaymentWindow(
          start: DateTime(2026, 11, 5),
          end: DateTime(2026, 11, 13),
          semantic: ExpectedPaymentWindowSemantic.userPreferred,
          source: ExpectedExpenseDateSource.explicit,
          confidence: ExpectedTemporalConfidence.high,
        ),
      );

      expect(occurrence.expectedIssueDate, DateTime(2026, 10, 23));
      expect(occurrence.expectedDueDate, DateTime(2026, 11, 14));
      expect(occurrence.expectedPaymentWindow!.end, DateTime(2026, 11, 13));
    });

    test('requires a source exactly when its expected date is present', () {
      expect(
        () => ExpectedExpenseOccurrence(
          occurrenceId: 'occurrence_missing_source',
          relationshipId: 'relationship_1',
          status: ExpectedExpenseOccurrenceStatus.pending,
          expectedIssueDate: DateTime(2026, 10, 23),
          expectedAmount: 10,
          estimationMethod: ExpenseEstimationMethod.manualEstimate,
          confidence: ExpenseEstimateConfidence.low,
          provisional: true,
          expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
            method: FinancePaymentMethod.manual,
          ),
          expectedSubject: FinanceSubject.matteo,
        ),
        throwsArgumentError,
      );
      expect(
        () => _occurrence(
          expectedIssueDate: null,
          omitDefaultIssueDate: true,
          issueDateSource: ExpectedExpenseDateSource.explicit,
        ),
        throwsArgumentError,
      );
    });

    test('parses legacy dated JSON without inventing temporal provenance', () {
      final json = _occurrence().toJson()..remove('expectedIssueDateSource');

      final restored = ExpectedExpenseOccurrence.fromJson(json);

      expect(
        restored.expectedIssueDateSource,
        ExpectedExpenseDateSource.legacyUnspecified,
      );
      expect(restored.toJson()['expectedIssueDateSource'], 'legacyUnspecified');
    });

    test('rejects invalid dates, evidence and required temporal context', () {
      expect(
        () => _occurrence(
          expectedIssueDate: DateTime(2026, 11, 15),
          expectedDueDate: DateTime(2026, 11, 14),
        ),
        throwsArgumentError,
      );
      expect(
        () => _occurrence(
          expectedIssueDate: null,
          expectedDueDate: null,
          omitDefaultIssueDate: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => _occurrence(evidence: const ['economic_fact_1', '']),
        throwsArgumentError,
      );
      expect(
        () =>
            _occurrence(evidence: const ['economic_fact_1', 'economic_fact_1']),
        throwsArgumentError,
      );
      expect(
        () => _occurrence(
          estimationMethod: ExpenseEstimationMethod.personalHistory,
          evidence: const [],
        ),
        throwsArgumentError,
      );
    });

    test('rejects malformed JSON and unknown enum values', () {
      final valid = _occurrence().toJson();
      for (final invalid in <Map<String, dynamic>>[
        {...valid}..remove('occurrenceId'),
        {...valid, 'status': 'forecast'},
        {...valid, 'estimationMethod': 'guess'},
        {...valid, 'confidence': 'certain'},
        {...valid, 'evidenceEconomicFactIds': 'economic_fact_1'},
        {...valid, 'expectedPaymentConfiguration': 'rid'},
      ]) {
        expect(
          () => ExpectedExpenseOccurrence.fromJson(invalid),
          throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
        );
      }
    });

    test(
      'occurrence identity is independent from relationship and real fact IDs',
      () {
        final pending = _occurrence(
          occurrenceId: 'occurrence_independent',
          relationshipId: 'relationship_independent',
          evidence: const ['economic_fact_evidence'],
        );
        final resolved = _occurrence(
          occurrenceId: 'occurrence_independent',
          relationshipId: 'relationship_independent',
          status: ExpectedExpenseOccurrenceStatus.resolved,
          resolvedEconomicFactId: 'economic_fact_resolution',
        );

        expect(pending.occurrenceId, isNot(pending.relationshipId));
        expect(
          pending.occurrenceId,
          isNot(pending.evidenceEconomicFactIds.single),
        );
        expect(resolved.occurrenceId, isNot(resolved.resolvedEconomicFactId));
      },
    );
  });
}

ExpectedExpenseOccurrence _occurrence({
  String occurrenceId = 'occurrence_1',
  String relationshipId = 'relationship_1',
  ExpectedExpenseOccurrenceStatus status =
      ExpectedExpenseOccurrenceStatus.pending,
  DateTime? expectedIssueDate,
  ExpectedExpenseDateSource? issueDateSource,
  DateTime? expectedDueDate,
  ExpectedExpenseDateSource? expectedDueDateSource,
  ExpectedPaymentWindow? paymentWindow,
  bool omitDefaultIssueDate = false,
  double expectedAmount = 59.63,
  ExpenseEstimationMethod estimationMethod =
      ExpenseEstimationMethod.firstAvailableFact,
  List<String> evidence = const ['economic_fact_first'],
  ExpenseEstimateConfidence confidence = ExpenseEstimateConfidence.low,
  bool provisional = true,
  ExpenseRelationshipPaymentConfiguration? payment,
  FinanceSubject subject = FinanceSubject.matteo,
  String? resolvedEconomicFactId,
}) => ExpectedExpenseOccurrence(
  occurrenceId: occurrenceId,
  relationshipId: relationshipId,
  status: status,
  expectedIssueDate: omitDefaultIssueDate
      ? expectedIssueDate
      : expectedIssueDate ?? DateTime(2026, 10, 23),
  expectedIssueDateSource:
      issueDateSource ??
      (omitDefaultIssueDate && expectedIssueDate == null
          ? null
          : ExpectedExpenseDateSource.explicit),
  expectedDueDate: expectedDueDate,
  expectedDueDateSource: expectedDueDateSource,
  expectedPaymentWindow: paymentWindow,
  expectedAmount: expectedAmount,
  estimationMethod: estimationMethod,
  evidenceEconomicFactIds: evidence,
  confidence: confidence,
  provisional: provisional,
  expectedPaymentConfiguration:
      payment ??
      ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.manual,
      ),
  expectedSubject: subject,
  resolvedEconomicFactId: resolvedEconomicFactId,
);
