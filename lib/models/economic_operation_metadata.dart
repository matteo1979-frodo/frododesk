enum OperationRole { main, accessory }

enum OperationContext { cashWithdrawal, financialPlanInstallment, utilityBill }

enum AccessoryCostType { bankCommission, postalAcceptanceCharge }

/// Structural metadata shared by distinct economic facts that belong to the
/// same composed operation.
///
/// The economic fact identity remains outside this value object: each fact
/// keeps its own identity while related facts share [operationId].
class EconomicOperationMetadata {
  final String operationId;
  final OperationRole role;
  final OperationContext context;
  final AccessoryCostType? accessoryCostType;

  EconomicOperationMetadata({
    required String operationId,
    required this.role,
    required this.context,
    this.accessoryCostType,
  }) : operationId = operationId.trim() {
    if (this.operationId.isEmpty) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'Must not be empty',
      );
    }
    if (role == OperationRole.main && accessoryCostType != null) {
      throw ArgumentError.value(
        accessoryCostType,
        'accessoryCostType',
        'Must be null for a main fact',
      );
    }
    if (role == OperationRole.accessory && accessoryCostType == null) {
      throw ArgumentError.value(
        accessoryCostType,
        'accessoryCostType',
        'Must be present for an accessory fact',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'role': role.name,
    'context': context.name,
    'accessoryCostType': accessoryCostType?.name,
  };

  factory EconomicOperationMetadata.fromJson(Map<String, dynamic> json) {
    final operationId = _requiredString(json, 'operationId');
    final role = _parseEnum(
      json,
      'role',
      OperationRole.values,
      (value) => value.name,
    );
    final context = _parseEnum(
      json,
      'context',
      OperationContext.values,
      (value) => value.name,
    );
    final accessoryCostTypeValue = json['accessoryCostType'];
    final accessoryCostType = accessoryCostTypeValue == null
        ? null
        : _parseEnum(
            json,
            'accessoryCostType',
            AccessoryCostType.values,
            (value) => value.name,
          );

    return EconomicOperationMetadata(
      operationId: operationId,
      role: role,
      context: context,
      accessoryCostType: accessoryCostType,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key must be a string');
    }
    return value;
  }

  static T _parseEnum<T>(
    Map<String, dynamic> json,
    String key,
    List<T> values,
    String Function(T value) nameOf,
  ) {
    final rawValue = json[key];
    if (rawValue is! String) {
      throw FormatException('$key must be a string');
    }
    for (final value in values) {
      if (nameOf(value) == rawValue) return value;
    }
    throw FormatException('Unknown $key: $rawValue');
  }
}
