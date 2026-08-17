import 'dart:collection';

import 'frodo_observation.dart';
import 'finance_balance.dart';
import 'real_expense.dart';
import 'spese_command.dart';

class SpeseSnapshot {
  final DateTime observedAt;
  final String monthTitle;
  final UnmodifiableListView<RealExpense> currentMonthExpenses;
  final UnmodifiableListView<RealExpense> recentExpenses;
  final UnmodifiableListView<RealExpense> previousMonthExpenses;
  final UnmodifiableListView<FrodoObservation> monthObservations;
  final UnmodifiableListView<FrodoObservation> visibleMonthObservations;
  final UnmodifiableMapView<String, double> categoryTotals;
  final UnmodifiableListView<FinanceBalance> activeBalances;
  final UnmodifiableListView<String> categories;
  final SpeseCommandRegistry commandRegistry;
  final double currentMonthTotal;
  final double last7DaysTotal;
  final double cashWalletTotal;
  final int movementCount;
  final String mainCategory;

  SpeseSnapshot({
    required this.observedAt,
    required this.monthTitle,
    required List<RealExpense> currentMonthExpenses,
    required List<RealExpense> recentExpenses,
    required List<RealExpense> previousMonthExpenses,
    required List<FrodoObservation> monthObservations,
    required List<FrodoObservation> visibleMonthObservations,
    required Map<String, double> categoryTotals,
    required List<FinanceBalance> activeBalances,
    required List<String> categories,
    required this.commandRegistry,
    required this.currentMonthTotal,
    required this.last7DaysTotal,
    required this.cashWalletTotal,
    required this.movementCount,
    required this.mainCategory,
  }) : currentMonthExpenses = UnmodifiableListView(
         List<RealExpense>.of(currentMonthExpenses),
       ),
       recentExpenses = UnmodifiableListView(
         List<RealExpense>.of(recentExpenses),
       ),
       previousMonthExpenses = UnmodifiableListView(
         List<RealExpense>.of(previousMonthExpenses),
       ),
       monthObservations = UnmodifiableListView(
         List<FrodoObservation>.of(monthObservations),
       ),
       visibleMonthObservations = UnmodifiableListView(
         List<FrodoObservation>.of(visibleMonthObservations),
       ),
       categoryTotals = UnmodifiableMapView(
         Map<String, double>.of(categoryTotals),
       ),
       activeBalances = UnmodifiableListView(
         List<FinanceBalance>.of(activeBalances),
       ),
       categories = UnmodifiableListView(List<String>.of(categories));
}
