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
}
