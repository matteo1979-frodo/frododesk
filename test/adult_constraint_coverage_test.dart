import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/alice_companion_store.dart';
import 'package:frododesk/logic/alice_event_store.dart';
import 'package:frododesk/logic/alice_presence_engine.dart';
import 'package:frododesk/logic/adult_logistics_availability_resolver.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_status_builder.dart';
import 'package:frododesk/logic/calendar/models/calendar_day_status.dart';
import 'package:frododesk/logic/alice_special_event_store.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/disease_period_store.dart';
import 'package:frododesk/logic/ferie_period_store.dart';
import 'package:frododesk/logic/real_event_store.dart';
import 'package:frododesk/logic/school_store.dart';
import 'package:frododesk/logic/summer_camp_schedule_store.dart';
import 'package:frododesk/logic/summer_camp_special_event_store.dart';
import 'package:frododesk/logic/support_network_store.dart';
import 'package:frododesk/logic/turn_engine.dart';
import 'package:frododesk/logic/turn_override_store.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/disease_period.dart';
import 'package:frododesk/models/adult_constraint_interval.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:frododesk/models/school_model.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:frododesk/models/turn_override.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final day = DateTime(2026, 8, 11);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AliceEventStore homeAllDayStore() {
    return AliceEventStore()..addEvent(
      AliceEventPeriod(start: day, end: day, type: AliceEventType.vacation),
    );
  }

  CoverageEngine canonicalCoverage({
    RealEventStore? realEvents,
    SupportNetworkStore? supportNetwork,
    DaySettingsStore? daySettings,
    TimeOfDay? sandraMorningStart,
    TimeOfDay? sandraMorningEnd,
    TimeOfDay? sandraLunchStart,
    TimeOfDay? sandraLunchEnd,
  }) {
    return CoverageEngine(
      aliceCompanionStore: AliceCompanionStore(),
      aliceEventStore: homeAllDayStore(),
      realEventStore: realEvents,
      supportNetworkStore: supportNetwork,
      daySettingsStore: daySettings,
      sandraCambioMattinaStart: sandraMorningStart,
      sandraCambioMattinaEnd: sandraMorningEnd,
      sandraPranzoStart: sandraLunchStart,
      sandraPranzoEnd: sandraLunchEnd,
    );
  }

  CoverageDayAnalysis analyzeCanonical(
    CoverageEngine coverage, {
    bool sandraMorning = false,
    bool sandraLunch = false,
  }) {
    return coverage.analyzeDayV2(
      day: day,
      uscita13: false,
      sandraMattinaOn: sandraMorning,
      sandraPranzoOn: sandraLunch,
      sandraSeraOn: false,
      schoolStart: const TimeOfDay(hour: 8, minute: 0),
      overrides: DayOverrides.empty(day),
    );
  }

  test('Chiara notte separa lavoro, ritorno e recupero sacrificabile', () {
    final constraints = TurnEngine().constraintsForPersonDay(
      person: TurnPerson.chiara,
      day: day,
    );

    final work = constraints.singleWhere(
      (c) => c.kind == AdultConstraintKind.work && c.end.day == day.day,
    );
    final travel = constraints.singleWhere(
      (c) =>
          c.kind == AdultConstraintKind.returnTravel && c.start.day == day.day,
    );
    final recovery = constraints.singleWhere(
      (c) => c.kind == AdultConstraintKind.recovery,
    );

    expect(work.end, DateTime(2026, 8, 11, 6));
    expect(travel.start, DateTime(2026, 8, 11, 6));
    expect(travel.end, DateTime(2026, 8, 11, 6, 35));
    expect(recovery.start, DateTime(2026, 8, 11, 6, 35));
    expect(recovery.end, DateTime(2026, 8, 12));
    expect(recovery.canBeSacrificedForCare, isTrue);
  });

  test('Matteo mattina separa andata, lavoro e ritorno', () {
    final constraints = TurnEngine().constraintsForPersonDay(
      person: TurnPerson.matteo,
      day: day,
    );

    expect(
      constraints.any(
        (c) =>
            c.kind == AdultConstraintKind.outboundTravel &&
            c.start == DateTime(2026, 8, 11, 5) &&
            c.end == DateTime(2026, 8, 11, 6),
      ),
      isTrue,
    );
    expect(
      constraints.any(
        (c) =>
            c.kind == AdultConstraintKind.work &&
            c.start == DateTime(2026, 8, 11, 6) &&
            c.end == DateTime(2026, 8, 11, 14),
      ),
      isTrue,
    );
    expect(
      constraints.any(
        (c) =>
            c.kind == AdultConstraintKind.returnTravel &&
            c.start == DateTime(2026, 8, 11, 14) &&
            c.end == DateTime(2026, 8, 11, 14, 30),
      ),
      isTrue,
    );
    expect(
      constraints
          .where((c) => c.kind != AdultConstraintKind.recovery)
          .every((c) => !c.canBeSacrificedForCare),
      isTrue,
    );
  });

  test('policy viaggio usa personId, turno e direzione', () {
    final configured = TravelDurationPolicy(
      personShiftDirection: {
        TravelDurationPolicy.keyFor(
          personId: 'adulto-2',
          shiftType: TurnType.notte,
          direction: TravelDirection.returnTrip,
        ): const Duration(
          minutes: 35,
        ),
      },
    );

    expect(
      configured.travelDurationFor(
        personId: 'adulto-2',
        shiftType: TurnType.notte,
        direction: TravelDirection.returnTrip,
      ),
      const Duration(minutes: 35),
    );
    expect(
      configured.travelDurationFor(
        personId: 'chiara',
        shiftType: TurnType.notte,
        direction: TravelDirection.returnTrip,
      ),
      const Duration(minutes: 30),
    );
  });

  test('solo recovery e copribile, lavoro e viaggio no', () {
    final coverage = CoverageEngine(aliceCompanionStore: AliceCompanionStore());

    expect(
      coverage.isChiaraBusyBetween(
        DateTime(2026, 8, 11, 6, 35),
        DateTime(2026, 8, 11, 14, 30),
        isHomePresenceWindow: true,
      ),
      isFalse,
    );
    expect(
      coverage.isChiaraBusyBetween(
        DateTime(2026, 8, 11, 6),
        DateTime(2026, 8, 11, 6, 35),
        isHomePresenceWindow: true,
      ),
      isTrue,
    );
    expect(
      coverage.isMatteoBusyBetween(
        DateTime(2026, 8, 11, 7),
        DateTime(2026, 8, 11, 8),
        isHomePresenceWindow: true,
      ),
      isTrue,
    );
  });

  test('11 agosto ha solo il gap reale 05:00-06:35', () {
    final analysis = analyzeCanonical(canonicalCoverage());

    expect(analysis.gaps, hasLength(1));
    expect(analysis.details.single.start, const TimeOfDay(hour: 5, minute: 0));
    expect(analysis.details.single.end, const TimeOfDay(hour: 6, minute: 35));
    expect(
      analysis.details.any(
        (detail) =>
            detail.start == const TimeOfDay(hour: 13, minute: 0) &&
            detail.end == const TimeOfDay(hour: 14, minute: 30),
      ),
      isFalse,
    );
    expect(
      const CalendarDayStatusBuilder().build(
        gapDetails: analysis.gapDetails,
        criticalityDetails: analysis.criticalityDetails,
        hasLogisticGaps: false,
      ),
      CalendarDayStatus.problem,
    );
  });

  test('spiegazione del gap usa nomi e vincoli in italiano', () {
    final analysis = analyzeCanonical(canonicalCoverage());
    final explanation = analysis.details.single.lines.join('\n');

    expect(explanation, contains('Matteo: viaggio di andata'));
    expect(explanation, contains('Matteo: lavoro'));
    expect(explanation, contains('Chiara: lavoro'));
    expect(explanation, contains('Chiara: viaggio di rientro'));
    expect(explanation, isNot(contains('outboundTravel')));
    expect(explanation, isNot(contains('returnTravel')));
    expect(explanation, isNot(contains('matteo:')));
    expect(explanation, isNot(contains('chiara:')));
  });

  test('timeline Alice a casa copre davvero 00:00-24:00', () {
    final presence = AlicePresenceEngine(
      aliceEventStore: homeAllDayStore(),
      aliceSpecialEventStore: AliceSpecialEventStore(),
      realEventStore: RealEventStore(),
      schoolStore: SchoolStore(),
      summerCampScheduleStore: SummerCampScheduleStore(),
      summerCampSpecialEventStore: SummerCampSpecialEventStore(),
      aliceCompanionStore: AliceCompanionStore(),
      supportNetworkStore: SupportNetworkStore(),
      daySettingsStore: DaySettingsStore(),
    );

    final timeline = presence.coverageTimelineForDay(day);

    expect(timeline.isSupported, isTrue);
    expect(timeline.windows, hasLength(1));
    expect(timeline.windows.single.start, DateTime(2026, 8, 11));
    expect(timeline.windows.single.end, DateTime(2026, 8, 12));
    expect(timeline.windows.single.requiresAdult, isTrue);
  });

  test('00:00-05:00 è analizzato: se entrambi occupati diventa gap', () {
    final events = RealEventStore();
    for (final personId in const ['matteo', 'chiara']) {
      events.addEvent(
        RealEvent(
          id: 'busy-$personId',
          startDate: day,
          endDate: day,
          title: 'Impegno',
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endTime: const TimeOfDay(hour: 5, minute: 0),
          personKey: personId,
        ),
      );
    }

    final analysis = analyzeCanonical(canonicalCoverage(realEvents: events));

    expect(analysis.details.single.start, const TimeOfDay(hour: 0, minute: 0));
    expect(analysis.details.single.end, const TimeOfDay(hour: 6, minute: 35));
  });

  test('orari Sandra mattina 07:00-08:00 non cambiano il gap reale', () {
    final analysis = analyzeCanonical(
      canonicalCoverage(
        sandraMorningStart: const TimeOfDay(hour: 7, minute: 0),
        sandraMorningEnd: const TimeOfDay(hour: 8, minute: 0),
      ),
    );

    expect(analysis.details.single.start, const TimeOfDay(hour: 5, minute: 0));
    expect(analysis.details.single.end, const TimeOfDay(hour: 6, minute: 35));
  });

  test('orari Sandra mattina 04:00-07:00 non cambiano il gap reale', () {
    final analysis = analyzeCanonical(
      canonicalCoverage(
        sandraMorningStart: const TimeOfDay(hour: 4, minute: 0),
        sandraMorningEnd: const TimeOfDay(hour: 7, minute: 0),
      ),
    );

    expect(analysis.details.single.start, const TimeOfDay(hour: 5, minute: 0));
    expect(analysis.details.single.end, const TimeOfDay(hour: 6, minute: 35));
  });

  test('orari Sandra pranzo non cambiano il gap reale se disabilitata', () {
    final analysis = analyzeCanonical(
      canonicalCoverage(
        sandraLunchStart: const TimeOfDay(hour: 10, minute: 0),
        sandraLunchEnd: const TimeOfDay(hour: 16, minute: 0),
      ),
    );

    expect(analysis.details.single.start, const TimeOfDay(hour: 5, minute: 0));
    expect(analysis.details.single.end, const TimeOfDay(hour: 6, minute: 35));
  });

  test('supporto 05:00-06:35 elimina il gap reale', () async {
    final support = SupportNetworkStore()
      ..addPerson(
        const SupportPerson(
          id: 'support-1',
          name: 'Supporto',
          enabled: true,
          start: TimeOfDay(hour: 5, minute: 0),
          end: TimeOfDay(hour: 6, minute: 35),
        ),
      );
    final settings = DaySettingsStore();
    await settings.setSupportPersonEnabledForDay(day, 'support-1', true);

    final analysis = analyzeCanonical(
      canonicalCoverage(supportNetwork: support, daySettings: settings),
    );

    expect(analysis.gaps, isEmpty);
  });

  test('recovery sovrapposto a nuovo work o travel resta bloccato', () {
    final overrides = TurnOverrideStore()
      ..setDailyOverride(
        person: TurnPersonId.chiara,
        day: day,
        newShift: TurnOverrideShift.mattina,
      );
    final coverage = CoverageEngine(
      aliceCompanionStore: AliceCompanionStore(),
      turnEngine: TurnEngine(turnOverrideStore: overrides),
    );

    expect(
      coverage.isChiaraBusyBetween(
        DateTime(2026, 8, 11, 7),
        DateTime(2026, 8, 11, 8),
        isHomePresenceWindow: true,
      ),
      isTrue,
    );
    expect(
      coverage.isChiaraBusyBetween(
        DateTime(2026, 8, 11, 14),
        DateTime(2026, 8, 11, 14, 30),
        isHomePresenceWindow: true,
      ),
      isTrue,
    );
  });

  test('recovery esiste solo dopo notte', () {
    for (final shift in const [
      TurnOverrideShift.mattina,
      TurnOverrideShift.pomeriggio,
    ]) {
      final overrides = TurnOverrideStore()
        ..setDailyOverride(
          person: TurnPersonId.matteo,
          day: day.subtract(const Duration(days: 1)),
          newShift: TurnOverrideShift.off,
        )
        ..setDailyOverride(
          person: TurnPersonId.matteo,
          day: day,
          newShift: shift,
        );
      final constraints = TurnEngine(
        turnOverrideStore: overrides,
      ).constraintsForPersonDay(person: TurnPerson.matteo, day: day);

      expect(
        constraints.any((c) => c.kind == AdultConstraintKind.recovery),
        isFalse,
      );
    }
  });

  test('policy viaggio copre fallback e rifiuta durate negative', () {
    final policy = TravelDurationPolicy(
      personShiftDirection: const {},
      shiftDirectionDefaults: {
        TravelDurationPolicy.shiftKeyFor(
          shiftType: TurnType.mattina,
          direction: TravelDirection.outbound,
        ): const Duration(
          minutes: 42,
        ),
      },
      generalDefault: const Duration(minutes: 17),
    );

    expect(
      policy.travelDurationFor(
        personId: 'adulto',
        shiftType: TurnType.mattina,
        direction: TravelDirection.outbound,
      ),
      const Duration(minutes: 42),
    );
    expect(
      policy.travelDurationFor(
        personId: 'adulto',
        shiftType: TurnType.notte,
        direction: TravelDirection.returnTrip,
      ),
      const Duration(minutes: 17),
    );
    expect(
      () => TravelDurationPolicy(generalDefault: const Duration(minutes: -1)),
      throwsArgumentError,
    );
  });

  test('Duration.zero non crea viaggi vuoti', () {
    final policy = TravelDurationPolicy(
      personShiftDirection: const {},
      shiftDirectionDefaults: const {},
      generalDefault: Duration.zero,
    );
    final constraints = TurnEngine(
      travelDurationPolicy: policy,
    ).constraintsForPersonDay(person: TurnPerson.matteo, day: day);

    expect(
      constraints.any(
        (c) =>
            c.kind == AdultConstraintKind.outboundTravel ||
            c.kind == AdultConstraintKind.returnTravel,
      ),
      isFalse,
    );
  });

  test('constraint sono ordinati e privi di duplicati identici', () {
    final constraints = TurnEngine().constraintsForPersonDay(
      person: TurnPerson.chiara,
      day: day,
    );

    for (var index = 1; index < constraints.length; index++) {
      expect(
        constraints[index].start.isBefore(constraints[index - 1].start),
        isFalse,
      );
    }
    final identities = constraints
        .map((c) => '${c.kind}|${c.start}|${c.end}')
        .toSet();
    expect(identities, hasLength(constraints.length));
  });

  test('giorno scuola resta sul percorso legacy', () {
    final school = SchoolStore()
      ..addPeriod(
        SchoolPeriod(
          id: 'school',
          name: 'Scuola',
          startDate: day,
          endDate: day,
          weekConfig: SchoolWeekConfig.empty().copyWith(
            tuesday: const SchoolDayConfig(
              enabled: true,
              entryMinutes: 8 * 60,
              exitRealMinutes: 16 * 60,
            ),
          ),
        ),
      );
    final presence = AlicePresenceEngine(
      aliceEventStore: AliceEventStore(),
      aliceSpecialEventStore: AliceSpecialEventStore(),
      realEventStore: RealEventStore(),
      schoolStore: school,
      summerCampScheduleStore: SummerCampScheduleStore(),
      summerCampSpecialEventStore: SummerCampSpecialEventStore(),
      aliceCompanionStore: AliceCompanionStore(),
      supportNetworkStore: SupportNetworkStore(),
      daySettingsStore: DaySettingsStore(),
    );

    expect(presence.coverageTimelineForDay(day).isSupported, isFalse);

    final analysis =
        CoverageEngine(
          aliceCompanionStore: AliceCompanionStore(),
          schoolStore: school,
        ).analyzeDayV2(
          day: day,
          uscita13: false,
          sandraMattinaOn: false,
          sandraPranzoOn: false,
          sandraSeraOn: false,
          schoolStart: const TimeOfDay(hour: 8, minute: 0),
          overrides: DayOverrides.empty(day),
        );

    expect(
      analysis.gaps.any(
        (gap) => gap.toLowerCase().startsWith('alice ingresso'),
      ),
      isTrue,
    );
  });

  group('equivalenza resolver adulti e CoverageEngine', () {
    Future<void> expectMatteoEquivalent({
      required DateTime start,
      required DateTime end,
      DaySettingsStore? settings,
      DiseasePeriodStore? diseases,
      RealEventStore? events,
      DayOverrides? overrides,
      FeriePeriodStore? holidays,
      bool home = false,
      bool? expectedAvailable,
    }) async {
      final daySettings = settings ?? DaySettingsStore();
      final diseaseStore = diseases ?? DiseasePeriodStore();
      final eventStore = events ?? RealEventStore();
      final effectiveOverrides = overrides ?? DayOverrides.empty(day);
      final turnEngine = TurnEngine();
      final resolver = AdultLogisticsAvailabilityResolver(
        turnEngine: turnEngine,
        diseasePeriodStore: diseaseStore,
        realEventStore: eventStore,
      );
      final engine = CoverageEngine(
        aliceCompanionStore: AliceCompanionStore(),
        turnEngine: turnEngine,
        daySettingsStore: daySettings,
        diseasePeriodStore: diseaseStore,
        realEventStore: eventStore,
      );

      final direct = resolver.canCoverRange(
        personKey: 'matteo',
        person: TurnPerson.matteo,
        day: day,
        start: start,
        end: end,
        isHomePresenceWindow: home,
        overrides: effectiveOverrides,
        ferieStore: holidays,
        forceAvailableDueToLunchCover:
            daySettings.lunchCoverForDay(day) == SchoolCoverChoice.matteo,
      );
      final throughCoverage = !engine.isMatteoBusyBetween(
        start,
        end,
        overrides: effectiveOverrides,
        ferieStore: holidays,
        isHomePresenceWindow: home,
      );
      expect(throughCoverage, direct);
      if (expectedAvailable != null) {
        expect(direct, expectedAvailable);
      }
    }

    test('lavoro, outbound, return, disponibile e indisponibile', () async {
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 7),
        end: DateTime(2026, 8, 11, 8),
        expectedAvailable: false,
      );
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 5, 15),
        end: DateTime(2026, 8, 11, 5, 45),
        expectedAvailable: false,
      );
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 14),
        end: DateTime(2026, 8, 11, 14, 30),
        expectedAvailable: false,
      );
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 15),
        end: DateTime(2026, 8, 11, 16),
        expectedAvailable: true,
      );
    });

    test('evento reale', () async {
      final events = RealEventStore()
        ..addEvent(
          RealEvent(
            id: 'equivalence-event',
            startDate: day,
            endDate: day,
            title: 'Impegno',
            personKey: 'matteo',
            startTime: const TimeOfDay(hour: 15, minute: 0),
            endTime: const TimeOfDay(hour: 16, minute: 0),
          ),
        );
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 15, 15),
        end: DateTime(2026, 8, 11, 15, 45),
        events: events,
        expectedAvailable: false,
      );
    });

    test('ferie e override mantengono le precedenze', () async {
      final holidays = FeriePeriodStore()
        ..add(
          FeriePeriod(person: FeriePerson.matteo, startDay: day, endDay: day),
        );
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 7),
        end: DateTime(2026, 8, 11, 8),
        holidays: holidays,
        expectedAvailable: true,
      );
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 7),
        end: DateTime(2026, 8, 11, 8),
        holidays: holidays,
        overrides: DayOverrides(
          day: day,
          matteo: PersonDayOverride(status: OverrideStatus.normal),
        ),
        expectedAvailable: false,
      );
    });

    test('malattia distingue casa e accompagnamento esterno', () async {
      final diseases = DiseasePeriodStore();
      await diseases.addPeriod(
        DiseasePeriod(
          personId: 'matteo',
          type: DiseaseType.bed,
          startDate: day,
          endDate: day,
        ),
      );
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 15),
        end: DateTime(2026, 8, 11, 16),
        diseases: diseases,
        home: true,
        expectedAvailable: true,
      );
      await expectMatteoEquivalent(
        start: DateTime(2026, 8, 11, 15),
        end: DateTime(2026, 8, 11, 16),
        diseases: diseases,
        home: false,
        expectedAvailable: false,
      );
    });

    test(
      'lunchCover conserva il comportamento corrente di azzeramento busy',
      () async {
        final settings = DaySettingsStore()
          ..setLunchCoverForDay(day, SchoolCoverChoice.matteo);
        await expectMatteoEquivalent(
          start: DateTime(2026, 8, 11, 7),
          end: DateTime(2026, 8, 11, 8),
          settings: settings,
          expectedAvailable: true,
        );
        final resolver = AdultLogisticsAvailabilityResolver(
          turnEngine: TurnEngine(),
          diseasePeriodStore: DiseasePeriodStore(),
          realEventStore: RealEventStore(),
        );
        expect(
          resolver.canCoverRange(
            personKey: 'matteo',
            person: TurnPerson.matteo,
            day: day,
            start: DateTime(2026, 8, 11, 7),
            end: DateTime(2026, 8, 11, 8),
            isHomePresenceWindow: false,
            overrides: DayOverrides.empty(day),
            forceAvailableDueToLunchCover: true,
          ),
          isTrue,
        );
      },
    );
  });
}
