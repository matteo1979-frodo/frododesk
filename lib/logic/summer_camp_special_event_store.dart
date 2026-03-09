// lib/logic/summer_camp_special_event_store.dart

import 'package:flutter/material.dart';

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
  final Map<String, SummerCampSpecialEvent> _eventsByDay = {};

  SummerCampSpecialEvent? getForDay(DateTime day) {
    return _eventsByDay[summerCampDayKey(day)];
  }

  bool hasEventForDay(DateTime day) {
    return _eventsByDay.containsKey(summerCampDayKey(day));
  }

  void setForDay(DateTime day, SummerCampSpecialEvent event) {
    _eventsByDay[summerCampDayKey(day)] = event;
  }

  void removeForDay(DateTime day) {
    _eventsByDay.remove(summerCampDayKey(day));
  }

  void clearAll() {
    _eventsByDay.clear();
  }

  Map<String, SummerCampSpecialEvent> getAll() {
    return Map<String, SummerCampSpecialEvent>.from(_eventsByDay);
  }
}
