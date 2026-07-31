import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/alice_companion_store.dart';
import 'package:frododesk/logic/alice_event_store.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_status_builder.dart';
import 'package:frododesk/logic/calendar/models/calendar_day_status.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/disease_period_store.dart';
import 'package:frododesk/logic/ferie_period_store.dart';
import 'package:frododesk/logic/real_event_store.dart';
import 'package:frododesk/logic/support_network_store.dart';
import 'package:frododesk/logic/turn_engine.dart';
import 'package:frododesk/logic/turn_override_store.dart';
import 'package:frododesk/models/adult_constraint_interval.dart';
import 'package:frododesk/models/coverage_criticality_detail.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/disease_period.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:frododesk/models/turn_override.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final day = DateTime(2026, 8, 11);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AliceEventStore homeAllDay([DateTime? requestedDay]) {
    final targetDay = requestedDay ?? day;
    return AliceEventStore()..addEvent(
      AliceEventPeriod(
        start: targetDay,
        end: targetDay,
        type: AliceEventType.vacation,
      ),
    );
  }

  Future<CoverageDayAnalysis> analyze({
    List<SupportTimeSlot> supportSlots = const [],
    List<SupportPerson> supportPeople = const [],
    Set<String>? enabledSupportIds,
    bool sandraMorning = false,
    TimeOfDay? sandraMorningStart,
    TimeOfDay? sandraMorningEnd,
    TurnEngine? turnEngine,
    DateTime? requestedDay,
    DayOverrides? overrides,
    DiseasePeriodStore? diseasePeriodStore,
    FeriePeriodStore? ferieStore,
    RealEventStore? realEventStore,
  }) async {
    final targetDay = requestedDay ?? day;
    final supportNetwork = SupportNetworkStore();
    final daySettings = DaySettingsStore();
    if (supportSlots.isNotEmpty) {
      supportNetwork.addPerson(
        SupportPerson(
          id: 'support-id',
          name: 'Nome irrilevante per la logica',
          enabled: true,
          start: supportSlots.first.start,
          end: supportSlots.first.end,
          slots: supportSlots,
        ),
      );
      await daySettings.setSupportPersonEnabledForDay(
        targetDay,
        'support-id',
        true,
      );
    }
    for (final person in supportPeople) {
      supportNetwork.addPerson(person);
    }
    for (final personId in enabledSupportIds ?? const <String>{}) {
      await daySettings.setSupportPersonEnabledForDay(
        targetDay,
        personId,
        true,
      );
    }

    return CoverageEngine(
      turnEngine: turnEngine,
      aliceCompanionStore: AliceCompanionStore(),
      aliceEventStore: homeAllDay(targetDay),
      diseasePeriodStore: diseasePeriodStore,
      realEventStore: realEventStore,
      supportNetworkStore: supportNetwork,
      daySettingsStore: daySettings,
      sandraCambioMattinaStart: sandraMorningStart,
      sandraCambioMattinaEnd: sandraMorningEnd,
    ).analyzeDayV2(
      day: targetDay,
      uscita13: false,
      sandraMattinaOn: sandraMorning,
      sandraPranzoOn: false,
      sandraSeraOn: false,
      schoolStart: const TimeOfDay(hour: 8, minute: 0),
      overrides: overrides ?? DayOverrides.empty(targetDay),
      ferieStore: ferieStore,
    );
  }

  CoverageCriticalityDetail criticality(
    CoverageDayAnalysis analysis,
    CoverageCriticalityKind kind,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    return analysis.criticalityDetails.singleWhere(
      (detail) =>
          detail.kind == kind &&
          detail.start == DateTime(2026, 8, 11, startHour, startMinute) &&
          detail.end ==
              (endHour == 24
                  ? DateTime(2026, 8, 12)
                  : DateTime(2026, 8, 11, endHour, endMinute)),
      orElse: () => throw TestFailure(
        'Criticality not found. Actual: ${analysis.criticalityDetails.map((detail) => '${detail.kind.name}|${detail.personId}|'
            '${detail.start}-${detail.end}|${detail.source.name}').join(', ')}',
      ),
    );
  }

  test('scenario canonico separa gap, sacrificed e protected', () async {
    final analysis = await analyze();

    expect(analysis.gapDetails, hasLength(1));
    expect(
      analysis.gapDetails.single.start,
      const TimeOfDay(hour: 5, minute: 0),
    );
    expect(
      analysis.gapDetails.single.end,
      const TimeOfDay(hour: 6, minute: 35),
    );

    final sacrificed = criticality(
      analysis,
      CoverageCriticalityKind.recoverySacrificed,
      6,
      35,
      14,
      30,
    );
    expect(sacrificed.personId, 'chiara');
    expect(sacrificed.source, CoverageSource.parentForced);
    expect(sacrificed.coverageProviderId, 'chiara');

    final protected = criticality(
      analysis,
      CoverageCriticalityKind.recoveryProtected,
      14,
      30,
      21,
      0,
    );
    expect(protected.personId, 'chiara');
    expect(protected.source, CoverageSource.parentNormal);
    expect(protected.coverageProviderId, 'matteo');
  });

  test('Sandra sul gap non cambia il recovery sacrificed', () async {
    final analysis = await analyze(sandraMorning: true);

    expect(analysis.gapDetails, isEmpty);
    criticality(
      analysis,
      CoverageCriticalityKind.recoverySacrificed,
      6,
      35,
      14,
      30,
    );
    expect(
      const CalendarDayStatusBuilder().build(
        gapDetails: analysis.gapDetails,
        criticalityDetails: analysis.criticalityDetails,
        hasLogisticGaps: false,
      ),
      CalendarDayStatus.attention,
    );
  });

  test('supporto completo protegge tutto il recovery richiesto', () async {
    final analysis = await analyze(
      supportSlots: const [
        SupportTimeSlot(
          start: TimeOfDay(hour: 6, minute: 35),
          end: TimeOfDay(hour: 14, minute: 30),
        ),
      ],
    );

    expect(
      analysis.criticalityDetails.where(
        (detail) =>
            detail.kind == CoverageCriticalityKind.recoverySacrificed &&
            detail.start.isBefore(DateTime(2026, 8, 11, 14, 30)) &&
            detail.end.isAfter(DateTime(2026, 8, 11, 6, 35)),
      ),
      isEmpty,
    );
    expect(
      criticality(
        analysis,
        CoverageCriticalityKind.recoveryProtected,
        6,
        35,
        14,
        30,
      ).source,
      CoverageSource.supportNetwork,
    );
    expect(
      criticality(
        analysis,
        CoverageCriticalityKind.recoveryProtected,
        6,
        35,
        14,
        30,
      ).coverageProviderId,
      'support-id',
    );
  });

  test('supporto 07:30-14:30 segmenta sacrificed e protected', () async {
    final analysis = await analyze(
      supportSlots: const [
        SupportTimeSlot(
          start: TimeOfDay(hour: 7, minute: 30),
          end: TimeOfDay(hour: 14, minute: 30),
        ),
      ],
    );

    criticality(
      analysis,
      CoverageCriticalityKind.recoverySacrificed,
      6,
      35,
      7,
      30,
    );
    final protected = criticality(
      analysis,
      CoverageCriticalityKind.recoveryProtected,
      7,
      30,
      14,
      30,
    );
    expect(protected.source, CoverageSource.supportNetwork);
    expect(protected.coverageProviderId, 'support-id');
  });

  test('supporto 10:00-12:00 divide sacrificed in due intervalli', () async {
    final analysis = await analyze(
      supportSlots: const [
        SupportTimeSlot(
          start: TimeOfDay(hour: 10, minute: 0),
          end: TimeOfDay(hour: 12, minute: 0),
        ),
      ],
    );

    criticality(
      analysis,
      CoverageCriticalityKind.recoverySacrificed,
      6,
      35,
      10,
      0,
    );
    final protected = criticality(
      analysis,
      CoverageCriticalityKind.recoveryProtected,
      10,
      0,
      12,
      0,
    );
    expect(protected.source, CoverageSource.supportNetwork);
    expect(protected.coverageProviderId, 'support-id');
    criticality(
      analysis,
      CoverageCriticalityKind.recoverySacrificed,
      12,
      0,
      14,
      30,
    );
  });

  test('adulto normale protegge recovery senza sacrificed', () async {
    final analysis = await analyze();
    final afterMatteoReturns = DateTime(2026, 8, 11, 14, 30);

    expect(
      analysis.criticalityDetails.where(
        (detail) =>
            detail.kind == CoverageCriticalityKind.recoverySacrificed &&
            detail.end.isAfter(afterMatteoReturns),
      ),
      isEmpty,
    );
    expect(
      analysis.criticalityDetails.any(
        (detail) =>
            detail.kind == CoverageCriticalityKind.recoveryProtected &&
            detail.source == CoverageSource.parentNormal &&
            detail.start == afterMatteoReturns,
      ),
      isTrue,
    );
    expect(
      analysis.criticalityDetails
          .singleWhere(
            (detail) =>
                detail.kind == CoverageCriticalityKind.recoveryProtected &&
                detail.start == afterMatteoReturns,
          )
          .coverageProviderId,
      'matteo',
    );
  });

  for (final blockerKind in [
    AdultConstraintKind.work,
    AdultConstraintKind.outboundTravel,
    AdultConstraintKind.returnTravel,
  ]) {
    test('recovery + ${blockerKind.name} non può coprire', () async {
      final analysis = await analyze(
        turnEngine: _OverlappingConstraintTurnEngine(blockerKind),
      );

      expect(
        analysis.criticalityDetails.any(
          (detail) =>
              detail.kind == CoverageCriticalityKind.recoverySacrificed &&
              detail.start.isBefore(DateTime(2026, 8, 11, 8)) &&
              detail.end.isAfter(DateTime(2026, 8, 11, 7)),
        ),
        isFalse,
      );
      expect(
        analysis.gapDetails.any(
          (detail) =>
              detail.start == const TimeOfDay(hour: 7, minute: 0) &&
              detail.end == const TimeOfDay(hour: 8, minute: 0),
        ),
        isTrue,
      );
    });
  }

  test('criticità non entra nei gap e la lista è cronologica', () async {
    final analysis = await analyze(
      supportSlots: const [
        SupportTimeSlot(
          start: TimeOfDay(hour: 10, minute: 0),
          end: TimeOfDay(hour: 12, minute: 0),
        ),
      ],
    );

    expect(analysis.gapDetails, hasLength(1));
    for (var index = 1; index < analysis.criticalityDetails.length; index++) {
      expect(
        analysis.criticalityDetails[index].start.isBefore(
          analysis.criticalityDetails[index - 1].start,
        ),
        isFalse,
      );
    }
  });

  test('merge solo se tipo, persona e sorgente coincidono', () async {
    final analysis = await analyze(
      supportSlots: const [
        SupportTimeSlot(
          start: TimeOfDay(hour: 10, minute: 0),
          end: TimeOfDay(hour: 11, minute: 0),
        ),
        SupportTimeSlot(
          start: TimeOfDay(hour: 11, minute: 0),
          end: TimeOfDay(hour: 12, minute: 0),
        ),
      ],
    );

    final protected = criticality(
      analysis,
      CoverageCriticalityKind.recoveryProtected,
      10,
      0,
      12,
      0,
    );
    expect(protected.coverageProviderId, 'support-id');
    expect(
      analysis.criticalityDetails.any(
        (detail) =>
            detail.source == CoverageSource.supportNetwork &&
            detail.end == DateTime(2026, 8, 12),
      ),
      isFalse,
    );
  });

  test('personId alternativo produce lo stesso comportamento', () async {
    final baseline = await analyze();
    final renamed = await analyze(turnEngine: _RenamedPersonTurnEngine());

    final baselineRanges = baseline.criticalityDetails
        .map((detail) => '${detail.kind}|${detail.start}|${detail.end}')
        .toList();
    final renamedRanges = renamed.criticalityDetails
        .map((detail) => '${detail.kind}|${detail.start}|${detail.end}')
        .toList();

    expect(renamedRanges, baselineRanges);
    expect(
      renamed.criticalityDetails
          .where((detail) => detail.personId == 'adulto-2')
          .length,
      baseline.criticalityDetails
          .where((detail) => detail.personId == 'chiara')
          .length,
    );
  });

  test('due supporti adiacenti restano provider distinti', () async {
    final analysis = await analyze(
      supportPeople: const [
        SupportPerson(
          id: 'support-a',
          name: 'A',
          enabled: true,
          start: TimeOfDay(hour: 10, minute: 0),
          end: TimeOfDay(hour: 11, minute: 0),
        ),
        SupportPerson(
          id: 'support-b',
          name: 'B',
          enabled: true,
          start: TimeOfDay(hour: 11, minute: 0),
          end: TimeOfDay(hour: 12, minute: 0),
        ),
      ],
      enabledSupportIds: const {'support-a', 'support-b'},
    );

    final protected = analysis.criticalityDetails
        .where(
          (detail) =>
              detail.kind == CoverageCriticalityKind.recoveryProtected &&
              detail.source == CoverageSource.supportNetwork &&
              !detail.start.isBefore(DateTime(2026, 8, 11, 10)) &&
              !detail.end.isAfter(DateTime(2026, 8, 11, 12)),
        )
        .toList();

    expect(protected, hasLength(2));
    expect(protected.map((detail) => detail.coverageProviderId).toList(), [
      'support-a',
      'support-b',
    ]);
    expect(protected[0].end, protected[1].start);
  });

  test('Sandra adiacente a SupportPerson non viene unita', () async {
    final analysis = await analyze(
      sandraMorning: true,
      sandraMorningStart: const TimeOfDay(hour: 6, minute: 35),
      sandraMorningEnd: const TimeOfDay(hour: 7, minute: 30),
      supportPeople: const [
        SupportPerson(
          id: 'support-after-sandra',
          name: 'Supporto',
          enabled: true,
          start: TimeOfDay(hour: 7, minute: 30),
          end: TimeOfDay(hour: 8, minute: 30),
        ),
      ],
      enabledSupportIds: const {'support-after-sandra'},
    );

    final sandra = criticality(
      analysis,
      CoverageCriticalityKind.recoveryProtected,
      6,
      35,
      7,
      30,
    );
    final support = criticality(
      analysis,
      CoverageCriticalityKind.recoveryProtected,
      7,
      30,
      8,
      30,
    );
    expect(sandra.coverageProviderId, CoverageProviderIds.sandraLegacy);
    expect(support.coverageProviderId, 'support-after-sandra');
  });

  for (final enabledGlobally in [false, true]) {
    test(
      enabledGlobally
          ? 'supporto non abilitato nel giorno non protegge'
          : 'supporto globalmente disabilitato non protegge',
      () async {
        final analysis = await analyze(
          supportPeople: [
            SupportPerson(
              id: 'inactive-support',
              name: 'Inattivo',
              enabled: enabledGlobally,
              start: const TimeOfDay(hour: 6, minute: 35),
              end: const TimeOfDay(hour: 14, minute: 30),
            ),
          ],
          enabledSupportIds: enabledGlobally
              ? const {}
              : const {'inactive-support'},
        );

        final sacrificed = criticality(
          analysis,
          CoverageCriticalityKind.recoverySacrificed,
          6,
          35,
          14,
          30,
        );
        expect(sacrificed.coverageProviderId, sacrificed.personId);
        expect(
          analysis.criticalityDetails.any(
            (detail) =>
                detail.source == CoverageSource.supportNetwork &&
                detail.coverageProviderId == 'inactive-support',
          ),
          isFalse,
        );
      },
    );
  }

  test('support network prevale sul genitore normale', () async {
    final analysis = await analyze(
      supportPeople: const [
        SupportPerson(
          id: 'support-over-parent',
          name: 'Supporto',
          enabled: true,
          start: TimeOfDay(hour: 14, minute: 30),
          end: TimeOfDay(hour: 15, minute: 30),
        ),
      ],
      enabledSupportIds: const {'support-over-parent'},
    );

    final protected = criticality(
      analysis,
      CoverageCriticalityKind.recoveryProtected,
      14,
      30,
      15,
      30,
    );
    expect(protected.source, CoverageSource.supportNetwork);
    expect(protected.coverageProviderId, 'support-over-parent');
  });

  test('due adulti normali non producono false criticità', () async {
    final analysis = await analyze(turnEngine: _NoConstraintsTurnEngine());

    expect(analysis.gapDetails, isEmpty);
    expect(analysis.criticalityDetails, isEmpty);
  });

  test(
    'due adulti in recovery scelgono un solo provider deterministico',
    () async {
      final analysis = await analyze(turnEngine: _BothRecoveryTurnEngine());

      expect(analysis.gapDetails, isEmpty);
      expect(analysis.criticalityDetails, hasLength(1));
      final sacrificed = analysis.criticalityDetails.single;
      expect(sacrificed.kind, CoverageCriticalityKind.recoverySacrificed);
      expect(sacrificed.personId, 'chiara');
      expect(sacrificed.coverageProviderId, 'chiara');
      expect(sacrificed.source, CoverageSource.parentForced);
    },
  );

  test('ordine completo e assenza di criticità duplicate', () async {
    final analysis = await analyze(
      supportSlots: const [
        SupportTimeSlot(
          start: TimeOfDay(hour: 10, minute: 0),
          end: TimeOfDay(hour: 12, minute: 0),
        ),
      ],
    );

    int compare(CoverageCriticalityDetail a, CoverageCriticalityDetail b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      final byEnd = a.end.compareTo(b.end);
      if (byEnd != 0) return byEnd;
      final byPerson = a.personId.compareTo(b.personId);
      if (byPerson != 0) return byPerson;
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      final bySource = a.source.index.compareTo(b.source.index);
      if (bySource != 0) return bySource;
      return (a.coverageProviderId ?? '').compareTo(b.coverageProviderId ?? '');
    }

    for (var index = 1; index < analysis.criticalityDetails.length; index++) {
      expect(
        compare(
          analysis.criticalityDetails[index - 1],
          analysis.criticalityDetails[index],
        ),
        lessThanOrEqualTo(0),
      );
    }
    final identities = analysis.criticalityDetails
        .map(
          (detail) =>
              '${detail.kind}|${detail.personId}|${detail.source}|'
              '${detail.coverageProviderId}|${detail.start}|${detail.end}',
        )
        .toSet();
    expect(identities, hasLength(analysis.criticalityDetails.length));
  });

  group('recovery solo dopo turno notturno effettivo', () {
    final runtimeDay = DateTime(2026, 7, 31);

    TurnEngine nightEngine({bool bothAdults = false}) {
      final shifts = TurnOverrideStore()
        ..setDailyOverride(
          person: TurnPersonId.matteo,
          day: runtimeDay.subtract(const Duration(days: 1)),
          newShift: TurnOverrideShift.notte,
        )
        ..setDailyOverride(
          person: TurnPersonId.matteo,
          day: runtimeDay,
          newShift: TurnOverrideShift.off,
        )
        ..setDailyOverride(
          person: TurnPersonId.chiara,
          day: runtimeDay,
          newShift: TurnOverrideShift.off,
        )
        ..setDailyOverride(
          person: TurnPersonId.chiara,
          day: runtimeDay.subtract(const Duration(days: 1)),
          newShift: bothAdults
              ? TurnOverrideShift.notte
              : TurnOverrideShift.off,
        );
      return TurnEngine(turnOverrideStore: shifts);
    }

    Iterable<CoverageCriticalityDetail> recoveryFor(
      CoverageDayAnalysis analysis,
      String personId,
    ) => analysis.criticalityDetails.where(
      (detail) => detail.personId == personId,
    );

    test('notte lavorata mantiene il recovery per Matteo', () async {
      final analysis = await analyze(
        requestedDay: runtimeDay,
        turnEngine: nightEngine(),
      );
      expect(recoveryFor(analysis, 'matteo'), isNotEmpty);
    });

    for (final status in [
      OverrideStatus.malattiaLeggera,
      OverrideStatus.malattiaALetto,
      OverrideStatus.ferie,
      OverrideStatus.permesso,
    ]) {
      test('${status.name} annulla ogni recovery pianificato', () async {
        final analysis = await analyze(
          requestedDay: runtimeDay,
          turnEngine: nightEngine(),
          overrides: DayOverrides(
            day: runtimeDay,
            matteo: PersonDayOverride(
              status: status,
              permessoRange: status == OverrideStatus.permesso
                  ? TimeRangeMinutes(startMin: 8 * 60, endMin: 12 * 60)
                  : null,
            ),
          ),
        );
        expect(recoveryFor(analysis, 'matteo'), isEmpty);
      });
    }

    for (final type in DiseaseType.values) {
      test('malattia ${type.name} da store annulla il recovery', () async {
        final diseases = DiseasePeriodStore();
        await diseases.addPeriod(
          DiseasePeriod(
            personId: 'matteo',
            type: type,
            startDate: runtimeDay,
            endDate: runtimeDay,
          ),
        );
        final analysis = await analyze(
          requestedDay: runtimeDay,
          turnEngine: nightEngine(),
          diseasePeriodStore: diseases,
        );
        expect(recoveryFor(analysis, 'matteo'), isEmpty);
      });
    }

    test('ferie da store annullano il recovery', () async {
      final holidays = FeriePeriodStore()
        ..add(
          FeriePeriod(
            person: FeriePerson.matteo,
            startDay: runtimeDay,
            endDay: runtimeDay,
          ),
        );
      final analysis = await analyze(
        requestedDay: runtimeDay,
        turnEngine: nightEngine(),
        ferieStore: holidays,
      );
      expect(recoveryFor(analysis, 'matteo'), isEmpty);
    });

    test('evento reale non annulla il recovery lavorato', () async {
      final events = RealEventStore()
        ..addEvent(
          RealEvent(
            id: 'event',
            startDate: runtimeDay,
            endDate: runtimeDay,
            title: 'Evento reale',
            startTime: const TimeOfDay(hour: 16, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
            personKey: 'matteo',
          ),
        );
      final analysis = await analyze(
        requestedDay: runtimeDay,
        turnEngine: nightEngine(),
        realEventStore: events,
      );
      expect(recoveryFor(analysis, 'matteo'), isNotEmpty);
    });

    test('31 luglio malattia leggera: niente coda 22:30-24 né gap', () async {
      final analysis = await analyze(
        requestedDay: runtimeDay,
        turnEngine: nightEngine(),
        overrides: DayOverrides(
          day: runtimeDay,
          matteo: PersonDayOverride(status: OverrideStatus.malattiaLeggera),
        ),
      );
      expect(analysis.criticalityDetails, isEmpty);
      expect(analysis.gapDetails, isEmpty);
      expect(
        const CalendarDayStatusBuilder().build(
          gapDetails: analysis.gapDetails,
          criticalityDetails: analysis.criticalityDetails,
          hasLogisticGaps: false,
        ),
        CalendarDayStatus.ok,
      );
    });

    test('due adulti: recovery soltanto per la notte lavorata', () async {
      final analysis = await analyze(
        requestedDay: runtimeDay,
        turnEngine: nightEngine(bothAdults: true),
        overrides: DayOverrides(
          day: runtimeDay,
          matteo: PersonDayOverride(status: OverrideStatus.malattiaLeggera),
        ),
      );
      expect(recoveryFor(analysis, 'matteo'), isEmpty);
      expect(recoveryFor(analysis, 'chiara'), isNotEmpty);
    });
  });
}

class _OverlappingConstraintTurnEngine extends TurnEngine {
  final AdultConstraintKind blockerKind;

  _OverlappingConstraintTurnEngine(this.blockerKind);

  @override
  List<AdultConstraintInterval> constraintsForPersonDay({
    required TurnPerson person,
    required DateTime day,
  }) {
    final constraints = super.constraintsForPersonDay(person: person, day: day);
    if (person != TurnPerson.chiara) return constraints;
    return [
      ...constraints,
      AdultConstraintInterval(
        personId: 'chiara',
        start: DateTime(2026, 8, 11, 7),
        end: DateTime(2026, 8, 11, 8),
        kind: blockerKind,
        canBeSacrificedForCare: false,
      ),
    ];
  }
}

class _RenamedPersonTurnEngine extends TurnEngine {
  @override
  List<AdultConstraintInterval> constraintsForPersonDay({
    required TurnPerson person,
    required DateTime day,
  }) {
    return super
        .constraintsForPersonDay(person: person, day: day)
        .map(
          (constraint) => AdultConstraintInterval(
            personId: person == TurnPerson.chiara
                ? 'adulto-2'
                : constraint.personId,
            start: constraint.start,
            end: constraint.end,
            kind: constraint.kind,
            canBeSacrificedForCare: constraint.canBeSacrificedForCare,
          ),
        )
        .toList();
  }
}

class _NoConstraintsTurnEngine extends TurnEngine {
  @override
  List<AdultConstraintInterval> constraintsForPersonDay({
    required TurnPerson person,
    required DateTime day,
  }) {
    return const [];
  }
}

class _BothRecoveryTurnEngine extends TurnEngine {
  @override
  List<AdultConstraintInterval> constraintsForPersonDay({
    required TurnPerson person,
    required DateTime day,
  }) {
    final personId = person == TurnPerson.matteo ? 'matteo' : 'chiara';
    return [
      AdultConstraintInterval(
        personId: personId,
        start: DateTime(2026, 8, 11),
        end: DateTime(2026, 8, 12),
        kind: AdultConstraintKind.recovery,
        canBeSacrificedForCare: true,
      ),
    ];
  }
}
