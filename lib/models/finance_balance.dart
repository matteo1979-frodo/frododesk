class FinanceBalance {
  final String personId;
  final double initialAmount;
  final double currentAmount;
  final DateTime updatedAt;

  const FinanceBalance({
    required this.personId,
    required this.initialAmount,
    required this.currentAmount,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'personId': personId,
      'initialAmount': initialAmount,
      'currentAmount': currentAmount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FinanceBalance.fromJson(Map<String, dynamic> json) {
    return FinanceBalance(
      personId: json['personId'] as String,
      initialAmount: (json['initialAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
