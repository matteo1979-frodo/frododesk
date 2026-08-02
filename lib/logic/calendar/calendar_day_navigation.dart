class CalendarDayNavigation {
  const CalendarDayNavigation();

  DateTime previous(DateTime selectedDay) =>
      _onlyDate(selectedDay).subtract(const Duration(days: 1));

  DateTime next(DateTime selectedDay) =>
      _onlyDate(selectedDay).add(const Duration(days: 1));

  DateTime _onlyDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
