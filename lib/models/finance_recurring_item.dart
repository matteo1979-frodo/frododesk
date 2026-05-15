enum FinanceRecurringType { monthly, yearly, oneShot }

enum FinanceCategory {
  salary,
  entertainment,
  house,
  auto,
  school,
  health,
  generic,
}

enum FinancePressureLevel { low, medium, high, critical }

enum FinanceVariability { fixed, variable }

enum FinancePaymentPriority { low, normal, high, critical }

enum FinanceProtectionLevel { none, protected, critical }

enum FinanceStability { stable, unstable }

enum FinanceSuspensionRisk { low, medium, high, critical }

class FinanceRecurringItem {
  final String id;
  final String name;
  final String description;
  final double expectedAmount;
  final DateTime nextDueDate;
  final bool isIncome;
  final FinanceRecurringType recurringType;
  final FinanceCategory category;
  final bool requiresManualConfirmation;
  final bool mandatory;
  final FinancePressureLevel pressureLevel;
  final bool confirmed;
  final FinanceVariability variability;
  final FinancePaymentPriority paymentPriority;
  final FinanceProtectionLevel protectionLevel;
  final FinanceStability stability;
  final FinanceSuspensionRisk suspensionRisk;

  const FinanceRecurringItem({
    required this.id,
    required this.name,
    required this.description,
    required this.expectedAmount,
    required this.nextDueDate,
    required this.isIncome,
    required this.recurringType,
    required this.category,
    required this.requiresManualConfirmation,
    required this.mandatory,
    required this.pressureLevel,
    required this.confirmed,
    required this.variability,
    required this.paymentPriority,
    required this.protectionLevel,
    required this.stability,
    required this.suspensionRisk,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'expectedAmount': expectedAmount,
      'nextDueDate': nextDueDate.toIso8601String(),
      'isIncome': isIncome,
      'recurringType': recurringType.name,
      'category': category.name,
      'requiresManualConfirmation': requiresManualConfirmation,
      'mandatory': mandatory,
      'pressureLevel': pressureLevel.name,
      'confirmed': confirmed,
      'variability': variability.name,
      'paymentPriority': paymentPriority.name,
      'protectionLevel': protectionLevel.name,
      'stability': stability.name,
      'suspensionRisk': suspensionRisk.name,
    };
  }

  factory FinanceRecurringItem.fromJson(Map<String, dynamic> json) {
    return FinanceRecurringItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      expectedAmount: (json['expectedAmount'] as num).toDouble(),
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      isIncome: json['isIncome'] as bool,
      recurringType: FinanceRecurringType.values.firstWhere(
        (e) => e.name == json['recurringType'],
      ),
      category: FinanceCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      requiresManualConfirmation: json['requiresManualConfirmation'] as bool,
      mandatory: json['mandatory'] as bool,
      pressureLevel: FinancePressureLevel.values.firstWhere(
        (e) => e.name == json['pressureLevel'],
      ),
      confirmed: json['confirmed'] as bool,
      variability: FinanceVariability.values.firstWhere(
        (e) => e.name == json['variability'],
      ),
      paymentPriority: FinancePaymentPriority.values.firstWhere(
        (e) => e.name == json['paymentPriority'],
      ),
      protectionLevel: FinanceProtectionLevel.values.firstWhere(
        (e) => e.name == json['protectionLevel'],
      ),
      stability: FinanceStability.values.firstWhere(
        (e) => e.name == json['stability'],
      ),
      suspensionRisk: FinanceSuspensionRisk.values.firstWhere(
        (e) => e.name == json['suspensionRisk'],
      ),
    );
  }
}
