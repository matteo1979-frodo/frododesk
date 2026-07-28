import 'package:flutter/material.dart';

import '../models/effective_school_day_timing.dart';

class EffectiveSchoolDayTimingResolver {
  static const TimeOfDay _fallbackSchoolEntry = TimeOfDay(hour: 8, minute: 25);
  static const TimeOfDay _fallbackSchoolExit = TimeOfDay(hour: 16, minute: 25);
  static const TimeOfDay _fallbackSchoolPickupWindowEnd = TimeOfDay(
    hour: 16,
    minute: 45,
  );

  const EffectiveSchoolDayTimingResolver();

  EffectiveSchoolDayTiming resolve(EffectiveSchoolDayTimingInput input) {
    final hasConfiguration = input.hasEnabledSchoolConfiguration;

    return EffectiveSchoolDayTiming(
      schoolEntryAt:
          (hasConfiguration ? input.configuredSchoolEntryAt : null) ??
          _fallbackSchoolEntry,
      schoolExitAt:
          input.schoolOutStartOverride ??
          (hasConfiguration ? input.configuredSchoolExitAt : null) ??
          _fallbackSchoolExit,
      schoolPickupWindowEnd:
          input.schoolOutEndOverride ??
          (hasConfiguration ? input.configuredSchoolPickupWindowEnd : null) ??
          _fallbackSchoolPickupWindowEnd,
      earlySchoolExitAt:
          input.earlySchoolExitOverride ??
          (input.isGlobalEarlySchoolExitEnabled
              ? input.globalEarlySchoolExitAt
              : null),
    );
  }
}
