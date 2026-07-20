import 'package:flutter/material.dart';

import '../../core_store.dart';
import '../../day_settings_store.dart';
import '../models/day_support_summaries.dart';
import 'coverage_support_network_builder.dart';

class DaySupportSummariesBuilder {
  const DaySupportSummariesBuilder();

  DaySupportSummaries build({
    required CoverageSupportNetworkBuilder coverageSupportNetworkBuilder,
    required CoreStore coreStore,
    required DaySettingsStore daySettingsStore,
    required DateTime day,
    required TimeOfDay schoolInStart,
    required TimeOfDay schoolInEnd,
    required TimeOfDay schoolOutStart,
    required TimeOfDay schoolOutEnd,
    required bool earlySchoolExitActive,
    required TimeOfDay? earlySchoolExitAt,
    required TimeOfDay lunchEnd,
  }) {
    final schoolIn = coverageSupportNetworkBuilder.summaryForRange(
      coreStore: coreStore,
      daySettingsStore: daySettingsStore,
      day: day,
      start: schoolInStart,
      end: schoolInEnd,
      label: 'Ingresso scuola',
    );
    final schoolOut = coverageSupportNetworkBuilder.summaryForRange(
      coreStore: coreStore,
      daySettingsStore: daySettingsStore,
      day: day,
      start: schoolOutStart,
      end: schoolOutEnd,
      label: 'Uscita scuola',
    );

    final lunch = earlySchoolExitActive && earlySchoolExitAt != null
        ? coverageSupportNetworkBuilder.summaryForRange(
            coreStore: coreStore,
            daySettingsStore: daySettingsStore,
            day: day,
            start: earlySchoolExitAt,
            end: lunchEnd,
            label: 'Pranzo',
          )
        : null;

    return DaySupportSummaries(
      schoolIn: schoolIn,
      schoolOut: schoolOut,
      lunch: lunch,
    );
  }
}
