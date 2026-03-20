// lib/logic/alice_event_store.dart

import 'dart:convert';

import 'persistence_store.dart';

enum AliceEventType {
  schoolNormal,
  vacation,
  schoolClosure,
  sickness,
  summerCamp,
}

class AliceEventPeriod {
  final DateTime start;
  final DateTime end;
  final AliceEventType type;

  AliceEventPeriod({
    required this.start,
    required this.end,
    required this.type,
  }) {
    if (_normalizeDay(end).isBefore(_normalizeDay(start))) {
      throw ArgumentError('AliceEventPeriod end must be on or after start');
    }
  }

  bool includesDay(DateTime day) {
    final d = _normalizeDay(day);
    final s = _normalizeDay(start);
    final e = _normalizeDay(end);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  AliceEventPeriod copyWith({
    DateTime? start,
    DateTime? end,
    AliceEventType? type,
  }) {
    return AliceEventPeriod(
      start: start ?? this.start,
      end: end ?? this.end,
      type: type ?? this.type,
    );
  }

  static DateTime _normalizeDay(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day, 12);
  }
}

class AliceEventStore {
  static const String _storageKey = 'alice_event_periods_v1';

  final List<AliceEventPeriod> _events = [];

  List<AliceEventPeriod> get events => List.unmodifiable(_events);

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _events.clear();

      for (final item in decoded) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);

        final startYear = map['startYear'];
        final startMonth = map['startMonth'];
        final startDay = map['startDay'];
        final endYear = map['endYear'];
        final endMonth = map['endMonth'];
        final endDay = map['endDay'];
        final typeIndex = map['typeIndex'];

        if (startYear is! int ||
            startMonth is! int ||
            startDay is! int ||
            endYear is! int ||
            endMonth is! int ||
            endDay is! int ||
            typeIndex is! int) {
          continue;
        }

        if (typeIndex < 0 || typeIndex >= AliceEventType.values.length) {
          continue;
        }

        final event = AliceEventPeriod(
          start: DateTime(startYear, startMonth, startDay),
          end: DateTime(endYear, endMonth, endDay),
          type: AliceEventType.values[typeIndex],
        );

        _events.add(event);
      }

      _sortEvents();
    } catch (_) {
      // dati corrotti ignorati
    }
  }

  void addEvent(AliceEventPeriod event) {
    _events.add(event);
    _sortEvents();
    _save();
  }

  void updateEvent(int index, AliceEventPeriod event) {
    _checkIndex(index);
    _events[index] = event;
    _sortEvents();
    _save();
  }

  void removeEventAt(int index) {
    _checkIndex(index);
    _events.removeAt(index);
    _save();
  }

  void clear() {
    _events.clear();
    _save();
  }

  bool hasEventForDay(DateTime day) {
    return getEventForDay(day) != null;
  }

  AliceEventPeriod? getEventForDay(DateTime day) {
    AliceEventPeriod? winner;

    for (final event in _events) {
      if (!event.includesDay(day)) continue;

      if (winner == null) {
        winner = event;
        continue;
      }

      final currentPriority = _eventPriority(event.type);
      final winnerPriority = _eventPriority(winner.type);

      if (currentPriority > winnerPriority) {
        winner = event;
        continue;
      }

      if (currentPriority == winnerPriority) {
        final currentStart = _normalizeDay(event.start);
        final winnerStart = _normalizeDay(winner.start);

        if (currentStart.isAfter(winnerStart)) {
          winner = event;
          continue;
        }

        if (currentStart.isAtSameMomentAs(winnerStart)) {
          final currentEnd = _normalizeDay(event.end);
          final winnerEnd = _normalizeDay(winner.end);

          if (currentEnd.isAfter(winnerEnd)) {
            winner = event;
          }
        }
      }
    }

    return winner;
  }

  AliceEventType? getEventTypeForDay(DateTime day) {
    return getEventForDay(day)?.type;
  }

  AliceEventPeriod? getSummerCampPeriodForDay(DateTime day) {
    final event = getEventForDay(day);
    if (event == null) return null;
    if (event.type != AliceEventType.summerCamp) return null;
    return event;
  }

  bool hasSummerCampPeriodForDay(DateTime day) {
    return getSummerCampPeriodForDay(day) != null;
  }

  bool isVacationDay(DateTime day) {
    return getEventTypeForDay(day) == AliceEventType.vacation;
  }

  bool isSchoolClosureDay(DateTime day) {
    return getEventTypeForDay(day) == AliceEventType.schoolClosure;
  }

  bool isSicknessDay(DateTime day) {
    return getEventTypeForDay(day) == AliceEventType.sickness;
  }

  bool isSummerCampDay(DateTime day) {
    return getEventTypeForDay(day) == AliceEventType.summerCamp;
  }

  bool isAliceAtHomeDay(DateTime day) {
    final type = getEventTypeForDay(day);
    return type == AliceEventType.vacation ||
        type == AliceEventType.schoolClosure ||
        type == AliceEventType.sickness;
  }

  bool isExternalActivityDay(DateTime day) {
    return getEventTypeForDay(day) == AliceEventType.summerCamp;
  }

  bool isSchoolNormalDay(DateTime day) {
    final eventType = getEventTypeForDay(day);

    return eventType != AliceEventType.vacation &&
        eventType != AliceEventType.schoolClosure &&
        eventType != AliceEventType.sickness &&
        eventType != AliceEventType.summerCamp;
  }

  bool isSummerCampOperationalDay(DateTime day) {
    return hasSummerCampPeriodForDay(day);
  }

  void _sortEvents() {
    _events.sort((a, b) {
      final startCompare = _normalizeDay(
        a.start,
      ).compareTo(_normalizeDay(b.start));
      if (startCompare != 0) return startCompare;

      final endCompare = _normalizeDay(a.end).compareTo(_normalizeDay(b.end));
      if (endCompare != 0) return endCompare;

      return _eventPriority(a.type).compareTo(_eventPriority(b.type));
    });
  }

  int _eventPriority(AliceEventType type) {
    switch (type) {
      case AliceEventType.schoolNormal:
        return 0;
      case AliceEventType.schoolClosure:
        return 1;
      case AliceEventType.vacation:
        return 2;
      case AliceEventType.summerCamp:
        return 3;
      case AliceEventType.sickness:
        return 4;
    }
  }

  void _checkIndex(int index) {
    if (index < 0 || index >= _events.length) {
      throw RangeError.index(index, _events, 'index');
    }
  }

  Future<void> _save() async {
    final data = _events
        .map(
          (event) => {
            'startYear': event.start.year,
            'startMonth': event.start.month,
            'startDay': event.start.day,
            'endYear': event.end.year,
            'endMonth': event.end.month,
            'endDay': event.end.day,
            'typeIndex': event.type.index,
          },
        )
        .toList();

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }

  static DateTime _normalizeDay(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day, 12);
  }
}
