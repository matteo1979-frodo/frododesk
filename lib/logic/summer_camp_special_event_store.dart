// lib/logic/summer_camp_special_event_store.dart

import 'dart:convert';
import 'package:flutter/material.dart';

import 'persistence_store.dart';

String summerCampDayKey(DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class SummerCampSpecialEvent {
  final bool enabled;
  final String label;
  final TimeOfDay start;
  final TimeOfDay end;

  const SummerCampSpecialEvent({
    required this.enabled,
    required this.label,
    required this.start,
    required this.end,
  });

  SummerCampSpecialEvent copyWith({
    bool? enabled,
    String? label,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return SummerCampSpecialEvent(
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

class SummerCampSpecialEventStore {
  static const String _storageKey = 'summer_camp_special_events_v1';
  final Map<String, SummerCampSpecialEvent> _eventsByDay = {};

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      _eventsByDay.clear();

      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key is! String || value is! Map) continue;

        final map = Map<String, dynamic>.from(value);

        final enabled = map['enabled'];
        final label = map['label'];
        final startHour = map['startHour'];
        final startMinute = map['startMinute'];
        final endHour = map['endHour'];
        final endMinute = map['endMinute'];

        if (enabled is! bool ||
            label is! String ||
            startHour is! int ||
            startMinute is! int ||
            endHour is! int ||
            endMinute is! int) {
          continue;
        }

        _eventsByDay[key] = SummerCampSpecialEvent(
          enabled: enabled,
          label: label,
          start: TimeOfDay(hour: startHour, minute: startMinute),
          end: TimeOfDay(hour: endHour, minute: endMinute),
        );
      }
    } catch (_) {
      // dati corrotti ignorati
    }
  }

  SummerCampSpecialEvent? getForDay(DateTime day) {
    return _eventsByDay[summerCampDayKey(day)];
  }

  bool hasEventForDay(DateTime day) {
    return _eventsByDay.containsKey(summerCampDayKey(day));
  }

  void setForDay(DateTime day, SummerCampSpecialEvent event) {
    _eventsByDay[summerCampDayKey(day)] = event;
    _save();
  }

  void removeForDay(DateTime day) {
    _eventsByDay.remove(summerCampDayKey(day));
    _save();
  }

  void clearAll() {
    _eventsByDay.clear();
    _save();
  }

  Map<String, SummerCampSpecialEvent> getAll() {
    return Map<String, SummerCampSpecialEvent>.from(_eventsByDay);
  }

  Future<void> _save() async {
    final data = _eventsByDay.map(
      (key, event) => MapEntry(key, {
        'enabled': event.enabled,
        'label': event.label,
        'startHour': event.start.hour,
        'startMinute': event.start.minute,
        'endHour': event.end.hour,
        'endMinute': event.end.minute,
      }),
    );

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }
}
