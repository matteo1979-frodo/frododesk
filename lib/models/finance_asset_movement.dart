enum FinanceAssetMovementKind {
  fundOpening,
  fundAllocation,
  fundRelease,
  fundExpense,
  fundTransferOut,
  fundTransferIn,
  legacyOpening,
  legacyUnclassified,
}

enum FinanceAssetLegType {
  balance,
  fund,
  openingBalance,
  expense,
  legacyCounterpart,
}

class FinanceAssetLeg {
  final FinanceAssetLegType type;
  final String? referenceId;
  final double delta;

  const FinanceAssetLeg({
    required this.type,
    this.referenceId,
    required this.delta,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'referenceId': referenceId,
    'delta': delta,
  };

  factory FinanceAssetLeg.fromJson(Map<String, dynamic> json) {
    return FinanceAssetLeg(
      type: FinanceAssetLegType.values.firstWhere(
        (value) => value.name == json['type'],
      ),
      referenceId: json['referenceId'] as String?,
      delta: (json['delta'] as num).toDouble(),
    );
  }
}

class FinanceAssetMovement {
  final String id;
  final String fundId;
  final FinanceAssetMovementKind kind;
  final String description;
  final DateTime occurredAt;
  final List<FinanceAssetLeg> legs;
  final String? economicFactId;

  const FinanceAssetMovement({
    required this.id,
    required this.fundId,
    required this.kind,
    required this.description,
    required this.occurredAt,
    required this.legs,
    this.economicFactId,
  });

  double get ownedWealthDelta => legs
      .where(
        (leg) =>
            leg.type == FinanceAssetLegType.balance ||
            leg.type == FinanceAssetLegType.fund,
      )
      .fold(0, (sum, leg) => sum + leg.delta);

  double get accountingDelta => legs.fold(0, (sum, leg) => sum + leg.delta);

  Map<String, dynamic> toJson() => {
    'id': id,
    'fundId': fundId,
    'kind': kind.name,
    'description': description,
    'occurredAt': occurredAt.toIso8601String(),
    'legs': legs.map((leg) => leg.toJson()).toList(),
    'economicFactId': economicFactId,
  };

  factory FinanceAssetMovement.fromJson(Map<String, dynamic> json) {
    return FinanceAssetMovement(
      id: json['id'] as String,
      fundId: json['fundId'] as String,
      kind: FinanceAssetMovementKind.values.firstWhere(
        (value) => value.name == json['kind'],
      ),
      description: json['description'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      legs: (json['legs'] as List)
          .map(
            (leg) => FinanceAssetLeg.fromJson(Map<String, dynamic>.from(leg)),
          )
          .toList(),
      economicFactId: json['economicFactId'] as String?,
    );
  }
}

class FinanceMoneyPortion {
  final String balanceId;
  final double amount;

  const FinanceMoneyPortion({required this.balanceId, required this.amount});
}
