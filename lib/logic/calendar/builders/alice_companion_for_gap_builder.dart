import 'package:flutter/material.dart';

import '../../alice_companion_store.dart';

class AliceCompanionForGapBuilder {
  const AliceCompanionForGapBuilder();

  AliceCompanionPerson build({
    required DateTime day,
    required TimeOfDay start,
    required TimeOfDay end,
    required bool matteoSick,
    required bool chiaraSick,
    required TimeOfDay? matteoWorkStart,
    required TimeOfDay? matteoWorkEnd,
    required TimeOfDay? chiaraWorkStart,
    required TimeOfDay? chiaraWorkEnd,
    required List<AliceCompanionBusyEvent> events,
  }) {
    DateTime toDateTime(TimeOfDay time) {
      return DateTime(day.year, day.month, day.day, time.hour, time.minute);
    }

    bool overlaps(
      DateTime aStart,
      DateTime aEnd,
      DateTime bStart,
      DateTime bEnd,
    ) {
      return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
    }

    final gapStart = toDateTime(start);
    final gapEnd = toDateTime(end);

    var matteoBusy = false;
    var chiaraBusy = false;

    if (matteoSick) {
      matteoBusy = false;
    }

    if (chiaraSick) {
      chiaraBusy = false;
    }

    if (matteoWorkStart != null && matteoWorkEnd != null) {
      final workStart = toDateTime(matteoWorkStart);
      final workEnd = toDateTime(matteoWorkEnd);

      matteoBusy = matteoBusy || overlaps(workStart, workEnd, gapStart, gapEnd);
    }

    if (chiaraWorkStart != null && chiaraWorkEnd != null) {
      final workStart = toDateTime(chiaraWorkStart);
      final workEnd = toDateTime(chiaraWorkEnd);

      chiaraBusy = chiaraBusy || overlaps(workStart, workEnd, gapStart, gapEnd);
    }

    for (final event in events) {
      final eventStart = toDateTime(event.start);
      final eventEnd = toDateTime(event.end);
      final hit = overlaps(eventStart, eventEnd, gapStart, gapEnd);

      if (!hit) continue;

      if (event.personKey == 'matteo') {
        matteoBusy = true;
      }

      if (event.personKey == 'chiara') {
        chiaraBusy = true;
      }
    }

    for (final event in events) {
      final eventStart = toDateTime(event.start);
      final eventEnd = toDateTime(event.end);
      final hit = overlaps(eventStart, eventEnd, gapStart, gapEnd);

      if (!hit) continue;

      if (event.personKey == 'chiara') {
        return AliceCompanionPerson.chiara;
      }

      if (event.personKey == 'matteo') {
        return AliceCompanionPerson.matteo;
      }
    }

    if (!matteoBusy && chiaraBusy) {
      return AliceCompanionPerson.matteo;
    }

    if (!chiaraBusy && matteoBusy) {
      return AliceCompanionPerson.chiara;
    }

    if (!matteoBusy && !chiaraBusy) {
      return AliceCompanionPerson.matteo;
    }

    return AliceCompanionPerson.nessuno;
  }
}

class AliceCompanionBusyEvent {
  final String? personKey;
  final TimeOfDay start;
  final TimeOfDay end;

  const AliceCompanionBusyEvent({
    required this.personKey,
    required this.start,
    required this.end,
  });
}
