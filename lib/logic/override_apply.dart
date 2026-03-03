import '../models/work_shift.dart';
import '../models/day_override.dart';

class OverrideApply {
  /// Applica un override alla lista busy base.
  /// Regola minima CNC: se override è null o Normal -> nessuna modifica.
  /// Se Ferie/Permesso/Malattia -> per ora “svuota lavoro” (poi in CoverageEngine gestisci malattia come copertura logica).
  static List<WorkShift> applyToBusyShifts({
    required DateTime day,
    required List<WorkShift> baseBusy,
    required PersonOverride? personOverride,
  }) {
    if (personOverride == null) return baseBusy;
    if (personOverride.status == OverrideStatus.normal) return baseBusy;

    // In questo livello: l'override toglie il turno lavoro (busy base).
    // Eventuali vincoli/limitazioni copertura vengono gestiti in CoverageEngine.
    return <WorkShift>[];
  }
}
