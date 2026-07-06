import '../../logic/core_store.dart';

class CalendarDayContext {
  final CoreStore coreStore;
  final DateTime selectedDay;
  final DateTime realNow;

  const CalendarDayContext({
    required this.coreStore,
    required this.selectedDay,
    required this.realNow,
  });

  DateTime get day =>
      DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

  DateTime get nowOnSelectedDay => DateTime(
    day.year,
    day.month,
    day.day,
    realNow.hour,
    realNow.minute,
    realNow.second,
    realNow.millisecond,
    realNow.microsecond,
  );

  bool get isToday {
    final today = DateTime(realNow.year, realNow.month, realNow.day);
    return day == today;
  }
}
