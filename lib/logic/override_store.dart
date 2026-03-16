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

    for (final entry in _byDay.entries) {
      final day = entry.key;
      final ov = entry.value;

      data[_dateKey(day)] = {
        'matteo': _personOverrideToJson(ov.matteo),
        'chiara': _personOverrideToJson(ov.chiara),
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
