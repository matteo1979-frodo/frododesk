enum FinanceBalanceType { bankAccount, cash, prepaidCard, sharedAccount }

class FinanceBalance {
  final String personId;
  final double initialAmount;
  final double currentAmount;
  final DateTime updatedAt;
  final FinanceBalanceType balanceType;
  final bool operational;
  final double reservedAmount;
  final double warningThreshold;
  final int persistentStressDays;
  final int recoveryDays;
  final String balanceId;

  const FinanceBalance({
    required this.personId,
    required this.balanceId,
    required this.initialAmount,
    required this.currentAmount,
    required this.updatedAt,
    required this.balanceType,
    required this.operational,
    required this.reservedAmount,
    required this.warningThreshold,
    required this.persistentStressDays,
    required this.recoveryDays,
  });

  double get availableAmount => currentAmount - reservedAmount;
  bool get isUnderWarning => availableAmount <= warningThreshold;
  bool get isRecovering => recoveryDays > persistentStressDays;
  bool get isFatigued =>
      persistentStressDays > 7 && !isUnderWarning && !isRecovering;
  bool get isLosingControl =>
      isUnderWarning &&
      persistentStressDays > 14 &&
      recoveryDays < persistentStressDays / 2;
  bool get isBorrowingFromFuture =>
      reservedAmount > availableAmount && persistentStressDays > 21;

  double get resilienceRatio {
    if (persistentStressDays <= 0) {
      return 1;
    }

    return recoveryDays / persistentStressDays;
  }

  bool get isResilient => resilienceRatio >= 1 && !isUnderWarning;
  bool get isSurviving => persistentStressDays > 0 && resilienceRatio < 1;
  bool get isDegrading => isUnderWarning && persistentStressDays > recoveryDays;
  bool get isDrowning => availableAmount <= 0 && persistentStressDays > 30;

  String get vitalityState {
    if (isDrowning) {
      return 'drowning';
    }

    if (isDegrading) {
      return 'degrading';
    }

    if (isLosingControl) {
      return 'losingControl';
    }

    if (isFatigued) {
      return 'fatigued';
    }

    if (isSurviving) {
      return 'surviving';
    }

    if (isRecovering) {
      return 'recovering';
    }

    if (isResilient) {
      return 'stable';
    }

    return 'warning';
  }

  Map<String, dynamic> toJson() {
    return {
      'personId': personId,
      'balanceId': balanceId,
      'initialAmount': initialAmount,
      'currentAmount': currentAmount,
      'updatedAt': updatedAt.toIso8601String(),
      'balanceType': balanceType.name,
      'operational': operational,
      'reservedAmount': reservedAmount,
      'warningThreshold': warningThreshold,
      'persistentStressDays': persistentStressDays,
      'recoveryDays': recoveryDays,
    };
  }

  factory FinanceBalance.fromJson(Map<String, dynamic> json) {
    return FinanceBalance(
      balanceId: json['balanceId'] as String,
      personId: json['personId'] as String,
      initialAmount: (json['initialAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      balanceType: json['balanceType'] == null
          ? FinanceBalanceType.bankAccount
          : FinanceBalanceType.values.firstWhere(
              (e) => e.name == json['balanceType'],
            ),
      operational: json['operational'] as bool? ?? true,
      reservedAmount: (json['reservedAmount'] as num?)?.toDouble() ?? 0,
      warningThreshold: (json['warningThreshold'] as num?)?.toDouble() ?? 200,
      persistentStressDays: (json['persistentStressDays'] as int?) ?? 0,
      recoveryDays: (json['recoveryDays'] as int?) ?? 0,
    );
  }
}
