// lib/logic/day_settings_store.dart
import 'package:flutter/material.dart';

import '../models/day_override.dart';

/// Impostazioni "operative" per giorno (NON globali).
/// - Se un valore non è presente per un giorno -> si usa il fallback globale (SettingsStore).
///
/// CNC:
/// - Sandra per fascia: mattina / pranzo / sera (fallback su legacy sandraForDay)
/// - Decisioni scuola: ingresso + uscita (scelta esplicita: Nessuno/Matteo/Chiara/Sandra/Altro)
/// - ✅ Decisione pranzo (solo se uscita anticipata): finestra pranzo
/// - ✅ STEP 1: Uscita scuola ORARIO modificabile per giorno (start+end)
/// - ✅ NEW: Uscita anticipata ORARIO per giorno (non più solo bool)
class DaySettingsStore {
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

  DateTime _k(DateTime d) => dayKey(d);

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
  }

  void clearSandraForDay(DateTime day) {
    _sandraDisponibile.remove(_k(day));
  }

  // -------------------------
  // ✅ Uscita anticipata (NEW: ORARIO per giorno)
  // -------------------------

  /// Legacy bool: true se esiste un orario di uscita anticipata per quel giorno.
  /// (Serve per compatibilità col codice che ragiona ancora "uscita13" come bool)
  bool? uscita13ForDay(DateTime day) => _uscitaAnticipataMin.containsKey(_k(day)) ? true : null;

  /// Legacy setter: se true setta 13:00, se false pulisce.
  /// (Consigliato usare setUscitaAnticipataTimeForDay)
  void setUscita13ForDay(DateTime day, bool value) {
    final dk = _k(day);
    if (value) {
      _uscitaAnticipataMin[dk] = 13 * 60;
    } else {
      _uscitaAnticipataMin.remove(dk);
    }
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
  }

  /// ✅ NEW: disattiva uscita anticipata per giorno.
  void clearUscitaAnticipataForDay(DateTime day) {
    _uscitaAnticipataMin.remove(_k(day));
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
  }

  void clearSandraMattinaForDay(DateTime day) {
    _sandraMattina.remove(_k(day));
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
  }

  void clearSandraPranzoForDay(DateTime day) {
    _sandraPranzo.remove(_k(day));
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
  }

  void clearSandraSeraForDay(DateTime day) {
    _sandraSera.remove(_k(day));
  }

  /// Utility: pulisce tutte e tre le fasce Sandra per quel giorno (non tocca il legacy).
  void clearAllSandraSlotsForDay(DateTime day) {
    final dk = _k(day);
    _sandraMattina.remove(dk);
    _sandraPranzo.remove(dk);
    _sandraSera.remove(dk);
  }

  // -------------------------
  // ✅ Decisioni scuola (ingresso / uscita)
  // -------------------------

  SchoolCoverChoice schoolInCoverForDay(DateTime day) =>
      _schoolInCover[_k(day)] ?? SchoolCoverChoice.none;

  void setSchoolInCoverForDay(DateTime day, SchoolCoverChoice choice) {
    _schoolInCover[_k(day)] = choice;
  }

  void clearSchoolInCoverForDay(DateTime day) {
    _schoolInCover.remove(_k(day));
  }

  SchoolCoverChoice schoolOutCoverForDay(DateTime day) =>
      _schoolOutCover[_k(day)] ?? SchoolCoverChoice.none;

  void setSchoolOutCoverForDay(DateTime day, SchoolCoverChoice choice) {
    _schoolOutCover[_k(day)] = choice;
  }

  void clearSchoolOutCoverForDay(DateTime day) {
    _schoolOutCover.remove(_k(day));
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
  }

  void clearSchoolOutTimesForDay(DateTime day) {
    final dk = _k(day);
    _schoolOutStartMin.remove(dk);
    _schoolOutEndMin.remove(dk);
  }

  // -------------------------
  // ✅ Decisione pranzo (solo se uscita anticipata)
  // -------------------------

  SchoolCoverChoice lunchCoverForDay(DateTime day) =>
      _lunchCover[_k(day)] ?? SchoolCoverChoice.none;

  void setLunchCoverForDay(DateTime day, SchoolCoverChoice choice) {
    _lunchCover[_k(day)] = choice;
  }

  void clearLunchCoverForDay(DateTime day) {
    _lunchCover.remove(_k(day));
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
  }

  void clearAllAliceWindowsForDay(DateTime day) {
    _aliceWindows.remove(_k(day));
  }
}

/// Scelta copertura scuola (CNC: predisposta ad "Altro" futuro).
enum SchoolCoverChoice { none, matteo, chiara, sandra, altro }

/// Chiavi ufficiali delle finestre logistiche di Alice (estensibile).
enum AliceWindowKey {
  schoolMorning, // ingresso scuola
  schoolPickup, // ritiro scuola
  homeSensitive, // rientro / momento delicato
}

/// Range in minuti da mezzanotte.
class MinuteRange {
  final int startMin; // incluso
  final int endMin; // escluso

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