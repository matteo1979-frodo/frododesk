import 'expected_expense_projection.dart';

enum FutureExpenseEconomicImpactPlacement {
  plannedEconomicImpact,
  expectedDebitWindow,
  insufficient,
}

enum FutureExpenseDisplayPlacement {
  plannedEconomicImpact,
  expectedDebitWindow,
  dueDateFallback,
  unplaced,
}

enum FutureExpenseOverdueQualification {
  notOverdue,
  overdueKnown,
  overdueEstimated,
  overdueUnspecifiedCertainty,
}

/// Read-only qualification of one open expected expense.
///
/// The complete source projection remains authoritative. Derived fields only
/// describe economic placement and overdue qualification for a supplied
/// reference time.
class FutureExpenseProjection {
  final ExpectedExpenseProjection source;
  final FutureExpenseEconomicImpactPlacement economicImpactPlacement;
  final DateTime? economicImpactStart;
  final DateTime? economicImpactEnd;
  final FutureExpenseDisplayPlacement displayPlacement;
  final DateTime? displayStart;
  final DateTime? displayEnd;
  final FutureExpenseOverdueQualification overdueQualification;

  const FutureExpenseProjection({
    required this.source,
    required this.economicImpactPlacement,
    required this.economicImpactStart,
    required this.economicImpactEnd,
    required this.displayPlacement,
    required this.displayStart,
    required this.displayEnd,
    required this.overdueQualification,
  });

  String get occurrenceId => source.occurrenceId;
  String get relationshipId => source.relationshipId;

  bool get requiresPlanning =>
      displayPlacement == FutureExpenseDisplayPlacement.dueDateFallback ||
      displayPlacement == FutureExpenseDisplayPlacement.unplaced;
}
