import 'dart:collection';

import 'documentary_obligation.dart';
import 'finance_recurring_item.dart';
import 'future_outflow_presentation.dart';

enum FinanceForecastDirection { outflow }

enum FinanceForecastTemporalKnowledge {
  economicDateKnown,
  economicWindowKnown,
  economicPeriodKnown,
  documentPeriodOnly,
  unlocated,
}

enum FinanceForecastCertainty { known, estimated, projected, unspecified }

/// Immutable, non-persisted financial forecast row.
class FinanceForecastPresentation {
  final String identity;
  final FinanceForecastDirection direction;
  final String label;
  final double amount;
  final FinanceSubject? subject;
  final FinanceForecastTemporalKnowledge temporalKnowledge;
  final DateTime? economicStart;
  final DateTime? economicEnd;
  final ExpectedDocumentPeriod? economicPeriod;
  final ExpectedDocumentPeriod? documentaryPeriod;
  final FinanceForecastCertainty certainty;
  final bool provisional;
  final FutureOutflowAuthority authority;
  final FutureOutflowDatePresentation provenance;
  final String? relationshipId;
  final int? cycleSequence;
  final String? occurrenceId;
  final String? obligationId;
  final String? documentaryInstallmentId;
  final String? planId;
  final int? installmentNumber;
  final String? economicFactId;
  final bool requiresUserAction;
  final bool requiresPlanning;

  const FinanceForecastPresentation({
    required this.identity,
    this.direction = FinanceForecastDirection.outflow,
    required this.label,
    required this.amount,
    required this.subject,
    required this.temporalKnowledge,
    required this.economicStart,
    required this.economicEnd,
    required this.economicPeriod,
    required this.documentaryPeriod,
    required this.certainty,
    required this.provisional,
    required this.authority,
    required this.provenance,
    required this.relationshipId,
    required this.cycleSequence,
    required this.occurrenceId,
    required this.obligationId,
    required this.documentaryInstallmentId,
    required this.planId,
    required this.installmentNumber,
    required this.economicFactId,
    required this.requiresUserAction,
    required this.requiresPlanning,
  });

  bool countsInEconomicMonth(DateTime month) {
    switch (temporalKnowledge) {
      case FinanceForecastTemporalKnowledge.economicDateKnown:
        return economicStart != null && _sameMonth(economicStart!, month);
      case FinanceForecastTemporalKnowledge.economicWindowKnown:
        return economicStart != null &&
            economicEnd != null &&
            _sameMonth(economicStart!, economicEnd!) &&
            _sameMonth(economicStart!, month);
      case FinanceForecastTemporalKnowledge.economicPeriodKnown:
        return economicPeriod != null &&
            economicPeriod!.year == month.year &&
            economicPeriod!.month == month.month;
      case FinanceForecastTemporalKnowledge.documentPeriodOnly:
      case FinanceForecastTemporalKnowledge.unlocated:
        return false;
    }
  }

  bool documentKnowledgeFallsIn(DateTime month) =>
      documentaryPeriod != null &&
      documentaryPeriod!.year == month.year &&
      documentaryPeriod!.month == month.month;

  static bool _sameMonth(DateTime left, DateTime right) =>
      left.year == right.year && left.month == right.month;
}

class FinanceForecastOverview {
  final UnmodifiableListView<FinanceForecastPresentation> items;

  FinanceForecastOverview(Iterable<FinanceForecastPresentation> items)
    : items = UnmodifiableListView(List.of(items));

  List<FinanceForecastPresentation> economicItemsForMonth(DateTime month) =>
      List.unmodifiable(
        items.where((item) => item.countsInEconomicMonth(month)),
      );

  double economicOutflowForMonth(DateTime month) => economicItemsForMonth(
    month,
  ).fold(0, (total, item) => total + item.amount);

  double documentaryOnlyOutflowForMonth(DateTime month) => items
      .where(
        (item) =>
            item.temporalKnowledge ==
                FinanceForecastTemporalKnowledge.documentPeriodOnly &&
            item.documentKnowledgeFallsIn(month),
      )
      .fold(0, (total, item) => total + item.amount);
}
