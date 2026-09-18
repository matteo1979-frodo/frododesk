enum ManualPaymentPreferenceStartAnchor { expectedDueDateMonth }

enum ManualPaymentPreferenceEndAnchor { expectedDueDate }

/// Reusable preference for the period in which a manual payment is handled.
///
/// This contract contains no absolute dates and does not materialize a payment
/// window. The preferred day belongs to the month of the expected due date;
/// the future window ends at that due date.
class ManualPaymentPreference {
  final int preferredStartDayOfMonth;
  final ManualPaymentPreferenceStartAnchor startAnchor;
  final ManualPaymentPreferenceEndAnchor endAnchor;

  ManualPaymentPreference({
    required this.preferredStartDayOfMonth,
    this.startAnchor = ManualPaymentPreferenceStartAnchor.expectedDueDateMonth,
    this.endAnchor = ManualPaymentPreferenceEndAnchor.expectedDueDate,
  }) {
    if (preferredStartDayOfMonth < 1 || preferredStartDayOfMonth > 31) {
      throw ArgumentError.value(
        preferredStartDayOfMonth,
        'preferredStartDayOfMonth',
        'Must be between 1 and 31',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'preferredStartDayOfMonth': preferredStartDayOfMonth,
    'startAnchor': startAnchor.name,
    'endAnchor': endAnchor.name,
  };

  factory ManualPaymentPreference.fromJson(Map<String, dynamic> json) {
    final preferredDay = json['preferredStartDayOfMonth'];
    if (preferredDay is! int) {
      throw const FormatException(
        'preferredStartDayOfMonth must be an integer',
      );
    }

    return ManualPaymentPreference(
      preferredStartDayOfMonth: preferredDay,
      startAnchor: _enumValue(
        json,
        'startAnchor',
        ManualPaymentPreferenceStartAnchor.values,
      ),
      endAnchor: _enumValue(
        json,
        'endAnchor',
        ManualPaymentPreferenceEndAnchor.values,
      ),
    );
  }
}

T _enumValue<T extends Enum>(
  Map<String, dynamic> json,
  String field,
  List<T> values,
) {
  final rawValue = json[field];
  if (rawValue is! String) {
    throw FormatException('$field must be a string');
  }
  final value = values
      .where((candidate) => candidate.name == rawValue)
      .firstOrNull;
  if (value == null) {
    throw FormatException('Unknown $field: $rawValue');
  }
  return value;
}
