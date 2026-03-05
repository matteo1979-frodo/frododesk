// lib/logic/settings_store.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Settings minimi (senza UI) per parametri che oggi sono bool sparsi.
/// Obiettivo: un solo punto di lettura per Home + Calendario.
/// Nessuna persistenza per ora (cantiere). Default = comportamento attuale.
class SettingsStore {
  SettingsStore();

  // Default attuali:
  // - Sandra disponibile = true
  // - Uscita anticipata (legacy bool) = false
  // - Orario uscita anticipata default = 13:00
  final ValueNotifier<bool> sandraDisponibile = ValueNotifier<bool>(true);

  /// Legacy: usato come fallback generale quando non c'è impostazione per giorno.
  /// (Resta compatibile con il resto del progetto)
  final ValueNotifier<bool> uscitaAnticipata13 = ValueNotifier<bool>(false);

  /// ✅ NEW: orario default uscita anticipata (minuti da mezzanotte)
  final ValueNotifier<int> uscitaAnticipataDefaultMin =
      ValueNotifier<int>(13 * 60);

  bool get isSandraDisponibile => sandraDisponibile.value;
  bool get isUscita13 => uscitaAnticipata13.value;

  TimeOfDay get uscitaAnticipataDefaultTime {
    final m = uscitaAnticipataDefaultMin.value.clamp(0, 23 * 60 + 59);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  void setSandraDisponibile(bool v) => sandraDisponibile.value = v;
  void setUscitaAnticipata13(bool v) => uscitaAnticipata13.value = v;

  void setUscitaAnticipataDefaultTime(TimeOfDay t) {
    uscitaAnticipataDefaultMin.value = t.hour * 60 + t.minute;
  }

  void dispose() {
    sandraDisponibile.dispose();
    uscitaAnticipata13.dispose();
    uscitaAnticipataDefaultMin.dispose();
  }
}