// lib/logic/override_store.dart
import 'package:flutter/foundation.dart';

import '../models/day_override.dart';
import 'ferie_period_store.dart';

/// Store in memoria per Step B:
/// - mantiene gli override MANUALI per data (solo giorno, senza orario)
/// - nessuna persistenza ancora (quella sarà Step B+ / futuro)
class OverrideStore extends ChangeNotifier {
  final Map<DateTime, DayOverrides> _byDay = {};

  /// Normalizza una DateTime a "solo giorno" (00:00)
  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Ritorna override MANUALE del giorno (se non presente -> vuoto)
  DayOverrides getForDay(DateTime day) {
    final key = _dayKey(day);
    return _byDay[key] ?? DayOverrides.empty(day);
  }

  /// ✅ NEW: Ritorna override "EFFETTIVO" per UI (Step B visibile)
  /// Regola: Override manuale > Ferie lunghe
  /// - Se esiste override manuale per una persona -> si mostra quello
  /// - Se NON esiste override manuale e la persona è in ferie -> si mostra Ferie
  ///
  /// NOTA: questo NON scrive nulla nello store. È solo una vista.
  DayOverrides getEffectiveForDay({
    required DateTime day,
    required FeriePeriodStore ferieStore,
  }) {
    final d0 = _dayKey(day);
    final manual = getForDay(d0);

    final matteoEff = manual.matteo ??
        (ferieStore.isOnHoliday(FeriePerson.matteo, d0)
            ? PersonDayOverride(status: OverrideStatus.ferie)
            : null);

    final chiaraEff = manual.chiara ??
        (ferieStore.isOnHoliday(FeriePerson.chiara, d0)
            ? PersonDayOverride(status: OverrideStatus.ferie)
            : null);

    return DayOverrides(
      day: dayKey(d0),
      matteo: matteoEff,
      chiara: chiaraEff,
    );
  }

  /// Imposta tutto l'override del giorno (MANUALE)
  void setForDay(DateTime day, DayOverrides overrides) {
    final key = _dayKey(day);
    _byDay[key] = overrides;
    notifyListeners();
  }

  /// Cancella override del giorno (torna a default)
  void clearDay(DateTime day) {
    final key = _dayKey(day);
    if (_byDay.remove(key) != null) {
      notifyListeners();
    }
  }

  /// Utility: true se esiste override salvato per quel giorno
  bool hasOverride(DateTime day) {
    final key = _dayKey(day);
    return _byDay.containsKey(key);
  }
}