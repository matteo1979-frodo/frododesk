enum FinanceFundCategory { emergency, auto, home, health, school, generic }

class FinanceFund {
  final String id;
  final String name;
  final String description;
  final double amount;
  final bool protected;
  final FinanceFundCategory category;

  const FinanceFund({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.protected,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'protected': protected,
      'category': category.name,
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
    );
  }
}
