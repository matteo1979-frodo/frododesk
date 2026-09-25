import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frododesk/models/continuing_service_relationship.dart';
import 'package:frododesk/stores/continuing_service_relationship_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts empty and round trips create/update', () async {
    final store = ContinuingServiceRelationshipStore();
    await store.load();
    expect(store.items, isEmpty);
    final item = ContinuingServiceRelationship(
      relationshipId: 'service_1',
      provider: 'TIM',
      label: 'SIM Matteo',
    );
    await store.add(item);
    final reloaded = ContinuingServiceRelationshipStore();
    await reloaded.load();
    expect(reloaded.items.single.relationshipId, 'service_1');
    await reloaded.update(
      item.copyWith(label: 'SIM aggiornata', active: false),
    );
    final finalStore = ContinuingServiceRelationshipStore();
    await finalStore.load();
    expect(finalStore.items.single.label, 'SIM aggiornata');
    expect(finalStore.items.single.active, isFalse);
  });
}
