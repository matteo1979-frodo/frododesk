import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/school_model.dart';
import 'persistence_store.dart';
import 'calendar_logic.dart';

class SchoolStore {
  static const String _storageKey = 'school_periods_v1';

  final List<SchoolPeriod> _periods = [];

  List<SchoolPeriod> get periods => List.unmodifiable(_periods);

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _periods.clear();

      for (final item in decoded) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);

        final id = map['id'];
        final name = map['name'];
        final startYear = map['startYear'];
        final startMonth = map['startMonth'];
        final startDay = map['startDay'];
        final endYear = map['endYear'];
        final endMonth = map['endMonth'];
        final endDay = map['endDay'];
        final weekConfigRaw = map['weekConfig'];

        if (id is! String ||
            name is! String ||
            startYear is! int ||
            startMonth is! int ||
            startDay is! int ||
            endYear is! int ||
            endMonth is! int ||
            endDay is! int ||
            weekConfigRaw is! Map) {
          continue;
        }

        final period = SchoolPeriod(
          id: id,
          name: name,
          startDate: DateTime(startYear, startMonth, startDay),
          endDate: DateTime(endYear, endMonth, endDay),
          weekConfig: _weekConfigFromMap(
            Map<String, dynamic>.from(weekConfigRaw),
          ),
        );

        _periods.add(period);
      }

      _sortPeriods();
    } catch (_) {
      // dati corrotti ignorati
    }
  }

  void setPeriods(List<SchoolPeriod> periods) {
    _periods
      ..clear()
      ..addAll(periods);
    _sortPeriods();
    _save();
  }

  void addPeriod(SchoolPeriod period) {
    _periods.add(period);
    _sortPeriods();
    _save();
  }

  void updatePeriod(SchoolPeriod updatedPeriod) {
    final index = _periods.indexWhere((p) => p.id == updatedPeriod.id);
    if (index == -1) return;
    _periods[index] = updatedPeriod;
    _sortPeriods();
    _save();
  }

  void removePeriod(String periodId) {
    _periods.removeWhere((p) => p.id == periodId);
    _save();
  }

  SchoolPeriod? activePeriodForDay(DateTime day) {
    for (final period in _periods) {
      if (period.isActiveOn(day)) {
        return period;
      }
    }
    return null;
  }

  SchoolDayConfig? schoolDayConfigFor(DateTime day) {
    final activePeriod = activePeriodForDay(day);
    if (activePeriod == null) return null;

    if (isItalianHoliday(day)) return null;

    final weekdayConfig = activePeriod.weekConfig.forWeekday(day.weekday);
    if (!weekdayConfig.enabled) return null;

    return weekdayConfig;
  }

  bool hasSchoolOn(DateTime day) {
    return schoolDayConfigFor(day) != null;
  }

  void clear() {
    _periods.clear();
    _save();
  }

  void _sortPeriods() {
    _periods.sort((a, b) {
      final startCompare = _normalizeDay(
        a.startDate,
      ).compareTo(_normalizeDay(b.startDate));
      if (startCompare != 0) return startCompare;

      final endCompare = _normalizeDay(
        a.endDate,
      ).compareTo(_normalizeDay(b.endDate));
      if (endCompare != 0) return endCompare;

      return a.name.compareTo(b.name);
    });
  }

  Future<void> _save() async {
    final data = _periods
        .map(
          (period) => {
            'id': period.id,
            'name': period.name,
            'startYear': period.startDate.year,
            'startMonth': period.startDate.month,
            'startDay': period.startDate.day,
            'endYear': period.endDate.year,
            'endMonth': period.endDate.month,
            'endDay': period.endDate.day,
            'weekConfig': _weekConfigToMap(period.weekConfig),
          },
        )
        .toList();

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }

  Map<String, dynamic> _weekConfigToMap(SchoolWeekConfig config) {
    return {
      'monday': _dayConfigToMap(config.monday),
      'tuesday': _dayConfigToMap(config.tuesday),
      'wednesday': _dayConfigToMap(config.wednesday),
      'thursday': _dayConfigToMap(config.thursday),
      'friday': _dayConfigToMap(config.friday),
      'saturday': _dayConfigToMap(config.saturday),
    };
  }

  Map<String, dynamic> _dayConfigToMap(SchoolDayConfig config) {
    return {
      'enabled': config.enabled,
      'entryHour': _hourFromMinutes(config.entryMinutes),
      'entryMinute': _minuteFromMinutes(config.entryMinutes),
      'exitHour': _hourFromMinutes(config.exitRealMinutes),
      'exitMinute': _minuteFromMinutes(config.exitRealMinutes),
    };
  }

  SchoolWeekConfig _weekConfigFromMap(Map<String, dynamic> map) {
    return SchoolWeekConfig(
      monday: _dayConfigFromMap(Map<String, dynamic>.from(map['monday'] ?? {})),
      tuesday: _dayConfigFromMap(
        Map<String, dynamic>.from(map['tuesday'] ?? {}),
      ),
      wednesday: _dayConfigFromMap(
        Map<String, dynamic>.from(map['wednesday'] ?? {}),
      ),
      thursday: _dayConfigFromMap(
        Map<String, dynamic>.from(map['thursday'] ?? {}),
      ),
      friday: _dayConfigFromMap(Map<String, dynamic>.from(map['friday'] ?? {})),
      saturday: _dayConfigFromMap(
        Map<String, dynamic>.from(map['saturday'] ?? {}),
      ),
    );
  }

  SchoolDayConfig _dayConfigFromMap(Map<String, dynamic> map) {
    final enabled = map['enabled'];
    final entryHour = map['entryHour'];
    final entryMinute = map['entryMinute'];
    final exitHour = map['exitHour'];
    final exitMinute = map['exitMinute'];

    if (enabled is! bool) {
      return const SchoolDayConfig.off();
    }

    if (!enabled) {
      return const SchoolDayConfig.off();
    }

    if (entryHour is! int ||
        entryMinute is! int ||
        exitHour is! int ||
        exitMinute is! int) {
      return const SchoolDayConfig.off();
    }

    final entry = TimeOfDay(hour: entryHour, minute: entryMinute);
    final exit = TimeOfDay(hour: exitHour, minute: exitMinute);

    return SchoolDayConfig(
      enabled: true,
      entryMinutes: _timeOfDayToMinutes(entry),
      exitRealMinutes: _timeOfDayToMinutes(exit),
    );
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  int _hourFromMinutes(int totalMinutes) {
    return totalMinutes ~/ 60;
  }

  int _minuteFromMinutes(int totalMinutes) {
    return totalMinutes % 60;
  }

  DateTime _normalizeDay(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day, 12);
  }
}
