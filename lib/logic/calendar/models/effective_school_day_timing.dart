import 'package:flutter/material.dart';

class EffectiveSchoolDayTimingInput {
  final bool hasEnabledSchoolConfiguration;
  final TimeOfDay? configuredSchoolEntryAt;
  final TimeOfDay? configuredSchoolExitAt;
  final TimeOfDay? configuredSchoolPickupWindowEnd;
  final TimeOfDay? schoolOutStartOverride;
  final TimeOfDay? schoolOutEndOverride;
  final TimeOfDay? earlySchoolExitOverride;
  final bool isGlobalEarlySchoolExitEnabled;
  final TimeOfDay globalEarlySchoolExitAt;

  const EffectiveSchoolDayTimingInput({
    required this.hasEnabledSchoolConfiguration,
    required this.configuredSchoolEntryAt,
    required this.configuredSchoolExitAt,
    required this.configuredSchoolPickupWindowEnd,
    required this.schoolOutStartOverride,
    required this.schoolOutEndOverride,
    required this.earlySchoolExitOverride,
    required this.isGlobalEarlySchoolExitEnabled,
    required this.globalEarlySchoolExitAt,
  });
}

class EffectiveSchoolDayTiming {
  final TimeOfDay schoolEntryAt;
  final TimeOfDay schoolExitAt;
  final TimeOfDay schoolPickupWindowEnd;
  final TimeOfDay? earlySchoolExitAt;

  const EffectiveSchoolDayTiming({
    required this.schoolEntryAt,
    required this.schoolExitAt,
    required this.schoolPickupWindowEnd,
    required this.earlySchoolExitAt,
  });

  bool get hasEarlySchoolExit => earlySchoolExitAt != null;
}
