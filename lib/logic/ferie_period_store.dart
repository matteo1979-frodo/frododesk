// lib/logic/ferie_period_store.dart
import 'package:flutter/material.dart';

import '../models/day_override.dart';

/// Persona per ferie lunghe (per ora solo Matteo/Chiara).
enum FeriePerson { matteo, chiara }

/// Periodo ferie: [startDay, endDay] inclusi (giorni interi).
@immutable
class FeriePeriod {
  final FeriePerson person;
  final DateTime startDay; // normalizzato 00:00
  final DateTime endDay; // normalizzato 00:00 (incluso)

  FeriePeriod({
    required this.person,
    required DateTime startDay,
    required DateTime endDay,
  }) : startDay = dayKey(startDay),
       endDay = dayKey(endDay) {
    if (this.endDay.isBefore(this.startDay)) {
      throw ArgumentError('endDay must be >= startDay');
    }
  }

  bool containsDay(DateTime day) {
    final d = dayKey(day);
    return !d.isBefore(startDay) && !d.isAfter(endDay);
  }

  @override
  String toString() =>
      'FeriePeriod(${person.name}: ${startDay.toIso8601String().substring(0, 10)} → ${endDay.toIso8601String().substring(0, 10)})';
}

/// Store in-memory (per ora). Più avanti: persistenza su file/db.
class FeriePeriodStore {
  final List<FeriePeriod> _periods = [];

  List<FeriePeriod> all() => List.unmodifiable(_periods);

  List<FeriePeriod> periodsFor(FeriePerson p) {
    final items = _periods.where((x) => x.person == p).toList();
    items.sort((a, b) => a.startDay.compareTo(b.startDay));
    return items;
  }

  void add(FeriePeriod p) {
    _periods.add(p);
  }

  void remove(FeriePeriod p) {
    _periods.remove(p);
  }

  void clearAll() {
    _periods.clear();
  }

  /// Ritorna true se la persona è in ferie quel giorno.
  bool isOnHoliday(FeriePerson person, DateTime day) {
    final d = dayKey(day);
    return _periods.any((p) => p.person == person && p.containsDay(d));
  }

  /// Helper: se è in ferie quel giorno, suggerisce OverrideStatus.ferie.
  /// NOTA: l'override manuale (Step B) dovrà sempre avere priorità sopra.
  OverrideStatus? holidayStatusForDay(FeriePerson person, DateTime day) {
    return isOnHoliday(person, day) ? OverrideStatus.ferie : null;
  }
}
