import 'dart:convert';

import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../stores/finance_store.dart';
import 'expected_expense_persistence.dart';

enum ExpectedExpenseUpdateOutcome {
  applied,
  unchanged,
  missingRelationship,
  missingOccurrence,
  identityMismatch,
}

/// Replaces existing expected-expense entities through one verified aggregate
/// save. Candidates must carry the same structural identities as current data.
class ExpectedExpenseUpdateCoordinator {
  final FinanceStore financeStore;

  const ExpectedExpenseUpdateCoordinator({required this.financeStore});

  Future<ExpectedExpenseUpdateOutcome> updateRelationship({
    required String relationshipId,
    required ExpenseRelationship candidate,
  }) async {
    final current = financeStore.expectedExpenseAggregate;
    final index = current.relationships.indexWhere(
      (item) => item.relationshipId == relationshipId,
    );
    if (index < 0) return ExpectedExpenseUpdateOutcome.missingRelationship;
    if (candidate.relationshipId != relationshipId) {
      return ExpectedExpenseUpdateOutcome.identityMismatch;
    }
    if (_equivalent(current.relationships[index], candidate)) {
      return ExpectedExpenseUpdateOutcome.unchanged;
    }

    final relationships = current.relationships.toList();
    relationships[index] = candidate;
    await financeStore.saveExpectedExpenseAggregate(
      ExpectedExpenseAggregate(
        relationships: relationships,
        occurrences: current.occurrences,
      ),
    );
    return ExpectedExpenseUpdateOutcome.applied;
  }

  Future<ExpectedExpenseUpdateOutcome> updateOccurrence({
    required String occurrenceId,
    required ExpectedExpenseOccurrence candidate,
  }) async {
    final current = financeStore.expectedExpenseAggregate;
    final index = current.occurrences.indexWhere(
      (item) => item.occurrenceId == occurrenceId,
    );
    if (index < 0) return ExpectedExpenseUpdateOutcome.missingOccurrence;
    final existing = current.occurrences[index];
    if (candidate.occurrenceId != occurrenceId ||
        candidate.relationshipId != existing.relationshipId ||
        !current.relationships.any(
          (item) => item.relationshipId == candidate.relationshipId,
        )) {
      return ExpectedExpenseUpdateOutcome.identityMismatch;
    }
    if (_equivalent(existing, candidate)) {
      return ExpectedExpenseUpdateOutcome.unchanged;
    }

    final occurrences = current.occurrences.toList();
    occurrences[index] = candidate;
    await financeStore.saveExpectedExpenseAggregate(
      ExpectedExpenseAggregate(
        relationships: current.relationships,
        occurrences: occurrences,
      ),
    );
    return ExpectedExpenseUpdateOutcome.applied;
  }

  Future<ExpectedExpenseUpdateOutcome> updateRelationshipAndOccurrence({
    required String relationshipId,
    required ExpenseRelationship relationshipCandidate,
    required String occurrenceId,
    required ExpectedExpenseOccurrence occurrenceCandidate,
  }) async {
    final current = financeStore.expectedExpenseAggregate;
    final relationshipIndex = current.relationships.indexWhere(
      (item) => item.relationshipId == relationshipId,
    );
    if (relationshipIndex < 0) {
      return ExpectedExpenseUpdateOutcome.missingRelationship;
    }
    final occurrenceIndex = current.occurrences.indexWhere(
      (item) => item.occurrenceId == occurrenceId,
    );
    if (occurrenceIndex < 0) {
      return ExpectedExpenseUpdateOutcome.missingOccurrence;
    }
    final existingOccurrence = current.occurrences[occurrenceIndex];
    if (relationshipCandidate.relationshipId != relationshipId ||
        occurrenceCandidate.occurrenceId != occurrenceId ||
        existingOccurrence.relationshipId != relationshipId ||
        occurrenceCandidate.relationshipId != relationshipId) {
      return ExpectedExpenseUpdateOutcome.identityMismatch;
    }

    final relationshipChanged = !_equivalent(
      current.relationships[relationshipIndex],
      relationshipCandidate,
    );
    final occurrenceChanged = !_equivalent(
      existingOccurrence,
      occurrenceCandidate,
    );
    if (!relationshipChanged && !occurrenceChanged) {
      return ExpectedExpenseUpdateOutcome.unchanged;
    }

    final relationships = current.relationships.toList();
    relationships[relationshipIndex] = relationshipCandidate;
    final occurrences = current.occurrences.toList();
    occurrences[occurrenceIndex] = occurrenceCandidate;
    await financeStore.saveExpectedExpenseAggregate(
      ExpectedExpenseAggregate(
        relationships: relationships,
        occurrences: occurrences,
      ),
    );
    return ExpectedExpenseUpdateOutcome.applied;
  }

  bool _equivalent(Object left, Object right) {
    final leftJson = switch (left) {
      ExpenseRelationship value => value.toJson(),
      ExpectedExpenseOccurrence value => value.toJson(),
      _ => throw ArgumentError.value(left, 'left'),
    };
    final rightJson = switch (right) {
      ExpenseRelationship value => value.toJson(),
      ExpectedExpenseOccurrence value => value.toJson(),
      _ => throw ArgumentError.value(right, 'right'),
    };
    return jsonEncode(leftJson) == jsonEncode(rightJson);
  }
}
