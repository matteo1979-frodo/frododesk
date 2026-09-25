import 'package:flutter/foundation.dart';

import '../logic/persistence_store.dart';
import '../models/continuing_service_relationship.dart';

class ContinuingServiceRelationshipStore extends ChangeNotifier {
  static const storageKey = 'continuing_service_relationships';
  final List<ContinuingServiceRelationship> _items = [];

  List<ContinuingServiceRelationship> get items => List.unmodifiable(_items);
  List<ContinuingServiceRelationship> get activeItems =>
      List.unmodifiable(_items.where((item) => item.active));

  Future<void> load() async {
    final raw = await PersistenceStore.loadJsonList(storageKey);
    _items
      ..clear()
      ..addAll(raw.map(ContinuingServiceRelationship.fromJson));
    notifyListeners();
  }

  Future<void> add(ContinuingServiceRelationship item) async {
    if (_items.any(
      (existing) => existing.relationshipId == item.relationshipId,
    )) {
      throw StateError('relationshipId already exists');
    }
    final next = [..._items, item];
    await _persist(next);
    _items
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  Future<void> update(ContinuingServiceRelationship item) async {
    final index = _items.indexWhere(
      (e) => e.relationshipId == item.relationshipId,
    );
    if (index < 0) throw StateError('relationshipId not found');
    final next = [..._items]..[index] = item;
    await _persist(next);
    _items
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  Future<void> _persist(List<ContinuingServiceRelationship> values) async {
    await PersistenceStore.saveJsonList(
      storageKey,
      values.map((value) => value.toJson()).toList(),
    );
  }
}
