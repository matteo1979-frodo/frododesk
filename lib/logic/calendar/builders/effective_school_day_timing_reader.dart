import 'package:flutter/material.dart';

import '../../core_store.dart';
import '../models/effective_school_day_timing.dart';
import 'effective_school_day_timing_resolver.dart';

class EffectiveSchoolDayTimingReader {
  final CoreStore coreStore;
  final EffectiveSchoolDayTimingResolver resolver;

  const EffectiveSchoolDayTimingReader(
    this.coreStore, {
    this.resolver = const EffectiveSchoolDayTimingResolver(),
  });

  EffectiveSchoolDayTiming read(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final schoolConfiguration = coreStore.schoolStore
        .activePeriodForDay(normalizedDay)
        ?.weekConfig
        .forWeekday(normalizedDay.weekday);
    final hasEnabledConfiguration = schoolConfiguration?.enabled ?? false;

    return resolver.resolve(
      EffectiveSchoolDayTimingInput(
        hasEnabledSchoolConfiguration: hasEnabledConfiguration,
        configuredSchoolEntryAt: hasEnabledConfiguration
            ? _fromMinutes(schoolConfiguration!.entryMinutes)
            : null,
        configuredSchoolExitAt: hasEnabledConfiguration
            ? _fromMinutes(schoolConfiguration!.exitRealMinutes)
            : null,
        configuredSchoolPickupWindowEnd: hasEnabledConfiguration
            ? _fromMinutes(schoolConfiguration!.returnHomeMinutes)
            : null,
        schoolOutStartOverride: coreStore.daySettingsStore.schoolOutStartForDay(
          normalizedDay,
        ),
        schoolOutEndOverride: coreStore.daySettingsStore.schoolOutEndForDay(
          normalizedDay,
        ),
        earlySchoolExitOverride: coreStore.daySettingsStore
            .uscitaAnticipataTimeForDay(normalizedDay),
        isGlobalEarlySchoolExitEnabled: coreStore.settingsStore.isUscita13,
        globalEarlySchoolExitAt:
            coreStore.settingsStore.uscitaAnticipataDefaultTime,
      ),
    );
  }

  TimeOfDay _fromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }
}
