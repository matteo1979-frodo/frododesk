import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/real_event.dart';
import 'persistence_store.dart';

class RealEventStore {
  static const String _eventsKey = 'real_events_v1';

  final Map<String, List<RealEvent>> _eventsByDay = {};
  final List<RealEvent> _allEvents = [];

  String _key(DateTime d) {
    return "${d.year}-${d.month}-${d.day}";
  }

  DateTime _normalize(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  // --------------------------------------------------
  // LOAD
  // --------------------------------------------------

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_eventsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _allEvents.clear();
      _eventsByDay.clear();

      for (final item in decoded) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);

        final id = map['id'];
        final startYear = map['startYear'];
        final startMonth = map['startMonth'];
        final startDay = map['startDay'];
        final endYear = map['endYear'];
        final endMonth = map['endMonth'];
        final endDay = map['endDay'];
        final title = map['title'];
        final typeIndex = map['typeIndex'];

        if (id is! String ||
            startYear is! int ||
            startMonth is! int ||
            startDay is! int ||
            endYear is! int ||
            endMonth is! int ||
            endDay is! int ||
            title is! String ||
            typeIndex is! int) {
          continue;
        }

        final startDate = DateTime(startYear, startMonth, startDay);
        final endDate = DateTime(endYear, endMonth, endDay);

        TimeOfDay? startTime;
        final startHour = map['startHour'];
        final startMinute = map['startMinute'];
        if (startHour is int && startMinute is int) {
          startTime = TimeOfDay(hour: startHour, minute: startMinute);
        }

        TimeOfDay? endTime;
        final endHour = map['endHour'];
        final endMinute = map['endMinute'];
        if (endHour is int && endMinute is int) {
          endTime = TimeOfDay(hour: endHour, minute: endMinute);
        }

        final location = map['location'] is String
            ? map['location'] as String
            : null;

        final personKey = map['personKey'] is String
            ? map['personKey'] as String
            : null;

        final rawParticipantKeys = map['participantKeys'];
        final participantKeys = rawParticipantKeys is List
            ? rawParticipantKeys.whereType<String>().toList()
            : <String>[];

        final notes = map['notes'] is String ? map['notes'] as String : null;

        final safeType =
            (typeIndex >= 0 && typeIndex < RealEventType.values.length)
            ? RealEventType.values[typeIndex]
            : RealEventType.generic;

        final event = RealEvent(
          id: id,
          startDate: startDate,
          endDate: endDate,
          title: title,
          startTime: startTime,
          endTime: endTime,
          type: safeType,
          location: location,
          personKey: personKey,
          participantKeys: participantKeys,
          notes: notes,
        );

        _allEvents.add(event);
      }

      _rebuildIndex();
    } catch (_) {
      // dati corrotti ignorati
    }
  }

  // --------------------------------------------------
  // READ
  // --------------------------------------------------

  List<RealEvent> eventsForDay(DateTime day) {
    return List.unmodifiable(_eventsByDay[_key(_normalize(day))] ?? []);
  }

  List<RealEvent> eventsForPersonOnDay({
    required DateTime day,
    required String personKey,
  }) {
    final events = eventsForDay(
      day,
    ).where((e) => e.involvesPerson(personKey)).toList();

    events.sort(_compareEventsByStart);
    return List.unmodifiable(events);
  }

  List<RealEvent> get allEvents => List.unmodifiable(_allEvents);

  bool hasConflictsForPersonOnDay({
    required DateTime day,
    required String personKey,
  }) {
    return overlappingPairsForPersonOnDay(
      day: day,
      personKey: personKey,
    ).isNotEmpty;
  }

  List<RealEventConflict> overlappingPairsForPersonOnDay({
    required DateTime day,
    required String personKey,
  }) {
    final d0 = _normalize(day);

    final events = eventsForPersonOnDay(
      day: d0,
      personKey: personKey,
    ).where(_isTimedSingleDayEvent).toList();

    final conflicts = <RealEventConflict>[];

    for (var i = 0; i < events.length; i++) {
      for (var j = i + 1; j < events.length; j++) {
        final a = events[i];
        final b = events[j];

        if (_eventsOverlapOnDay(a, b, d0)) {
          conflicts.add(RealEventConflict(first: a, second: b));
        }
      }
    }

    return List.unmodifiable(conflicts);
  }

  // --------------------------------------------------
  // WRITE
  // --------------------------------------------------

  void addEvent(RealEvent event) {
    _allEvents.removeWhere((e) => e.id == event.id);
    _allEvents.add(event);
    _rebuildIndex();
    _save();
  }

  void updateEventNotes({required String id, required String notes}) {
    final index = _allEvents.indexWhere((e) => e.id == id);
    if (index == -1) return;

    _allEvents[index] = _allEvents[index].copyWith(notes: notes);
    _rebuildIndex();
    _save();
  }

  void removeEvent(String id) {
    _allEvents.removeWhere((e) => e.id == id);
    _rebuildIndex();
    _save();
  }

  void clearDay(DateTime day) {
    final d0 = _normalize(day);

    _allEvents.removeWhere(
      (event) =>
          !d0.isBefore(_normalize(event.startDate)) &&
          !d0.isAfter(_normalize(event.endDate)),
    );

    _rebuildIndex();
    _save();
  }

  // --------------------------------------------------
  // INTERNAL
  // --------------------------------------------------

  void _rebuildIndex() {
    _eventsByDay.clear();

    for (final event in _allEvents) {
      final start = _normalize(event.startDate);
      final end = _normalize(event.endDate);

      DateTime current = start;
      while (!current.isAfter(end)) {
        final k = _key(current);
        final list = _eventsByDay.putIfAbsent(k, () => []);
        list.add(event);

        current = current.add(const Duration(days: 1));
      }
    }
  }

  int _compareEventsByStart(RealEvent a, RealEvent b) {
    final aHasTime = a.startTime != null;
    final bHasTime = b.startTime != null;

    if (aHasTime && bHasTime) {
      final ah = a.startTime!.hour;
      final am = a.startTime!.minute;
      final bh = b.startTime!.hour;
      final bm = b.startTime!.minute;

      if (ah != bh) return ah.compareTo(bh);
      if (am != bm) return am.compareTo(bm);
    }

    if (aHasTime && !bHasTime) return -1;
    if (!aHasTime && bHasTime) return 1;

    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  bool _isTimedSingleDayEvent(RealEvent event) {
    final sameDay = _normalize(event.startDate) == _normalize(event.endDate);

    return sameDay && event.startTime != null && event.endTime != null;
  }

  bool _eventsOverlapOnDay(RealEvent a, RealEvent b, DateTime day) {
    if (!_isTimedSingleDayEvent(a) || !_isTimedSingleDayEvent(b)) {
      return false;
    }

    final aStart = _toDateTime(day, a.startTime!);
    final aEnd = _toDateTime(day, a.endTime!);
    final bStart = _toDateTime(day, b.startTime!);
    final bEnd = _toDateTime(day, b.endTime!);

    if (!aEnd.isAfter(aStart) || !bEnd.isAfter(bStart)) {
      return false;
    }

    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  DateTime _toDateTime(DateTime day, TimeOfDay time) {
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final data = _allEvents
        .map(
          (event) => {
            'id': event.id,
            'startYear': event.startDate.year,
            'startMonth': event.startDate.month,
            'startDay': event.startDate.day,
            'endYear': event.endDate.year,
            'endMonth': event.endDate.month,
            'endDay': event.endDate.day,
            'title': event.title,
            'startHour': event.startTime?.hour,
            'startMinute': event.startTime?.minute,
            'endHour': event.endTime?.hour,
            'endMinute': event.endTime?.minute,
            'typeIndex': event.type.index,
            'location': event.location,
            'personKey': event.personKey,
            'participantKeys': event.participantKeys,
            'notes': event.notes,
          },
        )
        .toList();

    await PersistenceStore.saveString(_eventsKey, jsonEncode(data));
  }
}

class RealEventConflict {
  final RealEvent first;
  final RealEvent second;

  const RealEventConflict({required this.first, required this.second});
}
