import 'package:flutter/material.dart';

import '../../../models/alice_special_event.dart';
import '../../../models/real_event.dart';
import '../../../utils/status_visual.dart';
import '../../alice_event_store.dart';
import '../../alice_events/alice_event_engine.dart';
import '../models/alice_now_state.dart';
import 'time_range_matcher.dart';

class AliceNowResolver {
  const AliceNowResolver();

  bool isBusyForRealEventNow({
    required Iterable<RealEvent> events,
    required DateTime now,
  }) {
    return _activeRealEventNow(
          events: events,
          now: now,
        ) !=
        null;
  }

  bool isNowInsideTimeRange({
    required DateTime day,
    required DateTime now,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    return const TimeRangeMatcher().isNowInside(
      day: day,
      now: now,
      start: start,
      end: end,
    );
  }

  AliceNowState build({
    required DateTime day,
    required DateTime now,
    required Iterable<RealEvent> realEvents,
    required Iterable<AliceSpecialEvent> specialEvents,
    required AliceEventType? dayType,
    required bool isRealSchoolDay,
    required bool isSchoolNormalDay,
    required TimeOfDay schoolStart,
    required TimeOfDay schoolEnd,
    TimeOfDay? summerCampStart,
    TimeOfDay? summerCampEnd,
  }) {
    final activeRealEvent = _activeRealEventNow(
      events: realEvents,
      now: now,
    );

    final activeSpecialEvent = _activeSpecialEventNow(
      events: specialEvents,
      day: day,
      now: now,
    );

    bool isOutNow = activeRealEvent != null;

    if (!isOutNow) {
      if (dayType == null) {
        if (isRealSchoolDay) {
          isOutNow = isNowInsideTimeRange(
            day: day,
            now: now,
            start: schoolStart,
            end: schoolEnd,
          );
        }
      } else {
        switch (dayType) {
          case AliceEventType.schoolNormal:
            if (isRealSchoolDay) {
              isOutNow = isNowInsideTimeRange(
                day: day,
                now: now,
                start: schoolStart,
                end: schoolEnd,
              );
            }
            break;

          case AliceEventType.summerCamp:
            isOutNow = isNowInsideTimeRange(
              day: day,
              now: now,
              start:
                  summerCampStart ?? const TimeOfDay(hour: 8, minute: 30),
              end: summerCampEnd ?? const TimeOfDay(hour: 16, minute: 30),
            );
            break;

          case AliceEventType.vacation:
          case AliceEventType.schoolClosure:
          case AliceEventType.sickness:
            isOutNow = false;
            break;
        }
      }
    }

    if (activeSpecialEvent != null &&
        const AliceEventEngine().isAliceOutDuringEvent(activeSpecialEvent)) {
      isOutNow = true;
    }

    final isSick = dayType == AliceEventType.sickness;

    final nowLabel = isOutNow
        ? _outsideLabel(
            activeSpecialEvent: activeSpecialEvent,
            activeRealEvent: activeRealEvent,
            dayType: dayType,
            isSchoolNormalDay: isSchoolNormalDay,
          )
        : (isSick ? 'a casa • malata' : 'a casa');

    return AliceNowState(
      isOutNow: isOutNow,
      nowLabel: nowLabel,
      visual: getStatusVisual(nowLabel),
    );
  }

  RealEvent? _activeRealEventNow({
    required Iterable<RealEvent> events,
    required DateTime now,
  }) {
    for (final event in events) {
      final eventStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime?.hour ?? 0,
        event.startTime?.minute ?? 0,
      );

      DateTime eventEnd = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
        event.endTime?.hour ?? 23,
        event.endTime?.minute ?? 59,
      );

      if (!eventEnd.isAfter(eventStart)) {
        eventEnd = eventEnd.add(const Duration(days: 1));
      }

      final isNowInside =
          now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isNowInside) {
        return event;
      }
    }

    return null;
  }

  AliceSpecialEvent? _activeSpecialEventNow({
    required Iterable<AliceSpecialEvent> events,
    required DateTime day,
    required DateTime now,
  }) {
    for (final event in events) {
      final eventStart = DateTime(
        day.year,
        day.month,
        day.day,
        event.start.hour,
        event.start.minute,
      );

      final eventEnd = DateTime(
        day.year,
        day.month,
        day.day,
        event.end.hour,
        event.end.minute,
      );

      final isNowInside =
          now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isNowInside) {
        return event;
      }
    }

    return null;
  }

  String _outsideLabel({
    required AliceSpecialEvent? activeSpecialEvent,
    required RealEvent? activeRealEvent,
    required AliceEventType? dayType,
    required bool isSchoolNormalDay,
  }) {
    if (activeSpecialEvent != null) {
      return _outsideLabelFromText(
        activeSpecialEvent.label,
        category: activeSpecialEvent.category,
      );
    }

    if (activeRealEvent != null) {
      return _outsideLabelFromText(activeRealEvent.title);
    }

    if (dayType == AliceEventType.summerCamp) {
      return 'fuori • centro estivo';
    }

    if (isSchoolNormalDay) {
      return 'fuori • scuola';
    }

    return 'fuori • casa';
  }

  String _outsideLabelFromText(
    String text, {
    AliceSpecialEventCategory? category,
  }) {
    switch (category) {
      case AliceSpecialEventCategory.school:
        return 'fuori • scuola';

      case AliceSpecialEventCategory.health:
        return 'fuori • visita';

      case AliceSpecialEventCategory.sport:
        return 'fuori • sport';

      case AliceSpecialEventCategory.activity:
        return 'fuori • attività';

      case AliceSpecialEventCategory.other:
      case null:
        break;
    }

    final lower = text.toLowerCase();

    if (lower.contains('centro estivo')) {
      return 'fuori • centro estivo';
    }

    if (lower.contains('gita')) {
      return 'fuori • gita';
    }

    if (lower.contains('visita') ||
        lower.contains('dentista') ||
        lower.contains('medic') ||
        lower.contains('pediatra')) {
      return 'fuori • visita';
    }

    if (lower.contains('scuola')) {
      return 'fuori • scuola';
    }

    if (lower.contains('danza') ||
        lower.contains('ballo') ||
        lower.contains('pallavolo') ||
        lower.contains('sport')) {
      return 'fuori • sport';
    }

    if (lower.contains('teatro') ||
        lower.contains('ripetizioni') ||
        lower.contains('corso')) {
      return 'fuori • attività';
    }

    return 'fuori';
  }
}