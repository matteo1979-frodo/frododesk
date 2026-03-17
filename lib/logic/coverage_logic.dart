import '../models/person_availability.dart';

/// Ritorna true se la fascia [from, to) è coperta:
/// cioè se in ogni istante della fascia esiste almeno una persona libera.
///
/// Supporta anche copertura combinata a segmenti:
/// esempio:
/// - Chiara libera 07:30–09:00
/// - Matteo libero 09:00–10:00
/// - Chiara libera 10:00–16:25
/// => fascia coperta = true
bool isTimeCovered(
  DateTime from,
  DateTime to,
  List<PersonAvailability> people,
) {
  if (!to.isAfter(from)) return true;
  if (people.isEmpty) return false;

  final points = <DateTime>{from, to};

  for (final p in people) {
    for (final shift in p.busyShifts) {
      if (shift.start.isBefore(to) && shift.end.isAfter(from)) {
        if (!shift.start.isBefore(from) && !shift.start.isAfter(to)) {
          points.add(shift.start);
        }
        if (!shift.end.isBefore(from) && !shift.end.isAfter(to)) {
          points.add(shift.end);
        }
      }
    }
  }

  final ordered = points.toList()..sort((a, b) => a.compareTo(b));

  for (var i = 0; i < ordered.length - 1; i++) {
    final segStart = ordered[i];
    final segEnd = ordered[i + 1];

    if (!segEnd.isAfter(segStart)) continue;

    bool coveredBySomeone = false;

    for (final p in people) {
      final hasOverlap = p.busyShifts.any((s) => s.overlaps(segStart, segEnd));
      if (!hasOverlap) {
        coveredBySomeone = true;
        break;
      }
    }

    if (!coveredBySomeone) {
      return false;
    }
  }

  return true;
}
