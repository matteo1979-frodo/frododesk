enum FrodoObservationLevel { info, attention, problem, opportunity, success }

enum FrodoObservationStatus { active, resolved, ignored, expired }

enum FrodoObservationCategory {
  coverage,
  finance,
  expenses,
  calendar,
  health,
  home,
  system,
}

class FrodoObservationAction {
  final String label;
  final String targetModule;
  final String? targetId;
  final DateTime? targetDate;
  final Map<String, dynamic> payload;

  const FrodoObservationAction({
    required this.label,
    required this.targetModule,
    this.targetId,
    this.targetDate,
    this.payload = const {},
  });
}

class FrodoObservation {
  final String id;

  final String module;
  final FrodoObservationCategory category;

  final String title;
  final String message;
  final String? reason;

  final int priority;
  final double weight;
  final FrodoObservationLevel level;
  final FrodoObservationStatus status;

  final DateTime createdAt;
  final DateTime? validUntil;
  final DateTime? targetDate;

  final String? targetId;

  final bool resolvable;
  final bool ignorable;
  final bool persistent;

  final List<String> tags;

  final FrodoObservationAction? action;

  const FrodoObservation({
    required this.id,
    required this.module,
    required this.category,
    required this.title,
    required this.message,
    this.reason,
    required this.priority,
    this.weight = 1.0,
    required this.level,
    this.status = FrodoObservationStatus.active,
    required this.createdAt,
    this.validUntil,
    this.targetDate,
    this.targetId,
    this.resolvable = false,
    this.ignorable = true,
    this.persistent = false,
    this.tags = const [],
    this.action,
  });

  bool get isActive => status == FrodoObservationStatus.active;

  bool isExpired(DateTime now) {
    if (validUntil == null) return false;
    return now.isAfter(validUntil!);
  }

  FrodoObservation resolve() {
    return copyWith(status: FrodoObservationStatus.resolved);
  }

  FrodoObservation ignore() {
    return copyWith(status: FrodoObservationStatus.ignored);
  }

  FrodoObservation expire() {
    return copyWith(status: FrodoObservationStatus.expired);
  }

  bool isMeaningfullyDifferentFrom(FrodoObservation other) {
    return title != other.title ||
        message != other.message ||
        reason != other.reason ||
        level != other.level ||
        priority != other.priority ||
        weight != other.weight;
  }

  FrodoObservation copyWith({
    String? id,
    String? module,
    FrodoObservationCategory? category,
    String? title,
    String? message,
    String? reason,
    int? priority,
    double? weight,
    FrodoObservationLevel? level,
    FrodoObservationStatus? status,
    DateTime? createdAt,
    DateTime? validUntil,
    DateTime? targetDate,
    String? targetId,
    bool? resolvable,
    bool? ignorable,
    bool? persistent,
    List<String>? tags,
    FrodoObservationAction? action,
  }) {
    return FrodoObservation(
      id: id ?? this.id,
      module: module ?? this.module,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      reason: reason ?? this.reason,
      priority: priority ?? this.priority,
      weight: weight ?? this.weight,
      level: level ?? this.level,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      validUntil: validUntil ?? this.validUntil,
      targetDate: targetDate ?? this.targetDate,
      targetId: targetId ?? this.targetId,
      resolvable: resolvable ?? this.resolvable,
      ignorable: ignorable ?? this.ignorable,
      persistent: persistent ?? this.persistent,
      tags: tags ?? this.tags,
      action: action ?? this.action,
    );
  }
}
