// lib/logic/override_store.dart
import 'package:flutter/foundation.dart';

import '../models/day_override.dart';

/// Store in memoria per Step B:
/// - mantiene gli override per data (solo giorno, senza orario)
/// - nessuna persistenza ancora (quella sarà Step B+ / futuro)
class OverrideStore extends ChangeNotifier {
  final Map<DateTime, DayOverrides> _byDay = {};

  /// Normalizza una DateTime a "solo giorno" (00:00)
  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Ritorna override del giorno (se non presente -> vuoto)
  DayOverrides getForDay(DateTime day) {
    final key = _dayKey(day);
    return _byDay[key] ?? DayOverrides.empty(day);
  }

  /// Imposta tutto l'override del giorno
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
