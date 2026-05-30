enum FinanceTransactionType { income, expense, transfer }

enum FinanceTransactionOrigin { recurringItem, manual, fund, adjustment }

class FinanceTransaction {
  final String id;

  final String balanceId;

  final double amount;

  final DateTime date;

  final bool isIncome;

  final String description;

  final FinanceTransactionType type;

  final FinanceTransactionOrigin origin;

  final String? recurringItemId;

  final String? notes;

  const FinanceTransaction({
    required this.id,
    required this.balanceId,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.description,
    required this.type,
    required this.origin,
    this.recurringItemId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balanceId': balanceId,
      'amount': amount,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'description': description,
      'type': type.name,
      'origin': origin.name,
      'recurringItemId': recurringItemId,
      'notes': notes,
    };
  }

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: json['id'] as String,
      balanceId: json['balanceId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      isIncome: json['isIncome'] as bool,
      description: json['description'] as String,
      type: FinanceTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      origin: FinanceTransactionOrigin.values.firstWhere(
        (e) => e.name == json['origin'],
      ),
      recurringItemId: json['recurringItemId'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
