import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/expected_expense_reader.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/manual_payment_preference.dart';

void main() {
  const reader = ExpectedExpenseReader();

  test(
    'joins only by relationshipId and preserves the complete projection',
    () {
      final relationship = _relationship(
        id: 'relationship_target',
        service: 'Energia',
        provider: 'Provider corrente',
        subject: FinanceSubject.matteo,
        status: ExpenseRelationshipStatus.terminated,
        method: FinancePaymentMethod.bankTransfer,
        balanceId: 'balance_current',
      );
      final occurrence = _occurrence(
        id: 'occurrence_target',
        relationshipId: relationship.relationshipId,
        status: ExpectedExpenseOccurrenceStatus.resolved,
        knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
        knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
        expectedSubject: FinanceSubject.chiara,
        method: FinancePaymentMethod.rid,
        balanceId: 'balance_expected',
        resolvedEconomicFactId: 'economic_fact_resolved',
        issueDate: DateTime(2026, 10, 4),
        dueDate: DateTime(2026, 10, 18),
        paymentWindow: ExpectedPaymentWindow(
          start: DateTime(2026, 10, 12),
          end: DateTime(2026, 10, 18),
          semantic: ExpectedPaymentWindowSemantic.expectedDebit,
          source: ExpectedExpenseDateSource.explicit,
          confidence: ExpectedTemporalConfidence.high,
          origin: ExpectedPaymentWindowOrigin.occurrenceOverride,
        ),
      );
      final aggregate = ExpectedExpenseAggregate(
        relationships: [
          _relationship(
            id: 'relationship_decoy',
            service: relationship.service,
            provider: relationship.provider,
            subject: relationship.subject,
          ),
          relationship,
        ],
        occurrences: [occurrence],
      );

      final projection = reader.read(aggregate).single;

      expect(projection.occurrenceId, occurrence.occurrenceId);
      expect(projection.relationshipId, relationship.relationshipId);
      expect(projection.service, 'Energia');
      expect(projection.provider, 'Provider corrente');
      expect(
        projection.relationshipStatus,
        ExpenseRelationshipStatus.terminated,
      );
      expect(projection.periodicity.type, FinanceRecurringType.monthly);
      expect(projection.relationshipSubject, FinanceSubject.matteo);
      expect(projection.expectedSubject, FinanceSubject.chiara);
      expect(
        projection.relationshipPaymentConfiguration.method,
        FinancePaymentMethod.bankTransfer,
      );
      expect(
        projection.relationshipPaymentConfiguration.expectedBalanceId,
        'balance_current',
      );
      expect(
        projection.expectedPaymentConfiguration.method,
        FinancePaymentMethod.rid,
      );
      expect(
        projection.expectedPaymentConfiguration.expectedBalanceId,
        'balance_expected',
      );
      expect(projection.manualPaymentPreference?.preferredStartDayOfMonth, 5);
      expect(projection.expectedAmount, 123.45);
      expect(projection.provisional, isTrue);
      expect(projection.confidence, ExpenseEstimateConfidence.medium);
      expect(
        projection.estimationMethod,
        ExpenseEstimationMethod.personalHistory,
      );
      expect(projection.evidenceEconomicFactIds, ['fact_a', 'fact_b']);
      expect(projection.expectedIssueDate, DateTime(2026, 10, 4));
      expect(
        projection.expectedIssueDateSource,
        ExpectedExpenseDateSource.explicit,
      );
      expect(projection.expectedDueDate, DateTime(2026, 10, 18));
      expect(
        projection.expectedDueDateSource,
        ExpectedExpenseDateSource.calculatedFromPeriodicity,
      );
      expect(
        projection.expectedDueDateCertainty,
        ExpectedExpenseDateCertainty.known,
      );
      expect(projection.expectedPaymentWindow?.start, DateTime(2026, 10, 12));
      expect(projection.status, ExpectedExpenseOccurrenceStatus.resolved);
      expect(
        projection.knowledgeState,
        ExpectedExpenseKnowledgeState.knownUnpaid,
      );
      expect(
        projection.knowledgeSource,
        ExpectedExpenseKnowledgeSource.userConfirmed,
      );
      expect(projection.resolvedEconomicFactId, 'economic_fact_resolved');
    },
  );

  test(
    'preserves issue, due and payment-window temporal shapes separately',
    () {
      final relationship = _relationship(id: 'relationship_1');
      final window = ExpectedPaymentWindow(
        start: DateTime(2026, 12, 10),
        end: DateTime(2026, 12, 14),
      );
      final occurrences = [
        _occurrence(
          id: 'issue_only',
          relationshipId: relationship.relationshipId,
          issueDate: DateTime(2026, 10, 1),
        ),
        _occurrence(
          id: 'due_only',
          relationshipId: relationship.relationshipId,
          dueDate: DateTime(2026, 11, 2),
        ),
        _occurrence(
          id: 'window_only',
          relationshipId: relationship.relationshipId,
          paymentWindow: window,
        ),
        _occurrence(
          id: 'all_temporal_fields',
          relationshipId: relationship.relationshipId,
          issueDate: DateTime(2026, 12, 1),
          dueDate: DateTime(2026, 12, 14),
          paymentWindow: window,
        ),
      ];

      final projections = reader.read(
        ExpectedExpenseAggregate(
          relationships: [relationship],
          occurrences: occurrences,
        ),
      );

      expect(projections.map((item) => item.occurrenceId), [
        'issue_only',
        'due_only',
        'window_only',
        'all_temporal_fields',
      ]);
      expect(projections[0].expectedIssueDate, DateTime(2026, 10, 1));
      expect(projections[0].expectedDueDate, isNull);
      expect(projections[0].expectedPaymentWindow, isNull);
      expect(projections[1].expectedIssueDate, isNull);
      expect(projections[1].expectedDueDate, DateTime(2026, 11, 2));
      expect(projections[1].expectedPaymentWindow, isNull);
      expect(projections[2].expectedIssueDate, isNull);
      expect(projections[2].expectedDueDate, isNull);
      expect(projections[2].expectedPaymentWindow, same(window));
      expect(projections[3].expectedIssueDate, DateTime(2026, 12, 1));
      expect(projections[3].expectedDueDate, DateTime(2026, 12, 14));
      expect(projections[3].expectedPaymentWindow, same(window));
    },
  );

  test('preserves lifecycle and knowledge states without filtering', () {
    final relationship = _relationship(id: 'relationship_1');
    final projections = reader.read(
      ExpectedExpenseAggregate(
        relationships: [relationship],
        occurrences: [
          _occurrence(
            id: 'pending_forecast',
            relationshipId: relationship.relationshipId,
          ),
          _occurrence(
            id: 'resolved_known',
            relationshipId: relationship.relationshipId,
            status: ExpectedExpenseOccurrenceStatus.resolved,
            knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
            knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
            resolvedEconomicFactId: 'fact_resolved',
          ),
          _occurrence(
            id: 'cancelled_forecast',
            relationshipId: relationship.relationshipId,
            status: ExpectedExpenseOccurrenceStatus.cancelled,
          ),
        ],
      ),
    );

    expect(projections, hasLength(3));
    expect(projections[0].status, ExpectedExpenseOccurrenceStatus.pending);
    expect(
      projections[0].knowledgeState,
      ExpectedExpenseKnowledgeState.forecast,
    );
    expect(projections[1].status, ExpectedExpenseOccurrenceStatus.resolved);
    expect(
      projections[1].knowledgeState,
      ExpectedExpenseKnowledgeState.knownUnpaid,
    );
    expect(projections[2].status, ExpectedExpenseOccurrenceStatus.cancelled);
  });

  test('fails explicitly when the relationship is missing', () {
    final aggregate = ExpectedExpenseAggregate(
      occurrences: [
        _occurrence(id: 'orphan', relationshipId: 'missing_relationship'),
      ],
    );

    expect(
      () => reader.read(aggregate),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('orphan'),
        ),
      ),
    );
  });

  test('does not mutate sources and returns immutable collections', () {
    final relationship = _relationship(id: 'relationship_1');
    final occurrence = _occurrence(
      id: 'occurrence_1',
      relationshipId: relationship.relationshipId,
    );
    final aggregate = ExpectedExpenseAggregate(
      relationships: [relationship],
      occurrences: [occurrence],
    );
    final relationshipBefore = relationship.toJson();
    final occurrenceBefore = occurrence.toJson();

    final projections = reader.read(aggregate);

    expect(relationship.toJson(), relationshipBefore);
    expect(occurrence.toJson(), occurrenceBefore);
    expect(() => projections.add(projections.single), throwsUnsupportedError);
    expect(
      () => projections.single.evidenceEconomicFactIds.add('new_fact'),
      throwsUnsupportedError,
    );
  });
}

ExpenseRelationship _relationship({
  required String id,
  String service = 'Servizio',
  String provider = 'Provider',
  FinanceSubject subject = FinanceSubject.matteo,
  ExpenseRelationshipStatus status = ExpenseRelationshipStatus.active,
  FinancePaymentMethod method = FinancePaymentMethod.manual,
  String? balanceId,
}) => ExpenseRelationship(
  relationshipId: id,
  service: service,
  provider: provider,
  subject: subject,
  status: status,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.monthly,
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: method,
    expectedBalanceId: balanceId,
  ),
  manualPaymentPreference: ManualPaymentPreference(preferredStartDayOfMonth: 5),
);

ExpectedExpenseOccurrence _occurrence({
  required String id,
  required String relationshipId,
  ExpectedExpenseOccurrenceStatus status =
      ExpectedExpenseOccurrenceStatus.pending,
  ExpectedExpenseKnowledgeState knowledgeState =
      ExpectedExpenseKnowledgeState.forecast,
  ExpectedExpenseKnowledgeSource knowledgeSource =
      ExpectedExpenseKnowledgeSource.legacyUnspecified,
  FinanceSubject expectedSubject = FinanceSubject.matteo,
  FinancePaymentMethod method = FinancePaymentMethod.manual,
  String? balanceId,
  String? resolvedEconomicFactId,
  DateTime? issueDate,
  DateTime? dueDate,
  ExpectedPaymentWindow? paymentWindow,
}) => ExpectedExpenseOccurrence(
  occurrenceId: id,
  relationshipId: relationshipId,
  status: status,
  knowledgeState: knowledgeState,
  knowledgeSource: knowledgeSource,
  expectedIssueDate:
      issueDate ??
      (dueDate == null && paymentWindow == null ? DateTime(2026, 9, 1) : null),
  expectedIssueDateSource:
      issueDate != null || (dueDate == null && paymentWindow == null)
      ? ExpectedExpenseDateSource.explicit
      : null,
  expectedDueDate: dueDate,
  expectedDueDateSource: dueDate == null
      ? null
      : ExpectedExpenseDateSource.calculatedFromPeriodicity,
  expectedDueDateCertainty: dueDate == null
      ? null
      : ExpectedExpenseDateCertainty.known,
  expectedPaymentWindow: paymentWindow,
  expectedAmount: 123.45,
  estimationMethod: ExpenseEstimationMethod.personalHistory,
  evidenceEconomicFactIds: const ['fact_a', 'fact_b'],
  confidence: ExpenseEstimateConfidence.medium,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: method,
    expectedBalanceId: balanceId,
  ),
  expectedSubject: expectedSubject,
  resolvedEconomicFactId: resolvedEconomicFactId,
);
