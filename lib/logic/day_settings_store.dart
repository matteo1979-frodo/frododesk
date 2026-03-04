// lib/logic/day_settings_store.dart
import '../models/day_override.dart';

/// Impostazioni "operative" per giorno (NON globali).
/// - Se un valore non è presente per un giorno -> si usa il fallback globale (SettingsStore).
///
/// CNC:
/// - Sandra per fascia: mattina / pranzo / sera (fallback su legacy sandraForDay)
/// - Decisioni scuola: ingresso + uscita (scelta esplicita: Nessuno/Matteo/Chiara/Sandra/Altro)
/// - ✅ Decisione pranzo (solo se uscita13): 13:00–14:30 (come scuola)
class DaySettingsStore {
  final Map<DateTime, bool> _sandraDisponibile = {};
  final Map<DateTime, bool> _uscita13 = {};

  // ✅ Sandra per fascia (se non presente -> fallback su _sandraDisponibile)
  final Map<DateTime, bool> _sandraMattina = {};
  final Map<DateTime, bool> _sandraPranzo = {};
  final Map<DateTime, bool> _sandraSera = {};

  // ✅ Decisioni scuola per giorno (copertura esplicita)
  final Map<DateTime, SchoolCoverChoice> _schoolInCover = {};
  final Map<DateTime, SchoolCoverChoice> _schoolOutCover = {};

  // ✅ Decisione pranzo (solo se uscita13) — 13:00–14:30
  final Map<DateTime, SchoolCoverChoice> _lunchCover = {};

  // ✅ Finestre logistiche di Alice per giorno (minuti da mezzanotte)
  // (rimangono per future estensioni, non usate ancora nel motore)
  final Map<DateTime, Map<AliceWindowKey, MinuteRange>> _aliceWindows = {};

  DateTime _k(DateTime d) => dayKey(d);

  // -------------------------
  // Flags per giorno (legacy / compatibilità)
  // -------------------------

  /// Toggle "generale" Sandra per il giorno (legacy).
  /// Resta utile come fallback per le fasce se queste non sono impostate.
  bool? sandraForDay(DateTime day) => _sandraDisponibile[_k(day)];

  bool? uscita13ForDay(DateTime day) => _uscita13[_k(day)];

  void setSandraForDay(DateTime day, bool value) {
    _sandraDisponibile[_k(day)] = value;
  }

  void setUscita13ForDay(DateTime day, bool value) {
    _uscita13[_k(day)] = value;
  }

  void clearSandraForDay(DateTime day) {
    _sandraDisponibile.remove(_k(day));
  }

  void clearUscita13ForDay(DateTime day) {
    _uscita13.remove(_k(day));
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
  // ✅ Decisione pranzo (solo se uscita13)
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
