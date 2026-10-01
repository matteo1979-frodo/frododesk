enum CompositeCorrectionFactRole { compensation, replacement }

class CompositeCorrectionMetadata {
  final String correctionId;
  final String operationId;
  final String? originalEconomicFactId;
  final String? replacementEconomicFactId;
  final CompositeCorrectionFactRole role;
  final int revision;

  CompositeCorrectionMetadata({
    required this.correctionId,
    required this.operationId,
    this.originalEconomicFactId,
    this.replacementEconomicFactId,
    required this.role,
    required this.revision,
  }) {
    for (final entry in <String, String>{
      'correctionId': correctionId,
      'operationId': operationId,
    }.entries) {
      if (entry.value.trim().isEmpty || entry.value != entry.value.trim()) {
        throw ArgumentError.value(entry.value, entry.key, 'Must be non-empty');
      }
    }
    if (originalEconomicFactId != null &&
        (originalEconomicFactId!.trim().isEmpty ||
            originalEconomicFactId != originalEconomicFactId!.trim())) {
      throw ArgumentError.value(
        originalEconomicFactId,
        'originalEconomicFactId',
        'Must be non-empty',
      );
    }
    if (replacementEconomicFactId != null &&
        (replacementEconomicFactId!.trim().isEmpty ||
            replacementEconomicFactId != replacementEconomicFactId!.trim())) {
      throw ArgumentError.value(
        replacementEconomicFactId,
        'replacementEconomicFactId',
        'Must be non-empty',
      );
    }
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'Must be positive');
    }
  }

  Map<String, dynamic> toJson() => {
    'correctionId': correctionId,
    'operationId': operationId,
    'originalEconomicFactId': originalEconomicFactId,
    'replacementEconomicFactId': replacementEconomicFactId,
    'role': role.name,
    'revision': revision,
  };

  factory CompositeCorrectionMetadata.fromJson(Map<String, dynamic> json) =>
      CompositeCorrectionMetadata(
        correctionId: json['correctionId'] as String,
        operationId: json['operationId'] as String,
        originalEconomicFactId: json['originalEconomicFactId'] as String?,
        replacementEconomicFactId: json['replacementEconomicFactId'] as String?,
        role: CompositeCorrectionFactRole.values.firstWhere(
          (value) => value.name == json['role'],
        ),
        revision: json['revision'] as int,
      );
}
