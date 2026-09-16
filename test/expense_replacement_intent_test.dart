import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/expense_replacement_intent.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  test('complete JSON round-trip preserves the contract', () {
    final intent = _intent();

    final restored = ExpenseReplacementIntent.fromJson(
      jsonDecode(jsonEncode(intent.toJson())) as Map<String, dynamic>,
    );

    expect(restored.toJson(), intent.toJson());
    expect(restored.originalExpense.economicFactId, 'old-fact');
  });

  test('legacy original expense with null economicFactId round-trips', () {
    final intent = _intent(
      original: _expense(id: 'legacy', economicFactId: null),
    );

    final restored = ExpenseReplacementIntent.fromJson(intent.toJson());

    expect(restored.originalExpense.id, 'legacy');
    expect(restored.originalExpense.economicFactId, isNull);
  });

  test('empty replacement id and invalid ordinary records fail', () {
    expect(() => _intent(replacementId: ' '), throwsArgumentError);
    expect(
      () => _intent(original: _expense(isCashWithdrawal: true)),
      throwsArgumentError,
    );
    expect(
      () => ExpenseReplacementPayload(
        balanceId: 'account',
        balanceName: 'Account',
        amount: 0,
        description: 'New',
        category: 'Food',
        preparedAt: DateTime(2026, 9, 16),
        occurredAt: DateTime(2026, 9, 15),
      ),
      throwsArgumentError,
    );
  });

  test('unknown version and corrupt or incomplete JSON fail explicitly', () {
    final unknown = _intent().toJson()..['version'] = 2;
    expect(
      () => ExpenseReplacementIntent.fromJson(unknown),
      throwsFormatException,
    );
    for (final json in <Map<String, dynamic>>[
      {},
      {'version': 1, 'replacementId': 'id'},
      {..._intent().toJson(), 'originalExpense': 'broken'},
      {
        ..._intent().toJson(),
        'replacementPayload': {
          ..._intent().replacementPayload.toJson(),
          'occurredAt': 'not-a-date',
        },
      },
    ]) {
      expect(
        () => ExpenseReplacementIntent.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('identities are deterministic, namespaced, and input-sensitive', () {
    final first = _intent(replacementId: 'replace/one ü').identities;
    final retry = _intent(replacementId: 'replace/one ü').identities;
    final other = _intent(replacementId: 'replace/two ü').identities;

    expect(first.compensationTransactionId, retry.compensationTransactionId);
    expect(first.compensationEconomicFactId, retry.compensationEconomicFactId);
    expect(first.replacementCommandId, retry.replacementCommandId);
    expect(first.replacementTransactionId, retry.replacementTransactionId);
    expect(first.replacementEconomicFactId, retry.replacementEconomicFactId);
    expect(first.replacementCommandId, isNot(other.replacementCommandId));
    expect(
      first.replacementTransactionId,
      isNot(other.replacementTransactionId),
    );
    expect(
      first.replacementEconomicFactId,
      'economic_fact_spese_${first.replacementCommandId}',
    );
    expect(first.compensationTransactionId, isNot(contains('/')));
    expect(first.compensationTransactionId, isNot(contains('ü')));
  });

  test('identity derivation does not depend on dates or economic fields', () {
    final first = _intent().identities;
    final changed = _intent(
      payload: _payload(
        amount: 999,
        preparedAt: DateTime(2035, 1, 1),
        occurredAt: DateTime(2034, 12, 31),
        description: 'Entirely different',
      ),
    ).identities;

    expect(changed.compensationTransactionId, first.compensationTransactionId);
    expect(
      changed.compensationEconomicFactId,
      first.compensationEconomicFactId,
    );
    expect(changed.replacementCommandId, first.replacementCommandId);
    expect(changed.replacementTransactionId, first.replacementTransactionId);
    expect(changed.replacementEconomicFactId, first.replacementEconomicFactId);
  });

  test('replacement payload reconstructs an ordinary create command', () {
    final intent = _intent();
    final command = intent.replacementPayload.toCommand(intent.identities);

    expect(command.id, intent.identities.replacementCommandId);
    expect(command.amount, 25);
    expect(command.occurredAt, DateTime(2026, 9, 15, 11));
    expect(command.origin.referenceId, 'account');
    expect(command.personId, 'matteo');
  });
}

ExpenseReplacementIntent _intent({
  String replacementId = 'replacement-1',
  RealExpense? original,
  ExpenseReplacementPayload? payload,
}) => ExpenseReplacementIntent(
  replacementId: replacementId,
  originalExpense: original ?? _expense(),
  replacementPayload: payload ?? _payload(),
);

RealExpense _expense({
  String id = 'old-expense',
  String? economicFactId = 'old-fact',
  bool isCashWithdrawal = false,
}) => RealExpense(
  id: id,
  balanceId: 'account',
  balanceName: 'Account',
  amount: 20,
  description: 'Old expense',
  category: 'Food',
  date: DateTime(2026, 9, 14, 10),
  subject: FinanceSubject.matteo,
  economicFactId: economicFactId,
  isCashWithdrawal: isCashWithdrawal,
);

ExpenseReplacementPayload _payload({
  double amount = 25,
  DateTime? preparedAt,
  DateTime? occurredAt,
  String description = 'New expense',
}) => ExpenseReplacementPayload(
  balanceId: 'account',
  balanceName: 'Account',
  amount: amount,
  description: description,
  category: 'Food',
  preparedAt: preparedAt ?? DateTime(2026, 9, 16, 12),
  occurredAt: occurredAt ?? DateTime(2026, 9, 15, 11),
  personId: 'matteo',
);
