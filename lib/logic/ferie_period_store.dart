// lib/logic/ferie_period_store.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/day_override.dart';
import 'persistence_store.dart';

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

  Map<String, dynamic> toJson() => {
    'person': person.name,
    'startDay': startDay.toIso8601String(),
    'endDay': endDay.toIso8601String(),
  };

  static FeriePeriod? fromJson(dynamic json) {
    if (json is! Map) return null;

    final personRaw = json['person'];
    final startRaw = json['startDay'];
    final endRaw = json['endDay'];

    if (personRaw is! String || startRaw is! String || endRaw is! String) {
      return null;
    }

    try {
      final person = FeriePerson.values.firstWhere((e) => e.name == personRaw);
      final start = DateTime.parse(startRaw);
      final end = DateTime.parse(endRaw);

      return FeriePeriod(person: person, startDay: start, endDay: end);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'FeriePeriod(${person.name}: ${startDay.toIso8601String().substring(0, 10)} → ${endDay.toIso8601String().substring(0, 10)})';
}

/// Store ferie lunghe con persistenza locale.
class FeriePeriodStore {
  static const String _storageKey = 'ferie_period_store_v1';

  final List<FeriePeriod> _periods = [];

  List<FeriePeriod> all() => List.unmodifiable(_periods);

  List<FeriePeriod> periodsFor(FeriePerson p) {
    final items = _periods.where((x) => x.person == p).toList();
    items.sort((a, b) => a.startDay.compareTo(b.startDay));
    return items;
  }

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _periods.clear();

      for (final item in decoded) {
        final p = FeriePeriod.fromJson(item);
        if (p != null) {
          _periods.add(p);
        }
      }
    } catch (_) {
      // ignora dati corrotti
    }
  }

  Future<void> _save() async {
    final data = _periods.map((p) => p.toJson()).toList();
    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }

  void add(FeriePeriod p) {
    _periods.add(p);
    _save();
  }

  void remove(FeriePeriod p) {
    _periods.remove(p);
    _save();
  }

  void clearAll() {
    _periods.clear();
    _save();
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
