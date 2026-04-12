import 'package:flutter/material.dart';

enum AliceCompanionPerson { matteo, chiara, nessuno }

class AliceCompanionEntry {
  final DateTime day;
  final TimeOfDay start;
  final TimeOfDay end;
  final AliceCompanionPerson person;

  const AliceCompanionEntry({
    required this.day,
    required this.start,
    required this.end,
    required this.person,
  });

  String get dayKey =>
      "${day.year.toString().padLeft(4, '0')}-"
      "${day.month.toString().padLeft(2, '0')}-"
      "${day.day.toString().padLeft(2, '0')}";
}

class AliceCompanionStore {
  final Map<String, List<AliceCompanionEntry>> _items = {};

  String _dayKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  List<AliceCompanionEntry> entriesForDay(DateTime day) {
    final key = _dayKey(day);
    final list = _items[key];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }

  void addEntry(AliceCompanionEntry entry) {
    final key = _dayKey(entry.day);
    final list = _items.putIfAbsent(key, () => <AliceCompanionEntry>[]);
    list.add(entry);
  }

  void removeEntry(AliceCompanionEntry entry) {
    final key = _dayKey(entry.day);
    final list = _items[key];
    if (list == null) return;

    list.removeWhere(
      (e) =>
          e.person == entry.person &&
          e.start.hour == entry.start.hour &&
          e.start.minute == entry.start.minute &&
          e.end.hour == entry.end.hour &&
          e.end.minute == entry.end.minute,
    );

    if (list.isEmpty) {
      _items.remove(key);
    }
  }

  void clearDay(DateTime day) {
    _items.remove(_dayKey(day));
  }

  // ✅ FUNZIONE CORRETTA (PORTA ALICE CON TE)
  bool isAliceAccompanied({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final d0 = DateTime(day.year, day.month, day.day);

    final entries = entriesForDay(d0);

    for (final entry in entries) {
      final entryStart = DateTime(
        d0.year,
        d0.month,
        d0.day,
        entry.start.hour,
        entry.start.minute,
      );

      final entryEnd = DateTime(
        d0.year,
        d0.month,
        d0.day,
        entry.end.hour,
        entry.end.minute,
      );

      final covers =
          !entryStart.isAfter(start) &&
          !entryEnd.isBefore(end);

      if (covers) {
        return true;
      }
    }

    return false;
  }
}