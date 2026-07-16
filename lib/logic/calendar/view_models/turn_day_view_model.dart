import '../../turn_engine.dart';
import '../../../models/real_event.dart';
import '../models/turn_event_conflict.dart';

enum TurnSourceKind {
  standard,
  dailyOverride,
  periodOverride,
  rotationOverride,
  fourthShift,
}

class TurnPersonDayViewModel {
  final TurnPerson person;
  final String personKey;
  final String displayName;

  final TurnPlan plan;

  final String? statusText;
  final TurnSourceKind sourceKind;
  final String? sourceText;

  final bool isOnHoliday;
  final bool isSick;
  final bool isBedSick;

  final List<RealEvent> events;
  final List<TurnEventConflictResolution> conflicts;

  const TurnPersonDayViewModel({
    required this.person,
    required this.personKey,
    required this.displayName,
    required this.plan,
    required this.statusText,
    required this.sourceKind,
    required this.sourceText,
    required this.isOnHoliday,
    required this.isSick,
    required this.isBedSick,
    required this.events,
    required this.conflicts,
  });
}

class TurnDayViewModel {
  final DateTime day;

  final TurnConflictInfo turnConflict;

  final TurnPersonDayViewModel matteo;
  final TurnPersonDayViewModel chiara;

  final List<RealEvent> familyEvents;

  const TurnDayViewModel({
    required this.day,
    required this.turnConflict,
    required this.matteo,
    required this.chiara,
    required this.familyEvents,
  });
}
