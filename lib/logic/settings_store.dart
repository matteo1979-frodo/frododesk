// lib/logic/settings_store.dart
import 'package:flutter/foundation.dart';

/// Settings minimi (senza UI) per parametri che oggi sono bool sparsi.
/// Obiettivo: un solo punto di lettura per Home + Calendario.
/// Nessuna persistenza per ora (cantiere). Default = comportamento attuale.
class SettingsStore {
  SettingsStore();

  // Default attuali:
  // - Sandra disponibile = true
  // - Uscita anticipata 13 = false
  final ValueNotifier<bool> sandraDisponibile = ValueNotifier<bool>(true);
  final ValueNotifier<bool> uscitaAnticipata13 = ValueNotifier<bool>(false);

  bool get isSandraDisponibile => sandraDisponibile.value;
  bool get isUscita13 => uscitaAnticipata13.value;

  void setSandraDisponibile(bool v) => sandraDisponibile.value = v;
  void setUscitaAnticipata13(bool v) => uscitaAnticipata13.value = v;

  void dispose() {
    sandraDisponibile.dispose();
    uscitaAnticipata13.dispose();
  }
}
