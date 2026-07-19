import 'package:flutter/material.dart';

import '../../core_store.dart';
import '../../day_settings_store.dart';

class CoverageSupportMatch {
  final String personName;
  final TimeOfDay start;
  final TimeOfDay end;

  const CoverageSupportMatch({
    required this.personName,
    required this.start,
    required this.end,
  });
}

class CoverageSupportNetworkBuilder {
  const CoverageSupportNetworkBuilder();

  List<CoverageSupportMatch> matchesForRange({
    required CoreStore coreStore,
    required DaySettingsStore daySettingsStore,
    required DateTime day,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final d0 = DateTime(day.year, day.month, day.day);

    final rangeStart = DateTime(
      d0.year,
      d0.month,
      d0.day,
      start.hour,
      start.minute,
    );

    final rangeEnd = DateTime(d0.year, d0.month, d0.day, end.hour, end.minute);

    final matches = <CoverageSupportMatch>[];

    for (final person in coreStore.supportNetworkStore.people) {
      if (!person.enabled) continue;

      final enabledForDay = daySettingsStore.isSupportPersonEnabledForDay(
        d0,
        person.id,
      );

      if (!enabledForDay) continue;

      final supportStart = DateTime(
        d0.year,
        d0.month,
        d0.day,
        person.start.hour,
        person.start.minute,
      );

      final supportEnd = DateTime(
        d0.year,
        d0.month,
        d0.day,
        person.end.hour,
        person.end.minute,
      );

      final coversFullRange =
          !supportStart.isAfter(rangeStart) && !supportEnd.isBefore(rangeEnd);

      if (!coversFullRange) continue;

      matches.add(
        CoverageSupportMatch(
          personName: person.name,
          start: person.start,
          end: person.end,
        ),
      );
    }

    return matches;
  }

  bool coversRange({
    required CoreStore coreStore,
    required DaySettingsStore daySettingsStore,
    required DateTime day,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    return matchesForRange(
      coreStore: coreStore,
      daySettingsStore: daySettingsStore,
      day: day,
      start: start,
      end: end,
    ).isNotEmpty;
  }
}
