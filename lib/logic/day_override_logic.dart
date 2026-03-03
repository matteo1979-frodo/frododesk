// lib/logic/day_override_logic.dart
import '../models/day_override.dart';
import '../models/person_availability.dart';
import '../logic/override_apply.dart';

/// Disponibilità effettiva di una persona nel giorno:
/// - availability: busy shifts dopo applicazione override (Step B)
/// - weakCoverage: true se MalattiaLeggera
class EffectivePersonAvailability {
  final PersonAvailability availability;
  final bool weakCoverage;

  EffectivePersonAvailability({
    required this.availability,
    required this.weakCoverage,
  });
}

/// Costruisce la disponibilità effettiva per quel giorno,
/// partendo dalla base (Step A) + override (Step B).
EffectivePersonAvailability buildEffectiveAvailabilityForDay({
  required DateTime day,
  required PersonAvailability base,
  required PersonDayOverride? override,
}) {
  final busy = OverrideApply.applyToBusyShifts(
    day: dayKey(day),
    baseBusy: base.busyShifts,
    personOverride: override,
  );

  return EffectivePersonAvailability(
    availability: PersonAvailability(busyShifts: busy),
    weakCoverage: override?.status == OverrideStatus.malattiaLeggera,
  );
}
