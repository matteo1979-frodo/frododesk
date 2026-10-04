import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/turn_override.dart';
import 'persistence_store.dart';

typedef TurnOverrideStoreLoadString = Future<String?> Function(String key);
typedef TurnOverrideStoreSaveString =
    Future<void> Function(String key, String value);

class TurnOverrideStore extends ChangeNotifier {
  static const String _storageKey = 'turn_override_store_v1';

  final List<TurnOverride> _items = [];
  final TurnOverrideStoreLoadString _loadString;
  final TurnOverrideStoreSaveString _saveString;
  Future<void> _saveQueue = Future<void>.value();

  TurnOverrideStore({
    TurnOverrideStoreLoadString? loadString,
    TurnOverrideStoreSaveString? saveString,
  }) : _loadString = loadString ?? PersistenceStore.loadString,
       _saveString = saveString ?? PersistenceStore.saveString;

  List<TurnOverride> get items => List.unmodifiable(_items);

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> load() async {
    final raw = await _loadString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final loaded = <TurnOverride>[];
      for (final value in decoded) {
        final item = _decodeItem(value);
        if (item != null) loaded.add(item);
      }

      _items
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    } catch (_) {
      // Dati corrotti o incompatibili non devono impedire l'avvio dell'app.
    }
  }

  Future<void> add(TurnOverride item) {
    _items.add(item);
    notifyListeners();
    return _save();
  }

  Future<void> setDailyOverride({
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
    return _save();
  }

  Future<void> setPeriodOverride({
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
    return _save();
  }

  Future<void> remove(TurnOverride item) {
    _items.remove(item);
    notifyListeners();
    return _save();
  }

  Future<void> clearAll() {
    _items.clear();
    notifyListeners();
    return _save();
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

  Future<void> _save() {
    final snapshot = jsonEncode(_items.map(_encodeItem).toList());
    final write = _saveQueue.then((_) => _saveString(_storageKey, snapshot));
    _saveQueue = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }

  Map<String, dynamic> _encodeItem(TurnOverride item) => {
    'type': _typeToString(item.type),
    'person': _personToString(item.person),
    'startDate': _dateToString(item.startDate),
    'endDate': item.endDate == null ? null : _dateToString(item.endDate!),
    'shift': item.shift == null ? null : _shiftToString(item.shift!),
    'rotationIndex': item.rotationIndex,
  };

  TurnOverride? _decodeItem(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);

    final typeRaw = map['type'];
    final personRaw = map['person'];
    final startRaw = map['startDate'];
    final endRaw = map['endDate'];
    final shiftRaw = map['shift'];
    final rotationIndexRaw = map['rotationIndex'];

    if (typeRaw is! String ||
        personRaw is! String ||
        startRaw is! String ||
        (endRaw != null && endRaw is! String) ||
        (shiftRaw != null && shiftRaw is! String) ||
        (rotationIndexRaw != null && rotationIndexRaw is! int)) {
      return null;
    }

    final type = _typeFromString(typeRaw);
    final person = _personFromString(personRaw);
    final startDate = _dateFromString(startRaw);
    final endDate = endRaw == null ? null : _dateFromString(endRaw);
    final shift = shiftRaw == null ? null : _shiftFromString(shiftRaw);

    if (type == null || person == null || startDate == null) return null;
    if (endRaw != null && endDate == null) return null;
    if (shiftRaw != null && shift == null) return null;

    if (type == TurnOverrideType.dailyShiftChange && shift == null) {
      return null;
    }
    if (type == TurnOverrideType.periodShiftChange &&
        (shift == null || endDate == null || endDate.isBefore(startDate))) {
      return null;
    }

    return TurnOverride(
      type: type,
      person: person,
      startDate: startDate,
      endDate: endDate,
      shift: shift,
      rotationIndex: rotationIndexRaw,
    );
  }

  String _dateToString(DateTime value) {
    final date = _dayKey(value);
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime? _dateFromString(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  TurnOverrideType? _typeFromString(String value) {
    switch (value) {
      case 'dailyShiftChange':
        return TurnOverrideType.dailyShiftChange;
      case 'periodShiftChange':
        return TurnOverrideType.periodShiftChange;
      case 'rotationProfileChange':
        return TurnOverrideType.rotationProfileChange;
    }
    return null;
  }

  String _typeToString(TurnOverrideType value) {
    switch (value) {
      case TurnOverrideType.dailyShiftChange:
        return 'dailyShiftChange';
      case TurnOverrideType.periodShiftChange:
        return 'periodShiftChange';
      case TurnOverrideType.rotationProfileChange:
        return 'rotationProfileChange';
    }
  }

  TurnPersonId? _personFromString(String value) {
    switch (value) {
      case 'matteo':
        return TurnPersonId.matteo;
      case 'chiara':
        return TurnPersonId.chiara;
    }
    return null;
  }

  String _personToString(TurnPersonId value) {
    switch (value) {
      case TurnPersonId.matteo:
        return 'matteo';
      case TurnPersonId.chiara:
        return 'chiara';
    }
  }

  TurnOverrideShift? _shiftFromString(String value) {
    switch (value) {
      case 'mattina':
        return TurnOverrideShift.mattina;
      case 'pomeriggio':
        return TurnOverrideShift.pomeriggio;
      case 'notte':
        return TurnOverrideShift.notte;
      case 'giornata':
        return TurnOverrideShift.giornata;
      case 'off':
        return TurnOverrideShift.off;
    }
    return null;
  }

  String _shiftToString(TurnOverrideShift value) {
    switch (value) {
      case TurnOverrideShift.mattina:
        return 'mattina';
      case TurnOverrideShift.pomeriggio:
        return 'pomeriggio';
      case TurnOverrideShift.notte:
        return 'notte';
      case TurnOverrideShift.giornata:
        return 'giornata';
      case TurnOverrideShift.off:
        return 'off';
    }
  }
}
