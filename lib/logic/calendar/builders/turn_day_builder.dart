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

  TurnPersonDayViewModel buildPerson({
    required TurnPerson person,
    required String personKey,
    required String displayName,
    required DateTime day,
    required TurnPlan plan,
    required String turnSummary,
    required PersonDayOverride? manualOverride,
    required String? statusText,
    required TurnSourceKind sourceKind,
    required String? sourceText,
    required bool isOnHoliday,
    required bool isSick,
    required bool isBedSick,
    required List<RealEvent> personEvents,
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
      events: List<RealEvent>.unmodifiable(personEvents),
      conflicts: List.unmodifiable(conflicts),
    );
  }
}
