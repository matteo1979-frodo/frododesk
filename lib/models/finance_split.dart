class FinanceSplit {
  final String personId;
  final double amount;

  const FinanceSplit({required this.personId, required this.amount});

  Map<String, dynamic> toJson() {
    return {'personId': personId, 'amount': amount};
  }

  factory FinanceSplit.fromJson(Map<String, dynamic> json) {
    return FinanceSplit(
      personId: json['personId'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
