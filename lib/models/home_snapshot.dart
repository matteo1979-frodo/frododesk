import 'home_event_view_model.dart';
import 'home_observed_at.dart';

class HomeReminderGroupSnapshot {
  final String persona;
  final int count;
  final String firstText;

  const HomeReminderGroupSnapshot({
    required this.persona,
    required this.count,
    required this.firstText,
  });

  int get additionalCount => count - 1;
  bool get hasAdditionalItems => additionalCount > 0;
}

class HomeTodaySnapshot {
  final List<HomeReminderGroupSnapshot> reminderGroups;
  final List<HomeEventViewModel> events;
  final int reminderCount;

  const HomeTodaySnapshot({
    required this.reminderGroups,
    required this.events,
    required this.reminderCount,
  });

  int get eventCount => events.length;
  int get peopleCount => reminderGroups.length;
  bool get isEmpty => reminderGroups.isEmpty && events.isEmpty;
  bool get showReminders => reminderGroups.isNotEmpty;
  bool get showEvents => events.isNotEmpty;
}

class HomeEventDaySnapshot {
  final DateTime day;
  final String label;
  final List<HomeEventViewModel> events;

  const HomeEventDaySnapshot({
    required this.day,
    required this.label,
    required this.events,
  });
}

class HomeMonthEventsSnapshot {
  final int year;
  final int month;
  final String name;
  final List<HomeEventDaySnapshot> days;
  final List<HomeEventViewModel> events;

  const HomeMonthEventsSnapshot({
    required this.year,
    required this.month,
    required this.name,
    required this.days,
    required this.events,
  });

  int get eventCount => events.length;
  bool get hasEvents => events.isNotEmpty;
}

class HomeYearEventsSnapshot {
  final int year;
  final int eventCount;
  final List<HomeEventDaySnapshot> days;
  final List<HomeEventViewModel> events;
  final List<HomeMonthEventsSnapshot> months;

  const HomeYearEventsSnapshot({
    required this.year,
    required this.eventCount,
    required this.days,
    required this.events,
    required this.months,
  });

  bool get hasEvents => eventCount > 0;

  HomeMonthEventsSnapshot month(int value) => months[value - 1];
}

class HomeGlobalEventsSnapshot {
  final int currentYear;
  final List<HomeEventDaySnapshot> futureDaysUntilEndOfYear;
  final HomeYearEventsSnapshot currentYearEvents;
  final List<HomeYearEventsSnapshot> futureYears;
  final List<HomeYearEventsSnapshot> pastYears;
  final Map<int, HomeYearEventsSnapshot> years;

  const HomeGlobalEventsSnapshot({
    required this.currentYear,
    required this.futureDaysUntilEndOfYear,
    required this.currentYearEvents,
    required this.futureYears,
    required this.pastYears,
    required this.years,
  });

  int get futureDayCount => futureDaysUntilEndOfYear.length;

  HomeYearEventsSnapshot year(int value) => years[value]!;
}

class HomeSystemStatusSnapshot {
  final bool hasTodayCoverageIssue;
  final String stateText;
  final String mainSentence;
  final String systemDetail;

  const HomeSystemStatusSnapshot({
    required this.hasTodayCoverageIssue,
    required this.stateText,
    required this.mainSentence,
    required this.systemDetail,
  });
}

class HomeSnapshot {
  final HomeObservedAt observedAt;
  final HomeTodaySnapshot today;
  final HomeGlobalEventsSnapshot globalEvents;
  final HomeSystemStatusSnapshot systemStatus;

  const HomeSnapshot({
    required this.observedAt,
    required this.today,
    required this.globalEvents,
    required this.systemStatus,
  });
}
