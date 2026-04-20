bool isItalianHoliday(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);

  final isFixedHoliday =
      (d.month == 1 && d.day == 1) ||
      (d.month == 1 && d.day == 6) ||
      (d.month == 4 && d.day == 25) ||
      (d.month == 5 && d.day == 1) ||
      (d.month == 6 && d.day == 2) ||
      (d.month == 8 && d.day == 15) ||
      (d.month == 11 && d.day == 1) ||
      (d.month == 12 && d.day == 8) ||
      (d.month == 12 && d.day == 25) ||
      (d.month == 12 && d.day == 26);

  if (isFixedHoliday) return true;

  final easter = _calculateEasterSunday(d.year);
  final easterMonday = easter.add(const Duration(days: 1));

  final isEaster =
      d.year == easter.year && d.month == easter.month && d.day == easter.day;

  final isEasterMonday =
      d.year == easterMonday.year &&
      d.month == easterMonday.month &&
      d.day == easterMonday.day;

  return isEaster || isEasterMonday;
}

DateTime _calculateEasterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;

  return DateTime(year, month, day);
}
