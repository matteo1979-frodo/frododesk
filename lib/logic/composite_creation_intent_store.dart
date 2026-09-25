import 'dart:convert';

import '../models/composite_creation_intent.dart';
import 'persistence_store.dart';

class CompositeCreationIntentStore {
  static const storageKey = 'composite_creation_intents_v1';
  final List<CompositeCreationIntent> _intents = [];

  List<CompositeCreationIntent> get intents => List.unmodifiable(_intents);

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(storageKey);
    _intents
      ..clear()
      ..addAll(raw == null || raw.isEmpty
          ? const []
          : (jsonDecode(raw) as List).map((item) => CompositeCreationIntent.fromJson(Map<String, dynamic>.from(item as Map))));
  }

  Future<void> save(CompositeCreationIntent intent) async {
    final index = _intents.indexWhere((item) => item.operationId == intent.operationId);
    final next = [..._intents];
    if (index < 0) {
      next.add(intent);
    } else {
      next[index] = intent;
    }
    final value = jsonEncode(next.map((item) => item.toJson()).toList());
    final result = await PersistenceStore.saveStringVerified(storageKey, value);
    if (!result.matches(value)) throw StateError('Composite intent write failed');
    _intents
      ..clear()
      ..addAll(next);
  }

  CompositeCreationIntent? find(String operationId) {
    for (final intent in _intents) {
      if (intent.operationId == operationId) return intent;
    }
    return null;
  }
}
