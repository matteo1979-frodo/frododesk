// lib/logic/turn_override_store.dart

import 'package:flutter/foundation.dart';
import '../models/turn_override.dart';

class TurnOverrideStore extends ChangeNotifier {
  final List<TurnOverride> _items = [];

  List<TurnOverride> get items => List.unmodifiable(_items);

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  void add(TurnOverride item) {
    _items.add(item);
    notifyListeners();
  }

  void setDailyOverride({
    required TurnPersonId person,
    required DateTime day,
    required TurnOverrideShift newShift,
  }) {
    final d0 = _dayKey(day);

    _items.removeWhere(
      (e) =>
          e.person == person &&
          e.type == TurnOverrideType.dailyShiftChange &&
          _dayKey(e.startDate) == d0,
    );

    _items.add(
      TurnOverride(
        type: TurnOverrideType.dailyShiftChange,
        person: person,
        startDate: d0,
        shift: newShift,
      ),
    );

    notifyListeners();
  }

  void setPeriodOverride({
    required TurnPersonId person,
    required DateTime startDay,
    required DateTime endDay,
    required TurnOverrideShift newShift,
  }) {
    final start = _dayKey(startDay);
    final end = _dayKey(endDay);

    _items.removeWhere(
      (e) =>
          e.person == person &&
          e.type == TurnOverrideType.periodShiftChange &&
          e.startDate == start &&
          e.endDate == end,
    );

    _items.add(
      TurnOverride(
        type: TurnOverrideType.periodShiftChange,
        person: person,
        startDate: start,
        endDate: end,
        shift: newShift,
      ),
    );

    notifyListeners();
  }

  void remove(TurnOverride item) {
    _items.remove(item);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }

  List<TurnOverride> forPerson(TurnPersonId person) {
    return _items.where((e) => e.person == person).toList();
  }

  List<TurnOverride> activeOnDay({
    required TurnPersonId person,
    required DateTime day,
  }) {
    final d0 = _dayKey(day);

    return _items.where((e) {
      if (e.person != person) return false;
      return e.isActiveOn(d0);
    }).toList();
  }

  TurnOverride? dailyOverrideFor({
    required TurnPersonId person,
    required DateTime day,
  }) {
    final d0 = _dayKey(day);

    for (final item in _items.reversed) {
      if (item.person != person) continue;
      if (item.type != TurnOverrideType.dailyShiftChange) continue;
      if (item.isActiveOn(d0)) return item;
    }

    return null;
  }

  TurnOverride? periodOverrideFor({
    required TurnPersonId person,
    required DateTime day,
  }) {
    final d0 = _dayKey(day);

    for (final item in _items.reversed) {
      if (item.person != person) continue;
      if (item.type != TurnOverrideType.periodShiftChange) continue;
      if (item.isActiveOn(d0)) return item;
    }

    return null;
  }

  TurnOverride? rotationOverrideFor({
    required TurnPersonId person,
    required DateTime day,
  }) {
    final d0 = _dayKey(day);

    for (final item in _items.reversed) {
      if (item.person != person) continue;
      if (item.type != TurnOverrideType.rotationProfileChange) continue;

      final start = _dayKey(item.startDate);
      if (!d0.isBefore(start)) return item;
    }

    return null;
  }
}
