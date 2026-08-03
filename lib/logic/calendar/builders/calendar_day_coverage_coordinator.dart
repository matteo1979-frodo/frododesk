import 'package:flutter/material.dart';

import '../../../models/day_override.dart';
import '../../coverage_engine.dart';
import '../../day_settings_store.dart';
import '../../ferie_period_store.dart';
import '../models/coverage_result_step_a.dart';
import 'coverage_gap_filter.dart';
import 'coverage_result_step_a_builder.dart';
import 'coverage_summary_builder.dart';
import 'calendar_logistics_availability_resolver.dart';

class CalendarDayCoverageRequest {
  final DateTime day;
  final bool uscita13;
  final bool sandraMorningAvailable;
  final bool sandraLunchAvailable;
  final bool sandraEveningAvailable;
  final DayOverrides overrides;
  final FeriePeriodStore ferieStore;
  final SchoolCoverChoice schoolInCover;
  final SchoolCoverChoice schoolOutCover;
  final TimeOfDay schoolOutStart;
  final TimeOfDay schoolOutEnd;
  final SchoolCoverChoice lunchCover;
  final TimeOfDay? uscitaAnticipataAt;

  const CalendarDayCoverageRequest({
    required this.day,
    required this.uscita13,
    required this.sandraMorningAvailable,
    required this.sandraLunchAvailable,
    required this.sandraEveningAvailable,
    required this.overrides,
    required this.ferieStore,
    required this.schoolInCover,
    required this.schoolOutCover,
    required this.schoolOutStart,
    required this.schoolOutEnd,
    required this.lunchCover,
    required this.uscitaAnticipataAt,
  });
}

typedef CalendarDayCoverageAnalyzer =
    CoverageDayAnalysis Function(CalendarDayCoverageRequest request);

class CalendarDayCoverageInputs {
  final DayOverrides overrides;
  final FeriePeriodStore ferieStore;
  final SchoolCoverChoice schoolInCover;
  final SchoolCoverChoice schoolOutCover;
  final TimeOfDay schoolOutStart;
  final TimeOfDay schoolOutEnd;
  final SchoolCoverChoice lunchCover;
  final TimeOfDay? earlySchoolExitAt;
  final bool serveSandraMattina;
  final bool serveSandraPranzo;
  final bool serveSandraSera;
  final TimeOfDay sandraLunchStart;
  final CalendarLogisticsAvailabilityResult logisticsAvailability;

  const CalendarDayCoverageInputs({
    required this.overrides,
    required this.ferieStore,
    required this.schoolInCover,
    required this.schoolOutCover,
    required this.schoolOutStart,
    required this.schoolOutEnd,
    required this.lunchCover,
    required this.earlySchoolExitAt,
    required this.serveSandraMattina,
    required this.serveSandraPranzo,
    required this.serveSandraSera,
    this.sandraLunchStart = const TimeOfDay(hour: 13, minute: 0),
    required this.logisticsAvailability,
  });
}

class CalendarDayCoverageCoordinator {
  final CalendarDayCoverageAnalyzer analyze;
  final CoverageGapFilter gapFilter;
  final CoverageSummaryBuilder summaryBuilder;
  final CoverageResultStepABuilder resultBuilder;

  const CalendarDayCoverageCoordinator({
    required this.analyze,
    this.gapFilter = const CoverageGapFilter(),
    this.summaryBuilder = const CoverageSummaryBuilder(),
    this.resultBuilder = const CoverageResultStepABuilder(),
  });

  CoverageResultStepA build({
    required DateTime selectedDay,
    required DateTime observedAt,
    required CalendarDayCoverageInputs inputs,
  }) {
    final day = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final uscita13 = inputs.earlySchoolExitAt != null;
    final availability = inputs.logisticsAvailability;
    final analysis = analyze(
      CalendarDayCoverageRequest(
        day: day,
        uscita13: uscita13,
        sandraMorningAvailable: availability.sandraAvailableFor(
          SandraAvailabilityBand.mattina,
        ),
        sandraLunchAvailable: availability.sandraAvailableFor(
          SandraAvailabilityBand.pranzo,
        ),
        sandraEveningAvailable: availability.sandraAvailableFor(
          SandraAvailabilityBand.sera,
        ),
        overrides: inputs.overrides,
        ferieStore: inputs.ferieStore,
        schoolInCover: inputs.schoolInCover,
        schoolOutCover: inputs.schoolOutCover,
        schoolOutStart: inputs.schoolOutStart,
        schoolOutEnd: inputs.schoolOutEnd,
        lunchCover: inputs.lunchCover,
        uscitaAnticipataAt: inputs.earlySchoolExitAt,
      ),
    );

    final gapDetails = gapFilter.filter(
      details: analysis.details,
      selectedDay: day,
      now: observedAt,
      uscitaAnticipataActive: uscita13,
      schoolInCover: inputs.schoolInCover,
      schoolOutCover: inputs.schoolOutCover,
      lunchCover: inputs.lunchCover,
    );
    final gaps = gapDetails.map((detail) => detail.label).toList();
    final summary = summaryBuilder.build(
      serveSandraMattina: inputs.serveSandraMattina,
      serveSandraPranzo: inputs.serveSandraPranzo,
      serveSandraSera: inputs.serveSandraSera,
      coverageOk: gaps.isEmpty,
      gaps: gaps,
    );

    return resultBuilder.build(
      analysis: analysis,
      filteredGapDetails: gapDetails,
      summaryDetails: summary.details,
      bannerText: summary.bannerText,
    );
  }
}
