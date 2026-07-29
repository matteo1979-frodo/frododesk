class RecoveryWindowPolicy {
  const RecoveryWindowPolicy();

  DateTime recoveryEndForDay(DateTime day) {
    return DateTime(day.year, day.month, day.day).add(const Duration(days: 1));
  }
}
