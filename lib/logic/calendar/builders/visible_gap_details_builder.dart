import 'package:flutter/material.dart';

import '../../alice_companion_store.dart';
import '../../coverage_engine.dart';

class VisibleGapDetailsBuilder {
  const VisibleGapDetailsBuilder();

  List<CoverageGapDetail> build({
    required List<CoverageGapDetail> realGapDetails,
    required List<AliceCompanionEntry> companionEntries,
    required String Function(TimeOfDay time) formatTime,
  }) {
    if (realGapDetails.isNotEmpty) {
      return realGapDetails;
    }

    return companionEntries.map((entry) {
      final who = entry.person == AliceCompanionPerson.matteo
          ? 'Matteo'
          : 'Chiara';

      final start = TimeOfDay(
        hour: entry.start.hour,
        minute: entry.start.minute,
      );

      final end = TimeOfDay(hour: entry.end.hour, minute: entry.end.minute);

      return CoverageGapDetail(
        label: 'Alice con $who: ${formatTime(start)}–${formatTime(end)}',
        lines: const [],
        start: start,
        end: end,
      );
    }).toList();
  }
}
