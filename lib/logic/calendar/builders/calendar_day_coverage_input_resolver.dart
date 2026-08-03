import 'package:flutter/material.dart';

import '../../../models/day_override.dart';
import '../../core_store.dart';
import '../../day_settings_store.dart';
import '../../turn_engine.dart';
import '../models/effective_school_day_timing.dart';
import 'calendar_day_coverage_coordinator.dart';
import 'coverage_support_network_builder.dart';
import 'effective_school_day_timing_reader.dart';
import 'calendar_logistics_availability_resolver.dart';

class CalendarDayCoverageInputResolver {
  final CoreStore coreStore;
  final CoverageSupportNetworkBuilder supportNetworkBuilder;
  final EffectiveSchoolDayTimingReader timingReader;

  CalendarDayCoverageInputResolver({
    required this.coreStore,
    this.supportNetworkBuilder = const CoverageSupportNetworkBuilder(),
    EffectiveSchoolDayTimingReader? timingReader,
  }) : timingReader = timingReader ?? EffectiveSchoolDayTimingReader(coreStore);

  CalendarDayCoverageInputs resolve({
    required DateTime selectedDay,
    required DayOverrides overrides,
  }) {
    final day = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final timing = timingReader.read(day);
    final schoolInCover = _schoolInCover(day, timing);
    final schoolOutCover = _schoolOutCover(day, timing);
    final lunchCover = _lunchCover(day, timing);
    final sandraDecision = coreStore.coverageEngine.sandraDecisionForDay(
      day: day,
      uscita13: timing.hasEarlySchoolExit,
      overrides: overrides,
      ferieStore: coreStore.feriePeriodStore,
      lunchCover: lunchCover,
      uscitaAnticipataAt: timing.earlySchoolExitAt,
    );
    final sandraLunchStart = _sandraLunchStart(day, timing, lunchCover);
    final availability =
        CalendarLogisticsAvailabilityResolver(
          settingsStore: coreStore.settingsStore,
          daySettingsStore: coreStore.daySettingsStore,
          supportNetworkStore: coreStore.supportNetworkStore,
        ).resolve(
          day: day,
          mattinaStart: coreStore.coverageEngine.sandraCambioMattinaStart,
          mattinaEnd: coreStore.coverageEngine.sandraCambioMattinaEnd,
          pranzoStart: sandraLunchStart,
          pranzoEnd: coreStore.coverageEngine.sandraPranzoEnd,
          seraStart: coreStore.coverageEngine.sandraSeraStart,
          seraEnd: coreStore.coverageEngine.sandraSeraEnd,
        );

    return CalendarDayCoverageInputs(
      overrides: overrides,
      ferieStore: coreStore.feriePeriodStore,
      schoolInCover: schoolInCover,
      schoolOutCover: schoolOutCover,
      schoolOutStart: timing.schoolExitAt,
      schoolOutEnd: timing.schoolPickupWindowEnd,
      lunchCover: lunchCover,
      earlySchoolExitAt: timing.earlySchoolExitAt,
      sandraAvailable: availability.sandraAvailable,
      serveSandraMattina: sandraDecision.serveSandraMattina,
      serveSandraPranzo: sandraDecision.serveSandraPranzo,
      serveSandraSera: sandraDecision.serveSandraSera,
      sandraLunchStart: sandraLunchStart,
      logisticsAvailability: availability,
    );
  }

  SchoolCoverChoice _schoolInCover(
    DateTime day,
    EffectiveSchoolDayTiming timing,
  ) {
    final saved = coreStore.daySettingsStore.schoolInCoverForDay(day);
    if (saved != SchoolCoverChoice.none) return saved;
    final entry =
        coreStore.aliceEventStore.getEventForDay(day)?.summerCampStart ??
        timing.schoolEntryAt;
    final minutes = entry.hour * 60 + entry.minute - 20;
    final start = TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);
    return _covered(day, start, entry)
        ? SchoolCoverChoice.altro
        : SchoolCoverChoice.none;
  }

  SchoolCoverChoice _schoolOutCover(
    DateTime day,
    EffectiveSchoolDayTiming timing,
  ) {
    final saved = coreStore.daySettingsStore.schoolOutCoverForDay(day);
    if (saved != SchoolCoverChoice.none) return saved;
    return _covered(day, timing.schoolExitAt, timing.schoolPickupWindowEnd)
        ? SchoolCoverChoice.altro
        : SchoolCoverChoice.none;
  }

  SchoolCoverChoice _lunchCover(DateTime day, EffectiveSchoolDayTiming timing) {
    final saved = coreStore.daySettingsStore.lunchCoverForDay(day);
    if (saved != SchoolCoverChoice.none) return saved;
    final exit = timing.earlySchoolExitAt;
    if (exit == null) return SchoolCoverChoice.none;
    return _covered(day, exit, coreStore.coverageEngine.sandraPranzoEnd)
        ? SchoolCoverChoice.altro
        : SchoolCoverChoice.none;
  }

  bool _covered(DateTime day, TimeOfDay start, TimeOfDay end) =>
      supportNetworkBuilder.coversRange(
        coreStore: coreStore,
        daySettingsStore: coreStore.daySettingsStore,
        day: day,
        start: start,
        end: end,
      );

  TimeOfDay _sandraLunchStart(
    DateTime day,
    EffectiveSchoolDayTiming timing,
    SchoolCoverChoice lunchCover,
  ) {
    final exit = timing.earlySchoolExitAt;
    if (exit == null) return coreStore.coverageEngine.sandraPranzoStart;
    if (lunchCover == SchoolCoverChoice.matteo) {
      return _firstBusyStart(day, TurnPerson.matteo, exit);
    }
    if (lunchCover == SchoolCoverChoice.chiara) {
      return _firstBusyStart(day, TurnPerson.chiara, exit);
    }
    return exit;
  }

  TimeOfDay _firstBusyStart(DateTime day, TurnPerson person, TimeOfDay from) {
    final fromMinutes = from.hour * 60 + from.minute;
    final end = coreStore.coverageEngine.sandraPranzoEnd;
    final endMinutes = end.hour * 60 + end.minute;
    for (final shift in coreStore.turnEngine.busyShiftsForPerson(
      person: person,
      day: day,
    )) {
      final startMinutes = shift.start.hour * 60 + shift.start.minute;
      if (startMinutes >= fromMinutes && startMinutes < endMinutes) {
        return TimeOfDay(hour: shift.start.hour, minute: shift.start.minute);
      }
    }
    return end;
  }
}
