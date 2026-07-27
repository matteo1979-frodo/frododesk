import '../../../models/real_event.dart';
import '../models/alice_now_state.dart';
import 'package:flutter/material.dart';
import 'time_range_matcher.dart';

class AliceNowResolver {
  const AliceNowResolver();

  bool isBusyForRealEventNow({
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

      final isNowInside = now.isAfter(eventStart) && now.isBefore(eventEnd);

      if (isNowInside) {
        return true;
      }
    }

    return false;
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

  AliceNowState build() {
    throw UnimplementedError();
  }
}
