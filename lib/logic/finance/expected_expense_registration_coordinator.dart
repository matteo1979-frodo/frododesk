import 'dart:convert';

import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../models/first_cycle_expense_evidence.dart';
import '../../stores/finance_store.dart';
import 'expected_expense_persistence.dart';
import 'first_cycle_expected_expense_generator.dart';

enum ExpectedExpenseRegistrationOutcome { created, recovered, unchanged }

enum ExpectedExpenseManualRegistrationState {
  missing,
  equivalent,
  conflict,
}

class ExpectedExpenseRegistrationConflict implements Exception {
  final String message;

  const ExpectedExpenseRegistrationConflict(this.message);

  @override
  String toString() => 'ExpectedExpenseRegistrationConflict: $message';
}

/// Registers one continuing expense relationship together with its first
/// expected occurrence through the verified aggregate persistence boundary.
class ExpectedExpenseRegistrationCoordinator {
  final FinanceStore financeStore;
  final FirstCycleExpectedExpenseGenerator generator;

  const ExpectedExpenseRegistrationCoordinator({
    required this.financeStore,
    this.generator = const FirstCycleExpectedExpenseGenerator(),
  });

  /// Validates the canonical initial contract of a manually estimated first
  /// cycle. It deliberately requires no fabricated economic-fact evidence.
  static List<String> validateManualFirstOccurrence({
    required ExpenseRelationship relationship,
    required ExpectedExpenseOccurrence occurrence,
  }) {
    final errors = <String>[];
    if (relationship.status != ExpenseRelationshipStatus.active) {
      errors.add('The relationship must initially be active');
    }
    if (occurrence.relationshipId != relationship.relationshipId) {
      errors.add('Occurrence and relationship IDs do not match');
    }
    if (occurrence.cycleSequence != 1 || occurrence.cycleAnchor == null) {
      errors.add('The first occurrence must have cycle sequence 1 and an anchor');
    }
    if (occurrence.status != ExpectedExpenseOccurrenceStatus.pending) {
      errors.add('The first occurrence must initially be pending');
    }
    if (occurrence.resolvedEconomicFactId != null) {
      errors.add('The first occurrence cannot already be resolved');
    }
    if (occurrence.knowledgeState != ExpectedExpenseKnowledgeState.forecast ||
        occurrence.knowledgeSource !=
            ExpectedExpenseKnowledgeSource.legacyUnspecified) {
      errors.add('The first occurrence must initially be a forecast');
    }
    if (occurrence.estimationMethod !=
        ExpenseEstimationMethod.manualEstimate) {
      errors.add('The first occurrence must be a manual estimate');
    }
    if (occurrence.evidenceEconomicFactIds.isNotEmpty) {
      errors.add('A manual first occurrence cannot fabricate evidence');
    }
    if (occurrence.expectedSubject != relationship.subject) {
      errors.add('Occurrence and relationship subjects do not match');
    }
    if (occurrence.paymentExecutionMode !=
        relationship.paymentExecutionMode) {
      errors.add('Occurrence and relationship execution modes do not match');
    }
    if (!_equivalent(
      occurrence.expectedPaymentConfiguration.toJson(),
      relationship.paymentConfiguration.toJson(),
    )) {
      errors.add('Occurrence and relationship payment configurations differ');
    }

    final anchor = occurrence.cycleAnchor;
    final issue = occurrence.expectedIssueDate;
    final due = occurrence.expectedDueDate;
    final hasCanonicalIssue =
        issue != null && due == null && _sameDate(issue, anchor);
    final hasCanonicalDue =
        due != null && issue == null && _sameDate(due, anchor);
    if (!hasCanonicalIssue && !hasCanonicalDue) {
      errors.add(
        'The cycle anchor must equal the single initial issue or due date',
      );
    }
    return List.unmodifiable(errors);
  }

  ExpectedExpenseManualRegistrationState classifyManualEstimate({
    required ExpenseRelationship relationship,
    required ExpectedExpenseOccurrence occurrence,
  }) {
    if (validateManualFirstOccurrence(
      relationship: relationship,
      occurrence: occurrence,
    ).isNotEmpty) {
      return ExpectedExpenseManualRegistrationState.conflict;
    }
    final current = financeStore.expectedExpenseAggregate;
    final relationships = current.relationships
        .where((item) => item.relationshipId == relationship.relationshipId)
        .toList();
    final occurrences = current.occurrences
        .where((item) => item.occurrenceId == occurrence.occurrenceId)
        .toList();
    if (relationships.length > 1 || occurrences.length > 1) {
      return ExpectedExpenseManualRegistrationState.conflict;
    }
    final existingRelationship = relationships.firstOrNull;
    final existingOccurrence = occurrences.firstOrNull;
    if (existingRelationship != null &&
        !_equivalentInitialRelationship(existingRelationship, relationship)) {
      return ExpectedExpenseManualRegistrationState.conflict;
    }
    if (existingOccurrence != null &&
        !_equivalentInitialOccurrence(existingOccurrence, occurrence)) {
      return ExpectedExpenseManualRegistrationState.conflict;
    }
    if (existingRelationship == null || existingOccurrence == null) {
      return ExpectedExpenseManualRegistrationState.missing;
    }
    return ExpectedExpenseManualRegistrationState.equivalent;
  }

  Future<ExpectedExpenseRegistrationOutcome> registerManualEstimate({
    required ExpenseRelationship relationship,
    required ExpectedExpenseOccurrence occurrence,
  }) async {
    final errors = validateManualFirstOccurrence(
      relationship: relationship,
      occurrence: occurrence,
    );
    if (errors.isNotEmpty) {
      throw ExpectedExpenseRegistrationConflict(errors.join('; '));
    }
    final state = classifyManualEstimate(
      relationship: relationship,
      occurrence: occurrence,
    );
    if (state == ExpectedExpenseManualRegistrationState.conflict) {
      throw ExpectedExpenseRegistrationConflict(
        'Manual first occurrence has incompatible persisted data',
      );
    }
    if (state == ExpectedExpenseManualRegistrationState.equivalent) {
      return ExpectedExpenseRegistrationOutcome.unchanged;
    }

    final current = financeStore.expectedExpenseAggregate;
    final relationshipExists = current.relationships.any(
      (item) => item.relationshipId == relationship.relationshipId,
    );
    final occurrenceExists = current.occurrences.any(
      (item) => item.occurrenceId == occurrence.occurrenceId,
    );
    await financeStore.saveExpectedExpenseAggregate(
      ExpectedExpenseAggregate(
        relationships: [
          ...current.relationships,
          if (!relationshipExists) relationship,
        ],
        occurrences: [
          ...current.occurrences,
          if (!occurrenceExists) occurrence,
        ],
      ),
    );
    return relationshipExists
        ? ExpectedExpenseRegistrationOutcome.recovered
        : ExpectedExpenseRegistrationOutcome.created;
  }

  Future<ExpectedExpenseRegistrationOutcome> register({
    required ExpenseRelationship relationship,
    required FirstCycleExpenseEvidence evidence,
    required String occurrenceId,
    DateTime? explicitNextDate,
  }) async {
    final current = financeStore.expectedExpenseAggregate;
    final existingRelationship = current.relationships
        .where((item) => item.relationshipId == relationship.relationshipId)
        .firstOrNull;
    final existingOccurrence = current.occurrences
        .where((item) => item.occurrenceId == occurrenceId)
        .firstOrNull;

    if (existingRelationship == null && existingOccurrence != null) {
      throw ExpectedExpenseRegistrationConflict(
        'Occurrence $occurrenceId exists without relationship '
        '${relationship.relationshipId}',
      );
    }
    if (existingRelationship != null &&
        !_equivalent(existingRelationship.toJson(), relationship.toJson())) {
      throw ExpectedExpenseRegistrationConflict(
        'Relationship ${relationship.relationshipId} has incompatible data',
      );
    }

    final generated = generator.generate(
      relationship: relationship,
      evidence: evidence,
      occurrenceId: occurrenceId,
      explicitNextDate: explicitNextDate,
    );
    if (existingOccurrence != null &&
        !_equivalent(existingOccurrence.toJson(), generated.toJson())) {
      throw ExpectedExpenseRegistrationConflict(
        'Occurrence $occurrenceId has incompatible data',
      );
    }
    if (existingRelationship != null && existingOccurrence != null) {
      return ExpectedExpenseRegistrationOutcome.unchanged;
    }

    final candidate = ExpectedExpenseAggregate(
      relationships: [
        ...current.relationships,
        if (existingRelationship == null) relationship,
      ],
      occurrences: [
        ...current.occurrences,
        if (existingOccurrence == null) generated,
      ],
    );
    await financeStore.saveExpectedExpenseAggregate(candidate);
    return existingRelationship == null
        ? ExpectedExpenseRegistrationOutcome.created
        : ExpectedExpenseRegistrationOutcome.recovered;
  }

  static bool _equivalent(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) =>
      jsonEncode(left) == jsonEncode(right);

  static bool _equivalentInitialRelationship(
    ExpenseRelationship actual,
    ExpenseRelationship desired,
  ) =>
      actual.relationshipId == desired.relationshipId &&
      actual.service == desired.service &&
      actual.provider == desired.provider &&
      actual.subject == desired.subject &&
      _equivalent(actual.periodicity.toJson(), desired.periodicity.toJson()) &&
      _equivalent(
        actual.paymentConfiguration.toJson(),
        desired.paymentConfiguration.toJson(),
      ) &&
      actual.paymentExecutionMode == desired.paymentExecutionMode;

  static bool _equivalentInitialOccurrence(
    ExpectedExpenseOccurrence actual,
    ExpectedExpenseOccurrence desired,
  ) =>
      actual.occurrenceId == desired.occurrenceId &&
      actual.relationshipId == desired.relationshipId &&
      actual.cycleSequence == desired.cycleSequence &&
      _sameDate(actual.cycleAnchor, desired.cycleAnchor) &&
      actual.expectedAmount == desired.expectedAmount &&
      _sameDate(actual.expectedIssueDate, desired.expectedIssueDate) &&
      actual.expectedIssueDateSource == desired.expectedIssueDateSource &&
      _sameDate(actual.expectedDueDate, desired.expectedDueDate) &&
      actual.expectedDueDateSource == desired.expectedDueDateSource &&
      actual.expectedDueDateCertainty == desired.expectedDueDateCertainty &&
      _sameOptionalJson(
        actual.expectedPaymentWindow?.toJson(),
        desired.expectedPaymentWindow?.toJson(),
      ) &&
      _sameOptionalJson(
        actual.plannedEconomicImpact?.toJson(),
        desired.plannedEconomicImpact?.toJson(),
      ) &&
      actual.expectedSubject == desired.expectedSubject &&
      actual.paymentExecutionMode == desired.paymentExecutionMode &&
      _equivalent(
        actual.expectedPaymentConfiguration.toJson(),
        desired.expectedPaymentConfiguration.toJson(),
      ) &&
      actual.estimationMethod == desired.estimationMethod &&
      _sameStringList(
        actual.evidenceEconomicFactIds,
        desired.evidenceEconomicFactIds,
      ) &&
      actual.confidence == desired.confidence &&
      actual.provisional == desired.provisional;

  static bool _sameDate(DateTime? left, DateTime? right) =>
      left == null || right == null
      ? left == right
      : left.isAtSameMomentAs(right);

  static bool _sameOptionalJson(
    Map<String, dynamic>? left,
    Map<String, dynamic>? right,
  ) =>
      left == null || right == null
      ? left == right
      : _equivalent(left, right);

  static bool _sameStringList(Iterable<String> left, Iterable<String> right) =>
      jsonEncode(left.toList()) == jsonEncode(right.toList());
}
