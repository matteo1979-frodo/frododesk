import 'package:flutter/material.dart';

import '../../core_store.dart';
import '../../day_settings_store.dart';
import '../../../utils/calendario_formatters.dart';
import 'calendar_logistics_availability_resolver.dart';

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
    final availability = CalendarLogisticsAvailabilityResult(
      day: DateTime(day.year, day.month, day.day),
      sandraWindows: const [],
      supportNetworkStore: coreStore.supportNetworkStore,
      daySettingsStore: daySettingsStore,
    );
    return availability
        .supportForWindow(start, end)
        .map(
          (match) => CoverageSupportMatch(
            personName: match.displayName,
            start: match.slotStart,
            end: match.slotEnd,
          ),
        )
        .toList(growable: false);
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

  String? summaryForRange({
    required CoreStore coreStore,
    required DaySettingsStore daySettingsStore,
    required DateTime day,
    required TimeOfDay start,
    required TimeOfDay end,
    required String label,
  }) {
    final matches = matchesForRange(
      coreStore: coreStore,
      daySettingsStore: daySettingsStore,
      day: day,
      start: start,
      end: end,
    );

    if (matches.isEmpty) return null;

    final match = matches.first;

    final prettyName = match.personName.isEmpty
        ? match.personName
        : "${match.personName[0].toUpperCase()}${match.personName.substring(1)}";

    return "• $label coperto da $prettyName "
        "(${fmtTimeOfDay(match.start)}-${fmtTimeOfDay(match.end)})";
  }
}
