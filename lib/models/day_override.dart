// lib/models/day_override.dart
import 'package:flutter/material.dart';

/// Stati override giornalieri (Step B1)
enum OverrideStatus {
  normal, // nessun override: vale Step A
  ferie, // disponibile tutto il giorno (priorità normale)
  permesso, // disponibile solo in un intervallo (richiede orario)
  malattiaLeggera, // disponibile ma priorità bassa (copertura debole)
  malattiaALetto, // gestione speciale in CoverageEngine (presenza in casa)
}

/// Helper: normalizza una data alla "chiave giorno" (00:00) per usare mappe stabili.
DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// Intervallo orario nello stesso giorno (in minuti da mezzanotte).
/// Esempio: 10:30 => 630
@immutable
class TimeRangeMinutes {
  final int startMin; // inclusivo
  final int endMin; // esclusivo

  TimeRangeMinutes({required this.startMin, required this.endMin}) {
    if (startMin < 0 || startMin > 24 * 60) {
      throw ArgumentError('startMin out of range');
    }
    if (endMin < 0 || endMin > 24 * 60) {
      throw ArgumentError('endMin out of range');
    }
    if (endMin <= startMin) {
      throw ArgumentError('TimeRangeMinutes endMin must be > startMin');
    }
  }

  bool containsMinute(int m) => m >= startMin && m < endMin;
}

/// Override di una singola persona per un giorno
@immutable
class PersonDayOverride {
  final OverrideStatus status;

  /// Usato solo se status == permesso
  final TimeRangeMinutes? permessoRange;

  PersonDayOverride({required this.status, this.permessoRange}) {
    if (status == OverrideStatus.permesso && permessoRange == null) {
      throw ArgumentError('permessoRange required when status is permesso');
    }
    if (status != OverrideStatus.permesso && permessoRange != null) {
      throw ArgumentError('permessoRange must be null unless status is permesso');
    }
  }

  bool get isWeakCoverage => status == OverrideStatus.malattiaLeggera;

  bool get isAlwaysAvailable =>
      status == OverrideStatus.ferie ||
      status == OverrideStatus.malattiaLeggera;

  /// NOTA: malattiaALetto non è “mai disponibile” in assoluto:
  /// la logica reale (casa vs esterno) vive nel CoverageEngine.
  bool get isNeverAvailable => status == OverrideStatus.malattiaALetto;
}

/// ✅ COMPATIBILITÀ CNC
/// Alcuni file del progetto (es. override_apply.dart) usano il nome PersonOverride.
/// Per evitare refactor a cascata, lo aliasiamo al modello reale.
typedef PersonOverride = PersonDayOverride;

/// Override del giorno (può contenere override solo per uno dei due)
@immutable
class DayOverrides {
  final DateTime day; // sempre normalizzato (00:00) tramite dayKey()
  final PersonDayOverride? matteo;
  final PersonDayOverride? chiara;

  const DayOverrides({required this.day, this.matteo, this.chiara});

  DayOverrides copyWith({
    PersonDayOverride? matteo,
    PersonDayOverride? chiara,
  }) {
    return DayOverrides(
      day: day,
      matteo: matteo ?? this.matteo,
      chiara: chiara ?? this.chiara,
    );
  }

  /// Crea un DayOverrides "vuoto" (nessun override) per quel giorno.
  factory DayOverrides.empty(DateTime day) {
    return DayOverrides(day: dayKey(day));
  }
}