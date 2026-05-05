// lib/logic/settings_store.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'persistence_store.dart';

/// Settings minimi (senza UI) per parametri globali.
/// Ora include:
/// - Sandra disponibile
/// - Uscita anticipata
/// - ✅ Paga oraria Sandra
class SettingsStore {
  SettingsStore() {
    _load();
  }

  static const _keySandra = 'settings_sandraDisponibile';
  static const _keyUscita13 = 'settings_uscitaAnticipata13';
  static const _keyUscitaTime = 'settings_uscitaAnticipataDefaultMin';

  // ✅ NEW
  static const _keySandraRate = 'settings_sandraHourlyRate';

  final ValueNotifier<bool> sandraDisponibile = ValueNotifier<bool>(true);

  /// Legacy
  final ValueNotifier<bool> uscitaAnticipata13 = ValueNotifier<bool>(false);

  /// minuti da mezzanotte
  final ValueNotifier<int> uscitaAnticipataDefaultMin = ValueNotifier<int>(
    13 * 60,
  );

  // ✅ NEW: paga oraria Sandra
  final ValueNotifier<double> sandraHourlyRate =
      ValueNotifier<double>(10.0);

  bool get isSandraDisponibile => sandraDisponibile.value;

  bool get isUscita13 => uscitaAnticipata13.value;

  double get sandraRate => sandraHourlyRate.value;

  TimeOfDay get uscitaAnticipataDefaultTime {
    final m = uscitaAnticipataDefaultMin.value.clamp(0, 23 * 60 + 59);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  // -------------------------
  // LOAD
  // -------------------------

  Future<void> _load() async {
    final s = await PersistenceStore.loadBool(_keySandra);
    if (s != null) {
      sandraDisponibile.value = s;
    }

    final u = await PersistenceStore.loadBool(_keyUscita13);
    if (u != null) {
      uscitaAnticipata13.value = u;
    }

    final t = await PersistenceStore.loadInt(_keyUscitaTime);
    if (t != null) {
      uscitaAnticipataDefaultMin.value = t;
    }

    // ✅ NEW
    final r = await PersistenceStore.loadDouble(_keySandraRate);
    if (r != null) {
      sandraHourlyRate.value = r;
    }
  }

  // -------------------------
  // SETTERS
  // -------------------------

  void setSandraDisponibile(bool v) {
    sandraDisponibile.value = v;
    PersistenceStore.saveBool(_keySandra, v);
  }

  void setUscitaAnticipata13(bool v) {
    uscitaAnticipata13.value = v;
    PersistenceStore.saveBool(_keyUscita13, v);
  }

  void setUscitaAnticipataDefaultTime(TimeOfDay t) {
    final m = t.hour * 60 + t.minute;
    uscitaAnticipataDefaultMin.value = m;
    PersistenceStore.saveInt(_keyUscitaTime, m);
  }

  // ✅ NEW
  void setSandraHourlyRate(double value) {
    sandraHourlyRate.value = value;
    PersistenceStore.saveDouble(_keySandraRate, value);
  }

  // -------------------------
  // DISPOSE
  // -------------------------

  void dispose() {
    sandraDisponibile.dispose();
    uscitaAnticipata13.dispose();
    uscitaAnticipataDefaultMin.dispose();
    sandraHourlyRate.dispose(); // ✅ NEW
  }
}