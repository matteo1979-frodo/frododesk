enum ExpenseReplacementRole { compensation, replacement }

/// Persistent provenance for the new economic facts produced when an expense
/// is replaced. The original fact remains untouched.
class ExpenseReplacementMetadata {
  final String originalEconomicFactId;
  final String replacementEconomicFactId;
  final ExpenseReplacementRole role;

  ExpenseReplacementMetadata({
    required String originalEconomicFactId,
    required String replacementEconomicFactId,
    required this.role,
  }) : originalEconomicFactId = originalEconomicFactId.trim(),
       replacementEconomicFactId = replacementEconomicFactId.trim() {
    if (this.originalEconomicFactId.isEmpty) {
      throw ArgumentError.value(
        originalEconomicFactId,
        'originalEconomicFactId',
        'Must not be empty',
      );
    }
    if (this.replacementEconomicFactId.isEmpty) {
      throw ArgumentError.value(
        replacementEconomicFactId,
        'replacementEconomicFactId',
        'Must not be empty',
      );
    }
    if (this.originalEconomicFactId == this.replacementEconomicFactId) {
      throw ArgumentError.value(
        replacementEconomicFactId,
        'replacementEconomicFactId',
        'Must differ from originalEconomicFactId',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'originalEconomicFactId': originalEconomicFactId,
    'replacementEconomicFactId': replacementEconomicFactId,
    'role': role.name,
  };

  factory ExpenseReplacementMetadata.fromJson(Map<String, dynamic> json) {
    final originalEconomicFactId = _requiredString(
      json,
      'originalEconomicFactId',
    );
    final replacementEconomicFactId = _requiredString(
      json,
      'replacementEconomicFactId',
    );
    final rawRole = _requiredString(json, 'role');
    ExpenseReplacementRole? role;
    for (final candidate in ExpenseReplacementRole.values) {
      if (candidate.name == rawRole) {
        role = candidate;
        break;
      }
    }
    if (role == null) {
      throw FormatException('Unknown role: $rawRole');
    }
    try {
      return ExpenseReplacementMetadata(
        originalEconomicFactId: originalEconomicFactId,
        replacementEconomicFactId: replacementEconomicFactId,
        role: role,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid expense replacement metadata: $error');
    }
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key must be a string');
    }
    return value;
  }
}
