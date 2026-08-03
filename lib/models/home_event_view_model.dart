import 'alice_special_event.dart';
import 'real_event.dart';

enum HomeEventSource { realEvent, aliceSpecialEvent }

enum HomeEventDateLabelStyle { none, dayMonth, dayMonthYear }

class HomeEventViewModel {
  final String id;
  final DateTime day;
  final DateTime startDay;
  final DateTime endDay;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final HomeEventSource source;
  final List<String> participants;
  final String title;
  final String category;
  final String? description;
  final bool isEditable;
  final bool ipsImpact;
  final RealEvent? realEventRecord;
  final AliceSpecialEvent? aliceSpecialEventRecord;

  const HomeEventViewModel({
    required this.id,
    required this.day,
    required this.startDay,
    required this.endDay,
    required this.startDateTime,
    required this.endDateTime,
    required this.source,
    required this.participants,
    required this.title,
    required this.category,
    required this.description,
    required this.isEditable,
    required this.ipsImpact,
    required this.realEventRecord,
    required this.aliceSpecialEventRecord,
  }) : assert(
         (source == HomeEventSource.realEvent &&
                 realEventRecord != null &&
                 aliceSpecialEventRecord == null) ||
             (source == HomeEventSource.aliceSpecialEvent &&
                 aliceSpecialEventRecord != null &&
                 realEventRecord == null),
       );

  int? get startMinuteOfDay => startDateTime == null
      ? null
      : startDateTime!.hour * 60 + startDateTime!.minute;

  int? get endMinuteOfDay =>
      endDateTime == null ? null : endDateTime!.hour * 60 + endDateTime!.minute;
}

class HomeEventViewModelBuilder {
  const HomeEventViewModelBuilder();

  HomeEventViewModel fromRealEvent({
    required RealEvent event,
    required DateTime day,
  }) {
    return HomeEventViewModel(
      id: event.id,
      day: _dateOnly(day),
      startDay: _dateOnly(event.startDate),
      endDay: _dateOnly(event.endDate),
      startDateTime: _combine(
        event.startDate,
        event.startTime?.hour,
        event.startTime?.minute,
      ),
      endDateTime: _combine(
        event.endDate,
        event.endTime?.hour,
        event.endTime?.minute,
      ),
      source: HomeEventSource.realEvent,
      participants: List.unmodifiable(
        event.effectiveParticipantKeys.map(_participantLabel),
      ),
      title: event.title,
      category: event.personKey == null || event.personKey!.trim().isEmpty
          ? 'Evento'
          : event.personKey!,
      description: event.notes,
      isEditable: true,
      ipsImpact: true,
      realEventRecord: event,
      aliceSpecialEventRecord: null,
    );
  }

  HomeEventViewModel fromAliceSpecialEvent({
    required AliceSpecialEvent event,
    required DateTime day,
  }) {
    return HomeEventViewModel(
      id: event.id,
      day: _dateOnly(day),
      startDay: _dateOnly(event.date),
      endDay: _dateOnly(event.date),
      startDateTime: _combine(event.date, event.start.hour, event.start.minute),
      endDateTime: _combine(event.date, event.end.hour, event.end.minute),
      source: HomeEventSource.aliceSpecialEvent,
      participants: const ['Alice'],
      title: event.label,
      category: 'Alice',
      description: event.note,
      isEditable: true,
      ipsImpact: true,
      realEventRecord: null,
      aliceSpecialEventRecord: event,
    );
  }

  List<HomeEventViewModel> forDay({
    required DateTime day,
    required Iterable<RealEvent> realEvents,
    required Iterable<AliceSpecialEvent> aliceSpecialEvents,
  }) {
    final normalizedDay = _dateOnly(day);
    final items = <HomeEventViewModel>[
      for (final event in realEvents)
        fromRealEvent(event: event, day: normalizedDay),
      for (final event in aliceSpecialEvents)
        if (event.enabled)
          fromAliceSpecialEvent(event: event, day: normalizedDay),
    ];

    items.sort(compareByTime);
    return List.unmodifiable(items);
  }

  static int compareByTime(HomeEventViewModel a, HomeEventViewModel b) {
    final aMinutes = a.startMinuteOfDay;
    final bMinutes = b.startMinuteOfDay;

    if (aMinutes != null && bMinutes != null) {
      final timeComparison = aMinutes.compareTo(bMinutes);
      if (timeComparison != 0) return timeComparison;
    } else if (aMinutes != null) {
      return -1;
    } else if (bMinutes != null) {
      return 1;
    }

    final titleComparison = a.title.toLowerCase().compareTo(
      b.title.toLowerCase(),
    );
    if (titleComparison != 0) return titleComparison;

    final sourceComparison = a.source.index.compareTo(b.source.index);
    if (sourceComparison != 0) return sourceComparison;
    return a.id.compareTo(b.id);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime? _combine(DateTime date, int? hour, int? minute) {
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String _participantLabel(String key) {
    switch (key) {
      case 'matteo':
        return 'Matteo';
      case 'chiara':
        return 'Chiara';
      case 'alice':
        return 'Alice';
      case 'sandra':
        return 'Sandra';
      case 'family':
        return 'Famiglia';
      default:
        return key;
    }
  }
}

class HomeEventGrouping {
  const HomeEventGrouping._();

  static Map<DateTime, List<HomeEventViewModel>> byDay(
    Iterable<HomeEventViewModel> events,
  ) {
    final sortedEvents = events.toList()
      ..sort((a, b) {
        final dayComparison = a.day.compareTo(b.day);
        if (dayComparison != 0) return dayComparison;
        return HomeEventViewModelBuilder.compareByTime(a, b);
      });

    final grouped = <DateTime, List<HomeEventViewModel>>{};
    for (final event in sortedEvents) {
      grouped.putIfAbsent(event.day, () => []).add(event);
    }

    return Map<DateTime, List<HomeEventViewModel>>.unmodifiable({
      for (final entry in grouped.entries)
        entry.key: List<HomeEventViewModel>.unmodifiable(entry.value),
    });
  }
}

class HomeEventFormatter {
  const HomeEventFormatter._();

  static const _weekdays = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  static const _months = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];

  static String time(HomeEventViewModel event) {
    final start = event.startDateTime;
    final end = event.endDateTime;
    if (start == null) return 'Tutto il giorno';
    if (end == null) return _time(start);
    return '${_time(start)}-${_time(end)}';
  }

  static String tileTime(
    HomeEventViewModel event, {
    HomeEventDateLabelStyle dateStyle = HomeEventDateLabelStyle.none,
  }) {
    final timeLabel = time(event);
    switch (dateStyle) {
      case HomeEventDateLabelStyle.none:
        return timeLabel;
      case HomeEventDateLabelStyle.dayMonth:
        return '${event.day.day}/${event.day.month} • $timeLabel';
      case HomeEventDateLabelStyle.dayMonthYear:
        return '${event.day.day}/${event.day.month}/${event.day.year} • $timeLabel';
    }
  }

  static String readableDay(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return '${_weekdays[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}';
  }

  static String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
