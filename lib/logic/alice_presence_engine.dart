// lib/logic/alice_presence_engine.dart

import 'alice_event_store.dart';
import 'alice_special_event_store.dart';
import 'real_event_store.dart';
import 'school_store.dart';
import 'summer_camp_schedule_store.dart';
import 'summer_camp_special_event_store.dart';
import '../models/alice_presence_state.dart';

class AlicePresenceEngine {
  final AliceEventStore aliceEventStore;
  final AliceSpecialEventStore aliceSpecialEventStore;
  final RealEventStore realEventStore;
  final SchoolStore schoolStore;
  final SummerCampScheduleStore summerCampScheduleStore;
  final SummerCampSpecialEventStore summerCampSpecialEventStore;

  const AlicePresenceEngine({
    required this.aliceEventStore,
    required this.aliceSpecialEventStore,
    required this.realEventStore,
    required this.schoolStore,
    required this.summerCampScheduleStore,
    required this.summerCampSpecialEventStore,
  });

  DateTime _onlyDate(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }

  DateTime _atTime(DateTime d0, time) {
    return DateTime(d0.year, d0.month, d0.day, time.hour, time.minute);
  }

  bool isAliceAtHomeDay(DateTime day) {
    final d0 = _onlyDate(day);

    final isWeekend =
        d0.weekday == DateTime.saturday || d0.weekday == DateTime.sunday;

    return aliceEventStore.isAliceAtHomeDay(d0) ||
        isWeekend ||
        (!schoolStore.hasSchoolOn(d0) && !isAliceSummerCampOperationalDay(d0));
  }

  AlicePresenceState stateForRange({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    if (isAliceInsideRealEvent(day: day, start: start, end: end)) {
      return AlicePresenceState.realEvent;
    }

    if (isAliceInsideTimedEvent(day: day, start: start, end: end)) {
      return AlicePresenceState.timedEvent;
    }

    if (isAliceSummerCampOperationalDay(day)) {
      return AlicePresenceState.summerCamp;
    }

    if (isAliceSchoolNormalDay(day)) {
      return AlicePresenceState.school;
    }

    return AlicePresenceState.home;
  }

  bool isAliceSchoolNormalDay(DateTime day) {
    final d0 = _onlyDate(day);

    final isWeekend =
        d0.weekday == DateTime.saturday || d0.weekday == DateTime.sunday;

    if (isWeekend) return false;

    final type = aliceEventStore.getEventTypeForDay(d0);

    if (type == AliceEventType.vacation ||
        type == AliceEventType.sickness ||
        type == AliceEventType.schoolClosure ||
        type == AliceEventType.summerCamp) {
      return false;
    }

    return schoolStore.hasSchoolOn(d0);
  }

  bool isAliceInsideTimedEvent({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final d0 = _onlyDate(day);

    final events = aliceSpecialEventStore
        .eventsForDay(d0)
        .where((event) => event.enabled);

    for (final event in events) {
      final eventStart = _atTime(d0, event.start);
      final eventEnd = _atTime(d0, event.end);

      final overlaps = eventStart.isBefore(end) && eventEnd.isAfter(start);

      if (overlaps) return true;
    }

    return false;
  }

  bool isAliceInsideRealEvent({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final d0 = _onlyDate(day);
    final events = realEventStore.eventsForDay(d0);

    for (final event in events) {
      if (!event.involvesPerson('alice')) continue;
      if (event.startTime == null || event.endTime == null) continue;

      final eventStart = _atTime(d0, event.startTime!);
      final eventEnd = _atTime(d0, event.endTime!);

      final overlaps = eventStart.isBefore(end) && eventEnd.isAfter(start);

      if (overlaps) return true;
    }

    return false;
  }

  bool isAliceAwayFromHomeDuringRange({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    return isAliceInsideTimedEvent(day: day, start: start, end: end) ||
        isAliceInsideRealEvent(day: day, start: start, end: end);
  }

  bool isAliceSummerCampOperationalDay(DateTime day) {
    final d0 = _onlyDate(day);

    final period = aliceEventStore.getSummerCampPeriodForDay(d0);
    if (period == null) return false;

    final special = summerCampSpecialEventStore.getForDay(d0);
    final config = summerCampScheduleStore.getConfigForDay(d0);

    return special?.enabled ?? config.enabled;
  }
}
