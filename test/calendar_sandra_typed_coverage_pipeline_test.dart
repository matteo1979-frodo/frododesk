import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/adult_logistics_availability_resolver.dart';
import 'package:frododesk/logic/alice_event_store.dart';
import 'package:frododesk/logic/calendar/builders/alice_logistic_provider_availability_resolver.dart';
import 'package:frododesk/logic/calendar/builders/alice_summer_camp_logistics_coordinator.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_coverage_coordinator.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_coverage_input_resolver.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_status_builder.dart';
import 'package:frododesk/logic/calendar/builders/coverage_gap_companion_resolver.dart';
import 'package:frododesk/logic/calendar/models/alice_summer_camp_logistics.dart';
import 'package:frododesk/logic/calendar/models/calendar_day_status.dart';
import 'package:frododesk/logic/calendar/models/coverage_result_step_a.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/models/coverage_criticality_detail.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _day = DateTime(2026, 8, 11);

class _PipelineRun {
  final CoreStore store;
  final CalendarDayCoverageInputs inputs;
  final CalendarDayCoverageRequest request;
  final CoverageResultStepA result;
  final int analyzeCalls;

  const _PipelineRun({
    required this.store,
    required this.inputs,
    required this.request,
    required this.result,
    required this.analyzeCalls,
  });
}

Future<_PipelineRun> _runPipeline({
  required bool globalSandra,
  bool? morning,
  bool? lunch,
  bool? evening,
  bool addLunchAndEveningGaps = false,
}) async {
  final store = CoreStore(initialDate: _day);
  store.settingsStore.setSandraDisponibile(globalSandra);
  if (morning != null) {
    store.daySettingsStore.setSandraMattinaForDay(_day, morning);
  }
  if (lunch != null) {
    store.daySettingsStore.setSandraPranzoForDay(_day, lunch);
  }
  if (evening != null) {
    store.daySettingsStore.setSandraSeraForDay(_day, evening);
  }
  store.aliceEventStore.addEvent(
    AliceEventPeriod(start: _day, end: _day, type: AliceEventType.vacation),
  );

  if (addLunchAndEveningGaps) {
    void addBusy({
      required String id,
      required String person,
      required TimeOfDay start,
      required TimeOfDay end,
    }) {
      store.realEventStore.addEvent(
        RealEvent(
          id: id,
          startDate: _day,
          endDate: _day,
          title: 'Impegno test',
          personKey: person,
          startTime: start,
          endTime: end,
        ),
      );
    }

    addBusy(
      id: 'chiara-lunch',
      person: 'chiara',
      start: const TimeOfDay(hour: 13, minute: 0),
      end: const TimeOfDay(hour: 14, minute: 30),
    );
    for (final person in const ['matteo', 'chiara']) {
      addBusy(
        id: '$person-evening',
        person: person,
        start: const TimeOfDay(hour: 21, minute: 0),
        end: const TimeOfDay(hour: 22, minute: 35),
      );
    }
  }

  final inputs = CalendarDayCoverageInputResolver(
    coreStore: store,
  ).resolve(selectedDay: _day, overrides: DayOverrides.empty(_day));
  late CalendarDayCoverageRequest capturedRequest;
  var analyzeCalls = 0;
  final coordinator = CalendarDayCoverageCoordinator(
    analyze: (request) {
      capturedRequest = request;
      analyzeCalls++;
      return store.coverageEngine.analyzeDay(
        day: request.day,
        uscita13: request.uscita13,
        sandraMorningAvailable: request.sandraMorningAvailable,
        sandraLunchAvailable: request.sandraLunchAvailable,
        sandraEveningAvailable: request.sandraEveningAvailable,
        overrides: request.overrides,
        ferieStore: request.ferieStore,
        schoolInCover: request.schoolInCover,
        schoolOutCover: request.schoolOutCover,
        schoolOutStart: request.schoolOutStart,
        schoolOutEnd: request.schoolOutEnd,
        lunchCover: request.lunchCover,
        uscitaAnticipataAt: request.uscitaAnticipataAt,
      );
    },
  );
  final result = coordinator.build(
    selectedDay: _day,
    observedAt: _day.subtract(const Duration(days: 1)),
    inputs: inputs,
  );
  return _PipelineRun(
    store: store,
    inputs: inputs,
    request: capturedRequest,
    result: result,
    analyzeCalls: analyzeCalls,
  );
}

bool _hasGap(CoverageResultStepA result, TimeOfDay start, TimeOfDay end) =>
    result.gapDetails.any(
      (detail) => detail.start == start && detail.end == end,
    );

List<String> _criticalitySignature(
  List<CoverageCriticalityDetail> details,
) => details
    .map(
      (detail) =>
          '${detail.kind.name}|${detail.personId}|${detail.start.toIso8601String()}|'
          '${detail.end.toIso8601String()}|${detail.source.name}|${detail.coverageProviderId}',
    )
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('typed Sandra coverage pipeline', () {
    const morningStart = TimeOfDay(hour: 5, minute: 0);
    const morningEnd = TimeOfDay(hour: 6, minute: 35);
    const lunchStart = TimeOfDay(hour: 13, minute: 0);
    const lunchEnd = TimeOfDay(hour: 14, minute: 30);
    const eveningStart = TimeOfDay(hour: 21, minute: 0);
    const eveningEnd = TimeOfDay(hour: 22, minute: 35);

    Future<_PipelineRun> scenario({
      required bool global,
      bool? morning,
      bool? lunch,
      bool? evening,
    }) => _runPipeline(
      globalSandra: global,
      morning: morning,
      lunch: lunch,
      evening: evening,
      addLunchAndEveningGaps: true,
    );

    test(
      'none, one band, and all bands remain independent end to end',
      () async {
        final none = await scenario(global: true);
        final onlyMorning = await scenario(global: true, morning: true);
        final onlyLunch = await scenario(global: true, lunch: true);
        final onlyEvening = await scenario(global: true, evening: true);
        final all = await scenario(
          global: true,
          morning: true,
          lunch: true,
          evening: true,
        );

        expect(
          [
            none.request.sandraMorningAvailable,
            none.request.sandraLunchAvailable,
            none.request.sandraEveningAvailable,
          ],
          [false, false, false],
        );
        expect(_hasGap(none.result, morningStart, morningEnd), isTrue);
        expect(_hasGap(none.result, lunchStart, lunchEnd), isTrue);
        expect(_hasGap(none.result, eveningStart, eveningEnd), isTrue);

        expect(
          [
            onlyMorning.request.sandraMorningAvailable,
            onlyMorning.request.sandraLunchAvailable,
            onlyMorning.request.sandraEveningAvailable,
          ],
          [true, false, false],
        );
        expect(_hasGap(onlyMorning.result, morningStart, morningEnd), isFalse);
        expect(_hasGap(onlyMorning.result, lunchStart, lunchEnd), isTrue);
        expect(_hasGap(onlyMorning.result, eveningStart, eveningEnd), isTrue);

        expect(
          [
            onlyLunch.request.sandraMorningAvailable,
            onlyLunch.request.sandraLunchAvailable,
            onlyLunch.request.sandraEveningAvailable,
          ],
          [false, true, false],
        );
        expect(_hasGap(onlyLunch.result, morningStart, morningEnd), isTrue);
        expect(_hasGap(onlyLunch.result, lunchStart, lunchEnd), isFalse);
        expect(_hasGap(onlyLunch.result, eveningStart, eveningEnd), isTrue);

        expect(
          [
            onlyEvening.request.sandraMorningAvailable,
            onlyEvening.request.sandraLunchAvailable,
            onlyEvening.request.sandraEveningAvailable,
          ],
          [false, false, true],
        );
        expect(_hasGap(onlyEvening.result, morningStart, morningEnd), isTrue);
        expect(_hasGap(onlyEvening.result, lunchStart, lunchEnd), isTrue);
        expect(_hasGap(onlyEvening.result, eveningStart, eveningEnd), isFalse);

        expect(
          [
            all.request.sandraMorningAvailable,
            all.request.sandraLunchAvailable,
            all.request.sandraEveningAvailable,
          ],
          [true, true, true],
        );
        expect(_hasGap(all.result, morningStart, morningEnd), isFalse);
        expect(_hasGap(all.result, lunchStart, lunchEnd), isFalse);
        expect(_hasGap(all.result, eveningStart, eveningEnd), isFalse);
        expect(
          [
            none,
            onlyMorning,
            onlyLunch,
            onlyEvening,
            all,
          ].map((run) => run.analyzeCalls),
          everyElement(1),
        );
      },
    );

    test(
      'global disable and null daily values never become available',
      () async {
        final globallyDisabled = await scenario(global: false, morning: true);
        final dailyNull = await scenario(global: true);

        for (final run in [globallyDisabled, dailyNull]) {
          expect(
            [
              run.request.sandraMorningAvailable,
              run.request.sandraLunchAvailable,
              run.request.sandraEveningAvailable,
            ],
            [false, false, false],
          );
          expect(_hasGap(run.result, morningStart, morningEnd), isTrue);
          expect(_hasGap(run.result, lunchStart, lunchEnd), isTrue);
          expect(_hasGap(run.result, eveningStart, eveningEnd), isTrue);
        }
      },
    );

    test(
      'real August 11 gap toggles only with its resolved morning band',
      () async {
        final withoutSandra = await _runPipeline(globalSandra: true);
        final withMorning = await _runPipeline(
          globalSandra: true,
          morning: true,
        );
        final switchedOff = await _runPipeline(
          globalSandra: true,
          morning: false,
        );

        expect(_hasGap(withoutSandra.result, morningStart, morningEnd), isTrue);
        expect(_hasGap(withMorning.result, morningStart, morningEnd), isFalse);
        expect(_hasGap(switchedOff.result, morningStart, morningEnd), isTrue);
        expect(withoutSandra.result.gapCount, 1);
        expect(withMorning.result.gapCount, 0);
        expect(switchedOff.result.gapCount, 1);

        const statusBuilder = CalendarDayStatusBuilder();
        expect(
          statusBuilder.build(
            gapDetails: withoutSandra.result.gapDetails,
            criticalityDetails: withoutSandra.result.criticalityDetails,
            hasLogisticGaps: false,
          ),
          CalendarDayStatus.problem,
        );
        expect(
          statusBuilder.build(
            gapDetails: withMorning.result.gapDetails,
            criticalityDetails: withMorning.result.criticalityDetails,
            hasLogisticGaps: false,
          ),
          CalendarDayStatus.attention,
        );
        expect(
          withMorning.result.criticalDecisionCount,
          withoutSandra.result.criticalDecisionCount,
        );
        expect(
          withMorning.result.protectedRecoveryCount,
          withoutSandra.result.protectedRecoveryCount,
        );
        expect(
          _criticalitySignature(withMorning.result.criticalityDetails),
          _criticalitySignature(withoutSandra.result.criticalityDetails),
        );
      },
    );

    test(
      'same typed result feeds coverage, gap companion, and summer camp',
      () async {
        final run = await _runPipeline(globalSandra: true, morning: true);
        final availability = run.inputs.logisticsAvailability;
        expect(run.request.sandraMorningAvailable, isTrue);

        final companion = const CoverageGapCompanionResolver().resolve(
          day: _day,
          gap: CoverageGapDetail(
            label: 'Alice a casa',
            lines: const [],
            start: morningStart,
            end: morningEnd,
          ),
          isMatteoBusy: (_, _) => true,
          isChiaraBusy: (_, _) => true,
          availability: availability,
        );
        expect(
          companion.firstOf(CoverageGapCompanionKind.sandra)?.providerId,
          'sandra',
        );

        final summerCamp =
            AliceSummerCampLogisticsCoordinator(
              daySettingsStore: run.store.daySettingsStore,
              availabilityResolver: AliceLogisticProviderAvailabilityResolver(
                adultResolver: AdultLogisticsAvailabilityResolver(
                  turnEngine: run.store.turnEngine,
                  diseasePeriodStore: run.store.diseasePeriodStore,
                  realEventStore: run.store.realEventStore,
                ),
                logisticsAvailability: availability,
              ),
            ).resolveDay(
              day: _day,
              summerCampOperational: true,
              effectiveStart: DateTime(2026, 8, 11, 5, 20),
              effectiveEnd: DateTime(2026, 8, 11, 6, 15),
              overrides: DayOverrides.empty(_day),
            );
        expect(
          summerCamp.dropOff.availableProviders,
          contains(AliceLogisticProviderRef.sandra),
        );
        expect(
          summerCamp.pickUp.availableProviders,
          contains(AliceLogisticProviderRef.sandra),
        );
      },
    );
  });

  test('calendar production path has no aggregate or engine fallback', () {
    final screen = File(
      'lib/screens/calendario_screen_stepa.dart',
    ).readAsStringSync();
    final pipeline = File(
      'lib/logic/calendar/builders/calendar_day_coverage_pipeline.dart',
    ).readAsStringSync();
    final engine = File('lib/logic/coverage_engine.dart').readAsStringSync();
    final buildCoverage = screen.substring(
      screen.indexOf('CoverageResultStepA _buildDayCoverage'),
      screen.indexOf(
        'List<CoverageCriticalityViewModel> _criticalityViewModels',
      ),
    );

    expect(buildCoverage, isNot(contains('sandraAvailable:')));
    expect(
      RegExp(
        r'sandra\w+Available\s*\|\|\s*sandra\w+Available',
      ).hasMatch(buildCoverage),
      isFalse,
    );
    expect(buildCoverage, contains('CalendarDayCoveragePipeline'));
    expect(buildCoverage, isNot(contains('.analyzeDay(')));
    expect(RegExp(r'\.analyzeDay\(').allMatches(pipeline), hasLength(1));
    expect(pipeline, contains('sandraMorningAvailable:'));
    expect(pipeline, contains('sandraLunchAvailable:'));
    expect(pipeline, contains('sandraEveningAvailable:'));
    expect(engine, isNot(contains('.effectiveSandraMattina(')));
    expect(engine, isNot(contains('.effectiveSandraPranzo(')));
    expect(engine, isNot(contains('.effectiveSandraSera(')));
    expect(engine, isNot(contains('fallbackGlobal:')));
  });
}
