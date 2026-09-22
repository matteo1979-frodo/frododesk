import '../../models/expected_expense_projection.dart';
import 'expected_expense_persistence.dart';

/// Pure read boundary for expected expenses.
///
/// It preserves aggregate occurrence order and performs no filtering,
/// sorting, persistence, financial mutation, or temporal fallback.
class ExpectedExpenseReader {
  const ExpectedExpenseReader();

  List<ExpectedExpenseProjection> read(ExpectedExpenseAggregate aggregate) {
    final relationshipsById = {
      for (final relationship in aggregate.relationships)
        relationship.relationshipId: relationship,
    };

    return List<ExpectedExpenseProjection>.unmodifiable(
      aggregate.occurrences.map((occurrence) {
        final relationship = relationshipsById[occurrence.relationshipId];
        if (relationship == null) {
          throw StateError(
            'Expected expense occurrence ${occurrence.occurrenceId} references '
            'missing relationship ${occurrence.relationshipId}',
          );
        }

        return ExpectedExpenseProjection(
          occurrenceId: occurrence.occurrenceId,
          relationshipId: occurrence.relationshipId,
          cycleSequence: occurrence.cycleSequence,
          cycleAnchor: occurrence.cycleAnchor,
          service: relationship.service,
          provider: relationship.provider,
          relationshipStatus: relationship.status,
          periodicity: relationship.periodicity,
          relationshipSubject: relationship.subject,
          relationshipPaymentConfiguration: relationship.paymentConfiguration,
          relationshipPaymentExecutionMode: relationship.paymentExecutionMode,
          manualPaymentPreference: relationship.manualPaymentPreference,
          expectedSubject: occurrence.expectedSubject,
          expectedPaymentConfiguration: occurrence.expectedPaymentConfiguration,
          occurrencePaymentExecutionMode: occurrence.paymentExecutionMode,
          expectedAmount: occurrence.expectedAmount,
          provisional: occurrence.provisional,
          confidence: occurrence.confidence,
          estimationMethod: occurrence.estimationMethod,
          evidenceEconomicFactIds: occurrence.evidenceEconomicFactIds,
          expectedIssueDate: occurrence.expectedIssueDate,
          expectedIssueDateSource: occurrence.expectedIssueDateSource,
          expectedDueDate: occurrence.expectedDueDate,
          expectedDueDateSource: occurrence.expectedDueDateSource,
          expectedDueDateCertainty: occurrence.expectedDueDateCertainty,
          expectedPaymentWindow: occurrence.expectedPaymentWindow,
          plannedEconomicImpact: occurrence.plannedEconomicImpact,
          status: occurrence.status,
          knowledgeState: occurrence.knowledgeState,
          knowledgeSource: occurrence.knowledgeSource,
          resolvedEconomicFactId: occurrence.resolvedEconomicFactId,
        );
      }),
    );
  }
}
