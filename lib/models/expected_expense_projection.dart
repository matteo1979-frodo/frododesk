import 'dart:collection';

import 'expense_relationship.dart';
import 'documentary_obligation.dart';
import 'expected_expense_occurrence.dart';
import 'finance_recurring_item.dart';
import 'manual_payment_preference.dart';
import 'planned_economic_impact.dart';

/// Immutable read model joining one expected occurrence to its relationship.
///
/// Temporal fields remain independent: this contract deliberately exposes no
/// dominant, fallback, "next", or "relevant" date.
class ExpectedExpenseProjection {
  final String occurrenceId;
  final String relationshipId;
  final int? cycleSequence;
  final DateTime? cycleAnchor;
  final ExpectedDocumentPeriod? expectedPeriod;

  final String service;
  final String provider;
  final ExpenseRelationshipStatus relationshipStatus;
  final ExpenseRelationshipPeriodicity periodicity;
  final ExpenseRelationshipCycleLabelPolicy cycleLabelPolicy;
  final FinanceSubject relationshipSubject;
  final ExpenseRelationshipPaymentConfiguration
  relationshipPaymentConfiguration;
  final PaymentExecutionMode relationshipPaymentExecutionMode;
  final ManualPaymentPreference? manualPaymentPreference;

  final FinanceSubject expectedSubject;
  final ExpenseRelationshipPaymentConfiguration expectedPaymentConfiguration;
  final PaymentExecutionMode occurrencePaymentExecutionMode;

  final double expectedAmount;
  final bool provisional;
  final ExpenseEstimateConfidence confidence;
  final ExpenseEstimationMethod estimationMethod;
  final String? sourceDocumentaryObligationId;
  final UnmodifiableListView<String> evidenceEconomicFactIds;

  final DateTime? expectedIssueDate;
  final ExpectedExpenseDateSource? expectedIssueDateSource;
  final DateTime? expectedDueDate;
  final ExpectedExpenseDateSource? expectedDueDateSource;
  final ExpectedExpenseDateCertainty? expectedDueDateCertainty;
  final ExpectedPaymentWindow? expectedPaymentWindow;
  final PlannedEconomicImpact? plannedEconomicImpact;

  final ExpectedExpenseOccurrenceStatus status;
  final ExpectedExpenseKnowledgeState knowledgeState;
  final ExpectedExpenseKnowledgeSource knowledgeSource;
  final String? resolvedEconomicFactId;

  ExpectedExpenseProjection({
    required this.occurrenceId,
    required this.relationshipId,
    required this.cycleSequence,
    required this.cycleAnchor,
    this.expectedPeriod,
    required this.service,
    required this.provider,
    required this.relationshipStatus,
    required this.periodicity,
    this.cycleLabelPolicy =
        ExpenseRelationshipCycleLabelPolicy.stableNameOnly,
    required this.relationshipSubject,
    required this.relationshipPaymentConfiguration,
    required this.relationshipPaymentExecutionMode,
    required this.manualPaymentPreference,
    required this.expectedSubject,
    required this.expectedPaymentConfiguration,
    required this.occurrencePaymentExecutionMode,
    required this.expectedAmount,
    required this.provisional,
    required this.confidence,
    required this.estimationMethod,
    this.sourceDocumentaryObligationId,
    required Iterable<String> evidenceEconomicFactIds,
    required this.expectedIssueDate,
    required this.expectedIssueDateSource,
    required this.expectedDueDate,
    required this.expectedDueDateSource,
    required this.expectedDueDateCertainty,
    required this.expectedPaymentWindow,
    required this.plannedEconomicImpact,
    required this.status,
    required this.knowledgeState,
    required this.knowledgeSource,
    required this.resolvedEconomicFactId,
  }) : evidenceEconomicFactIds = UnmodifiableListView(
         List<String>.of(evidenceEconomicFactIds),
       );
}
