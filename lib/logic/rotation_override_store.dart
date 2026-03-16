import 'package:flutter/foundation.dart';
import '../models/rotation_override.dart';
import '../models/turn_override.dart';

class RotationOverrideStore extends ChangeNotifier {
  final List<RotationOverride> _items = [];

  List<RotationOverride> get items => List.unmodifiable(_items);

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  void add(RotationOverride item) {
    _items.add(item);
    notifyListeners();
  }

  void remove(RotationOverride item) {
    _items.remove(item);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }

  RotationOverride? activeFor({
    required TurnPersonId person,
    required DateTime day,
  }) {
    final d0 = _dayKey(day);

    RotationOverride? best;

    for (final item in _items) {
      if (item.person != person) continue;

      final start = _dayKey(item.startDate);
      if (d0.isBefore(start)) continue;

      if (best == null) {
        best = item;
        continue;
      }

      final bestStart = _dayKey(best.startDate);
      if (start.isAfter(bestStart)) {
        best = item;
      }
    }

    return best;
  }
}
