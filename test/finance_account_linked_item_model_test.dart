import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/finance_account_linked_item.dart';

void main() {
  const legacyJson = <String, dynamic>{
    'id': 'linked_legacy',
    'balanceId': 'parent_bank',
    'type': 'prepaidCard',
    'name': 'Prepagata storica',
    'description': 'Rapporto esistente',
    'expirationDate': '2028-06-30T00:00:00.000',
    'amount': 25.5,
    'active': false,
  };

  FinanceAccountLinkedItem linkedItem({String? autonomousBalanceId}) {
    return FinanceAccountLinkedItem(
      id: 'linked_test',
      balanceId: 'parent_bank',
      autonomousBalanceId: autonomousBalanceId,
      type: FinanceAccountLinkedItemType.prepaidCard,
      name: 'Prepagata test',
      description: 'Carta collegata',
      expirationDate: DateTime(2029, 7, 31),
      amount: 120.40,
      active: true,
    );
  }

  test('legacy JSON remains compatible without autonomous balance id', () {
    final item = FinanceAccountLinkedItem.fromJson(legacyJson);

    expect(item.id, 'linked_legacy');
    expect(item.balanceId, 'parent_bank');
    expect(item.autonomousBalanceId, isNull);
    expect(item.type, FinanceAccountLinkedItemType.prepaidCard);
    expect(item.name, 'Prepagata storica');
    expect(item.description, 'Rapporto esistente');
    expect(item.expirationDate, DateTime(2028, 6, 30));
    expect(item.amount, 25.5);
    expect(item.active, isFalse);
  });

  test('new JSON round-trip preserves parent and autonomous identities', () {
    final original = linkedItem(autonomousBalanceId: 'balance_prepaid_test');

    final json = original.toJson();
    final restored = FinanceAccountLinkedItem.fromJson(json);

    expect(json['balanceId'], 'parent_bank');
    expect(json['autonomousBalanceId'], 'balance_prepaid_test');
    expect(restored.id, original.id);
    expect(restored.balanceId, 'parent_bank');
    expect(restored.autonomousBalanceId, 'balance_prepaid_test');
    expect(restored.type, original.type);
    expect(restored.name, original.name);
    expect(restored.description, original.description);
    expect(restored.expirationDate, original.expirationDate);
    expect(restored.amount, original.amount);
    expect(restored.active, original.active);
  });

  test(
    'copyWith preserves autonomous balance id while changing another field',
    () {
      final original = linkedItem(autonomousBalanceId: 'balance_prepaid_test');

      final copy = original.copyWith(name: 'Nome aggiornato');

      expect(copy.name, 'Nome aggiornato');
      expect(copy.balanceId, 'parent_bank');
      expect(copy.autonomousBalanceId, 'balance_prepaid_test');
    },
  );

  test('copyWith sets autonomous balance id', () {
    final copy = linkedItem().copyWith(
      autonomousBalanceId: 'balance_prepaid_test',
    );

    expect(copy.balanceId, 'parent_bank');
    expect(copy.autonomousBalanceId, 'balance_prepaid_test');
  });

  test('copyWith clears autonomous balance id explicitly', () {
    final original = linkedItem(autonomousBalanceId: 'balance_prepaid_test');

    final copy = original.copyWith(clearAutonomousBalanceId: true);

    expect(copy.balanceId, 'parent_bank');
    expect(copy.autonomousBalanceId, isNull);
  });

  test('parent and autonomous ids coexist without being confused', () {
    final original = linkedItem(autonomousBalanceId: 'prepaid_balance');

    final restored = FinanceAccountLinkedItem.fromJson(original.toJson());
    final copied = restored.copyWith(description: 'Aggiornata');

    expect(restored.balanceId, 'parent_bank');
    expect(restored.autonomousBalanceId, 'prepaid_balance');
    expect(copied.balanceId, 'parent_bank');
    expect(copied.autonomousBalanceId, 'prepaid_balance');
  });
}
