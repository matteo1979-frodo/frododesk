// lib/logic/override_apply.dart
import '../models/work_shift.dart';
import '../models/day_override.dart';

class OverrideApply {
  /// Applica un override alla lista busy base.
  ///
  /// Regole CNC:
  /// - null o Normal -> nessuna modifica (vale baseBusy)
  /// - Ferie / Malattia -> rimuove i turni lavoro (busy = [])
  /// - ✅ Permesso(start–end) -> disponibile SOLO in quel range:
  ///     busy = [00:00–start) + [end–24:00)
  static List<WorkShift> applyToBusyShifts({
    required DateTime day,
    required List<WorkShift> baseBusy,
    required PersonOverride? personOverride,
  }) {
    if (personOverride == null) return baseBusy;
    if (personOverride.status == OverrideStatus.normal) return baseBusy;

    // Permesso = disponibile solo nell'intervallo permessoRange
    if (personOverride.status == OverrideStatus.permesso) {
      final range = personOverride.permessoRange!;
      final d0 = DateTime(day.year, day.month, day.day);

      final start = d0.add(Duration(minutes: range.startMin));
      final end = d0.add(Duration(minutes: range.endMin));

      final dayStart = d0; // 00:00
      final dayEnd = d0.add(const Duration(days: 1)); // 24:00

      final busy = <WorkShift>[];

      // Busy prima del permesso
      if (start.isAfter(dayStart)) {
        busy.add(
          WorkShift(
            start: dayStart,
            end: start,
          ),
        );
      }

      // Busy dopo il permesso
      if (dayEnd.isAfter(end)) {
        busy.add(
          WorkShift(
            start: end,
            end: dayEnd,
          ),
        );
      }

      return busy;
    }

    // Ferie / Malattia: qui togliamo il turno lavoro (busy base).
    // Vincoli "casa vs esterno" restano nel CoverageEngine.
    return <WorkShift>[];
  }
}