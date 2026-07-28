import 'package:flutter/material.dart';

import '../../alice_event_store.dart';
import '../../core_store.dart';
import '../models/alice_day_context.dart';
import '../view_models/alice_now_event_view_model.dart';
import 'effective_school_day_timing_reader.dart';

class AliceDayContextBuilder {
  final CoreStore coreStore;

  const AliceDayContextBuilder(this.coreStore);

  AliceDayContext build(DateTime day) {
    final normalizedDay = _onlyDate(day);
    final events = <AliceNowEventViewModel>[];

    final period = coreStore.aliceEventStore.getEventForDay(normalizedDay);
    final schoolTiming = EffectiveSchoolDayTimingReader(
      coreStore,
    ).read(normalizedDay);

    final dayStateLabel = _dayStateLabel(period?.type);

    final isSummerCampDay =
        period?.type == AliceEventType.summerCamp;

    final isSchoolDay =
        period == null && _hasConfiguredSchoolOnDay(normalizedDay);

    if (isSchoolDay) {
      events.add(
        AliceNowEventViewModel(
          title: 'Scuola',
          start: schoolTiming.schoolEntryAt,
          end:
              schoolTiming.earlySchoolExitAt ??
              schoolTiming.schoolPickupWindowEnd,
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
