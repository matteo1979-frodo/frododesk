enum FundTransactionType { deposit, withdraw }

class FundTransaction {
  final String id;
  final String fundId;
  final String description;
  final double amount;
  final DateTime date;
  final FundTransactionType type;

  const FundTransaction({
    required this.id,
    required this.fundId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fundId': fundId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
    };
  }

  factory FundTransaction.fromJson(Map<String, dynamic> json) {
    return FundTransaction(
      id: json['id'] as String,
      fundId: json['fundId'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: FundTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
    );
  }
}
