import 'package:flutter/material.dart';

enum TimeVisibilityState { past, active, future }

DateTime onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime atDayTime(DateTime day, TimeOfDay t) {
  final d0 = onlyDate(day);
  return DateTime(d0.year, d0.month, d0.day, t.hour, t.minute);
}

TimeVisibilityState dateRangeVisibility({
  required DateTime startDate,
  required DateTime endDate,
  DateTime? now,
}) {
  final nowValue = now ?? DateTime.now();
  final today = onlyDate(nowValue);
  final start = onlyDate(startDate);
  final end = onlyDate(endDate);

  if (end.isBefore(today)) {
    return TimeVisibilityState.past;
  }

  if (start.isAfter(today)) {
    return TimeVisibilityState.future;
  }

  return TimeVisibilityState.active;
}

TimeVisibilityState timedEventVisibility({
  required DateTime startDate,
  required DateTime endDate,
  TimeOfDay? startTime,
  TimeOfDay? endTime,
  DateTime? now,
}) {
  final nowValue = now ?? DateTime.now();

  final base = dateRangeVisibility(
    startDate: startDate,
    endDate: endDate,
    now: nowValue,
  );

  if (base == TimeVisibilityState.past || base == TimeVisibilityState.future) {
    return base;
  }

  final today = onlyDate(nowValue);
  final startDay = onlyDate(startDate);
  final endDay = onlyDate(endDate);

  if (startDay != endDay) {
    return TimeVisibilityState.active;
  }

  if (startTime == null && endTime == null) {
    return TimeVisibilityState.active;
  }

  if (endTime != null) {
    final eventEnd = atDayTime(today, endTime);
    if (!eventEnd.isAfter(nowValue)) {
      return TimeVisibilityState.past;
    }
  }

  if (startTime != null) {
    final eventStart = atDayTime(today, startTime);
    if (eventStart.isAfter(nowValue)) {
      return TimeVisibilityState.future;
    }
  }

  return TimeVisibilityState.active;
}

bool isPastDateRange({
  required DateTime startDate,
  required DateTime endDate,
  DateTime? now,
}) {
  return dateRangeVisibility(
        startDate: startDate,
        endDate: endDate,
        now: now,
      ) ==
      TimeVisibilityState.past;
}

bool isActiveDateRange({
  required DateTime startDate,
  required DateTime endDate,
  DateTime? now,
}) {
  return dateRangeVisibility(
        startDate: startDate,
        endDate: endDate,
        now: now,
      ) ==
      TimeVisibilityState.active;
}

bool isFutureDateRange({
  required DateTime startDate,
  required DateTime endDate,
  DateTime? now,
}) {
  return dateRangeVisibility(
        startDate: startDate,
        endDate: endDate,
        now: now,
      ) ==
      TimeVisibilityState.future;
}

bool isPastTimedEvent({
  required DateTime startDate,
  required DateTime endDate,
  TimeOfDay? startTime,
  TimeOfDay? endTime,
  DateTime? now,
}) {
  return timedEventVisibility(
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        now: now,
      ) ==
      TimeVisibilityState.past;
}

bool isActiveTimedEvent({
  required DateTime startDate,
  required DateTime endDate,
  TimeOfDay? startTime,
  TimeOfDay? endTime,
  DateTime? now,
}) {
  return timedEventVisibility(
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        now: now,
      ) ==
      TimeVisibilityState.active;
}

bool isFutureTimedEvent({
  required DateTime startDate,
  required DateTime endDate,
  TimeOfDay? startTime,
  TimeOfDay? endTime,
  DateTime? now,
}) {
  return timedEventVisibility(
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        now: now,
      ) ==
      TimeVisibilityState.future;
}
