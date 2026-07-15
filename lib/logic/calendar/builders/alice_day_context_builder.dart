import 'package:flutter/material.dart';

import '../../alice_event_store.dart';
import '../../core_store.dart';
import '../models/alice_day_context.dart';
import '../view_models/alice_now_event_view_model.dart';

class AliceDayContextBuilder {
  final CoreStore coreStore;

  const AliceDayContextBuilder(this.coreStore);

  AliceDayContext build(DateTime day) {
    final normalizedDay = _onlyDate(day);
    final events = <AliceNowEventViewModel>[];

    final period = coreStore.aliceEventStore.getEventForDay(normalizedDay);

    final dayStateLabel = _dayStateLabel(period?.type);

    final isSummerCampDay =
        period?.type == AliceEventType.summerCamp;

    final isSchoolDay =
        period == null && _hasConfiguredSchoolOnDay(normalizedDay);

    if (isSchoolDay) {
      events.add(
        AliceNowEventViewModel(
          title: 'Scuola',
          start: _effectiveSchoolStart(normalizedDay),
          end:
              _effectiveEarlySchoolExit(normalizedDay) ??
              _effectiveSchoolOutEnd(normalizedDay),
        ),
      );
    }

    if (isSummerCampDay) {
      events.add(
        AliceNowEventViewModel(
          title: 'Centro estivo',
          start:
              period?.summerCampStart ??
              const TimeOfDay(hour: 8, minute: 30),
          end:
              period?.summerCampEnd ??
              const TimeOfDay(hour: 16, minute: 30),
        ),
      );
    }

    final specialEvents = coreStore.aliceSpecialEventStore.eventsForDay(
      normalizedDay,
    );

    for (final event in specialEvents) {
      events.add(
        AliceNowEventViewModel(
          title: event.label,
          start: event.start,
          end: event.end,
        ),
      );
    }

    final realEvents = coreStore.realEventStore
        .eventsForDay(normalizedDay)
        .where((event) => event.involvesPerson('alice'));

    for (final event in realEvents) {
      events.add(
        AliceNowEventViewModel(
          title: event.title,
          start: event.startTime,
          end: event.endTime,
        ),
      );
    }

    events.sort(_compareEventsByStartTime);

    return AliceDayContext(
      dayStateLabel: dayStateLabel,
      isSchoolDay: isSchoolDay,
      isSummerCampDay: isSummerCampDay,
      events: events,
    );
  }

  String? _dayStateLabel(AliceEventType? type) {
    switch (type) {
      case AliceEventType.schoolNormal:
        return 'Scuola';
      case AliceEventType.vacation:
        return 'Vacanza';
      case AliceEventType.schoolClosure:
        return 'Scuola chiusa';
      case AliceEventType.sickness:
        return 'Malattia';
      case AliceEventType.summerCamp:
        return 'Centro estivo';
      case null:
        return null;
    }
  }

  bool _hasConfiguredSchoolOnDay(DateTime day) {
    final config = coreStore.schoolStore
        .activePeriodForDay(day)
        ?.weekConfig
        .forWeekday(day.weekday);

    return config?.enabled ?? false;
  }

  TimeOfDay _effectiveSchoolStart(DateTime day) {
    final config = coreStore.schoolStore
        .activePeriodForDay(day)
        ?.weekConfig
        .forWeekday(day.weekday);

    if (config == null || !config.enabled) {
      return const TimeOfDay(hour: 8, minute: 25);
    }

    return TimeOfDay(
      hour: config.entryMinutes ~/ 60,
      minute: config.entryMinutes % 60,
    );
  }

  TimeOfDay? _effectiveEarlySchoolExit(DateTime day) {
    final customTime = coreStore.daySettingsStore
        .uscitaAnticipataTimeForDay(day);

    if (customTime != null) {
      return customTime;
    }

    if (coreStore.settingsStore.isUscita13) {
      return coreStore.settingsStore.uscitaAnticipataDefaultTime;
    }

    return null;
  }

  TimeOfDay _effectiveSchoolOutEnd(DateTime day) {
    final customTime = coreStore.daySettingsStore.schoolOutEndForDay(day);

    if (customTime != null) {
      return customTime;
    }

    final config = coreStore.schoolStore
        .activePeriodForDay(day)
        ?.weekConfig
        .forWeekday(day.weekday);

    if (config == null || !config.enabled) {
      return const TimeOfDay(hour: 16, minute: 45);
    }

    final returnMinutes = config.returnHomeMinutes;

    return TimeOfDay(
      hour: returnMinutes ~/ 60,
      minute: returnMinutes % 60,
    );
  }

  int _compareEventsByStartTime(
    AliceNowEventViewModel first,
    AliceNowEventViewModel second,
  ) {
    final firstMinutes = first.start == null
        ? 9999
        : first.start!.hour * 60 + first.start!.minute;

    final secondMinutes = second.start == null
        ? 9999
        : second.start!.hour * 60 + second.start!.minute;

    return firstMinutes.compareTo(secondMinutes);
  }

  DateTime _onlyDate(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }
}