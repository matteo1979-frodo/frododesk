import 'finance_split.dart';
import 'finance_category_template.dart';

enum FinanceRecurringType { monthly, yearly, oneShot, custom }

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

enum FinancePaymentOwner { matteo, chiara, shared }

enum FinanceOriginType { manual, contractual, lifeGenerated }

enum FinanceStability { stable, unstable }

enum FinanceSuspensionRisk { low, medium, high, critical }

class FinanceBehaviorProfile {
  final bool predictable;
  final bool lifeGenerated;
  final bool timeSensitive;
  final bool canBeDelayed;
  final bool canBeSplit;
  final bool canBeReduced;
  final bool affectsResilience;
  final bool affectsOperationalOxygen;
  final double rigidityScore;
  final double maneuverabilityScore;
  final double recoveryImpactScore;

  const FinanceBehaviorProfile({
    this.predictable = true,
    this.lifeGenerated = false,
    this.timeSensitive = false,
    this.canBeDelayed = false,
    this.canBeSplit = false,
    this.canBeReduced = false,
    this.affectsResilience = true,
    this.affectsOperationalOxygen = true,
    this.rigidityScore = 0.5,
    this.maneuverabilityScore = 0.5,
    this.recoveryImpactScore = 0.5,
  });

  Map<String, dynamic> toJson() {
    return {
      'predictable': predictable,
      'lifeGenerated': lifeGenerated,
      'timeSensitive': timeSensitive,
      'canBeDelayed': canBeDelayed,
      'canBeSplit': canBeSplit,
      'canBeReduced': canBeReduced,
      'affectsResilience': affectsResilience,
      'affectsOperationalOxygen': affectsOperationalOxygen,
      'rigidityScore': rigidityScore,
      'maneuverabilityScore': maneuverabilityScore,
      'recoveryImpactScore': recoveryImpactScore,
    };
  }

  factory FinanceBehaviorProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FinanceBehaviorProfile();
    }

    return FinanceBehaviorProfile(
      predictable: json['predictable'] as bool? ?? true,
      lifeGenerated: json['lifeGenerated'] as bool? ?? false,
      timeSensitive: json['timeSensitive'] as bool? ?? false,
      canBeDelayed: json['canBeDelayed'] as bool? ?? false,
      canBeSplit: json['canBeSplit'] as bool? ?? false,
      canBeReduced: json['canBeReduced'] as bool? ?? false,
      affectsResilience: json['affectsResilience'] as bool? ?? true,
      affectsOperationalOxygen:
          json['affectsOperationalOxygen'] as bool? ?? true,
      rigidityScore: (json['rigidityScore'] as num?)?.toDouble() ?? 0.5,
      maneuverabilityScore:
          (json['maneuverabilityScore'] as num?)?.toDouble() ?? 0.5,
      recoveryImpactScore:
          (json['recoveryImpactScore'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class FinanceRecurringItem {
  final String id;
  final String name;
  final String description;
  final double expectedAmount;
  final DateTime nextDueDate;
  final bool isIncome;
  final FinanceRecurringType recurringType;
  final int? customInterval;
  final String? customIntervalUnit;
  final FinanceCategory category;
  final bool requiresManualConfirmation;
  final bool mandatory;
  final FinancePressureLevel pressureLevel;
  final bool confirmed;
  final double? realAmount;
  final FinanceVariability variability;
  final FinancePaymentPriority paymentPriority;
  final FinanceProtectionLevel protectionLevel;
  final FinancePaymentOwner paymentOwner;
  final String? balanceId;
  final FinancePaymentMethod paymentMethod;
  final FinanceStability stability;
  final FinanceSuspensionRisk suspensionRisk;
  final FinanceOriginType originType;
  final List<FinanceSplit> splits;
  final FinanceBehaviorProfile behaviorProfile;

  const FinanceRecurringItem({
    required this.id,
    required this.name,
    required this.description,
    required this.expectedAmount,
    required this.nextDueDate,
    required this.isIncome,
    required this.recurringType,
    this.customInterval,
    this.customIntervalUnit,
    required this.category,
    required this.requiresManualConfirmation,
    required this.mandatory,
    required this.pressureLevel,
    required this.confirmed,
    this.realAmount,
    required this.variability,
    required this.paymentPriority,
    required this.protectionLevel,
    required this.paymentOwner,
    this.balanceId,
    required this.paymentMethod,
    required this.stability,
    required this.suspensionRisk,
    required this.originType,
    required this.splits,
    this.behaviorProfile = const FinanceBehaviorProfile(),
  });

  bool get hasCustomSplits => splits.isNotEmpty;

  FinanceRecurringItem copyWith({
    String? name,
    String? description,
    double? expectedAmount,
    DateTime? nextDueDate,
    bool? confirmed,
    double? realAmount,
    int? customInterval,
    String? customIntervalUnit,
    String? id,
    FinanceOriginType? originType,
    FinancePaymentOwner? paymentOwner,
    List<FinanceSplit>? splits,
    FinanceBehaviorProfile? behaviorProfile,
    String? balanceId,
    FinancePaymentMethod? paymentMethod,
  }) {
    return FinanceRecurringItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isIncome: isIncome,
      recurringType: recurringType,
      customInterval: customInterval ?? this.customInterval,
      customIntervalUnit: customIntervalUnit ?? this.customIntervalUnit,
      category: category,
      requiresManualConfirmation: requiresManualConfirmation,
      mandatory: mandatory,
      pressureLevel: pressureLevel,
      confirmed: confirmed ?? this.confirmed,
      realAmount: realAmount ?? this.realAmount,
      variability: variability,
      paymentPriority: paymentPriority,
      protectionLevel: protectionLevel,
      stability: stability,
      suspensionRisk: suspensionRisk,
      originType: originType ?? this.originType,
      splits: splits ?? this.splits,
      paymentOwner: paymentOwner ?? this.paymentOwner,
      balanceId: balanceId ?? this.balanceId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      behaviorProfile: behaviorProfile ?? this.behaviorProfile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'expectedAmount': expectedAmount,
      'nextDueDate': nextDueDate.toIso8601String(),
      'isIncome': isIncome,
      'recurringType': recurringType.name,
      'customInterval': customInterval,
      'customIntervalUnit': customIntervalUnit,
      'category': category.name,
      'requiresManualConfirmation': requiresManualConfirmation,
      'mandatory': mandatory,
      'pressureLevel': pressureLevel.name,
      'confirmed': confirmed,
      'realAmount': realAmount,
      'variability': variability.name,
      'paymentPriority': paymentPriority.name,
      'protectionLevel': protectionLevel.name,
      'paymentOwner': paymentOwner.name,
      'balanceId': balanceId,
      'stability': stability.name,
      'suspensionRisk': suspensionRisk.name,
      'originType': originType.name,
      'splits': splits.map((s) => s.toJson()).toList(),
      'behaviorProfile': behaviorProfile.toJson(),
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
      customInterval: json['customInterval'] as int?,
      customIntervalUnit: json['customIntervalUnit'] as String?,
      category: FinanceCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      requiresManualConfirmation: json['requiresManualConfirmation'] as bool,
      mandatory: json['mandatory'] as bool,
      pressureLevel: FinancePressureLevel.values.firstWhere(
        (e) => e.name == json['pressureLevel'],
      ),
      confirmed: json['confirmed'] as bool,
      realAmount: (json['realAmount'] as num?)?.toDouble(),
      variability: FinanceVariability.values.firstWhere(
        (e) => e.name == json['variability'],
      ),
      paymentPriority: FinancePaymentPriority.values.firstWhere(
        (e) => e.name == json['paymentPriority'],
      ),
      protectionLevel: FinanceProtectionLevel.values.firstWhere(
        (e) => e.name == json['protectionLevel'],
      ),
      paymentOwner: json['paymentOwner'] == null
          ? FinancePaymentOwner.shared
          : FinancePaymentOwner.values.firstWhere(
              (e) => e.name == json['paymentOwner'],
            ),
      balanceId: json['balanceId'] as String?,
      paymentMethod: json['paymentMethod'] == null
          ? FinancePaymentMethod.manual
          : FinancePaymentMethod.values.firstWhere(
              (e) => e.name == json['paymentMethod'],
            ),
      stability: FinanceStability.values.firstWhere(
        (e) => e.name == json['stability'],
      ),
      suspensionRisk: FinanceSuspensionRisk.values.firstWhere(
        (e) => e.name == json['suspensionRisk'],
      ),
      originType: json['originType'] == null
          ? FinanceOriginType.manual
          : FinanceOriginType.values.firstWhere(
              (e) => e.name == json['originType'],
            ),
      splits: json['splits'] == null
          ? []
          : (json['splits'] as List)
                .map((e) => FinanceSplit.fromJson(e))
                .toList(),
      behaviorProfile: FinanceBehaviorProfile.fromJson(
        json['behaviorProfile'] as Map<String, dynamic>?,
      ),
    );
  }
}
