class HomeFinanceSnapshot {
  final double totalBalance;
  final double projectedMonthlyMargin;
  final bool underPressure;
  final double economicPressureScore;

  const HomeFinanceSnapshot({
    required this.totalBalance,
    required this.projectedMonthlyMargin,
    required this.underPressure,
    required this.economicPressureScore,
  });
}
