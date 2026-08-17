import '../../../models/finance_category_template.dart';
import '../../../models/finance_recurring_draft.dart';
import '../../../models/finance_recurring_item.dart';

class FinanceRecurringItemBuilder {
  const FinanceRecurringItemBuilder();

  String? validate(FinanceRecurringDraft draft) {
    final matteo = draft.matteoPercentage;
    final chiara = draft.chiaraPercentage;
    if ((matteo == null) != (chiara == null)) {
      return 'Indica entrambe le percentuali';
    }
    if (matteo != null && chiara != null) {
      if (matteo < 0 || chiara < 0 || (matteo + chiara - 100).abs() > 0.001) {
        return 'La ripartizione deve totalizzare 100%';
      }
    }
    return null;
  }

  FinanceTemplateDefaults defaultsFor(FinanceSmartTemplateType type) {
    final template = financeSmartTemplates.firstWhere(
      (candidate) => candidate.type == type,
      orElse: () => financeSmartTemplates.last,
    );
    final category = switch (type) {
      FinanceSmartTemplateType.salary => FinanceCategory.salary,
      FinanceSmartTemplateType.car => FinanceCategory.auto,
      FinanceSmartTemplateType.school => FinanceCategory.school,
      FinanceSmartTemplateType.health => FinanceCategory.health,
      FinanceSmartTemplateType.mortgage ||
      FinanceSmartTemplateType.rent => FinanceCategory.house,
      _ => FinanceCategory.generic,
    };
    final behavior = switch (type) {
      FinanceSmartTemplateType.subscription => const FinanceBehaviorProfile(
        timeSensitive: true,
        canBeDelayed: false,
        canBeReduced: true,
      ),
      FinanceSmartTemplateType.utilityBill => const FinanceBehaviorProfile(
        timeSensitive: true,
        canBeDelayed: false,
        canBeSplit: true,
        rigidityScore: 0.75,
        maneuverabilityScore: 0.25,
      ),
      FinanceSmartTemplateType.insurance ||
      FinanceSmartTemplateType.mortgage ||
      FinanceSmartTemplateType.rent => const FinanceBehaviorProfile(
        timeSensitive: true,
        canBeDelayed: false,
        rigidityScore: 0.9,
        maneuverabilityScore: 0.1,
      ),
      FinanceSmartTemplateType.salary => const FinanceBehaviorProfile(
        predictable: true,
        canBeDelayed: false,
        rigidityScore: 0.2,
        maneuverabilityScore: 0.8,
      ),
      _ => const FinanceBehaviorProfile(),
    };
    return FinanceTemplateDefaults(
      paymentMethod: template.defaultPaymentMethod,
      category: category,
      behaviorProfile: behavior,
    );
  }

  FinanceRecurringItem build(FinanceRecurringDraft draft, DateTime now) {
    final validationError = validate(draft);
    if (validationError != null) throw ArgumentError(validationError);
    final existing = draft.existing;
    return FinanceRecurringItem(
      id: draft.id ?? existing?.id ?? 'recurring_${now.microsecondsSinceEpoch}',
      name: draft.name,
      description: draft.description,
      expectedAmount: draft.expectedAmount,
      nextDueDate: draft.nextDueDate,
      isIncome: draft.isIncome,
      recurringType: draft.recurringType,
      customInterval: draft.recurringType == FinanceRecurringType.custom
          ? draft.customInterval ?? 1
          : null,
      customIntervalUnit: draft.recurringType == FinanceRecurringType.custom
          ? 'months'
          : null,
      category: draft.category,
      requiresManualConfirmation: existing?.requiresManualConfirmation ?? true,
      mandatory: draft.mandatory,
      pressureLevel:
          existing?.pressureLevel ??
          (draft.isIncome
              ? FinancePressureLevel.low
              : FinancePressureLevel.medium),
      confirmed: existing?.confirmed ?? false,
      realAmount: existing?.realAmount,
      variability: draft.variability,
      paymentPriority: draft.paymentPriority,
      protectionLevel: draft.protectionLevel,
      paymentOwner: draft.paymentOwner,
      subject: draft.subject,
      balanceId: draft.balanceId,
      paymentMethod: draft.paymentMethod,
      stability: draft.stability,
      suspensionRisk: draft.suspensionRisk,
      originType: existing?.originType ?? FinanceOriginType.manual,
      splits: draft.buildSplits(),
      behaviorProfile: draft.behaviorProfile,
    );
  }
}
