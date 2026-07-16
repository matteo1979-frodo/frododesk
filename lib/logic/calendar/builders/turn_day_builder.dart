import '../../../models/day_override.dart';
import '../../../models/real_event.dart';
import '../../turn_engine.dart';
import '../view_models/turn_day_view_model.dart';
import 'turn_event_conflict_builder.dart';

class TurnDayBuilder {
  final TurnEventConflictBuilder conflictBuilder;

  const TurnDayBuilder({
    this.conflictBuilder = const TurnEventConflictBuilder(),
  });

  TurnSourceKind _sourceKindFromText(String? sourceText) {
    if (sourceText == null) {
      return TurnSourceKind.standard;
    }

    final lower = sourceText.toLowerCase();

    if (lower.contains('solo oggi')) {
      return TurnSourceKind.dailyOverride;
    }

    if (lower.contains('periodo')) {
      return TurnSourceKind.periodOverride;
    }

    if (lower.contains('nuova rotazione')) {
      return TurnSourceKind.rotationOverride;
    }

    if (lower.contains('quarta squadra')) {
      return TurnSourceKind.fourthShift;
    }

    return TurnSourceKind.standard;
  }

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

  TurnPersonDayViewModel buildPerson({
    required TurnPerson person,
    required String personKey,
    required String displayName,
    required DateTime day,
    required TurnPlan plan,
    required String turnSummary,
    required PersonDayOverride? manualOverride,
    required String? statusText,
    required String? sourceText,
    required bool isOnHoliday,
    required bool isSick,
    required bool isBedSick,
    required List<RealEvent> allDayEvents,
  }) {
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
    return TurnPersonDayViewModel(
      person: person,
      personKey: personKey,
      displayName: displayName,
      plan: plan,
      statusText: statusText,
      sourceKind: _sourceKindFromText(sourceText),
      sourceText: sourceText,
      isOnHoliday: isOnHoliday,
      isSick: isSick,
      isBedSick: isBedSick,
      events: List<RealEvent>.unmodifiable(personEvents),
      conflicts: List.unmodifiable(conflicts),
    );
  }

  TurnDayViewModel buildDay({
    required DateTime day,
    required TurnConflictInfo turnConflict,
    required TurnPersonDayViewModel matteo,
    required TurnPersonDayViewModel chiara,
    required List<RealEvent> familyEvents,
  }) {
    return TurnDayViewModel(
      day: DateTime(day.year, day.month, day.day),
      turnConflict: turnConflict,
      matteo: matteo,
      chiara: chiara,
      familyEvents: List<RealEvent>.unmodifiable(familyEvents),
    );
  }
}
