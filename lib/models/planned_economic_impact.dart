enum PlannedEconomicImpactOrigin { userDecision }

/// An occurrence-specific plan for when its economic impact should happen.
///
/// This is neither a due date nor a payment preference. A single planned date
/// is represented by equal [start] and [end] values.
class PlannedEconomicImpact {
  final DateTime start;
  final DateTime end;
  final PlannedEconomicImpactOrigin origin;

  PlannedEconomicImpact({
    required this.start,
    required this.end,
    required this.origin,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'Must not be before start');
    }
  }

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'origin': origin.name,
  };

  factory PlannedEconomicImpact.fromJson(Map<String, dynamic> json) {
    final startRaw = json['start'];
    final endRaw = json['end'];
    final originRaw = json['origin'];
    if (startRaw is! String) {
      throw const FormatException('start must be a string');
    }
    if (endRaw is! String) {
      throw const FormatException('end must be a string');
    }
    if (originRaw is! String) {
      throw const FormatException('origin must be a string');
    }
    final origin = PlannedEconomicImpactOrigin.values
        .where((value) => value.name == originRaw)
        .firstOrNull;
    if (origin == null) {
      throw FormatException(
        'Unknown planned economic impact origin: $originRaw',
      );
    }
    return PlannedEconomicImpact(
      start: DateTime.parse(startRaw),
      end: DateTime.parse(endRaw),
      origin: origin,
    );
  }
}
