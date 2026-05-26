class FinanceSnapshot {
  final DateTime date;
  final double totalBalance;
  final double totalFunds;
  final double projectedMonthlyIncome;
  final double projectedMonthlyExpenses;
  final double projectedMonthlyMargin;
  final bool underPressure;

  final double operationalBalance;
  final double operationalStressRatio;
  final String operationalStressLevel;
  final String vitalityState;
  final String economicTrend;
  final double resilienceRatio;
  final bool recovering;
  final bool fatigued;
  final bool degrading;
  final bool losingControl;
  final bool drowning;

  const FinanceSnapshot({
    required this.date,
    required this.totalBalance,
    required this.totalFunds,
    required this.projectedMonthlyIncome,
    required this.projectedMonthlyExpenses,
    required this.projectedMonthlyMargin,
    required this.underPressure,
    required this.operationalBalance,
    required this.operationalStressRatio,
    required this.operationalStressLevel,
    required this.vitalityState,
    required this.economicTrend,
    required this.resilienceRatio,
    required this.recovering,
    required this.fatigued,
    required this.degrading,
    required this.losingControl,
    required this.drowning,
  });
}