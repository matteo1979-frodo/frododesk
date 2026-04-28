import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/day_override.dart';
import 'ferie_period_store.dart';
import 'persistence_store.dart';

/// Store per Step B:
/// - mantiene override MANUALI per giorno
/// - ora con PERSISTENZA locale

class OverrideStore extends ChangeNotifier {
  static const String _storageKey = 'override_store_v1';

  final Map<DateTime, DayOverrides> _byDay = {};

  final Map<DateTime, Map<String, List<String>>> _forcedConflictEventIdsByDay =
      {};

  Map<String, dynamic> _forcedConflictMapToJson(
    Map<String, List<String>> value,
  ) {
    return value.map((personKey, ids) => MapEntry(personKey, [...ids]..sort()));
  }

  Map<String, List<String>> _forcedConflictMapFromJson(dynamic raw) {
    if (raw is! Map) return {};

    final result = <String, List<String>>{};

    for (final entry in raw.entries) {
      final personKey = entry.key;
      final value = entry.value;

      if (personKey is! String || value is! List) continue;

      final ids = value.whereType<String>().toList()..sort();
      if (ids.isEmpty) continue;

      result[personKey] = ids;
    }

    return result;
  }

  String _forcedConflictStorageKey({
    required String personKey,
    required List<String> eventIds,
  }) {
    final sorted = [...eventIds]..sort();
    return "$personKey|${sorted.join("|")}";
  }

  List<String> _forcedConflictEventIdsFromStorageKey(String storageKey) {
    final parts = storageKey.split('|');
    if (parts.length < 2) return const [];
    return parts.sublist(1).where((e) => e.trim().isNotEmpty).toList()..sort();
  }

  bool isForcedConflictForDay({
    required DateTime day,
    required String personKey,
    required List<String> eventIds,
  }) {
    final key = _dayKey(day);
    final byPerson = _forcedConflictEventIdsByDay[key];
    if (byPerson == null) return false;

    final savedIds = byPerson[personKey];
    if (savedIds == null || savedIds.isEmpty) return false;

    final currentIds = [...eventIds]..sort();

    if (savedIds.length != currentIds.length) return false;

    for (int i = 0; i < savedIds.length; i++) {
      if (savedIds[i] != currentIds[i]) return false;
    }

    return true;
  }

  bool isEventForcedForDay({
    required DateTime day,
    required String personKey,
    required String eventId,
  }) {
    final key = _dayKey(day);
    final byPerson = _forcedConflictEventIdsByDay[key];
    if (byPerson == null) return false;

    final savedIds = byPerson[personKey];
    if (savedIds == null || savedIds.isEmpty) return false;

    return savedIds.contains(eventId);
  }

  void setForcedConflictForDay({
    required DateTime day,
    required String personKey,
    required List<String> eventIds,
    required bool forced,
  }) {
    final key = _dayKey(day);
    final current = Map<String, List<String>>.from(
      _forcedConflictEventIdsByDay[key] ?? {},
    );

    if (forced) {
      final ids = [...eventIds]..sort();
      if (ids.isNotEmpty) {
        current[personKey] = ids;
      }
    } else {
      current.remove(personKey);
    }

    if (current.isEmpty) {
      _forcedConflictEventIdsByDay.remove(key);
    } else {
      _forcedConflictEventIdsByDay[key] = current;
    }

    _save();
    notifyListeners();
  }

  void clearForcedConflictsForDay(DateTime day) {
    final key = _dayKey(day);

    if (_forcedConflictEventIdsByDay.remove(key) != null) {
      _save();
      notifyListeners();
    }
  }

  /// Normalizza una DateTime a "solo giorno"
  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime dayKey(DateTime d) => _dayKey(d);

  String _dateKey(DateTime d) {
    final k = _dayKey(d);
    final y = k.year.toString().padLeft(4, '0');
    final m = k.month.toString().padLeft(2, '0');
    final day = k.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime? _dateFromKey(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length != 3) return null;

      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);

      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _personOverrideToJson(PersonDayOverride? value) {
    if (value == null) return null;

    return {
      'status': value.status.name,
      'permessoRange': value.permessoRange == null
          ? null
          : {
              'startMin': value.permessoRange!.startMin,
              'endMin': value.permessoRange!.endMin,
            },
    };
  }

  PersonDayOverride? _personOverrideFromJson(dynamic raw) {
    if (raw == null) return null;

    if (raw is String) {
      final status = OverrideStatus.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => OverrideStatus.normal,
      );

      if (status == OverrideStatus.normal) return null;

      if (status == OverrideStatus.permesso) {
        return null;
      }

      return PersonDayOverride(status: status);
    }

    if (raw is! Map) return null;

    final statusRaw = raw['status'];
    if (statusRaw is! String) return null;

    final status = OverrideStatus.values.firstWhere(
      (e) => e.name == statusRaw,
      orElse: () => OverrideStatus.normal,
    );

    if (status == OverrideStatus.normal) return null;

    if (status == OverrideStatus.permesso) {
      final pr = raw['permessoRange'];
      if (pr is! Map) return null;

      final startMin = pr['startMin'];
      final endMin = pr['endMin'];

      if (startMin is! int || endMin is! int) return null;

      try {
        return PersonDayOverride(
          status: OverrideStatus.permesso,
          permessoRange: TimeRangeMinutes(startMin: startMin, endMin: endMin),
        );
      } catch (_) {
        return null;
      }
    }

    return PersonDayOverride(status: status);
  }

  /// -------------------------
  /// LOAD
  /// -------------------------

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_storageKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) return;

      _byDay.clear();

      for (final entry in decoded.entries) {
        final day = _dateFromKey(entry.key);

        if (day == null) continue;

        final value = entry.value;
        if (value is! Map) continue;

        final matteo = _personOverrideFromJson(value['matteo']);
        final chiara = _personOverrideFromJson(value['chiara']);

        _byDay[dayKey(day)] = DayOverrides(
          day: dayKey(day),
          matteo: matteo,
          chiara: chiara,
        );

        final forcedRaw = value['forcedConflicts'];
        final forcedMap = _forcedConflictMapFromJson(forcedRaw);
        if (forcedMap.isNotEmpty) {
          _forcedConflictEventIdsByDay[dayKey(day)] = forcedMap;
        }
      }
    } catch (_) {
      // ignora dati corrotti
    }
  }

  /// -------------------------
  /// SAVE
  /// -------------------------

  Future<void> _save() async {
    final data = <String, dynamic>{};

    final allDays = <DateTime>{
      ..._byDay.keys,
      ..._forcedConflictEventIdsByDay.keys,
    };

    for (final day in allDays) {
      final ov = _byDay[day] ?? DayOverrides.empty(day);

      data[_dateKey(day)] = {
        'matteo': _personOverrideToJson(ov.matteo),
        'chiara': _personOverrideToJson(ov.chiara),
        'forcedConflicts': _forcedConflictMapToJson(
          _forcedConflictEventIdsByDay[day] ?? {},
        ),
      };
    }

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }

  /// -------------------------
  /// ACCESS
  /// -------------------------

  DayOverrides getForDay(DateTime day) {
    final key = _dayKey(day);
    return _byDay[key] ?? DayOverrides.empty(day);
  }

  /// Vista effettiva: Override manuale > Ferie lunghe
  DayOverrides getEffectiveForDay({
    required DateTime day,
    required FeriePeriodStore ferieStore,
  }) {
    final d0 = _dayKey(day);

    final manual = getForDay(d0);

    final matteoEff =
        manual.matteo ??
        (ferieStore.isOnHoliday(FeriePerson.matteo, d0)
            ? PersonDayOverride(status: OverrideStatus.ferie)
            : null);

    final chiaraEff =
        manual.chiara ??
        (ferieStore.isOnHoliday(FeriePerson.chiara, d0)
            ? PersonDayOverride(status: OverrideStatus.ferie)
            : null);

    return DayOverrides(day: dayKey(d0), matteo: matteoEff, chiara: chiaraEff);
  }

  /// -------------------------
  /// MODIFICA
  /// -------------------------

  void setForDay(DateTime day, DayOverrides overrides) {
    final key = _dayKey(day);

    _byDay[key] = overrides;

    _save();

    notifyListeners();
  }

  void clearDay(DateTime day) {
    final key = _dayKey(day);

    if (_byDay.remove(key) != null) {
      _save();

      notifyListeners();
    }
  }

  bool hasOverride(DateTime day) {
    final key = _dayKey(day);

    return _byDay.containsKey(key);
  }
}
