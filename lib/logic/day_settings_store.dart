// lib/logic/day_settings_store.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/day_override.dart';
import 'persistence_store.dart';

/// Impostazioni "operative" per giorno (NON globali).
/// - Se un valore non è presente per un giorno -> si usa il fallback globale (SettingsStore).
///
/// CNC:
/// - Sandra per fascia: mattina / pranzo / sera (fallback su legacy sandraForDay)
/// - Decisioni scuola: ingresso + uscita (scelta esplicita: Nessuno/Matteo/Chiara/Sandra/Altro)
/// - ✅ Decisione pranzo (solo se uscita anticipata): finestra pranzo
/// - ✅ STEP 1: Uscita scuola ORARIO modificabile per giorno (start+end)
/// - ✅ NEW: Uscita anticipata ORARIO per giorno (non più solo bool)
/// - ✅ NEW: Attivazione giornaliera rete di supporto (per personId)
class DaySettingsStore {
  DaySettingsStore();

  static const String _storageKey = 'day_settings_store_v1';

  final Map<DateTime, bool> _sandraDisponibile = {};

  // ✅ NEW: uscita anticipata ORARIO (minuti da mezzanotte)
  // Se presente => uscita anticipata attiva per quel giorno.
  final Map<DateTime, int> _uscitaAnticipataMin = {};

  // ✅ Sandra per fascia (se non presente -> fallback su _sandraDisponibile)
  final Map<DateTime, bool> _sandraMattina = {};
  final Map<DateTime, bool> _sandraPranzo = {};
  final Map<DateTime, bool> _sandraSera = {};

  // ✅ Decisioni scuola per giorno (copertura esplicita)
  final Map<DateTime, SchoolCoverChoice> _schoolInCover = {};
  final Map<DateTime, SchoolCoverChoice> _schoolOutCover = {};

  // ✅ Decisione pranzo (solo se uscita anticipata) — come scuola
  final Map<DateTime, SchoolCoverChoice> _lunchCover = {};

  // ✅ Finestre logistiche di Alice per giorno (minuti da mezzanotte)
  // (rimangono per future estensioni, non usate ancora nel motore)
  final Map<DateTime, Map<AliceWindowKey, MinuteRange>> _aliceWindows = {};

  // ✅ STEP 1: uscita scuola orario variabile per giorno (minuti da mezzanotte)
  final Map<DateTime, int> _schoolOutStartMin = {};
  final Map<DateTime, int> _schoolOutEndMin = {};

  // ✅ NEW: Rete di supporto attiva per giorno
  // Chiave = giorno, Valore = insieme degli id persona attivi quel giorno
  final Map<DateTime, Set<String>> _supportPeopleEnabledForDay = {};

  DateTime _k(DateTime d) => dayKey(d);

  String _dateKey(DateTime d) {
    final k = _k(d);
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
      return dayKey(DateTime(y, m, d));
    } catch (_) {
      return null;
    }
  }

  // -------------------------
  // Lifecycle persistence
  // -------------------------

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      _sandraDisponibile.clear();
      _uscitaAnticipataMin.clear();
      _sandraMattina.clear();
      _sandraPranzo.clear();
      _sandraSera.clear();
      _schoolInCover.clear();
      _schoolOutCover.clear();
      _lunchCover.clear();
      _aliceWindows.clear();
      _schoolOutStartMin.clear();
      _schoolOutEndMin.clear();
      _supportPeopleEnabledForDay.clear();

      _loadBoolMap(decoded['sandraDisponibile'], _sandraDisponibile);
      _loadIntMap(decoded['uscitaAnticipataMin'], _uscitaAnticipataMin);
      _loadBoolMap(decoded['sandraMattina'], _sandraMattina);
      _loadBoolMap(decoded['sandraPranzo'], _sandraPranzo);
      _loadBoolMap(decoded['sandraSera'], _sandraSera);

      _loadEnumMap(
        decoded['schoolInCover'],
        _schoolInCover,
        SchoolCoverChoice.values,
      );
      _loadEnumMap(
        decoded['schoolOutCover'],
        _schoolOutCover,
        SchoolCoverChoice.values,
      );
      _loadEnumMap(
        decoded['lunchCover'],
        _lunchCover,
        SchoolCoverChoice.values,
      );

      _loadIntMap(decoded['schoolOutStartMin'], _schoolOutStartMin);
      _loadIntMap(decoded['schoolOutEndMin'], _schoolOutEndMin);

      _loadAliceWindows(decoded['aliceWindows']);
      _loadSupportPeople(decoded['supportPeopleEnabledForDay']);
    } catch (_) {
      // Se il JSON è corrotto/non compatibile, ignoriamo senza rompere l'app.
    }
  }

  Future<void> _save() async {
    final data = <String, dynamic>{
      'sandraDisponibile': _encodeBoolMap(_sandraDisponibile),
      'uscitaAnticipataMin': _encodeIntMap(_uscitaAnticipataMin),
      'sandraMattina': _encodeBoolMap(_sandraMattina),
      'sandraPranzo': _encodeBoolMap(_sandraPranzo),
      'sandraSera': _encodeBoolMap(_sandraSera),
      'schoolInCover': _encodeEnumMap(_schoolInCover),
      'schoolOutCover': _encodeEnumMap(_schoolOutCover),
      'lunchCover': _encodeEnumMap(_lunchCover),
      'aliceWindows': _encodeAliceWindows(),
      'schoolOutStartMin': _encodeIntMap(_schoolOutStartMin),
      'schoolOutEndMin': _encodeIntMap(_schoolOutEndMin),
      'supportPeopleEnabledForDay': _encodeSupportPeople(),
    };

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }

  Map<String, dynamic> _encodeBoolMap(Map<DateTime, bool> source) {
    final out = <String, dynamic>{};
    for (final entry in source.entries) {
      out[_dateKey(entry.key)] = entry.value;
    }
    return out;
  }

  Map<String, dynamic> _encodeIntMap(Map<DateTime, int> source) {
    final out = <String, dynamic>{};
    for (final entry in source.entries) {
      out[_dateKey(entry.key)] = entry.value;
    }
    return out;
  }

  Map<String, dynamic> _encodeEnumMap<T extends Enum>(Map<DateTime, T> source) {
    final out = <String, dynamic>{};
    for (final entry in source.entries) {
      out[_dateKey(entry.key)] = entry.value.name;
    }
    return out;
  }

  Map<String, dynamic> _encodeAliceWindows() {
    final out = <String, dynamic>{};

    for (final entry in _aliceWindows.entries) {
      final inner = <String, dynamic>{};
      for (final windowEntry in entry.value.entries) {
        inner[windowEntry.key.name] = windowEntry.value.toJson();
      }
      out[_dateKey(entry.key)] = inner;
    }

    return out;
  }

  Map<String, dynamic> _encodeSupportPeople() {
    final out = <String, dynamic>{};

    for (final entry in _supportPeopleEnabledForDay.entries) {
      out[_dateKey(entry.key)] = entry.value.toList()..sort();
    }

    return out;
  }

  void _loadBoolMap(dynamic raw, Map<DateTime, bool> target) {
    if (raw is! Map) return;

    for (final entry in raw.entries) {
      final day = _dateFromKey(entry.key.toString());
      final value = entry.value;
      if (day != null && value is bool) {
        target[day] = value;
      }
    }
  }

  void _loadIntMap(dynamic raw, Map<DateTime, int> target) {
    if (raw is! Map) return;

    for (final entry in raw.entries) {
      final day = _dateFromKey(entry.key.toString());
      final value = entry.value;
      if (day != null && value is int) {
        target[day] = value;
      }
    }
  }

  void _loadEnumMap<T extends Enum>(
    dynamic raw,
    Map<DateTime, T> target,
    List<T> values,
  ) {
    if (raw is! Map) return;

    for (final entry in raw.entries) {
      final day = _dateFromKey(entry.key.toString());
      final value = entry.value;
      if (day == null || value is! String) continue;

      try {
        final parsed = values.firstWhere((e) => e.name == value);
        target[day] = parsed;
      } catch (_) {
        // ignora valori non validi
      }
    }
  }

  void _loadAliceWindows(dynamic raw) {
    if (raw is! Map) return;

    for (final entry in raw.entries) {
      final day = _dateFromKey(entry.key.toString());
      if (day == null) continue;

      final dayMap = entry.value;
      if (dayMap is! Map) continue;

      final parsed = <AliceWindowKey, MinuteRange>{};

      for (final w in dayMap.entries) {
        final keyName = w.key.toString();

        AliceWindowKey? windowKey;
        try {
          windowKey = AliceWindowKey.values.firstWhere(
            (e) => e.name == keyName,
          );
        } catch (_) {
          windowKey = null;
        }
        if (windowKey == null) continue;

        final range = MinuteRange.fromJson(w.value);
        if (range != null) {
          parsed[windowKey] = range;
        }
      }

      if (parsed.isNotEmpty) {
        _aliceWindows[day] = parsed;
      }
    }
  }

  void _loadSupportPeople(dynamic raw) {
    if (raw is! Map) return;

    for (final entry in raw.entries) {
      final day = _dateFromKey(entry.key.toString());
      final value = entry.value;
      if (day == null || value is! List) continue;

      final ids = value.whereType<String>().toSet();
      if (ids.isNotEmpty) {
        _supportPeopleEnabledForDay[day] = ids;
      }
    }
  }

  // -------------------------
  // Helpers time
  // -------------------------

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMinutes(int m) {
    final hh = (m ~/ 60).clamp(0, 23);
    final mm = (m % 60).clamp(0, 59);
    return TimeOfDay(hour: hh, minute: mm);
  }

  bool _isValidMinute(int m) => m >= 0 && m <= 24 * 60;

  // -------------------------
  // Flags per giorno (legacy / compatibilità)
  // -------------------------

  /// Toggle "generale" Sandra per il giorno (legacy).
  /// Resta utile come fallback per le fasce se queste non sono impostate.
  bool? sandraForDay(DateTime day) => _sandraDisponibile[_k(day)];

  void setSandraForDay(DateTime day, bool value) {
    _sandraDisponibile[_k(day)] = value;
    _save();
  }

  void clearSandraForDay(DateTime day) {
    _sandraDisponibile.remove(_k(day));
    _save();
  }

  // -------------------------
  // ✅ Uscita anticipata (NEW: ORARIO per giorno)
  // -------------------------

  /// Legacy bool: true se esiste un orario di uscita anticipata per quel giorno.
  /// (Serve per compatibilità col codice che ragiona ancora "uscita13" come bool)
  bool? uscita13ForDay(DateTime day) =>
      _uscitaAnticipataMin.containsKey(_k(day)) ? true : null;

  /// Legacy setter: se true setta 13:00, se false pulisce.
  /// (Consigliato usare setUscitaAnticipataTimeForDay)
  void setUscita13ForDay(DateTime day, bool value) {
    final dk = _k(day);
    if (value) {
      _uscitaAnticipataMin[dk] = 13 * 60;
    } else {
      _uscitaAnticipataMin.remove(dk);
    }
    _save();
  }

  /// ✅ NEW: orario uscita anticipata per giorno (TimeOfDay), null se non attiva.
  TimeOfDay? uscitaAnticipataTimeForDay(DateTime day) {
    final m = _uscitaAnticipataMin[_k(day)];
    if (m == null) return null;
    if (!_isValidMinute(m)) return null;
    return _fromMinutes(m);
  }

  /// ✅ NEW: imposta orario uscita anticipata per giorno (attiva la funzione).
  void setUscitaAnticipataTimeForDay(DateTime day, TimeOfDay time) {
    final dk = _k(day);
    final m = _toMinutes(time);
    if (!_isValidMinute(m)) return;
    _uscitaAnticipataMin[dk] = m;
    _save();
  }

  /// ✅ NEW: disattiva uscita anticipata per giorno.
  void clearUscitaAnticipataForDay(DateTime day) {
    _uscitaAnticipataMin.remove(_k(day));
    _save();
  }

  // -------------------------
  // ✅ Sandra per fascia
  // -------------------------

  bool? sandraMattinaForDay(DateTime day) => _sandraMattina[_k(day)];

  bool effectiveSandraMattina(DateTime day, {required bool fallbackGlobal}) {
    final dk = _k(day);
    final v = _sandraMattina[dk];
    if (v != null) return v;
    final legacy = _sandraDisponibile[dk];
    return legacy ?? fallbackGlobal;
  }

  void setSandraMattinaForDay(DateTime day, bool value) {
    _sandraMattina[_k(day)] = value;
    _save();
  }

  void clearSandraMattinaForDay(DateTime day) {
    _sandraMattina.remove(_k(day));
    _save();
  }

  bool? sandraPranzoForDay(DateTime day) => _sandraPranzo[_k(day)];

  bool effectiveSandraPranzo(DateTime day, {required bool fallbackGlobal}) {
    final dk = _k(day);
    final v = _sandraPranzo[dk];
    if (v != null) return v;
    final legacy = _sandraDisponibile[dk];
    return legacy ?? fallbackGlobal;
  }

  void setSandraPranzoForDay(DateTime day, bool value) {
    _sandraPranzo[_k(day)] = value;
    _save();
  }

  void clearSandraPranzoForDay(DateTime day) {
    _sandraPranzo.remove(_k(day));
    _save();
  }

  bool? sandraSeraForDay(DateTime day) => _sandraSera[_k(day)];

  bool effectiveSandraSera(DateTime day, {required bool fallbackGlobal}) {
    final dk = _k(day);
    final v = _sandraSera[dk];
    if (v != null) return v;
    final legacy = _sandraDisponibile[dk];
    return legacy ?? fallbackGlobal;
  }

  void setSandraSeraForDay(DateTime day, bool value) {
    _sandraSera[_k(day)] = value;
    _save();
  }

  void clearSandraSeraForDay(DateTime day) {
    _sandraSera.remove(_k(day));
    _save();
  }

  /// Utility: pulisce tutte e tre le fasce Sandra per quel giorno (non tocca il legacy).
  void clearAllSandraSlotsForDay(DateTime day) {
    final dk = _k(day);
    _sandraMattina.remove(dk);
    _sandraPranzo.remove(dk);
    _sandraSera.remove(dk);
    _save();
  }

  // -------------------------
  // ✅ Decisioni scuola (ingresso / uscita)
  // -------------------------

  SchoolCoverChoice schoolInCoverForDay(DateTime day) =>
      _schoolInCover[_k(day)] ?? SchoolCoverChoice.none;

  void setSchoolInCoverForDay(DateTime day, SchoolCoverChoice choice) {
    _schoolInCover[_k(day)] = choice;
    _save();
  }

  void clearSchoolInCoverForDay(DateTime day) {
    _schoolInCover.remove(_k(day));
    _save();
  }

  SchoolCoverChoice schoolOutCoverForDay(DateTime day) =>
      _schoolOutCover[_k(day)] ?? SchoolCoverChoice.none;

  void setSchoolOutCoverForDay(DateTime day, SchoolCoverChoice choice) {
    _schoolOutCover[_k(day)] = choice;
    _save();
  }

  void clearSchoolOutCoverForDay(DateTime day) {
    _schoolOutCover.remove(_k(day));
    _save();
  }

  // -------------------------
  // ✅ STEP 1: Orario uscita scuola per giorno
  // -------------------------

  TimeOfDay? schoolOutStartForDay(DateTime day) {
    final m = _schoolOutStartMin[_k(day)];
    if (m == null) return null;
    if (!_isValidMinute(m)) return null;
    return _fromMinutes(m);
  }

  TimeOfDay? schoolOutEndForDay(DateTime day) {
    final m = _schoolOutEndMin[_k(day)];
    if (m == null) return null;
    if (!_isValidMinute(m)) return null;
    return _fromMinutes(m);
  }

  void setSchoolOutTimesForDay(DateTime day, TimeOfDay start, TimeOfDay end) {
    final dk = _k(day);
    final a = _toMinutes(start);
    final b = _toMinutes(end);
    if (!_isValidMinute(a) || !_isValidMinute(b)) return;
    if (b <= a) return;
    _schoolOutStartMin[dk] = a;
    _schoolOutEndMin[dk] = b;
    _save();
  }

  void clearSchoolOutTimesForDay(DateTime day) {
    final dk = _k(day);
    _schoolOutStartMin.remove(dk);
    _schoolOutEndMin.remove(dk);
    _save();
  }

  // -------------------------
  // ✅ Decisione pranzo (solo se uscita anticipata)
  // -------------------------

  SchoolCoverChoice lunchCoverForDay(DateTime day) =>
      _lunchCover[_k(day)] ?? SchoolCoverChoice.none;

  void setLunchCoverForDay(DateTime day, SchoolCoverChoice choice) {
    _lunchCover[_k(day)] = choice;
    _save();
  }

  void clearLunchCoverForDay(DateTime day) {
    _lunchCover.remove(_k(day));
    _save();
  }

  // -------------------------
  // ✅ NEW: Rete di supporto per giorno
  // -------------------------

  Set<String> supportPeopleEnabledIdsForDay(DateTime day) {
    final ids = _supportPeopleEnabledForDay[_k(day)];
    if (ids == null) return <String>{};
    return Set<String>.from(ids);
  }

  bool isSupportPersonEnabledForDay(DateTime day, String personId) {
    final ids = _supportPeopleEnabledForDay[_k(day)];
    if (ids == null) return false;
    return ids.contains(personId);
  }

  void setSupportPersonEnabledForDay(
    DateTime day,
    String personId,
    bool enabled,
  ) {
    final dk = _k(day);
    final current = Set<String>.from(
      _supportPeopleEnabledForDay[dk] ?? <String>{},
    );

    if (enabled) {
      current.add(personId);
    } else {
      current.remove(personId);
    }

    if (current.isEmpty) {
      _supportPeopleEnabledForDay.remove(dk);
    } else {
      _supportPeopleEnabledForDay[dk] = current;
    }

    _save();
  }

  void clearSupportPersonForDay(DateTime day, String personId) {
    setSupportPersonEnabledForDay(day, personId, false);
  }

  void clearAllSupportPeopleForDay(DateTime day) {
    _supportPeopleEnabledForDay.remove(_k(day));
    _save();
  }

  /// ✅ NEW: rimuove una persona supporto da TUTTI i giorni salvati.
  void clearSupportPersonFromAllDays(String personId) {
    final days = _supportPeopleEnabledForDay.keys.toList();

    for (final day in days) {
      final current = Set<String>.from(
        _supportPeopleEnabledForDay[day] ?? <String>{},
      );
      current.remove(personId);

      if (current.isEmpty) {
        _supportPeopleEnabledForDay.remove(day);
      } else {
        _supportPeopleEnabledForDay[day] = current;
      }
    }

    _save();
  }

  // -------------------------
  // Alice windows per giorno
  // -------------------------

  MinuteRange? aliceWindowForDay(DateTime day, AliceWindowKey key) {
    final m = _aliceWindows[_k(day)];
    return m?[key];
  }

  void setAliceWindowForDay(
    DateTime day,
    AliceWindowKey key,
    MinuteRange range,
  ) {
    final dk = _k(day);
    final existing = _aliceWindows[dk] ?? <AliceWindowKey, MinuteRange>{};
    existing[key] = range;
    _aliceWindows[dk] = existing;
    _save();
  }

  void clearAliceWindowForDay(DateTime day, AliceWindowKey key) {
    final dk = _k(day);
    final existing = _aliceWindows[dk];
    if (existing == null) return;
    existing.remove(key);
    if (existing.isEmpty) {
      _aliceWindows.remove(dk);
    } else {
      _aliceWindows[dk] = existing;
    }
    _save();
  }

  void clearAllAliceWindowsForDay(DateTime day) {
    _aliceWindows.remove(_k(day));
    _save();
  }
}

/// Scelta copertura scuola (CNC: predisposta ad "Altro" futuro).
enum SchoolCoverChoice { none, matteo, chiara, sandra, altro }

/// Chiavi ufficiali delle finestre logistiche di Alice (estensibile).
enum AliceWindowKey { schoolMorning, schoolPickup, homeSensitive }

/// Range in minuti da mezzanotte.
class MinuteRange {
  final int startMin;
  final int endMin;

  const MinuteRange({required this.startMin, required this.endMin})
    : assert(startMin >= 0),
      assert(endMin >= 0),
      assert(endMin > startMin),
      assert(endMin <= 24 * 60);

  int get durationMin => endMin - startMin;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'startMin': startMin,
    'endMin': endMin,
  };

  static MinuteRange? fromJson(dynamic json) {
    if (json is! Map) return null;
    final a = json['startMin'];
    final b = json['endMin'];
    if (a is! int || b is! int) return null;
    if (b <= a) return null;
    if (a < 0 || b > 24 * 60) return null;
    return MinuteRange(startMin: a, endMin: b);
  }
}
