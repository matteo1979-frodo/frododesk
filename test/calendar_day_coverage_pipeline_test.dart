import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/alice_home_risk_view_model_builder.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_coverage_coordinator.dart';
import 'package:frododesk/logic/calendar/builders/coverage_result_step_a_builder.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/ferie_period_store.dart';
import 'package:frododesk/models/coverage_criticality_detail.dart';
import 'package:frododesk/models/day_override.dart';

CoverageGapDetail _gap(int startHour, int endHour) => CoverageGapDetail(
  label: 'Alice a casa',
  lines: const ['Nessun adulto disponibile'],
  start: TimeOfDay(hour: startHour, minute: 0),
  end: TimeOfDay(hour: endHour, minute: 0),
);

CoverageCriticalityDetail _criticality(CoverageCriticalityKind kind) =>
    CoverageCriticalityDetail(
      kind: kind,
      personId: 'matteo',
      start: DateTime(2026, 8, 11, 6, 35),
      end: DateTime(2026, 8, 11, 14, 30),
      source: CoverageSource.parentForced,
      coverageProviderId: null,
    );

CalendarDayCoverageInputs _inputs(DateTime day) => CalendarDayCoverageInputs(
  overrides: DayOverrides.empty(day),
  ferieStore: FeriePeriodStore(),
  schoolInCover: SchoolCoverChoice.none,
  schoolOutCover: SchoolCoverChoice.none,
  schoolOutStart: const TimeOfDay(hour: 16, minute: 25),
  schoolOutEnd: const TimeOfDay(hour: 16, minute: 45),
  lunchCover: SchoolCoverChoice.none,
  earlySchoolExitAt: null,
  sandraAvailable: false,
  serveSandraMattina: false,
  serveSandraPranzo: false,
  serveSandraSera: false,
);

class _CountingResultBuilder extends CoverageResultStepABuilder {
  int calls = 0;

  @override
  build({
    required analysis,
    required filteredGapDetails,
    required summaryDetails,
    required bannerText,
  }) {
    calls++;
    return super.build(
      analysis: analysis,
      filteredGapDetails: filteredGapDetails,
      summaryDetails: summaryDetails,
      bannerText: bannerText,
    );
  }
}

void main() {
  group('CalendarDayCoverageCoordinator', () {
    test('analyzes and transforms once, preserving typed details', () {
      final day = DateTime(2026, 8, 11);
      final gap = _gap(5, 6);
      final criticality = _criticality(
        CoverageCriticalityKind.recoverySacrificed,
      );
      final analysis = CoverageDayAnalysis(
        gaps: [gap.label],
        details: [gap],
        criticalityDetails: [criticality],
      );
      var analyzeCalls = 0;
      final resultBuilder = _CountingResultBuilder();
      final coordinator = CalendarDayCoverageCoordinator(
        analyze: (_) {
          analyzeCalls++;
          return analysis;
        },
        resultBuilder: resultBuilder,
      );

      final result = coordinator.build(
        selectedDay: day,
        observedAt: DateTime(2026, 8, 11, 4),
        inputs: _inputs(day),
      );

      expect(analyzeCalls, 1);
      expect(resultBuilder.calls, 1);
      expect(result.gapDetails, hasLength(1));
      expect(result.gapDetails.single, same(gap));
      expect(result.criticalityDetails, same(analysis.criticalityDetails));
      expect(result.gapCount, 1);
      expect(result.criticalDecisionCount, 1);
      expect(result.ok, isFalse);
    });

    test('zero gaps remains coverage OK with separate criticality', () {
      final day = DateTime(2026, 8, 11);
      final criticality = _criticality(
        CoverageCriticalityKind.recoveryProtected,
      );
      final coordinator = CalendarDayCoverageCoordinator(
        analyze: (_) => CoverageDayAnalysis(
          gaps: const [],
          details: const [],
          criticalityDetails: [criticality],
        ),
      );

      final result = coordinator.build(
        selectedDay: day,
        observedAt: DateTime(2026, 8, 11, 4),
        inputs: _inputs(day),
      );

      expect(result.ok, isTrue);
      expect(result.bannerText, 'Copertura OK');
      expect(result.gapCount, 0);
      expect(result.protectedRecoveryCount, 1);
    });
  });

  group('AliceHomeRiskViewModelBuilder', () {
    const builder = AliceHomeRiskViewModelBuilder();
    final selectedDay = DateTime(2026, 8, 11);

    test('today hides completed gaps and shows current and future gaps', () {
      final completed = _gap(5, 6);
      final current = _gap(9, 11);
      final future = _gap(14, 15);
      final model = builder.build(
        gapDetails: [completed, current, future],
        selectedDay: selectedDay,
        observedAt: DateTime(2026, 8, 11, 10),
      );

      expect(model.gapDetails, [same(current), same(future)]);
      expect(model.hasRisk, isTrue);
    });

    test('past and future days preserve every real gap', () {
      final gap = _gap(5, 6);

      final past = builder.build(
        gapDetails: [gap],
        selectedDay: DateTime(2026, 8, 10),
        observedAt: DateTime(2026, 8, 11, 23),
      );
      final future = builder.build(
        gapDetails: [gap],
        selectedDay: DateTime(2026, 8, 12),
        observedAt: DateTime(2026, 8, 11, 23),
      );

      expect(past.gapDetails.single, same(gap));
      expect(future.gapDetails.single, same(gap));
    });

    test('zero gaps and criticalities alone never create Alice risk', () {
      final noGaps = builder.build(
        gapDetails: const [],
        selectedDay: selectedDay,
        observedAt: DateTime(2026, 8, 11, 10),
      );

      expect(noGaps.hasRisk, isFalse);
      for (final kind in CoverageCriticalityKind.values) {
        final criticality = _criticality(kind);
        expect(criticality.kind, kind);
        expect(noGaps.hasRisk, isFalse);
      }
    });

    test('one gap plus a criticality still produces one risk', () {
      final gap = _gap(9, 11);
      final criticality = _criticality(
        CoverageCriticalityKind.recoverySacrificed,
      );
      final model = builder.build(
        gapDetails: [gap],
        selectedDay: selectedDay,
        observedAt: DateTime(2026, 8, 11, 10),
      );

      expect(model.gapDetails, [same(gap)]);
      expect(criticality.kind, CoverageCriticalityKind.recoverySacrificed);
    });
  });
}
