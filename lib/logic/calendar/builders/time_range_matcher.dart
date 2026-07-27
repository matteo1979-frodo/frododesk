import 'package:flutter/material.dart';

class TimeRangeMatcher {
  const TimeRangeMatcher();

  bool isNowInside({
    required DateTime day,
    required DateTime now,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final rangeStart = DateTime(
      day.year,
      day.month,
      day.day,
      start.hour,
      start.minute,
    );

    final rangeEnd = DateTime(
      day.year,
      day.month,
      day.day,
      end.hour,
      end.minute,
    );

    return now.isAfter(rangeStart) && now.isBefore(rangeEnd);
  }
}
