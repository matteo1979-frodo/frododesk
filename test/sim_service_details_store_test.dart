import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frododesk/models/sim_service_details.dart';
import 'package:frododesk/stores/sim_service_details_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('verified save survives reload and preserves full references', () async {
    final store = SimServiceDetailsStore();
    await store.save(
      SimServiceDetails(
        relationshipId: 'service_1',
        phoneNumber: '3703042030',
        offerName: 'Offer',
        activationDate: DateTime(2026, 6, 12),
        simExpirationDate: DateTime(2027, 10, 11),
        creditBalanceId: 'balance_1',
        expenseRelationshipId: 'expense_1',
      ),
    );

    final reloaded = SimServiceDetailsStore();
    await reloaded.load();
    final restored = reloaded.findByRelationshipId('service_1')!;

    expect(restored.phoneNumber, '3703042030');
    expect(restored.creditBalanceId, 'balance_1');
    expect(restored.expenseRelationshipId, 'expense_1');
  });
}
