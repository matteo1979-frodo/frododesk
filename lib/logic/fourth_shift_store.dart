import 'dart:convert';

import '../models/fourth_shift_period.dart';
import '../models/day_override.dart';
import 'persistence_store.dart';

class FourthShiftStore {
  static const String _storageKey = 'fourth_shift_store_v1';

  final List<FourthShiftPeriod> _periods = [];

  List<FourthShiftPeriod> get all => List.unmodifiable(_periods);

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
        final startDateRaw = item['startDate'];
        final endDateRaw = item['endDate'];
        final initialCycleWeekRaw = item['initialCycleWeek'];

        if (personId is! String ||
            startDateRaw is! String ||
            endDateRaw is! String ||
            initialCycleWeekRaw is! int) {
          continue;
        }

        try {
          final period = FourthShiftPeriod(
            personId: personId,
            startDate: DateTime.parse(startDateRaw),
            endDate: DateTime.parse(endDateRaw),
            initialCycleWeek: FourthShiftCycleWeekX.fromNumber(
              initialCycleWeekRaw,
            ),
          );

          _periods.add(period);
        } catch (_) {
          // ignora record non validi
        }
      }

      _sortPeriods();
    } catch (_) {
      // ignora dati corrotti
    }
  }

  Future<void> _save() async {
    final data = _periods
        .map(
          (p) => {
            'personId': p.personId,
            'startDate': p.startDate.toIso8601String(),
            'endDate': p.endDate.toIso8601String(),
            'initialCycleWeek': p.initialCycleWeek.number,
          },
        )
        .toList();

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }

  void addPeriod(FourthShiftPeriod period) {
    _periods.add(period);
    _sortPeriods();
    _save();
  }

  void removePeriod(FourthShiftPeriod period) {
    _periods.remove(period);
    _save();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _periods.length) return;
    _periods.removeAt(index);
    _save();
  }

  void replacePeriod(FourthShiftPeriod oldPeriod, FourthShiftPeriod newPeriod) {
    final index = _periods.indexOf(oldPeriod);
    if (index == -1) return;

    _periods[index] = newPeriod;
    _sortPeriods();
    _save();
  }

  List<FourthShiftPeriod> periodsForPerson(String personId) {
    return _periods.where((p) => p.personId == personId).toList();
  }

  FourthShiftPeriod? activePeriodForPersonOnDay(String personId, DateTime day) {
    final d = _normalizeDay(day);

    for (final period in _periods) {
      if (period.personId != personId) continue;
      if (period.containsDay(d)) return period;
    }

    return null;
  }

  bool isActiveForPersonOnDay(String personId, DateTime day) {
    return activePeriodForPersonOnDay(personId, day) != null;
  }

  void clearAll() {
    _periods.clear();
    _save();
  }

  DateTime _normalizeDay(DateTime day) {
    final k = dayKey(day);
    return DateTime(k.year, k.month, k.day);
  }

  void _sortPeriods() {
    _periods.sort((a, b) {
      final byPerson = a.personId.compareTo(b.personId);
      if (byPerson != 0) return byPerson;

      return a.startDate.compareTo(b.startDate);
    });
  }
}
