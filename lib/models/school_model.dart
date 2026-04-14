class SchoolDayConfig {
  final bool enabled;
  final int entryMinutes;
  final int exitRealMinutes;

  const SchoolDayConfig({
    required this.enabled,
    required this.entryMinutes,
    required this.exitRealMinutes,
  });

  const SchoolDayConfig.off()
    : enabled = false,
      entryMinutes = 0,
      exitRealMinutes = 0;

  int get returnHomeMinutes => exitRealMinutes + 20;

  SchoolDayConfig copyWith({
    bool? enabled,
    int? entryMinutes,
    int? exitRealMinutes,
  }) {
    return SchoolDayConfig(
      enabled: enabled ?? this.enabled,
      entryMinutes: entryMinutes ?? this.entryMinutes,
      exitRealMinutes: exitRealMinutes ?? this.exitRealMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'entryMinutes': entryMinutes,
      'exitRealMinutes': exitRealMinutes,
    };
  }

  factory SchoolDayConfig.fromJson(Map<String, dynamic> json) {
    return SchoolDayConfig(
      enabled: json['enabled'] ?? false,
      entryMinutes: json['entryMinutes'] ?? 0,
      exitRealMinutes: json['exitRealMinutes'] ?? 0,
    );
  }
}

class SchoolWeekConfig {
  final SchoolDayConfig monday;
  final SchoolDayConfig tuesday;
  final SchoolDayConfig wednesday;
  final SchoolDayConfig thursday;
  final SchoolDayConfig friday;
  final SchoolDayConfig saturday;

  const SchoolWeekConfig({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
  });

  factory SchoolWeekConfig.empty() {
    return const SchoolWeekConfig(
      monday: SchoolDayConfig.off(),
      tuesday: SchoolDayConfig.off(),
      wednesday: SchoolDayConfig.off(),
      thursday: SchoolDayConfig.off(),
      friday: SchoolDayConfig.off(),
      saturday: SchoolDayConfig.off(),
    );
  }

  SchoolDayConfig forWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return monday;
      case 2:
        return tuesday;
      case 3:
        return wednesday;
      case 4:
        return thursday;
      case 5:
        return friday;
      case 6:
        return saturday;
      default:
        return const SchoolDayConfig.off();
    }
  }

  SchoolWeekConfig copyWith({
    SchoolDayConfig? monday,
    SchoolDayConfig? tuesday,
    SchoolDayConfig? wednesday,
    SchoolDayConfig? thursday,
    SchoolDayConfig? friday,
    SchoolDayConfig? saturday,
  }) {
    return SchoolWeekConfig(
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monday': monday.toJson(),
      'tuesday': tuesday.toJson(),
      'wednesday': wednesday.toJson(),
      'thursday': thursday.toJson(),
      'friday': friday.toJson(),
      'saturday': saturday.toJson(),
    };
  }

  factory SchoolWeekConfig.fromJson(Map<String, dynamic> json) {
    return SchoolWeekConfig(
      monday: SchoolDayConfig.fromJson(
        Map<String, dynamic>.from(json['monday'] ?? {}),
      ),
      tuesday: SchoolDayConfig.fromJson(
        Map<String, dynamic>.from(json['tuesday'] ?? {}),
      ),
      wednesday: SchoolDayConfig.fromJson(
        Map<String, dynamic>.from(json['wednesday'] ?? {}),
      ),
      thursday: SchoolDayConfig.fromJson(
        Map<String, dynamic>.from(json['thursday'] ?? {}),
      ),
      friday: SchoolDayConfig.fromJson(
        Map<String, dynamic>.from(json['friday'] ?? {}),
      ),
      saturday: SchoolDayConfig.fromJson(
        Map<String, dynamic>.from(json['saturday'] ?? {}),
      ),
    );
  }
}

class SchoolPeriod {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final SchoolWeekConfig weekConfig;

  const SchoolPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.weekConfig,
  });

  bool isActiveOn(DateTime day) {
    final checkDay = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return !checkDay.isBefore(start) && !checkDay.isAfter(end);
  }

  SchoolPeriod copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    SchoolWeekConfig? weekConfig,
  }) {
    return SchoolPeriod(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weekConfig: weekConfig ?? this.weekConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': _dateOnlyToIso(startDate),
      'endDate': _dateOnlyToIso(endDate),
      'weekConfig': weekConfig.toJson(),
    };
  }

  factory SchoolPeriod.fromJson(Map<String, dynamic> json) {
    return SchoolPeriod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      weekConfig: SchoolWeekConfig.fromJson(
        Map<String, dynamic>.from(json['weekConfig'] ?? {}),
      ),
    );
  }

  static String _dateOnlyToIso(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }
}
