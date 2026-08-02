import '../../../models/day_override.dart';
import '../../../models/disease_period.dart';
import '../../../models/real_event.dart';
import '../../turn_engine.dart';
import '../view_models/turn_day_view_model.dart';
import 'turn_event_conflict_builder.dart';
import 'turn_person_status_builder.dart';
import 'turn_presentation_state_builder.dart';
import '../models/turn_presentation_state.dart';

class TurnDayBuilder {
  final TurnEventConflictBuilder conflictBuilder;
  final TurnPersonStatusBuilder statusBuilder;
  final TurnPresentationStateBuilder presentationBuilder;

  const TurnDayBuilder({
    this.conflictBuilder = const TurnEventConflictBuilder(),
    this.statusBuilder = const TurnPersonStatusBuilder(),
    this.presentationBuilder = const TurnPresentationStateBuilder(),
  });

  List<RealEvent> _eventsForPerson({
    required String personKey,
    required List<RealEvent> allDayEvents,
  }) {
    final events = allDayEvents
        .where((event) => event.personKey == personKey)
        .toList();

    events.sort((a, b) {
      final aMinutes = a.startTime == null
          ? 9999
          : a.startTime!.hour * 60 + a.startTime!.minute;

      final bMinutes = b.startTime == null
          ? 9999
          : b.startTime!.hour * 60 + b.startTime!.minute;

      return aMinutes.compareTo(bMinutes);
    });

    return events;
  }

  List<RealEvent> _familyEvents({required List<RealEvent> allDayEvents}) {
    final events = allDayEvents
        .where(
          (event) =>
              event.personKey?.toLowerCase() == 'family' ||
              event.personKey?.toLowerCase() == 'generale',
        )
        .toList();

    events.sort((a, b) {
      final aMinutes = a.startTime == null
          ? 9999
          : a.startTime!.hour * 60 + a.startTime!.minute;

      final bMinutes = b.startTime == null
          ? 9999
          : b.startTime!.hour * 60 + b.startTime!.minute;

      return aMinutes.compareTo(bMinutes);
    });

    return events;
  }

  TurnPersonDayViewModel buildPerson({
    required TurnPerson person,
    required String personKey,
    required String displayName,
    required DateTime day,
    required TurnPlan plan,
    required String turnSummary,
    required PersonDayOverride? manualOverride,
    required DiseasePeriod? diseasePeriod,
    required String? turnOverrideStatusText,
    required String? sourceText,
    required TurnSourceKind sourceKind,
    required bool isManualShiftChange,
    required DateTime observedAt,
    required bool isOnHoliday,
    required bool isSick,
    required bool isBedSick,
    required List<RealEvent> allDayEvents,
  }) {
    final statusText = statusBuilder.build(
      manualOverride: manualOverride,
      diseasePeriod: diseasePeriod,
      isOnHoliday: isOnHoliday,
      turnOverrideStatusText: turnOverrideStatusText,
    );

    final conflicts = conflictBuilder.build(
      personKey: personKey,
      day: day,
      turnPlan: plan,
      turnSummary: turnSummary,
      manualOverride: manualOverride,
      isOnHoliday: isOnHoliday,
      isSick: isSick,
      isBedSick: isBedSick,
      events: allDayEvents,
    );

    final personEvents = _eventsForPerson(
      personKey: personKey,
      allDayEvents: allDayEvents,
    );

    final presentation = presentationBuilder.build(
      day: day,
      observedAt: observedAt,
      plan: plan,
      manualOverride: manualOverride,
      diseasePeriod: diseasePeriod,
      isOnHoliday: isOnHoliday,
      isSick: isSick,
      isBedSick: isBedSick,
      isManualShiftChange: isManualShiftChange,
      statusText: statusText,
      sourceKind: sourceKind,
      sourceText: sourceText,
      hasConflict: conflicts.isNotEmpty,
    );

    return TurnPersonDayViewModel(
      person: person,
      personKey: personKey,
      displayName: displayName,
      plan: plan,
      statusText: statusText,
      sourceKind: sourceKind,
      sourceText: sourceText,
      isOnHoliday: isOnHoliday,
      isSick: isSick,
      isBedSick: isBedSick,
      presentation: presentation,
      events: List<RealEvent>.unmodifiable(personEvents),
      conflicts: List.unmodifiable(conflicts),
    );
  }

  TurnDayViewModel buildDay({
    required DateTime day,
    required TurnConflictInfo turnConflict,
    required TurnPersonDayViewModel matteo,
    required TurnPersonDayViewModel chiara,
    required List<RealEvent> allDayEvents,
  }) {
    final familyEvents = _familyEvents(allDayEvents: allDayEvents);

    return TurnDayViewModel(
      day: DateTime(day.year, day.month, day.day),
      turnConflict: turnConflict,
      matteo: matteo,
      chiara: chiara,
      familyEvents: List<RealEvent>.unmodifiable(familyEvents),
    );
  }
}
