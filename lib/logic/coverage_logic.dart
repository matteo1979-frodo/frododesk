import '../models/person_availability.dart';

/// Ritorna true se la fascia [from, to) è coperta:
/// cioè se esiste ALMENO una persona libera per TUTTA la fascia.
bool isTimeCovered(
  DateTime from,
  DateTime to,
  List<PersonAvailability> people,
) {
  if (!to.isAfter(from)) return true;

  for (final p in people) {
    final hasOverlap = p.busyShifts.any((s) => s.overlaps(from, to));
    if (!hasOverlap) return true; // persona libera per tutta la fascia
  }

  return false;
}