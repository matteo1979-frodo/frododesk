import 'expected_expense_projection.dart';

enum FutureExpenseEconomicImpactPlacement {
  plannedEconomicImpact,
  expectedDebitWindow,
  insufficient,
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
  final FutureExpenseOverdueQualification overdueQualification;

  const FutureExpenseProjection({
    required this.source,
    required this.economicImpactPlacement,
    required this.economicImpactStart,
    required this.economicImpactEnd,
    required this.overdueQualification,
  });

  String get occurrenceId => source.occurrenceId;
  String get relationshipId => source.relationshipId;
}
