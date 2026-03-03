// lib/logic/emergency_store.dart
import 'package:flutter/foundation.dart';

/// Chiave giorno (00:00) per mappe stabili.
DateTime emergencyDayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Intervallo orario nello stesso giorno (minuti da mezzanotte).
/// Esempio: 08:00 => 480
@immutable
class EmergencyTimeRange {
  final int startMin; // inclusivo
  final int endMin; // esclusivo

  const EmergencyTimeRange({required this.startMin, required this.endMin})
    : assert(startMin >= 0 && startMin <= 24 * 60),
      assert(endMin >= 0 && endMin <= 24 * 60),
      assert(endMin > startMin);

  /// Ritorna "HH:MM" da minuti da mezzanotte (es. 450 -> "07:30")
  static String _fmtHM(int minutes) {
    final m = minutes.clamp(0, 24 * 60);
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  /// Range leggibile: "07:30–08:40"
  String toDisplayString() => '${_fmtHM(startMin)}–${_fmtHM(endMin)}';

  /// Durata in minuti (semplice utility)
  int get durationMin => endMin - startMin;

  EmergencyTimeRange copyWith({int? startMin, int? endMin}) {
    return EmergencyTimeRange(
      startMin: startMin ?? this.startMin,
      endMin: endMin ?? this.endMin,
    );
  }

  @override
  String toString() => 'EmergencyTimeRange(${toDisplayString()})';
}

/// Impostazioni Modalità Emergenza per un singolo giorno.
/// - enabled: toggle manuale (poi la logica può forzarlo se entrambi allettati)
/// - morningEnabled / afternoonEnabled: mostrare/valutare i blocchi se rilevanti
/// - morningRange / afternoonRange: orari (sempre modificabili con ✏️)
@immutable
class EmergencySettings {
  final DateTime day; // normalizzato a dayKey

  /// Toggle manuale della modalità emergenza (Copertura).
  final bool enabled;

  /// Se true, il blocco Mattina Scuola è attivo/mostrabile (se giorno rilevante).
  final bool morningEnabled;

  /// Se true, il blocco Ritiro/Pomeriggio è attivo/mostrabile (se giorno rilevante).
  final bool afternoonEnabled;

  /// Orari mattina (default o modificati)
  final EmergencyTimeRange morningRange;

  /// Orari pomeriggio (default o modificati)
  final EmergencyTimeRange afternoonRange;

  /// Flag “Rientro delicato” (di base lo deciderà la logica se entrambi allettati),
  /// ma lo lasciamo qui per eventuali casi manuali futuri.
  final bool homeReturnDelicate;

  const EmergencySettings({
    required this.day,
    required this.enabled,
    required this.morningEnabled,
    required this.afternoonEnabled,
    required this.morningRange,
    required this.afternoonRange,
    required this.homeReturnDelicate,
  });

  /// Defaults “sensati” (poi saranno sempre modificabili con ✏️ in UI)
  static EmergencySettings defaultsFor(DateTime day) {
    final k = emergencyDayKey(day);

    // Default proposti (modificabili sempre):
    // - Mattina: 07:30–08:40 (vestizione + arrivo scuola)
    // - Pomeriggio: 16:25–16:50 (ritiro + rientro)
    // Se vuoi cambiare questi default più avanti, lo faremo qui e basta.
    return EmergencySettings(
      day: k,
      enabled: false,
      morningEnabled: true,
      afternoonEnabled: true,
      morningRange: const EmergencyTimeRange(
        startMin: 7 * 60 + 30,
        endMin: 8 * 60 + 40,
      ),
      afternoonRange: const EmergencyTimeRange(
        startMin: 16 * 60 + 25,
        endMin: 16 * 60 + 50,
      ),
      homeReturnDelicate: false,
    );
  }

  /// Modalità emergenza effettiva (manuale OR forzata dall’esterno).
  bool effectiveEnabled({required bool forced}) => forced || enabled;

  EmergencySettings copyWith({
    bool? enabled,
    bool? morningEnabled,
    bool? afternoonEnabled,
    EmergencyTimeRange? morningRange,
    EmergencyTimeRange? afternoonRange,
    bool? homeReturnDelicate,
  }) {
    return EmergencySettings(
      day: day,
      enabled: enabled ?? this.enabled,
      morningEnabled: morningEnabled ?? this.morningEnabled,
      afternoonEnabled: afternoonEnabled ?? this.afternoonEnabled,
      morningRange: morningRange ?? this.morningRange,
      afternoonRange: afternoonRange ?? this.afternoonRange,
      homeReturnDelicate: homeReturnDelicate ?? this.homeReturnDelicate,
    );
  }
}

/// Store in-memory (per ora) per impostazioni emergenza giorno-per-giorno.
/// Indipendente da OverrideStore (CNC: sottoprogramma separato).
class EmergencyStore {
  final Map<DateTime, EmergencySettings> _byDay =
      <DateTime, EmergencySettings>{};

  /// Legge le impostazioni del giorno, se non esistono ritorna i default.
  EmergencySettings getForDay(DateTime day) {
    final k = emergencyDayKey(day);
    return _byDay[k] ?? EmergencySettings.defaultsFor(k);
  }

  /// Salva/aggiorna impostazioni del giorno.
  void setForDay(DateTime day, EmergencySettings settings) {
    final k = emergencyDayKey(day);
    _byDay[k] = settings;
  }

  /// Helper: aggiorna con una funzione (stile "transaction").
  void updateForDay(
    DateTime day,
    EmergencySettings Function(EmergencySettings current) update,
  ) {
    final current = getForDay(day);
    final next = update(current);
    setForDay(day, next);
  }

  /// Toggle manuale emergenza.
  void setEnabled(DateTime day, bool enabled) {
    updateForDay(day, (cur) => cur.copyWith(enabled: enabled));
  }

  /// Abilita/disabilita blocco mattina.
  void setMorningEnabled(DateTime day, bool enabled) {
    updateForDay(day, (cur) => cur.copyWith(morningEnabled: enabled));
  }

  /// Abilita/disabilita blocco pomeriggio.
  void setAfternoonEnabled(DateTime day, bool enabled) {
    updateForDay(day, (cur) => cur.copyWith(afternoonEnabled: enabled));
  }

  /// Modifica orario mattina (minuti da mezzanotte).
  void setMorningRange(DateTime day, EmergencyTimeRange range) {
    updateForDay(day, (cur) => cur.copyWith(morningRange: range));
  }

  /// Modifica orario pomeriggio (minuti da mezzanotte).
  void setAfternoonRange(DateTime day, EmergencyTimeRange range) {
    updateForDay(day, (cur) => cur.copyWith(afternoonRange: range));
  }

  /// Flag rientro delicato (manuale).
  void setHomeReturnDelicate(DateTime day, bool value) {
    updateForDay(day, (cur) => cur.copyWith(homeReturnDelicate: value));
  }

  /// Solo debug / eventuale UI futura.
  int get countSavedDays => _byDay.length;

  /// Cancella un giorno (torna ai default).
  void clearDay(DateTime day) {
    final k = emergencyDayKey(day);
    _byDay.remove(k);
  }

  /// Cancella tutto (reset).
  void clearAll() => _byDay.clear();
}
