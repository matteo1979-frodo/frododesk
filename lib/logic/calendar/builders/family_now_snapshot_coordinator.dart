import '../../../models/day_override.dart';
import '../../../models/real_event.dart';
import '../../../utils/calendario_formatters.dart';
import '../../core_store.dart';
import '../../ferie_period_store.dart';
import '../../turn_engine.dart';
import '../models/adult_now_state.dart';
import '../models/family_now_snapshot.dart';
import 'adult_now_state_builder.dart';
import 'alice_now_resolver.dart';
import 'effective_school_day_timing_reader.dart';
import 'family_now_snapshot_builder.dart';
import 'person_effective_status_builder.dart';

class FamilyNowSnapshotCoordinator {
  final PersonEffectiveStatusBuilder effectiveStatusBuilder;
  final AdultNowStateBuilder adultNowStateBuilder;
  final AliceNowResolver aliceNowResolver;
  final FamilyNowSnapshotBuilder snapshotBuilder;

  const FamilyNowSnapshotCoordinator({
    this.effectiveStatusBuilder = const PersonEffectiveStatusBuilder(),
    this.adultNowStateBuilder = const AdultNowStateBuilder(),
    this.aliceNowResolver = const AliceNowResolver(),
    this.snapshotBuilder = const FamilyNowSnapshotBuilder(),
  });

  FamilyNowSnapshot build({
    required DateTime selectedDay,
    required DateTime observedAt,
    required CoreStore coreStore,
    DayOverrides? overrides,
  }) {
    final day = _onlyDate(selectedDay);
    final dayOverrides = overrides ?? coreStore.overrideStore.getForDay(day);

    final matteo = _buildAdult(
      personKey: 'matteo',
      person: TurnPerson.matteo,
      day: day,
      observedAt: observedAt,
      override: dayOverrides.matteo,
      coreStore: coreStore,
    );
    final chiara = _buildAdult(
      personKey: 'chiara',
      person: TurnPerson.chiara,
      day: day,
      observedAt: observedAt,
      override: dayOverrides.chiara,
      coreStore: coreStore,
    );

    final alicePeriod = coreStore.aliceEventStore.getEventForDay(day);
    final schoolTiming = EffectiveSchoolDayTimingReader(coreStore).read(day);
    final alice = aliceNowResolver.build(
      day: day,
      now: observedAt,
      realEvents: coreStore.realEventStore
          .eventsForDay(day)
          .where((event) => event.personKey == 'alice'),
      specialEvents: coreStore.aliceSpecialEventStore.eventsForDay(day),
      dayType: alicePeriod?.type,
      isRealSchoolDay: coreStore.schoolStore.hasSchoolOn(day),
      isSchoolNormalDay: coreStore.aliceEventStore.isSchoolNormalDay(day),
      schoolStart: schoolTiming.schoolEntryAt,
      schoolEnd:
          schoolTiming.earlySchoolExitAt ?? schoolTiming.schoolPickupWindowEnd,
      summerCampStart: alicePeriod?.summerCampStart,
      summerCampEnd: alicePeriod?.summerCampEnd,
    );

    return snapshotBuilder.build(
      realNow: observedAt,
      now: observedAt,
      matteo: matteo,
      chiara: chiara,
      alice: alice,
    );
  }

  AdultNowState _buildAdult({
    required String personKey,
    required TurnPerson person,
    required DateTime day,
    required DateTime observedAt,
    required PersonDayOverride? override,
    required CoreStore coreStore,
  }) {
    final effectiveStatus = effectiveStatusBuilder.build(
      manualOverride: override,
      diseasePeriod: coreStore.diseasePeriodStore.getPeriodForDay(
        personKey,
        day,
      ),
      isInHolidayPeriod: coreStore.feriePeriodStore.isOnHoliday(
        person == TurnPerson.matteo ? FeriePerson.matteo : FeriePerson.chiara,
        day,
      ),
    );
    final turnPlan = coreStore.turnEngine.turnPlanForPersonDay(
      person: person,
      day: day,
    );

    return adultNowStateBuilder.build(
      effectiveStatus: effectiveStatus,
      isBusyForEventNow: _hasActiveEvent(
        events: coreStore.realEventStore
            .eventsForDay(day)
            .where((event) => event.personKey == personKey),
        observedAt: observedAt,
      ),
      isBusyForTurn: person == TurnPerson.matteo
          ? coreStore.coverageEngine.isMatteoBusyBetween(
              observedAt,
              observedAt.add(const Duration(minutes: 1)),
            )
          : coreStore.coverageEngine.isChiaraBusyBetween(
              observedAt,
              observedAt.add(const Duration(minutes: 1)),
            ),
      turnLabel: effectiveStatusBuilder.buildTurnLabel(
        isOff: turnPlan.isOff,
        startText: fmtTimeOfDay(turnPlan.start),
        endText: fmtTimeOfDay(turnPlan.end),
      ),
    );
  }

  bool _hasActiveEvent({
    required Iterable<RealEvent> events,
    required DateTime observedAt,
  }) {
    for (final event in events) {
      final start = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime?.hour ?? 0,
        event.startTime?.minute ?? 0,
      );
      var end = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
        event.endTime?.hour ?? 23,
        event.endTime?.minute ?? 59,
      );
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
      if (observedAt.isAfter(start) && observedAt.isBefore(end)) return true;
    }
    return false;
  }

  DateTime _onlyDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
