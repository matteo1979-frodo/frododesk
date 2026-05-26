class FinanceMonthProjection {
  final DateTime month;

  final double expectedIncome;
  final double expectedExpenses;
  final double expectedMargin;

  final double pressureScore;
  final int pressureItemCount;
  final double pressureDensity;

  const FinanceMonthProjection({
    required this.month,
    required this.expectedIncome,
    required this.expectedExpenses,
    required this.expectedMargin,
    required this.pressureScore,
    required this.pressureItemCount,
    required this.pressureDensity,
  });
}