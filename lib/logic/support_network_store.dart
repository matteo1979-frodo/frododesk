import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/support_person.dart';
import 'persistence_store.dart';

class SupportNetworkStore {
  static const String _peopleKey = 'support_network_people_v1';
  static const String _namesKey = 'support_network_saved_names_v1';

  final List<SupportPerson> _people = [];
  final List<String> _savedNames = [];

  List<SupportPerson> get people => List.unmodifiable(_people);
  List<String> get savedNames => List.unmodifiable(_savedNames);

  // --------------------------------------------------
  // LOAD
  // --------------------------------------------------

  Future<void> load() async {
    await _loadPeople();
    await _loadNames();
  }

  Future<void> _loadPeople() async {
    final raw = await PersistenceStore.loadString(_peopleKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _people.clear();

      for (final item in decoded) {
        if (item is! Map) continue;

        final id = item['id'];
        final name = item['name'];
        final enabled = item['enabled'];
        final startMin = item['startMin'];
        final endMin = item['endMin'];

        if (id is! String ||
            name is! String ||
            enabled is! bool ||
            startMin is! int ||
            endMin is! int) {
          continue;
        }

        final start = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
        final end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);

        _people.add(
          SupportPerson(
            id: id,
            name: name,
            enabled: enabled,
            start: start,
            end: end,
          ),
        );
      }
    } catch (_) {
      // dati corrotti ignorati
    }
  }

  Future<void> _loadNames() async {
    final raw = await PersistenceStore.loadStringList(_namesKey);
    if (raw == null) return;

    _savedNames
      ..clear()
      ..addAll(raw);
  }

  // --------------------------------------------------
  // SAVE
  // --------------------------------------------------

  Future<void> _savePeople() async {
    final data = _people
        .map(
          (p) => {
            'id': p.id,
            'name': p.name,
            'enabled': p.enabled,
            'startMin': p.start.hour * 60 + p.start.minute,
            'endMin': p.end.hour * 60 + p.end.minute,
          },
        )
        .toList();

    await PersistenceStore.saveString(_peopleKey, jsonEncode(data));
  }

  Future<void> _saveNames() async {
    await PersistenceStore.saveStringList(_namesKey, _savedNames);
  }

  // --------------------------------------------------
  // PEOPLE
  // --------------------------------------------------

  void addPerson(SupportPerson person) {
    _people.add(person);
    saveName(person.name);
    _savePeople();
  }

  void updatePerson(String id, SupportPerson updated) {
    final index = _people.indexWhere((p) => p.id == id);
    if (index == -1) return;

    _people[index] = updated;
    saveName(updated.name);
    _savePeople();
  }

  void removePerson(String id) {
    _people.removeWhere((p) => p.id == id);
    _savePeople();
  }

  // --------------------------------------------------
  // SAVED NAMES
  // --------------------------------------------------

  void saveName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final exists = _savedNames.any(
      (n) => n.toLowerCase() == clean.toLowerCase(),
    );
    if (exists) return;

    _savedNames.add(clean);
    _savedNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    _saveNames();
  }

  void removeSavedName(String name) {
    _savedNames.removeWhere(
      (n) => n.toLowerCase() == name.trim().toLowerCase(),
    );

    _saveNames();
  }
}
