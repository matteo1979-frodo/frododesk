import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/sim_service_details.dart';

void main() {
  final activation = DateTime(2026, 6, 12);
  final expiration = DateTime(2027, 10, 11);

  test('serializes and preserves complete phone number', () {
    final original = SimServiceDetails(
      relationshipId: 'service_1', phoneNumber: '3703042030',
      offerName: 'TIM POWER FAMIGLIA IRON', activationDate: activation,
      simExpirationDate: expiration,
    );
    final restored = SimServiceDetails.fromJson(original.toJson());
    expect(restored.phoneNumber, '3703042030');
    expect(restored.activationDate, activation);
    expect(restored.simExpirationDate, expiration);
    expect(restored.creditBalanceId, isNull);
    expect(restored.expenseRelationshipId, isNull);
  });

  test('masks while keeping the last four digits', () {
    final details = SimServiceDetails(
      relationshipId: 'service_1', phoneNumber: '3703042030', offerName: 'offer',
      activationDate: activation, simExpirationDate: expiration,
    );
    expect(details.maskedPhoneNumber, '******2030');
  });

  test('short numbers are deterministic', () {
    final details = SimServiceDetails(
      relationshipId: 'service_1', phoneNumber: '123', offerName: 'offer',
      activationDate: activation, simExpirationDate: expiration,
    );
    expect(details.maskedPhoneNumber, '123');
  });

  test('credit reference is optional and can be set or cleared', () {
    final details = SimServiceDetails(
      relationshipId: 'service_1', phoneNumber: '3703042030', offerName: 'offer',
      activationDate: activation, simExpirationDate: expiration,
      creditBalanceId: 'balance_sim',
    );
    expect(SimServiceDetails.fromJson(details.toJson()).creditBalanceId, 'balance_sim');
    expect(details.copyWith(creditBalanceId: null).creditBalanceId, isNull);
  });

  test('expense relationship reference is optional and round trips', () {
    final details = SimServiceDetails(
      relationshipId: 'service_1', phoneNumber: '3703042030', offerName: 'offer',
      activationDate: activation, simExpirationDate: expiration,
      expenseRelationshipId: 'expense_relationship_1',
    );
    expect(
      SimServiceDetails.fromJson(details.toJson()).expenseRelationshipId,
      'expense_relationship_1',
    );
    expect(details.copyWith(expenseRelationshipId: null).expenseRelationshipId, isNull);
  });

  test('copyWith updates details without changing relationship identity', () {
    final details = SimServiceDetails(
      relationshipId: 'service_1', phoneNumber: '3703042030', offerName: 'old',
      activationDate: activation, simExpirationDate: expiration,
    );
    final updated = details.copyWith(offerName: 'new', phoneNumber: '3703000000');
    expect(updated.relationshipId, 'service_1');
    expect(updated.offerName, 'new');
    expect(updated.phoneNumber, '3703000000');
  });
}
