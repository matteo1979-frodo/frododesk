// lib/logic/alice_event_store.dart

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
  final List<AliceEventPeriod> _events = [];

  List<AliceEventPeriod> get events => List.unmodifiable(_events);

  void addEvent(AliceEventPeriod event) {
    _events.add(event);
    _sortEvents();
  }

  void updateEvent(int index, AliceEventPeriod event) {
    _checkIndex(index);
    _events[index] = event;
    _sortEvents();
  }

  void removeEventAt(int index) {
    _checkIndex(index);
    _events.removeAt(index);
  }

  void clear() {
    _events.clear();
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
    return !isAliceAtHomeDay(day) && !isExternalActivityDay(day);
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
      case AliceEventType.summerCamp:
        return 1;
      case AliceEventType.schoolClosure:
        return 2;
      case AliceEventType.vacation:
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

  static DateTime _normalizeDay(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day, 12);
  }
}
