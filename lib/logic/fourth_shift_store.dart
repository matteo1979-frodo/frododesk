import '../models/fourth_shift_period.dart';
import '../models/day_override.dart';

class FourthShiftStore {
  final List<FourthShiftPeriod> _periods = [];

  List<FourthShiftPeriod> get all => List.unmodifiable(_periods);

  void addPeriod(FourthShiftPeriod period) {
    _periods.add(period);
    _sortPeriods();
  }

  void removePeriod(FourthShiftPeriod period) {
    _periods.remove(period);
  }

  void removeAt(int index) {
    if (index < 0 || index >= _periods.length) return;
    _periods.removeAt(index);
  }

  void replacePeriod(FourthShiftPeriod oldPeriod, FourthShiftPeriod newPeriod) {
    final index = _periods.indexOf(oldPeriod);
    if (index == -1) return;

    _periods[index] = newPeriod;
    _sortPeriods();
  }

  List<FourthShiftPeriod> periodsForPerson(String personId) {
    return _periods.where((p) => p.personId == personId).toList();
  }

  FourthShiftPeriod? activePeriodForPersonOnDay(String personId, DateTime day) {
    final d = _normalizeDay(day);

    for (final period in _periods) {
      if (period.personId != personId) continue;
      if (period.containsDay(d)) return period;
    }

    return null;
  }

  bool isActiveForPersonOnDay(String personId, DateTime day) {
    return activePeriodForPersonOnDay(personId, day) != null;
  }

  void clearAll() {
    _periods.clear();
  }

  DateTime _normalizeDay(DateTime day) {
    final k = dayKey(day);
    return DateTime(k.year, k.month, k.day);
  }

  void _sortPeriods() {
    _periods.sort((a, b) {
      final byPerson = a.personId.compareTo(b.personId);
      if (byPerson != 0) return byPerson;

      return a.startDate.compareTo(b.startDate);
    });
  }
}
