import 'dart:convert';

import '../models/disease_period.dart';
import 'persistence_store.dart';

class DiseasePeriodStore {
  static const String _storageKey = 'disease_period_store_v1';

  final List<DiseasePeriod> _periods = [];

  List<DiseasePeriod> get all => List.unmodifiable(_periods);

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _periods.clear();

      for (final item in decoded) {
        if (item is! Map) continue;

        final personId = item['personId'];
        final typeRaw = item['type'];
        final startRaw = item['startDate'];
        final endRaw = item['endDate'];

        if (personId is! String ||
            typeRaw is! String ||
            startRaw is! String ||
            endRaw is! String) {
          continue;
        }

        try {
          final type = DiseaseType.values.firstWhere((e) => e.name == typeRaw);

          final start = DateTime.parse(startRaw);
          final end = DateTime.parse(endRaw);

          _periods.add(
            DiseasePeriod(
              personId: personId,
              type: type,
              startDate: start,
              endDate: end,
            ),
          );
        } catch (_) {
          // ignora record non validi
        }
      }
    } catch (_) {
      // ignora dati corrotti
    }
  }

  Future<void> _save() async {
    final data = _periods
        .map(
          (p) => {
            'personId': p.personId,
            'type': p.type.name,
            'startDate': p.startDate.toIso8601String(),
            'endDate': p.endDate.toIso8601String(),
          },
        )
        .toList();

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }

  /// Aggiunge un periodo di malattia
  /// Non permette sovrapposizioni per la stessa persona
  void addPeriod(DiseasePeriod period) {
    for (final existing in _periods) {
      if (existing.personId != period.personId) continue;

      final overlaps =
          !(period.endDate.isBefore(existing.startDate) ||
              period.startDate.isAfter(existing.endDate));

      if (overlaps) {
        throw Exception('Periodo malattia sovrapposto per ${period.personId}');
      }
    }

    _periods.add(period);
    _save();
  }

  /// Rimuove un periodo
  void removePeriod(DiseasePeriod period) {
    _periods.remove(period);
    _save();
  }

  /// Ritorna il periodo attivo in un giorno (se esiste)
  DiseasePeriod? getPeriodForDay(String personId, DateTime day) {
    for (final p in _periods) {
      if (p.personId != personId) continue;
      if (p.containsDay(day)) {
        return p;
      }
    }
    return null;
  }

  /// Controlla se una persona è malata in un giorno
  bool isSick(String personId, DateTime day) {
    return getPeriodForDay(personId, day) != null;
  }
}
