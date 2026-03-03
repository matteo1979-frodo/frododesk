// lib/logic/week_store.dart
import '../models/week_identity.dart';

/// Store di dominio per la "Settimana Attiva".
/// CNC: non è UI, non è widget.
/// Predisposto per persistenza futura (interfaccia), ma ora è solo in-memory.
class WeekStore {
  WeekIdentity _activeWeek;

  WeekStore({DateTime? initialDate})
      : _activeWeek = WeekIdentity.fromDate(initialDate ?? DateTime.now());

  WeekIdentity get activeWeek => _activeWeek;

  /// Imposta settimana attiva partendo da una data qualsiasi (deterministico).
  void setFromDate(DateTime anyDate) {
    _activeWeek = WeekIdentity.fromDate(anyDate);
  }

  /// Navigazione infinita
  void nextWeek() {
    _activeWeek = _activeWeek.nextWeek();
  }

  void previousWeek() {
    _activeWeek = _activeWeek.previousWeek();
  }

  // --- Predisposizione persistenza (NON implementata ora) ---
  Future<void> load() async {
    // TODO: caricare weekStart salvato
  }

  Future<void> save() async {
    // TODO: salvare weekStart
  }
}