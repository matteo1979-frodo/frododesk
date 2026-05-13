// lib/logic/alice_presence_engine.dart

import 'alice_event_store.dart';
import 'alice_special_event_store.dart';
import 'real_event_store.dart';
import 'school_store.dart';
import 'summer_camp_schedule_store.dart';
import 'summer_camp_special_event_store.dart';
import '../models/alice_presence_state.dart';
import '../models/alice_special_event.dart';
import 'alice_companion_store.dart';
import 'support_network_store.dart';
import 'day_settings_store.dart';

class AlicePresenceEngine {
  final AliceEventStore aliceEventStore;
  final AliceSpecialEventStore aliceSpecialEventStore;
  final RealEventStore realEventStore;
  final SchoolStore schoolStore;
  final SummerCampScheduleStore summerCampScheduleStore;
  final SummerCampSpecialEventStore summerCampSpecialEventStore;
  final AliceCompanionStore aliceCompanionStore;
  final SupportNetworkStore supportNetworkStore;
  final DaySettingsStore daySettingsStore;

  const AlicePresenceEngine({
    required this.aliceEventStore,
    required this.aliceSpecialEventStore,
    required this.realEventStore,
    required this.schoolStore,
    required this.summerCampScheduleStore,
    required this.summerCampSpecialEventStore,
    required this.aliceCompanionStore,
    required this.supportNetworkStore,
    required this.daySettingsStore,
  });

  DateTime _onlyDate(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }

  DateTime _atTime(DateTime d0, time) {
    return DateTime(d0.year, d0.month, d0.day, time.hour, time.minute);
  }

  bool isCoveredBySupportNetwork({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final d0 = _onlyDate(day);

    for (final person in supportNetworkStore.people) {
      if (!person.enabled) continue;

      final enabledForDay = daySettingsStore.isSupportPersonEnabledForDay(
        d0,
        person.id,
      );

      if (!enabledForDay) continue;

      for (final window in person.effectiveSlots) {
        final supportStart = DateTime(
          d0.year,
          d0.month,
          d0.day,
          window.start.hour,
          window.start.minute,
        );

        final supportEnd = DateTime(
          d0.year,
          d0.month,
          d0.day,
          window.end.hour,
          window.end.minute,
        );

        final coversFullRange =
            !supportStart.isAfter(start) && !supportEnd.isBefore(end);

        if (coversFullRange) return true;
      }
    }

    return false;
  }

  bool isAliceAtHomeDay(DateTime day) {
    final d0 = _onlyDate(day);

    final isWeekend =
        d0.weekday == DateTime.saturday || d0.weekday == DateTime.sunday;

    return aliceEventStore.isAliceAtHomeDay(d0) ||
        isWeekend ||
        (!schoolStore.hasSchoolOn(d0) && !isAliceSummerCampOperationalDay(d0));
  }

  AliceEventType? getAliceEventTypeForDay(DateTime day) {
    return aliceEventStore.getEventTypeForDay(_onlyDate(day));
  }

  AliceEventPeriod? getSummerCampPeriodForDay(DateTime day) {
    return aliceEventStore.getSummerCampPeriodForDay(_onlyDate(day));
  }

  SummerCampDayConfig getSummerCampConfigForDay(DateTime day) {
    return summerCampScheduleStore.getEffectiveConfigForDay(_onlyDate(day));
  }

  SummerCampSpecialEvent? getSummerCampSpecialEventForDay(DateTime day) {
    return summerCampSpecialEventStore.getForDay(_onlyDate(day));
  }

  bool hasSummerCampSpecialEventForDay(DateTime day) {
    return summerCampSpecialEventStore.hasEventForDay(_onlyDate(day));
  }

  bool isAliceExternalActivityDay(DateTime day) {
    return aliceEventStore.isExternalActivityDay(_onlyDate(day));
  }

  bool isAliceAtHomeDuringRange({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    return stateForRange(day: day, start: start, end: end) ==
        AlicePresenceState.home;
  }

  bool isAliceAccompaniedDuringRange({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    return aliceCompanionStore.findCompanionForRange(
          day: day,
          start: start,
          end: end,
        ) !=
        null;
  }

  DateTime? aliceCompanionEndForRange({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final d0 = _onlyDate(day);
    final entries = aliceCompanionStore.entriesForDay(d0);

    DateTime? bestEnd;

    for (final entry in entries) {
      final entryStart = DateTime(
        d0.year,
        d0.month,
        d0.day,
        entry.start.hour,
        entry.start.minute,
      );

      final entryEnd = DateTime(
        d0.year,
        d0.month,
        d0.day,
        entry.end.hour,
        entry.end.minute,
      );

      final overlapsWindow =
          entryStart.isBefore(end) && entryEnd.isAfter(start);

      if (!overlapsWindow) continue;

      if (entryStart.isAfter(start)) continue;

      if (bestEnd == null || entryEnd.isAfter(bestEnd)) {
        bestEnd = entryEnd;
      }
    }

    return bestEnd;
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
      final companion = aliceCompanionStore.findCompanionForRange(
        day: day,
        start: start,
        end: end,
      );

      if (companion != null) {
        return AlicePresenceState.accompanied;
      }

      return AlicePresenceState.timedEvent;
    }

    if (isAliceInsideSummerCampRange(day: day, start: start, end: end)) {
      return AlicePresenceState.summerCamp;
    }

    if (isAliceInsideSchoolRange(day: day, start: start, end: end)) {
      return AlicePresenceState.school;
    }

    if (isCoveredBySupportNetwork(day: day, start: start, end: end)) {
      return AlicePresenceState.support;
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
    if (enabledTimedEventsForDay(d0).isNotEmpty) {
      return false;
    }

    return schoolStore.hasSchoolOn(d0);
  }

  bool isAliceInsideSchoolRange({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final d0 = _onlyDate(day);

    if (!isAliceSchoolNormalDay(d0)) return false;

    final cfg = schoolStore
        .activePeriodForDay(d0)
        ?.weekConfig
        .forWeekday(d0.weekday);

    if (cfg == null || !cfg.enabled) return false;

    final schoolStart = DateTime(
      d0.year,
      d0.month,
      d0.day,
      cfg.entryMinutes ~/ 60,
      cfg.entryMinutes % 60,
    );

    final schoolEnd = DateTime(
      d0.year,
      d0.month,
      d0.day,
      cfg.returnHomeMinutes ~/ 60,
      cfg.returnHomeMinutes % 60,
    );

    return schoolStart.isBefore(end) && schoolEnd.isAfter(start);
  }

  bool isAliceInsideSummerCampRange({
    required DateTime day,
    required DateTime start,
    required DateTime end,
  }) {
    final d0 = _onlyDate(day);

    if (!isAliceSummerCampOperationalDay(d0)) {
      return false;
    }

    final special = summerCampSpecialEventStore.getForDay(d0);
    final config = summerCampScheduleStore.getEffectiveConfigForDay(d0);

    final campStart = DateTime(
      d0.year,
      d0.month,
      d0.day,
      (special?.start ?? config.start).hour,
      (special?.start ?? config.start).minute,
    );

    final campEnd = DateTime(
      d0.year,
      d0.month,
      d0.day,
      (special?.end ?? config.end).hour,
      (special?.end ?? config.end).minute,
    );

    return campStart.isBefore(end) && campEnd.isAfter(start);
  }

  List<AliceSpecialEvent> enabledTimedEventsForDay(DateTime day) {
    final events = aliceSpecialEventStore
        .eventsForDay(_onlyDate(day))
        .where((event) => event.enabled)
        .toList();

    events.sort((a, b) {
      final aMinutes = a.start.hour * 60 + a.start.minute;
      final bMinutes = b.start.hour * 60 + b.start.minute;

      return aMinutes.compareTo(bMinutes);
    });

    return events;
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
