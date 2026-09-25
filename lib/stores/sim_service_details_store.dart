import 'dart:convert';

import '../logic/persistence_store.dart';
import '../models/sim_service_details.dart';

/// Persisted registry of SIM-specific details, keyed by service relationship.
class SimServiceDetailsStore {
  static const storageKey = 'sim_service_details_v1';

  final List<SimServiceDetails> _items = [];

  List<SimServiceDetails> get items => List.unmodifiable(_items);

  SimServiceDetails? findByRelationshipId(String relationshipId) {
    for (final item in _items) {
      if (item.relationshipId == relationshipId) return item;
    }
    return null;
  }

  Future<void> load() async {
    final raw = await PersistenceStore.loadString(storageKey);
    _items
      ..clear()
      ..addAll(
        raw == null || raw.isEmpty
            ? const []
            : (jsonDecode(raw) as List).map(
                (item) => SimServiceDetails.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              ),
      );
  }

  Future<void> save(SimServiceDetails details) async {
    final index = _items.indexWhere(
      (item) => item.relationshipId == details.relationshipId,
    );
    final next = [..._items];
    if (index < 0) {
      next.add(details);
    } else {
      next[index] = details;
    }

    final serialized = jsonEncode(
      next.map((item) => item.toJson()).toList(),
    );
    final verification = await PersistenceStore.saveStringVerified(
      storageKey,
      serialized,
    );
    if (!verification.matches(serialized)) {
      throw StateError('SIM service details write failed');
    }

    _items
      ..clear()
      ..addAll(next);
  }
}
