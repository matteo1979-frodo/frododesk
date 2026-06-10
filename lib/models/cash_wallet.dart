class CashWallet {
  final String id;
  final String personId;
  final String name;
  final double currentAmount;
  final bool active;

  const CashWallet({
    required this.id,
    required this.personId,
    required this.name,
    required this.currentAmount,
    this.active = true,
  });

  CashWallet copyWith({double? currentAmount, bool? active}) {
    return CashWallet(
      id: id,
      personId: personId,
      name: name,
      currentAmount: currentAmount ?? this.currentAmount,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personId': personId,
      'name': name,
      'currentAmount': currentAmount,
      'active': active,
    };
  }

  factory CashWallet.fromJson(Map<String, dynamic> json) {
    return CashWallet(
      id: json['id'] as String? ?? '',
      personId: json['personId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }
}
