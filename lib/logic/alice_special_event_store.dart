import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/alice_special_event.dart';
import 'persistence_store.dart';

String aliceSpecialEventDayKey(DateTime day) {
  final y = day.year.toString().padLeft(4, '0');
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class AliceSpecialEventStore {
  static const String _storageKey = 'alice_special_events_v1';

  final Map<String, List<AliceSpecialEvent>> _eventsByDay = {};

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

        if (key is! String || value is! List) continue;

        final parsedEvents = <AliceSpecialEvent>[];

        for (final item in value) {
          if (item is! Map) continue;

          final map = Map<String, dynamic>.from(item);

          final id = map['id'];
          final label = map['label'];
          final categoryName = map['category'];
          final year = map['year'];
          final month = map['month'];
          final day = map['day'];
          final startHour = map['startHour'];
          final startMinute = map['startMinute'];
          final endHour = map['endHour'];
          final endMinute = map['endMinute'];
          final note = map['note'];
          final enabled = map['enabled'];

          if (id is! String ||
              label is! String ||
              categoryName is! String ||
              year is! int ||
              month is! int ||
              day is! int ||
              startHour is! int ||
              startMinute is! int ||
              endHour is! int ||
              endMinute is! int ||
              note is! String ||
              enabled is! bool) {
            continue;
          }

          AliceSpecialEventCategory? category;
          for (final value in AliceSpecialEventCategory.values) {
            if (value.name == categoryName) {
              category = value;
              break;
            }
          }
          if (category == null) continue;

          parsedEvents.add(
            AliceSpecialEvent(
              id: id,
              label: label,
              category: category,
              date: DateTime(year, month, day),
              start: TimeOfDay(hour: startHour, minute: startMinute),
              end: TimeOfDay(hour: endHour, minute: endMinute),
              note: note,
              enabled: enabled,
            ),
          );
        }

        _eventsByDay[key] = parsedEvents;
      }
    } catch (_) {
      // dati corrotti ignorati
    }
  }

  List<AliceSpecialEvent> eventsForDay(DateTime day) {
    final key = aliceSpecialEventDayKey(day);
    return List<AliceSpecialEvent>.from(_eventsByDay[key] ?? const []);
  }

  bool hasEventsForDay(DateTime day) {
    final key = aliceSpecialEventDayKey(day);
    return (_eventsByDay[key] ?? const []).isNotEmpty;
  }

  void addEvent(DateTime day, AliceSpecialEvent event) {
    final key = aliceSpecialEventDayKey(day);
    final current = List<AliceSpecialEvent>.from(_eventsByDay[key] ?? const []);
    current.add(event);
    _eventsByDay[key] = current;
    _save();
  }

  void replaceEventsForDay(DateTime day, List<AliceSpecialEvent> events) {
    final key = aliceSpecialEventDayKey(day);
    _eventsByDay[key] = List<AliceSpecialEvent>.from(events);
    _save();
  }

  void removeEvent(DateTime day, String eventId) {
    final key = aliceSpecialEventDayKey(day);
    final current = List<AliceSpecialEvent>.from(_eventsByDay[key] ?? const []);
    current.removeWhere((event) => event.id == eventId);

    if (current.isEmpty) {
      _eventsByDay.remove(key);
    } else {
      _eventsByDay[key] = current;
    }

    _save();
  }

  void clearDay(DateTime day) {
    _eventsByDay.remove(aliceSpecialEventDayKey(day));
    _save();
  }

  void clearAll() {
    _eventsByDay.clear();
    _save();
  }

  Map<String, List<AliceSpecialEvent>> getAll() {
    return _eventsByDay.map(
      (key, value) => MapEntry(key, List<AliceSpecialEvent>.from(value)),
    );
  }

  List<DateTime> allDates() {
    return _eventsByDay.keys.map((key) {
      final parts = key.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList();
  }

  void addTestEvent(DateTime day) {
    addEvent(
      day,
      AliceSpecialEvent(
        id: 'test_${day.millisecondsSinceEpoch}',
        label: 'Evento test Alice',
        category: AliceSpecialEventCategory.activity,
        date: DateTime(day.year, day.month, day.day),
        start: const TimeOfDay(hour: 18, minute: 0),
        end: const TimeOfDay(hour: 20, minute: 0),
        note: 'Creato da bottone test',
        enabled: true,
      ),
    );
  }

  Future<void> _save() async {
    final data = _eventsByDay.map(
      (key, events) => MapEntry(
        key,
        events
            .map(
              (event) => {
                'id': event.id,
                'label': event.label,
                'category': event.category.name,
                'year': event.date.year,
                'month': event.date.month,
                'day': event.date.day,
                'startHour': event.start.hour,
                'startMinute': event.start.minute,
                'endHour': event.end.hour,
                'endMinute': event.end.minute,
                'note': event.note,
                'enabled': event.enabled,
              },
            )
            .toList(),
      ),
    );

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }
}
