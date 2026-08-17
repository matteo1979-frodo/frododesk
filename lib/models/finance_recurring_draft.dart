import 'finance_category_template.dart';
import 'finance_recurring_item.dart';
import 'finance_split.dart';

class FinanceRecurringDraft {
  final String? id;
  final String name;
  final String description;
  final double expectedAmount;
  final DateTime nextDueDate;
  final bool isIncome;
  final FinanceRecurringType recurringType;
  final int? customInterval;
  final FinanceCategory category;
  final FinancePaymentOwner paymentOwner;
  final FinanceSubject subject;
  final String? balanceId;
  final FinancePaymentMethod paymentMethod;
  final FinanceSmartTemplateType templateType;
  final double? matteoPercentage;
  final double? chiaraPercentage;
  final bool mandatory;
  final FinancePaymentPriority paymentPriority;
  final FinanceVariability variability;
  final FinanceProtectionLevel protectionLevel;
  final FinanceStability stability;
  final FinanceSuspensionRisk suspensionRisk;
  final FinanceBehaviorProfile behaviorProfile;
  final FinanceRecurringItem? existing;

  const FinanceRecurringDraft({
    this.id,
    required this.name,
    required this.description,
    required this.expectedAmount,
    required this.nextDueDate,
    required this.isIncome,
    required this.recurringType,
    this.customInterval,
    required this.category,
    required this.paymentOwner,
    required this.subject,
    this.balanceId,
    required this.paymentMethod,
    required this.templateType,
    this.matteoPercentage,
    this.chiaraPercentage,
    required this.mandatory,
    required this.paymentPriority,
    required this.variability,
    required this.protectionLevel,
    required this.stability,
    required this.suspensionRisk,
    required this.behaviorProfile,
    this.existing,
  });

  List<FinanceSplit> buildSplits() {
    final matteo = matteoPercentage;
    final chiara = chiaraPercentage;
    if (matteo == null || chiara == null) return const [];
    return [
      FinanceSplit(personId: 'matteo', amount: expectedAmount * matteo / 100),
      FinanceSplit(personId: 'chiara', amount: expectedAmount * chiara / 100),
    ];
  }
}

class FinanceTemplateDefaults {
  final FinancePaymentMethod paymentMethod;
  final FinanceCategory category;
  final FinanceBehaviorProfile behaviorProfile;

  const FinanceTemplateDefaults({
    required this.paymentMethod,
    required this.category,
    required this.behaviorProfile,
  });
}
