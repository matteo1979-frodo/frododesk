const _preservePersonId = Object();

/// Stable, non-economic identity of an ongoing real-world service relationship.
///
/// Economic consequences remain owned by Spese/Expected Expenses and Finance.
class ContinuingServiceRelationship {
  final String relationshipId;
  final String provider;
  final String label;
  final String? personId;
  final bool active;

  ContinuingServiceRelationship({
    required String relationshipId,
    required String provider,
    required String label,
    this.personId,
    this.active = true,
  }) : relationshipId = _requiredText(relationshipId, 'relationshipId'),
       provider = _requiredText(provider, 'provider'),
       label = _requiredText(label, 'label');

  ContinuingServiceRelationship copyWith({
    String? provider,
    String? label,
    Object? personId = _preservePersonId,
    bool? active,
  }) => ContinuingServiceRelationship(
    relationshipId: relationshipId,
    provider: provider ?? this.provider,
    label: label ?? this.label,
    personId: identical(personId, _preservePersonId)
        ? this.personId
        : personId as String?,
    active: active ?? this.active,
  );

  Map<String, dynamic> toJson() => {
    'relationshipId': relationshipId,
    'provider': provider,
    'label': label,
    'personId': personId,
    'active': active,
  };

  factory ContinuingServiceRelationship.fromJson(Map<String, dynamic> json) {
    final personId = json['personId'];
    if (personId != null && personId is! String) {
      throw const FormatException('personId must be a string or null');
    }
    final active = json['active'];
    if (active != null && active is! bool) {
      throw const FormatException('active must be a boolean');
    }
    return ContinuingServiceRelationship(
      relationshipId: _requiredJsonText(json, 'relationshipId'),
      provider: _requiredJsonText(json, 'provider'),
      label: _requiredJsonText(json, 'label'),
      personId: personId as String?,
      active: active as bool? ?? true,
    );
  }

  static String _requiredJsonText(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key must be a string');
    }
    return value;
  }
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty');
  }
  return normalized;
}
