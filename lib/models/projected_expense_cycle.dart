import 'expense_relationship.dart';
import 'documentary_obligation.dart';
import 'finance_recurring_item.dart';

class ExpenseCycleIdentity {
  final String relationshipId;
  final int cycleSequence;

  const ExpenseCycleIdentity({
    required this.relationshipId,
    required this.cycleSequence,
  });

  String get value => '$relationshipId#$cycleSequence';
}

/// Read-only forecast for one canonical cycle of an expense relationship.
/// It is neither persisted nor an economic fact.
class ProjectedExpenseCycle {
  final ExpenseCycleIdentity identity;
  final DateTime? cycleAnchor;
  final ExpectedDocumentPeriod? expectedPeriod;
  final String sourceOccurrenceId;
  final String service;
  final String provider;
  final double expectedAmount;
  final FinanceSubject expectedSubject;
  final ExpenseRelationshipPaymentConfiguration expectedPaymentConfiguration;
  final PaymentExecutionMode paymentExecutionMode;
  final bool provisional;

  ProjectedExpenseCycle({
    required this.identity,
    this.cycleAnchor,
    this.expectedPeriod,
    required this.sourceOccurrenceId,
    required this.service,
    required this.provider,
    required this.expectedAmount,
    required this.expectedSubject,
    required this.expectedPaymentConfiguration,
    required this.paymentExecutionMode,
    required this.provisional,
  }) {
    if ((cycleAnchor == null) == (expectedPeriod == null)) {
      throw ArgumentError(
        'Exactly one of cycleAnchor and expectedPeriod is required',
      );
    }
  }
}

class ExpenseProjectionHorizon {
  final DateTime start;
  final DateTime end;

  ExpenseProjectionHorizon({required this.start, required this.end}) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'Must not be before start');
    }
  }

  bool contains(DateTime value) =>
      !value.isBefore(start) && !value.isAfter(end);
}
