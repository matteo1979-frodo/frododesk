import 'finance_recurring_item.dart';
import 'income.dart';

class IncomeForecastPresentation {
  final String identity;
  final String relationshipId;
  final String? occurrenceId;
  final int? cycleSequence;
  final String label;
  final double amount;
  final DateTime economicDate;
  final FinanceSubject subject;
  final String? destinationBalanceId;
  final IncomeProvenance provenance;
  final IncomeKnowledge knowledge;
  final List<String> evidenceEconomicFactIds;
  final bool projected;

  const IncomeForecastPresentation({
    required this.identity,
    required this.relationshipId,
    required this.occurrenceId,
    required this.cycleSequence,
    required this.label,
    required this.amount,
    required this.economicDate,
    required this.subject,
    required this.destinationBalanceId,
    required this.provenance,
    required this.knowledge,
    required this.evidenceEconomicFactIds,
    required this.projected,
  });

  bool fallsInMonth(DateTime month) =>
      economicDate.year == month.year && economicDate.month == month.month;
}

class IncomeForecastOverview {
  final List<IncomeForecastPresentation> items;

  IncomeForecastOverview(Iterable<IncomeForecastPresentation> items)
    : items = List.unmodifiable(items);

  List<IncomeForecastPresentation> itemsForMonth(DateTime month) =>
      List.unmodifiable(items.where((item) => item.fallsInMonth(month)));

  double totalForMonth(DateTime month) =>
      itemsForMonth(month).fold(0, (sum, item) => sum + item.amount);
}
