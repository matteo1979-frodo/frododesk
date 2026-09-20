import 'dart:collection';

import 'expense_relationship.dart';
import 'expected_expense_occurrence.dart';
import 'finance_recurring_item.dart';
import 'manual_payment_preference.dart';

/// Immutable read model joining one expected occurrence to its relationship.
///
/// Temporal fields remain independent: this contract deliberately exposes no
/// dominant, fallback, "next", or "relevant" date.
class ExpectedExpenseProjection {
  final String occurrenceId;
  final String relationshipId;

  final String service;
  final String provider;
  final ExpenseRelationshipStatus relationshipStatus;
  final ExpenseRelationshipPeriodicity periodicity;
  final FinanceSubject relationshipSubject;
  final ExpenseRelationshipPaymentConfiguration
  relationshipPaymentConfiguration;
  final ManualPaymentPreference? manualPaymentPreference;

  final FinanceSubject expectedSubject;
  final ExpenseRelationshipPaymentConfiguration expectedPaymentConfiguration;

  final double expectedAmount;
  final bool provisional;
  final ExpenseEstimateConfidence confidence;
  final ExpenseEstimationMethod estimationMethod;
  final UnmodifiableListView<String> evidenceEconomicFactIds;

  final DateTime? expectedIssueDate;
  final ExpectedExpenseDateSource? expectedIssueDateSource;
  final DateTime? expectedDueDate;
  final ExpectedExpenseDateSource? expectedDueDateSource;
  final ExpectedExpenseDateCertainty? expectedDueDateCertainty;
  final ExpectedPaymentWindow? expectedPaymentWindow;

  final ExpectedExpenseOccurrenceStatus status;
  final ExpectedExpenseKnowledgeState knowledgeState;
  final ExpectedExpenseKnowledgeSource knowledgeSource;
  final String? resolvedEconomicFactId;

  ExpectedExpenseProjection({
    required this.occurrenceId,
    required this.relationshipId,
    required this.service,
    required this.provider,
    required this.relationshipStatus,
    required this.periodicity,
    required this.relationshipSubject,
    required this.relationshipPaymentConfiguration,
    required this.manualPaymentPreference,
    required this.expectedSubject,
    required this.expectedPaymentConfiguration,
    required this.expectedAmount,
    required this.provisional,
    required this.confidence,
    required this.estimationMethod,
    required Iterable<String> evidenceEconomicFactIds,
    required this.expectedIssueDate,
    required this.expectedIssueDateSource,
    required this.expectedDueDate,
    required this.expectedDueDateSource,
    required this.expectedDueDateCertainty,
    required this.expectedPaymentWindow,
    required this.status,
    required this.knowledgeState,
    required this.knowledgeSource,
    required this.resolvedEconomicFactId,
  }) : evidenceEconomicFactIds = UnmodifiableListView(
         List<String>.of(evidenceEconomicFactIds),
       );
}
