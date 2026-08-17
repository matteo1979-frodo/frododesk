enum FinanceFundCategory { emergency, auto, home, health, school, generic }

enum FinanceFundStatus { active, closed }

enum FinanceFundOpeningKind { fundedFromAccounts, preExisting, legacyImported }

class FinanceFund {
  final String id;
  final String name;
  final String description;
  final double amount;
  final bool protected;
  final FinanceFundCategory category;
  final FinanceFundStatus status;
  final FinanceFundOpeningKind openingKind;
  final DateTime? openedAt;
  final DateTime? closedAt;

  const FinanceFund({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.protected,
    required this.category,
    this.status = FinanceFundStatus.active,
    this.openingKind = FinanceFundOpeningKind.legacyImported,
    this.openedAt,
    this.closedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'protected': protected,
      'category': category.name,
      'status': status.name,
      'openingKind': openingKind.name,
      'openedAt': openedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
    };
  }

  factory FinanceFund.fromJson(Map<String, dynamic> json) {
    return FinanceFund(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      protected: json['protected'] as bool,
      category: FinanceFundCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => FinanceFundCategory.generic,
      ),
      status: FinanceFundStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => FinanceFundStatus.active,
      ),
      openingKind: FinanceFundOpeningKind.values.firstWhere(
        (value) => value.name == json['openingKind'],
        orElse: () => FinanceFundOpeningKind.legacyImported,
      ),
      openedAt: json['openedAt'] == null
          ? null
          : DateTime.parse(json['openedAt'] as String),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
    );
  }
}
