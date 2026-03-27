// lib/logic/summer_camp_schedule_store.dart

import 'package:flutter/material.dart';

class SummerCampDayConfig {
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  const SummerCampDayConfig({
    required this.enabled,
    required this.start,
    required this.end,
  });

  SummerCampDayConfig copyWith({
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return SummerCampDayConfig(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

class SummerCampWeekConfig {
  final SummerCampDayConfig monday;
  final SummerCampDayConfig tuesday;
  final SummerCampDayConfig wednesday;
  final SummerCampDayConfig thursday;
  final SummerCampDayConfig friday;
  final SummerCampDayConfig saturday;
  final SummerCampDayConfig sunday;

  const SummerCampWeekConfig({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory SummerCampWeekConfig.standard() {
    const defaultDay = SummerCampDayConfig(
      enabled: true,
      start: TimeOfDay(hour: 8, minute: 30),
      end: TimeOfDay(hour: 17, minute: 30),
    );

    const offDay = SummerCampDayConfig(
      enabled: false,
      start: TimeOfDay(hour: 8, minute: 30),
      end: TimeOfDay(hour: 17, minute: 30),
    );

    return const SummerCampWeekConfig(
      monday: defaultDay,
      tuesday: defaultDay,
      wednesday: defaultDay,
      thursday: defaultDay,
      friday: defaultDay,
      saturday: offDay,
      sunday: offDay,
    );
  }

  SummerCampDayConfig forWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        throw ArgumentError('Invalid weekday: $weekday');
    }
  }

  SummerCampWeekConfig copyWith({
    SummerCampDayConfig? monday,
    SummerCampDayConfig? tuesday,
    SummerCampDayConfig? wednesday,
    SummerCampDayConfig? thursday,
    SummerCampDayConfig? friday,
    SummerCampDayConfig? saturday,
    SummerCampDayConfig? sunday,
  }) {
    return SummerCampWeekConfig(
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
    );
  }
}

class SummerCampScheduleStore {
  SummerCampWeekConfig _weekConfig = SummerCampWeekConfig.standard();

  // 🔥 NUOVO: override giornalieri
  final Map<String, SummerCampDayConfig> _dailyOverrides = {};

  SummerCampWeekConfig get weekConfig => _weekConfig;

  String _dayKey(DateTime day) {
    return "${day.year}-${day.month}-${day.day}";
  }

  SummerCampDayConfig getConfigForDay(DateTime day) {
    return _weekConfig.forWeekday(day.weekday);
  }

  SummerCampDayConfig getEffectiveConfigForDay(DateTime day) {
    final key = _dayKey(day);

    if (_dailyOverrides.containsKey(key)) {
      return _dailyOverrides[key]!;
    }

    return getConfigForDay(day);
  }

  bool hasOverrideForDay(DateTime day) {
    final key = _dayKey(day);
    return _dailyOverrides.containsKey(key);
  }

  void setOverrideForDay(DateTime day, SummerCampDayConfig config) {
    final key = _dayKey(day);
    _dailyOverrides[key] = config;
  }

  void removeOverrideForDay(DateTime day) {
    final key = _dayKey(day);
    _dailyOverrides.remove(key);
  }

  bool isEnabledForDay(DateTime day) {
    return getEffectiveConfigForDay(day).enabled;
  }

  TimeOfDay getStartForDay(DateTime day) {
    return getEffectiveConfigForDay(day).start;
  }

  TimeOfDay getEndForDay(DateTime day) {
    return getEffectiveConfigForDay(day).end;
  }

  void setWholeWeek(SummerCampWeekConfig config) {
    _weekConfig = config;
  }

  void setDayConfig(int weekday, SummerCampDayConfig config) {
    switch (weekday) {
      case DateTime.monday:
        _weekConfig = _weekConfig.copyWith(monday: config);
        return;
      case DateTime.tuesday:
        _weekConfig = _weekConfig.copyWith(tuesday: config);
        return;
      case DateTime.wednesday:
        _weekConfig = _weekConfig.copyWith(wednesday: config);
        return;
      case DateTime.thursday:
        _weekConfig = _weekConfig.copyWith(thursday: config);
        return;
      case DateTime.friday:
        _weekConfig = _weekConfig.copyWith(friday: config);
        return;
      case DateTime.saturday:
        _weekConfig = _weekConfig.copyWith(saturday: config);
        return;
      case DateTime.sunday:
        _weekConfig = _weekConfig.copyWith(sunday: config);
        return;
      default:
        throw ArgumentError('Invalid weekday: $weekday');
    }
  }
}
