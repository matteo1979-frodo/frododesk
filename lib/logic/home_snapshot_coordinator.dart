import '../models/alice_special_event.dart';
import '../models/home_event_view_model.dart';
import '../models/home_observed_at.dart';
import '../models/home_snapshot.dart';
import '../models/promemoria.dart';
import '../models/real_event.dart';
import 'calendar/builders/alice_home_risk_view_model_builder.dart';
import 'calendar/builders/calendar_day_coverage_pipeline.dart';
import 'calendar/builders/calendar_day_status_builder.dart';
import 'calendar/models/calendar_day_status.dart';
import 'calendar/models/coverage_result_step_a.dart';
import 'core_store.dart';

class HomeSnapshotCoordinator {
  static const _monthNames = [
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

  static const _shortWeekdays = [
    'Lun',
    'Mar',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom',
  ];

  final CoreStore coreStore;
  final HomeEventViewModelBuilder eventBuilder;

  const HomeSnapshotCoordinator({
    required this.coreStore,
    this.eventBuilder = const HomeEventViewModelBuilder(),
  });

  HomeSnapshot build({required HomeObservedAt observedAt}) {
    final eventCatalogue = _buildEventCatalogue(observedAt);

    return HomeSnapshot(
      observedAt: observedAt,
      today: _buildToday(observedAt, eventCatalogue),
      globalEvents: _buildGlobalEvents(observedAt, eventCatalogue),
      systemStatus: _buildSystemStatus(observedAt),
    );
  }

  HomeTodaySnapshot _buildToday(
    HomeObservedAt observedAt,
    _HomeEventCatalogue eventCatalogue,
  ) {
    final reminders = coreStore.promemoriaStore.items.where(
      (reminder) => _isReminderVisibleToday(reminder, observedAt.day),
    );
    final grouped = <String, List<Promemoria>>{};

    for (final reminder in reminders) {
      grouped.putIfAbsent(reminder.persona, () => []).add(reminder);
    }

    final groups = grouped.entries.toList()
      ..sort((a, b) => _personaOrder(a.key).compareTo(_personaOrder(b.key)));
    final reminderGroups = List<HomeReminderGroupSnapshot>.unmodifiable(
      groups.map(
        (entry) => HomeReminderGroupSnapshot(
          persona: entry.key,
          count: entry.value.length,
          firstText: entry.value.first.testo,
        ),
      ),
    );

    return HomeTodaySnapshot(
      reminderGroups: reminderGroups,
      events: eventCatalogue.eventsForDay(observedAt.day),
      reminderCount: reminderGroups.fold(
        0,
        (count, group) => count + group.count,
      ),
    );
  }

  bool _isReminderVisibleToday(Promemoria reminder, DateTime today) {
    final created = _dateOnly(reminder.createdDay);
    final completed = reminder.completedDay == null
        ? null
        : _dateOnly(reminder.completedDay!);

    return !created.isAfter(today) && (!reminder.done || completed == today);
  }

  int _personaOrder(String persona) {
    switch (persona.toLowerCase()) {
      case 'matteo':
        return 0;
      case 'chiara':
        return 1;
      case 'alice':
        return 2;
      case 'famiglia':
        return 3;
      default:
        return 99;
    }
  }

  HomeGlobalEventsSnapshot _buildGlobalEvents(
    HomeObservedAt observedAt,
    _HomeEventCatalogue catalogue,
  ) {
    final years = <int, HomeYearEventsSnapshot>{};
    for (
      var year = observedAt.year - 10;
      year <= observedAt.year + 10;
      year++
    ) {
      years[year] = _buildYear(year, catalogue);
    }

    final futureDays = catalogue.days
        .where(
          (day) =>
              day.day.isAfter(observedAt.day) &&
              day.day.year == observedAt.year,
        )
        .toList(growable: false);

    return HomeGlobalEventsSnapshot(
      currentYear: observedAt.year,
      futureDaysUntilEndOfYear: List.unmodifiable(futureDays),
      currentYearEvents: years[observedAt.year]!,
      futureYears: List.unmodifiable([
        for (var offset = 1; offset <= 10; offset++)
          years[observedAt.year + offset]!,
      ]),
      pastYears: List.unmodifiable([
        for (var offset = 1; offset <= 10; offset++)
          years[observedAt.year - offset]!,
      ]),
      years: Map.unmodifiable(years),
    );
  }

  HomeYearEventsSnapshot _buildYear(int year, _HomeEventCatalogue catalogue) {
    final days = catalogue.days
        .where((day) => day.day.year == year)
        .toList(growable: false);
    final months = <HomeMonthEventsSnapshot>[];

    for (var month = 1; month <= 12; month++) {
      final monthDays = days
          .where((day) => day.day.month == month)
          .toList(growable: false);
      months.add(
        HomeMonthEventsSnapshot(
          year: year,
          month: month,
          name: _monthNames[month - 1],
          days: List.unmodifiable(monthDays),
          events: List.unmodifiable([
            for (final day in monthDays) ...day.events,
          ]),
        ),
      );
    }

    final realEventCount = coreStore.realEventStore.allEvents.where((event) {
      return event.startDate.year <= year && event.endDate.year >= year;
    }).length;
    final aliceEventCount = coreStore.aliceSpecialEventStore
        .allDates()
        .where((day) => day.year == year)
        .fold<int>(
          0,
          (count, day) =>
              count +
              coreStore.aliceSpecialEventStore
                  .eventsForDay(day)
                  .where((event) => event.enabled)
                  .length,
        );

    return HomeYearEventsSnapshot(
      year: year,
      eventCount: realEventCount + aliceEventCount,
      days: List.unmodifiable(days),
      events: List.unmodifiable([for (final day in days) ...day.events]),
      months: List.unmodifiable(months),
    );
  }

  _HomeEventCatalogue _buildEventCatalogue(HomeObservedAt observedAt) {
    final firstDay = DateTime(observedAt.year - 10, 1, 1);
    final lastDay = DateTime(observedAt.year + 10, 12, 31);
    final realEventsByDay = <DateTime, List<RealEvent>>{};
    final aliceEventsByDay = <DateTime, List<AliceSpecialEvent>>{};

    for (final event in coreStore.realEventStore.allEvents) {
      var day = _dateOnly(event.startDate);
      final eventEnd = _dateOnly(event.endDate);
      if (day.isBefore(firstDay)) day = firstDay;
      final end = eventEnd.isAfter(lastDay) ? lastDay : eventEnd;

      while (!day.isAfter(end)) {
        realEventsByDay.putIfAbsent(day, () => []).add(event);
        day = day.add(const Duration(days: 1));
      }
    }

    for (final rawDay in coreStore.aliceSpecialEventStore.allDates()) {
      final day = _dateOnly(rawDay);
      if (day.isBefore(firstDay) || day.isAfter(lastDay)) continue;
      aliceEventsByDay[day] = coreStore.aliceSpecialEventStore.eventsForDay(
        day,
      );
    }

    final eventDays = {
      ...realEventsByDay.keys,
      ...aliceEventsByDay.keys,
    }.toList()..sort();
    final days = <HomeEventDaySnapshot>[];
    final eventsByDay = <DateTime, List<HomeEventViewModel>>{};

    for (final day in eventDays) {
      final events = eventBuilder.forDay(
        day: day,
        realEvents: realEventsByDay[day] ?? const [],
        aliceSpecialEvents: aliceEventsByDay[day] ?? const [],
      );
      if (events.isEmpty) continue;

      eventsByDay[day] = events;
      days.add(
        HomeEventDaySnapshot(
          day: day,
          label: HomeEventFormatter.readableDay(day),
          events: events,
        ),
      );
    }

    return _HomeEventCatalogue(
      days: List.unmodifiable(days),
      eventsByDay: Map.unmodifiable(eventsByDay),
    );
  }

  HomeSystemStatusSnapshot _buildSystemStatus(HomeObservedAt observedAt) {
    final pipeline = CalendarDayCoveragePipeline(coreStore: coreStore);
    final todayCoverage = pipeline.build(
      selectedDay: observedAt.day,
      observedAt: observedAt.observedAt,
    );
    final todayRisk = const AliceHomeRiskViewModelBuilder().build(
      gapDetails: todayCoverage.gapDetails,
      selectedDay: observedAt.day,
      observedAt: observedAt.observedAt,
    );
    final todayStatus = const CalendarDayStatusBuilder().build(
      gapDetails: todayRisk.gapDetails,
      criticalityDetails: todayCoverage.criticalityDetails,
      hasLogisticGaps: false,
    );
    final hasTodayCoverageIssue = todayStatus == CalendarDayStatus.problem;
    final nextIssue = _nextCoverageIssueIn30Days(
      observedAt: observedAt,
      pipeline: pipeline,
    );

    final stateText = hasTodayCoverageIssue
        ? '✋ Problema oggi'
        : '😌 Sistema stabilizzato';
    final mainSentence = hasTodayCoverageIssue
        ? 'Oggi: Alice non coperta'
        : 'Nessuna criticità oggi';

    late final String systemDetail;
    if (hasTodayCoverageIssue) {
      final first = todayRisk.gapDetails.first;
      systemDetail =
          'Copertura: Alice scoperta oggi ${_formatTime(first.start.hour, first.start.minute)}–${_formatTime(first.end.hour, first.end.minute)}';
    } else if (nextIssue != null) {
      final first = nextIssue.coverage.gapDetails.first;
      final weekday = _shortWeekdays[nextIssue.day.weekday - 1];
      systemDetail =
          'Prossimo problema: $weekday ${nextIssue.day.day}/${nextIssue.day.month} • ${_formatTime(first.start.hour, first.start.minute)}–${_formatTime(first.end.hour, first.end.minute)}';
    } else {
      systemDetail = 'Nessuna criticità prevista';
    }

    return HomeSystemStatusSnapshot(
      hasTodayCoverageIssue: hasTodayCoverageIssue,
      stateText: stateText,
      mainSentence: mainSentence,
      systemDetail: systemDetail,
    );
  }

  ({DateTime day, CoverageResultStepA coverage})? _nextCoverageIssueIn30Days({
    required HomeObservedAt observedAt,
    required CalendarDayCoveragePipeline pipeline,
  }) {
    for (var offset = 1; offset <= 30; offset++) {
      final day = observedAt.day.add(Duration(days: offset));
      final coverage = pipeline.build(
        selectedDay: day,
        observedAt: observedAt.observedAt,
      );
      if (!coverage.ok) return (day: day, coverage: coverage);
    }
    return null;
  }

  String _formatTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _HomeEventCatalogue {
  final List<HomeEventDaySnapshot> days;
  final Map<DateTime, List<HomeEventViewModel>> eventsByDay;

  const _HomeEventCatalogue({required this.days, required this.eventsByDay});

  List<HomeEventViewModel> eventsForDay(DateTime day) =>
      eventsByDay[DateTime(day.year, day.month, day.day)] ?? const [];
}
