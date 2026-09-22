import '../../stores/finance_store.dart';
import 'expected_expense_persistence.dart';

enum LegacyExpenseCycleIdentityOutcome { assigned, unchanged }

class LegacyExpenseCycleIdentityConflict implements Exception {
  final String message;

  const LegacyExpenseCycleIdentityConflict(this.message);

  @override
  String toString() => 'LegacyExpenseCycleIdentityConflict: $message';
}

/// Explicitly assigns canonical cycle identity to one legacy occurrence.
///
/// No field of the occurrence is used to infer either identity component.
class LegacyExpenseCycleIdentityCoordinator {
  final FinanceStore financeStore;

  const LegacyExpenseCycleIdentityCoordinator({required this.financeStore});

  Future<LegacyExpenseCycleIdentityOutcome> assign({
    required String relationshipId,
    required String occurrenceId,
    required int cycleSequence,
    required DateTime cycleAnchor,
  }) async {
    if (cycleSequence <= 0) {
      throw ArgumentError.value(
        cycleSequence,
        'cycleSequence',
        'Must be greater than zero',
      );
    }

    final current = financeStore.expectedExpenseAggregate;
    if (!current.relationships.any(
      (item) => item.relationshipId == relationshipId,
    )) {
      throw LegacyExpenseCycleIdentityConflict(
        'Missing relationship $relationshipId',
      );
    }
    final index = current.occurrences.indexWhere(
      (item) => item.occurrenceId == occurrenceId,
    );
    if (index < 0) {
      throw LegacyExpenseCycleIdentityConflict(
        'Missing occurrence $occurrenceId',
      );
    }
    final occurrence = current.occurrences[index];
    if (occurrence.relationshipId != relationshipId) {
      throw LegacyExpenseCycleIdentityConflict(
        'Occurrence $occurrenceId does not belong to $relationshipId',
      );
    }
    if (occurrence.cycleSequence != null || occurrence.cycleAnchor != null) {
      if (occurrence.cycleSequence == cycleSequence &&
          occurrence.cycleAnchor == cycleAnchor) {
        return LegacyExpenseCycleIdentityOutcome.unchanged;
      }
      throw LegacyExpenseCycleIdentityConflict(
        'Occurrence $occurrenceId already has an incompatible cycle identity',
      );
    }
    for (final item in current.occurrences) {
      if (item.relationshipId != relationshipId ||
          item.occurrenceId == occurrenceId) {
        continue;
      }
      if (item.cycleSequence == cycleSequence) {
        throw LegacyExpenseCycleIdentityConflict(
          'Cycle sequence $cycleSequence already exists for $relationshipId',
        );
      }
      if (item.cycleAnchor == cycleAnchor) {
        throw LegacyExpenseCycleIdentityConflict(
          'Cycle anchor ${cycleAnchor.toIso8601String()} already exists for '
          '$relationshipId',
        );
      }
    }

    final occurrences = current.occurrences.toList();
    occurrences[index] = occurrence.copyWith(
      cycleSequence: cycleSequence,
      cycleAnchor: cycleAnchor,
    );
    await financeStore.saveExpectedExpenseAggregate(
      ExpectedExpenseAggregate(
        relationships: current.relationships,
        occurrences: occurrences,
      ),
    );
    return LegacyExpenseCycleIdentityOutcome.assigned;
  }
}
