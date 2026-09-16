import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/logic/spese/expense_replacement_persistence.dart';
import 'package:frododesk/models/expense_replacement_intent.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add, load, and both lookup paths preserve the intent', () async {
    final persistence = ExpenseReplacementPersistence();
    final intent = _intent();

    expect(await persistence.add(intent), isTrue);
    expect((await persistence.load()).single.toJson(), intent.toJson());
    expect(
      (await persistence.findByReplacementId('replacement-1'))?.toJson(),
      intent.toJson(),
    );
    expect(
      (await persistence.findByOriginalExpenseId('old-expense'))?.toJson(),
      intent.toJson(),
    );
  });

  test('write and remove use verified read-back', () async {
    final writes = <String>[];
    String? storage;
    final persistence = ExpenseReplacementPersistence(
      load: (_) async => storage,
      saveVerified: (_, value) async {
        writes.add(value);
        storage = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: storage,
        );
      },
    );

    expect(await persistence.add(_intent()), isTrue);
    expect(await persistence.remove('replacement-1'), isTrue);
    expect(writes, hasLength(2));
    expect((jsonDecode(writes.last) as Map)['intents'], isEmpty);
    expect(await persistence.load(), isEmpty);
  });

  test('coherent retry is inert and does not write a duplicate', () async {
    var writes = 0;
    String? storage;
    final persistence = ExpenseReplacementPersistence(
      load: (_) async => storage,
      saveVerified: (_, value) async {
        writes++;
        storage = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );
    final intent = _intent();

    expect(await persistence.add(intent), isTrue);
    expect(await persistence.add(intent), isFalse);
    expect(writes, 1);
    expect(await persistence.load(), hasLength(1));
  });

  test('same replacement id with incompatible payload conflicts', () async {
    final persistence = ExpenseReplacementPersistence();
    await persistence.add(_intent());

    await expectLater(
      persistence.add(_intent(amount: 99)),
      throwsA(isA<StateError>()),
    );
    expect((await persistence.load()).single.replacementPayload.amount, 25);
  });

  test('different replacement id for the same original conflicts', () async {
    final persistence = ExpenseReplacementPersistence();
    await persistence.add(_intent());

    await expectLater(
      persistence.add(_intent(replacementId: 'replacement-2')),
      throwsA(isA<StateError>()),
    );
    expect(await persistence.load(), hasLength(1));
  });

  test('different original expenses can have pending intents', () async {
    final persistence = ExpenseReplacementPersistence();

    await persistence.add(_intent());
    await persistence.add(
      _intent(replacementId: 'replacement-2', originalId: 'other-expense'),
    );

    expect(await persistence.load(), hasLength(2));
  });

  test(
    'writer rejection, missing and mismatched read-back fail explicitly',
    () async {
      for (final verification in const [
        PersistenceWriteVerification(backendAccepted: false, readBack: null),
        PersistenceWriteVerification(backendAccepted: true, readBack: null),
        PersistenceWriteVerification(backendAccepted: true, readBack: 'other'),
      ]) {
        final persistence = ExpenseReplacementPersistence(
          saveVerified: (_, _) async => verification,
        );
        await expectLater(
          persistence.add(_intent()),
          throwsA(isA<StateError>()),
        );
      }
    },
  );

  test('remove failure leaves the persisted intent observable', () async {
    final intent = _intent();
    final stored = jsonEncode({
      'version': 1,
      'intents': [intent.toJson()],
    });
    final persistence = ExpenseReplacementPersistence(
      load: (_) async => stored,
      saveVerified: (_, _) async => const PersistenceWriteVerification(
        backendAccepted: false,
        readBack: null,
      ),
    );

    await expectLater(
      persistence.remove(intent.replacementId),
      throwsA(isA<StateError>()),
    );
    expect(
      (await persistence.load()).single.replacementId,
      intent.replacementId,
    );
  });

  test(
    'corrupt, incomplete, unknown, and duplicate storage fail wholly',
    () async {
      final intent = _intent();
      final cases = <String>[
        '{broken',
        '[]',
        jsonEncode({'version': 2, 'intents': const []}),
        jsonEncode({'version': 1}),
        jsonEncode({
          'version': 1,
          'intents': [42],
        }),
        jsonEncode({
          'version': 1,
          'intents': [intent.toJson(), intent.toJson()],
        }),
        jsonEncode({
          'version': 1,
          'intents': [
            intent.toJson(),
            _intent(replacementId: 'replacement-2').toJson(),
          ],
        }),
      ];
      for (final raw in cases) {
        final persistence = ExpenseReplacementPersistence(
          load: (_) async => raw,
        );
        await expectLater(persistence.load(), throwsFormatException);
      }
    },
  );

  test('removing an absent identity is an idempotent no-op', () async {
    var writes = 0;
    final persistence = ExpenseReplacementPersistence(
      saveVerified: (_, value) async {
        writes++;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );

    expect(await persistence.remove('missing'), isFalse);
    expect(writes, 0);
  });
}

ExpenseReplacementIntent _intent({
  String replacementId = 'replacement-1',
  String originalId = 'old-expense',
  double amount = 25,
}) => ExpenseReplacementIntent(
  replacementId: replacementId,
  originalExpense: RealExpense(
    id: originalId,
    balanceId: 'account',
    balanceName: 'Account',
    amount: 20,
    description: 'Old expense',
    category: 'Food',
    date: DateTime(2026, 9, 14, 10),
    subject: FinanceSubject.matteo,
    economicFactId: 'old-fact-$originalId',
  ),
  replacementPayload: ExpenseReplacementPayload(
    balanceId: 'account',
    balanceName: 'Account',
    amount: amount,
    description: 'New expense',
    category: 'Food',
    preparedAt: DateTime(2026, 9, 16, 12),
    occurredAt: DateTime(2026, 9, 15, 11),
    personId: 'matteo',
  ),
);
