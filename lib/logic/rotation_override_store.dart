import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/rotation_override.dart';
import '../models/turn_override.dart';
import 'persistence_store.dart';

class RotationOverrideStore extends ChangeNotifier {
  static const String _storageKey = 'rotation_override_store_v1';

  final List<RotationOverride> _items = [];

  List<RotationOverride> get items => List.unmodifiable(_items);

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _items.clear();

      for (final item in decoded) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);

        final personRaw = map['person'];
        final startDateRaw = map['startDate'];
        final startPointRaw = map['startPoint'];

        if (personRaw is! String ||
            startDateRaw is! String ||
            startPointRaw is! String) {
          continue;
        }

        final person = _personFromString(personRaw);
        final startPoint = _startPointFromString(startPointRaw);

        if (person == null || startPoint == null) continue;

        try {
          _items.add(
            RotationOverride(
              person: person,
              startDate: DateTime.parse(startDateRaw),
              startPoint: startPoint,
            ),
          );
        } catch (_) {
          // record non valido: ignorato
        }
      }

      _sortItems();
      notifyListeners();
    } catch (_) {
      // dati corrotti: ignorati
    }
  }

  Future<void> _save() async {
    final data = _items
        .map(
          (item) => {
            'person': _personToString(item.person),
            'startDate': _dayKey(item.startDate).toIso8601String(),
            'startPoint': _startPointToString(item.startPoint),
          },
        )
        .toList();

    await PersistenceStore.saveString(_storageKey, jsonEncode(data));
  }

  void add(RotationOverride item) {
    _items.add(item);
    _sortItems();
    _save();
    notifyListeners();
  }

  void remove(RotationOverride item) {
    _items.remove(item);
    _save();
    notifyListeners();
  }

  bool removeActiveFor({required TurnPersonId person, required DateTime day}) {
    final active = activeFor(person: person, day: day);
    if (active == null) return false;

    _items.remove(active);
    _save();
    notifyListeners();
    return true;
  }

  void clearAll() {
    _items.clear();
    _save();
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

  void _sortItems() {
    _items.sort((a, b) {
      final byPerson = _personToString(
        a.person,
      ).compareTo(_personToString(b.person));
      if (byPerson != 0) return byPerson;

      return _dayKey(a.startDate).compareTo(_dayKey(b.startDate));
    });
  }

  TurnPersonId? _personFromString(String value) {
    switch (value) {
      case 'matteo':
        return TurnPersonId.matteo;
      case 'chiara':
        return TurnPersonId.chiara;
    }
  }

  String _personToString(TurnPersonId person) {
    switch (person) {
      case TurnPersonId.matteo:
        return 'matteo';
      case TurnPersonId.chiara:
        return 'chiara';
    }
  }

  RotationStartPoint? _startPointFromString(String value) {
    switch (value) {
      case 'mattina':
        return RotationStartPoint.mattina;
      case 'pomeriggio':
        return RotationStartPoint.pomeriggio;
      case 'notte':
        return RotationStartPoint.notte;
    }
  }

  String _startPointToString(RotationStartPoint value) {
    switch (value) {
      case RotationStartPoint.mattina:
        return 'mattina';
      case RotationStartPoint.pomeriggio:
        return 'pomeriggio';
      case RotationStartPoint.notte:
        return 'notte';
    }
  }
}
