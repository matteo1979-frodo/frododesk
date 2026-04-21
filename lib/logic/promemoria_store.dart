import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/promemoria.dart';

class PromemoriaStore {
  static const String _prefsKey = 'promemoria_giorno';

  final List<Promemoria> _items = [];

  List<Promemoria> get items => List.unmodifiable(_items);

  List<Promemoria> itemsFor(String persona) {
    return _items.where((p) => p.persona == persona).toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);

    _items.clear();

    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        _items.add(Promemoria.fromJson(item));
      } else if (item is Map) {
        _items.add(Promemoria.fromJson(Map<String, dynamic>.from(item)));
      }
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> add({
    required String persona,
    required String testo,
    required DateTime day,
  }) async {
    _items.add(
      Promemoria(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        persona: persona,
        testo: testo,
        done: false,
        day: DateTime(day.year, day.month, day.day),
      ),
    );
    await save();
  }

  Future<void> update(Promemoria updated) async {
    final index = _items.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;

    _items[index] = updated;
    await save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((p) => p.id == id);
    await save();
  }

  Future<void> toggleDone(String id, bool done) async {
    final index = _items.indexWhere((p) => p.id == id);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(done: done);
    await save();
  }
}
