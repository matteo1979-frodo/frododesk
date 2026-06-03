enum FinanceAccountLinkedItemType {
  debitCard,
  creditCard,
  prepaidCard,
  loan,
  mortgage,
  bankContact,
  other,
}

class FinanceAccountLinkedItem {
  final String id;
  final String balanceId;
  final FinanceAccountLinkedItemType type;
  final String name;
  final String description;
  final DateTime? expirationDate;
  final double? amount;
  final bool active;

  const FinanceAccountLinkedItem({
    required this.id,
    required this.balanceId,
    required this.type,
    required this.name,
    required this.description,
    this.expirationDate,
    this.amount,
    this.active = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balanceId': balanceId,
      'type': type.name,
      'name': name,
      'description': description,
      'expirationDate': expirationDate?.toIso8601String(),
      'amount': amount,
      'active': active,
    };
  }

  factory FinanceAccountLinkedItem.fromJson(Map<String, dynamic> json) {
    return FinanceAccountLinkedItem(
      id: json['id'] as String,
      balanceId: json['balanceId'] as String,
      type: FinanceAccountLinkedItemType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      amount: (json['amount'] as num?)?.toDouble(),
      active: json['active'] as bool? ?? true,
    );
  }

  FinanceAccountLinkedItem copyWith({
    FinanceAccountLinkedItemType? type,
    String? name,
    String? description,
    DateTime? expirationDate,
    double? amount,
    bool? active,
  }) {
    return FinanceAccountLinkedItem(
      id: id,
      balanceId: balanceId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      expirationDate: expirationDate ?? this.expirationDate,
      amount: amount ?? this.amount,
      active: active ?? this.active,
    );
  }
}
