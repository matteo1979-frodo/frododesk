import '../models/day_override.dart';
import '../models/disease_period.dart';
import '../models/person_availability.dart';
import '../models/work_shift.dart';
import 'coverage_logic.dart';
import 'disease_period_store.dart';
import 'ferie_period_store.dart';
import 'override_apply.dart';
import 'real_event_store.dart';
import 'turn_engine.dart';

/// Canonical availability rules shared by coverage and external logistics.
class AdultLogisticsAvailabilityResolver {
  final TurnEngine turnEngine;
  final DiseasePeriodStore diseasePeriodStore;
  final RealEventStore realEventStore;

  const AdultLogisticsAvailabilityResolver({
    required this.turnEngine,
    required this.diseasePeriodStore,
    required this.realEventStore,
  });

  bool canCoverRange({
    required String personKey,
    required TurnPerson person,
    required DateTime day,
    required DateTime start,
    required DateTime end,
    required bool isHomePresenceWindow,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
    bool forceAvailableDueToLunchCover = false,
  }) {
    final state = effectivePlannedShiftState(
      personKey: personKey,
      day: day,
      overrides: overrides,
      ferieStore: ferieStore,
    );
    final personOverride = state.personOverride;

    var baseBusy = turnEngine
        .constraintsForPersonDay(person: person, day: day)
        .where((constraint) => !constraint.canBeSacrificedForCare)
        .map(
          (constraint) =>
              WorkShift(start: constraint.start, end: constraint.end),
        )
        .toList();
    if (!state.isPlannedShiftActive) baseBusy = [];

    final effectiveBusy = OverrideApply.applyToBusyShifts(
      day: day,
      baseBusy: <WorkShift>[...baseBusy, ..._realEventBusy(personKey, day)],
      personOverride: personOverride,
    );
    final adjustedBusy = forceAvailableDueToLunchCover
        ? <WorkShift>[]
        : effectiveBusy;
    final status = state.status;

    if (status == OverrideStatus.malattiaALetto) {
      return isHomePresenceWindow &&
          isTimeCovered(start, end, [
            PersonAvailability(busyShifts: adjustedBusy),
          ]);
    }
    if (status == OverrideStatus.malattiaLeggera &&
        !isHomePresenceWindow &&
        _overlapsExternalImpediments(day, start, end)) {
      return false;
    }
    return isTimeCovered(start, end, [
      PersonAvailability(busyShifts: adjustedBusy),
    ]);
  }

  /// Resolves whether the planned work constraints are part of the adult's
  /// real day. This is the same typed status resolution used by availability.
  EffectivePlannedShiftState effectivePlannedShiftState({
    required String personKey,
    required DateTime day,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final personOverride = personKey == 'matteo'
        ? overrides.matteo
        : overrides.chiara;
    final hasManual = personOverride != null;
    final diseaseStatus = hasManual
        ? null
        : _diseaseStatus(personId: personKey, day: day);
    final isHoliday =
        !hasManual &&
        diseaseStatus == null &&
        ((personKey == 'matteo'
                ? ferieStore?.isOnHoliday(FeriePerson.matteo, day)
                : ferieStore?.isOnHoliday(FeriePerson.chiara, day)) ??
            false);
    final status =
        personOverride?.status ??
        diseaseStatus ??
        (isHoliday ? OverrideStatus.ferie : OverrideStatus.normal);

    return EffectivePlannedShiftState(
      status: status,
      personOverride: personOverride,
      isPlannedShiftActive: status == OverrideStatus.normal,
    );
  }

  OverrideStatus? _diseaseStatus({
    required String personId,
    required DateTime day,
  }) {
    final period = diseasePeriodStore.getPeriodForDay(personId, day);
    if (period == null) return null;
    return period.type == DiseaseType.mild
        ? OverrideStatus.malattiaLeggera
        : OverrideStatus.malattiaALetto;
  }

  List<WorkShift> _realEventBusy(String personKey, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return realEventStore
        .eventsForDay(d)
        .where((e) => e.involvesPerson(personKey))
        .map((e) {
          final start = e.startTime == null
              ? DateTime(d.year, d.month, d.day)
              : DateTime(
                  d.year,
                  d.month,
                  d.day,
                  e.startTime!.hour,
                  e.startTime!.minute,
                );
          final end = e.endTime == null
              ? DateTime(d.year, d.month, d.day, 23, 59)
              : DateTime(
                  d.year,
                  d.month,
                  d.day,
                  e.endTime!.hour,
                  e.endTime!.minute,
                );
          return WorkShift(start: start, end: end);
        })
        .where((shift) => shift.end.isAfter(shift.start))
        .toList();
  }

  bool _overlapsExternalImpediments(
    DateTime day,
    DateTime start,
    DateTime end,
  ) {
    final firstStart = DateTime(day.year, day.month, day.day, 10);
    final firstEnd = DateTime(day.year, day.month, day.day, 12);
    final secondStart = DateTime(day.year, day.month, day.day, 17);
    final secondEnd = DateTime(day.year, day.month, day.day, 19);
    return (start.isBefore(firstEnd) && end.isAfter(firstStart)) ||
        (start.isBefore(secondEnd) && end.isAfter(secondStart));
  }
}

class EffectivePlannedShiftState {
  final OverrideStatus status;
  final PersonDayOverride? personOverride;
  final bool isPlannedShiftActive;

  const EffectivePlannedShiftState({
    required this.status,
    required this.personOverride,
    required this.isPlannedShiftActive,
  });
}
