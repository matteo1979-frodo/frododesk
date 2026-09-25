/// SIM-specific details owned by a [ContinuingServiceRelationship].
///
/// This model intentionally contains no pricing, cadence, current credit or
/// payment facts. Those remain owned by Spese and Finanze.
class SimServiceDetails {
  final String relationshipId;
  final String phoneNumber;
  final String offerName;
  final DateTime activationDate;
  final DateTime simExpirationDate;
  final String? creditBalanceId;
  final String? expenseRelationshipId;

  SimServiceDetails({
    required String relationshipId,
    required String phoneNumber,
    required String offerName,
    required this.activationDate,
    required this.simExpirationDate,
    this.creditBalanceId,
    this.expenseRelationshipId,
  }) : relationshipId = _required(relationshipId, 'relationshipId'),
       phoneNumber = _required(phoneNumber, 'phoneNumber'),
       offerName = _required(offerName, 'offerName');

  /// Ordinary UI representation. Numbers of four digits or fewer are shown
  /// unchanged because masking them would remove the only distinguishing data.
  String get maskedPhoneNumber {
    final visible = phoneNumber.length < 4 ? phoneNumber.length : 4;
    if (phoneNumber.length <= visible) return phoneNumber;
    return '${'*' * (phoneNumber.length - visible)}${phoneNumber.substring(phoneNumber.length - visible)}';
  }

  SimServiceDetails copyWith({
    String? phoneNumber,
    String? offerName,
    DateTime? activationDate,
    DateTime? simExpirationDate,
    Object? creditBalanceId = _preserveCreditBalanceId,
    Object? expenseRelationshipId = _preserveExpenseRelationshipId,
  }) => SimServiceDetails(
    relationshipId: relationshipId,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    offerName: offerName ?? this.offerName,
    activationDate: activationDate ?? this.activationDate,
    simExpirationDate: simExpirationDate ?? this.simExpirationDate,
    creditBalanceId: identical(creditBalanceId, _preserveCreditBalanceId)
        ? this.creditBalanceId
        : creditBalanceId as String?,
    expenseRelationshipId:
        identical(expenseRelationshipId, _preserveExpenseRelationshipId)
        ? this.expenseRelationshipId
        : expenseRelationshipId as String?,
  );

  Map<String, dynamic> toJson() => {
    'relationshipId': relationshipId,
    'phoneNumber': phoneNumber,
    'offerName': offerName,
    'activationDate': activationDate.toIso8601String(),
    'simExpirationDate': simExpirationDate.toIso8601String(),
    'creditBalanceId': creditBalanceId,
    'expenseRelationshipId': expenseRelationshipId,
  };

  factory SimServiceDetails.fromJson(Map<String, dynamic> json) {
    final credit = json['creditBalanceId'];
    if (credit != null && credit is! String) {
      throw const FormatException('creditBalanceId must be a string or null');
    }
    final expense = json['expenseRelationshipId'];
    if (expense != null && expense is! String) {
      throw const FormatException(
        'expenseRelationshipId must be a string or null',
      );
    }
    return SimServiceDetails(
      relationshipId: _jsonText(json, 'relationshipId'),
      phoneNumber: _jsonText(json, 'phoneNumber'),
      offerName: _jsonText(json, 'offerName'),
      activationDate: DateTime.parse(_jsonText(json, 'activationDate')),
      simExpirationDate: DateTime.parse(_jsonText(json, 'simExpirationDate')),
      creditBalanceId: credit as String?,
      expenseRelationshipId: expense as String?,
    );
  }
}

const _preserveCreditBalanceId = Object();
const _preserveExpenseRelationshipId = Object();

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field, 'Must not be empty');
  return normalized;
}

String _jsonText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}
