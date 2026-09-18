import 'dart:convert';

import '../../models/expense_relationship.dart';
import '../../models/first_cycle_expense_evidence.dart';
import '../../stores/finance_store.dart';
import 'expected_expense_persistence.dart';
import 'first_cycle_expected_expense_generator.dart';

enum ExpectedExpenseRegistrationOutcome { created, recovered, unchanged }

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

  bool _equivalent(Map<String, dynamic> left, Map<String, dynamic> right) =>
      jsonEncode(left) == jsonEncode(right);
}
