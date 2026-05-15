class FinanceSnapshot {
  final DateTime date;
  final double totalBalance;
  final double totalFunds;
  final double projectedMonthlyIncome;
  final double projectedMonthlyExpenses;
  final double projectedMonthlyMargin;
  final bool underPressure;

  const FinanceSnapshot({
    required this.date,
    required this.totalBalance,
    required this.totalFunds,
    required this.projectedMonthlyIncome,
    required this.projectedMonthlyExpenses,
    required this.projectedMonthlyMargin,
    required this.underPressure,
  });
}
