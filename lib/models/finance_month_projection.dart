class FinanceMonthProjection {
  final DateTime month;

  final double expectedIncome;
  final double expectedExpenses;
  final double expectedMargin;

  final double pressureScore;

  const FinanceMonthProjection({
    required this.month,
    required this.expectedIncome,
    required this.expectedExpenses,
    required this.expectedMargin,
    required this.pressureScore,
  });
}