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

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalBalance': totalBalance,
      'totalFunds': totalFunds,
      'projectedMonthlyIncome': projectedMonthlyIncome,
      'projectedMonthlyExpenses': projectedMonthlyExpenses,
      'projectedMonthlyMargin': projectedMonthlyMargin,
      'underPressure': underPressure,
      'operationalBalance': operationalBalance,
      'operationalStressRatio': operationalStressRatio,
      'operationalStressLevel': operationalStressLevel,
      'vitalityState': vitalityState,
      'economicTrend': economicTrend,
      'resilienceRatio': resilienceRatio,
      'recovering': recovering,
      'fatigued': fatigued,
      'degrading': degrading,
      'losingControl': losingControl,
      'drowning': drowning,
    };
  }

  factory FinanceSnapshot.fromJson(Map<String, dynamic> json) {
    return FinanceSnapshot(
      date: DateTime.parse(json['date'] as String),
      totalBalance: (json['totalBalance'] as num).toDouble(),
      totalFunds: (json['totalFunds'] as num).toDouble(),
      projectedMonthlyIncome: (json['projectedMonthlyIncome'] as num)
          .toDouble(),
      projectedMonthlyExpenses: (json['projectedMonthlyExpenses'] as num)
          .toDouble(),
      projectedMonthlyMargin: (json['projectedMonthlyMargin'] as num)
          .toDouble(),
      underPressure: json['underPressure'] as bool,
      operationalBalance: (json['operationalBalance'] as num).toDouble(),
      operationalStressRatio: (json['operationalStressRatio'] as num)
          .toDouble(),
      operationalStressLevel: json['operationalStressLevel'] as String,
      vitalityState: json['vitalityState'] as String,
      economicTrend: json['economicTrend'] as String,
      resilienceRatio: (json['resilienceRatio'] as num).toDouble(),
      recovering: json['recovering'] as bool,
      fatigued: json['fatigued'] as bool,
      degrading: json['degrading'] as bool,
      losingControl: json['losingControl'] as bool,
      drowning: json['drowning'] as bool,
    );
  }
}
