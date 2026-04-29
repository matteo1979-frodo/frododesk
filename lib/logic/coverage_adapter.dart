import 'package:flutter/material.dart';

import '../models/day_override.dart';
import 'override_store.dart';
import 'coverage_engine.dart';
import 'ferie_period_store.dart';

/// Adapter certificato: IPS NON calcola.
/// Legge solo i buchi finali reali NON risolti dal CoverageEngine.
class CoverageAdapter {
  final OverrideStore overrideStore;
  final CoverageEngine engine;
  final FeriePeriodStore ferieStore;

  final bool Function(DateTime day) sandraDisponibileForDay;
  final bool Function(DateTime day) uscita13ForDay;

  CoverageAdapter({
    required this.overrideStore,
    required this.engine,
    required this.ferieStore,
    required this.sandraDisponibileForDay,
    required this.uscita13ForDay,
  });

  List<CoverageGapDetail> realGapDetailsForDay(DateTime day) {
    final d0 = DateTime(day.year, day.month, day.day);

    final entryMinutes =
        engine.schoolStore.schoolDayConfigFor(d0)?.entryMinutes ?? 505;

    final schoolInCover = engine.daySettingsStore.schoolInCoverForDay(d0);
    final schoolOutCover = engine.daySettingsStore.schoolOutCoverForDay(d0);
    final lunchCover = engine.daySettingsStore.lunchCoverForDay(d0);

    final hasSchoolInChoice = schoolInCover.name.toLowerCase() != 'none';
    final hasSchoolOutChoice = schoolOutCover.name.toLowerCase() != 'none';
    final hasLunchChoice = lunchCover.name.toLowerCase() != 'none';

    final details = engine
        .analyzeDayV2(
          day: d0,
          uscita13:
              engine.daySettingsStore.uscita13ForDay(d0) ?? uscita13ForDay(d0),
          sandraMattinaOn:
              engine.daySettingsStore.sandraMattinaForDay(d0) ??
              sandraDisponibileForDay(d0),
          sandraPranzoOn:
              engine.daySettingsStore.sandraPranzoForDay(d0) ??
              sandraDisponibileForDay(d0),
          sandraSeraOn:
              engine.daySettingsStore.sandraSeraForDay(d0) ??
              sandraDisponibileForDay(d0),
          schoolStart: TimeOfDay(
            hour: entryMinutes ~/ 60,
            minute: entryMinutes % 60,
          ),
          overrides: overrideStore.getEffectiveForDay(
            day: d0,
            ferieStore: ferieStore,
          ),
          ferieStore: ferieStore,
          schoolInCover: schoolInCover,
          schoolOutCover: schoolOutCover,
          schoolOutStart:
              engine.daySettingsStore.schoolOutStartForDay(d0) ??
              const TimeOfDay(hour: 16, minute: 25),
          schoolOutEnd:
              engine.daySettingsStore.schoolOutEndForDay(d0) ??
              const TimeOfDay(hour: 16, minute: 45),
          lunchCover: lunchCover,
          uscitaAnticipataAt: engine.daySettingsStore
              .uscitaAnticipataTimeForDay(d0),
        )
        .details;

    return details
        .where(
          (detail) => _isFinalUnresolvedGap(
            detail,
            hasSchoolInChoice: hasSchoolInChoice,
            hasSchoolOutChoice: hasSchoolOutChoice,
            hasLunchChoice: hasLunchChoice,
          ),
        )
        .toList(growable: false);
  }

  bool _isFinalUnresolvedGap(
    CoverageGapDetail detail, {
    required bool hasSchoolInChoice,
    required bool hasSchoolOutChoice,
    required bool hasLunchChoice,
  }) {
    final label = detail.label.toLowerCase();
    final text = detail.lines.join(' ').toLowerCase();

    if (label.contains('alice ingresso') && hasSchoolInChoice) {
      return false;
    }

    if (label.contains('alice uscita') && hasSchoolOutChoice) {
      return false;
    }

    if (label.contains('alice pranzo') && hasLunchChoice) {
      return false;
    }

    final hasCoverage =
        text.contains('risulta disponibile') ||
        text.contains('potrebbe coprire') ||
        text.contains('rete supporto disponibile') ||
        text.contains('sandra è attiva');

    return !hasCoverage;
  }

  List<String> gapsForDay(DateTime day) {
    return realGapDetailsForDay(day).map((g) => g.label).toList();
  }

  int riskScore30Days({DateTime? startDay}) {
    final DateTime now = DateTime.now();
    final DateTime base = startDay ?? now;
    final DateTime start = DateTime(base.year, base.month, base.day);

    final todayDetails = realGapDetailsForDay(start);

    final int nowMinutes = now.hour * 60 + now.minute;

    for (final detail in todayDetails) {
      final startMinutes = detail.start.hour * 60 + detail.start.minute;
      final endMinutes = detail.end.hour * 60 + detail.end.minute;

      if (startMinutes <= nowMinutes && endMinutes > nowMinutes) {
        return 80;
      }
    }

    for (final detail in todayDetails) {
      final endMinutes = detail.end.hour * 60 + detail.end.minute;

      if (endMinutes > nowMinutes) {
        return 60;
      }
    }

    for (int i = 1; i < 30; i++) {
      final d = start.add(Duration(days: i));
      final details = realGapDetailsForDay(d);

      if (details.isNotEmpty) {
        return 40;
      }
    }

    return 0;
  }
}
