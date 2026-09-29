import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/expense_store.dart';

void main() {
  test('mutation before load is rejected without persistence', () async {
    var writes = 0;
    final store = ExpenseStore(
      load: (_) async => '[]',
      saveVerified: (_, value) async {
        writes++;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );

    await expectLater(store.save(), throwsStateError);
    await expectLater(store.addExpense(_expense()), throwsStateError);
    await expectLater(store.addExpenseVerified(_expense()), throwsStateError);
    await expectLater(
      store.replaceExpenseVerified(
        original: _expense(),
        replacement: _expense(id: 'replacement'),
      ),
      throwsStateError,
    );
    await expectLater(store.removeExpense('new-expense'), throwsStateError);
    expect(store.isLoaded, isFalse);
    expect(store.all, isEmpty);
    expect(writes, 0);
  });

  test('successful load enables mutation and preserves loaded records', () async {
    String? written;
    final existing = _expense(id: 'existing', factId: 'existing-fact');
    final store = ExpenseStore(
      load: (_) async => jsonEncode([existing.toJson()]),
      saveVerified: (_, value) async {
        written = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );

    await store.load();
    final result = await store.addExpenseVerified(_expense());

    expect(store.isLoaded, isTrue);
    expect(result.status, VerifiedExpenseAddStatus.added);
    expect(store.all.map((item) => item.id), ['existing', 'new-expense']);
    expect(jsonDecode(written!) as List, hasLength(2));
  });

  test('failed load leaves mutations disabled and memory unpublished', () async {
    var writes = 0;
    final existing = _expense(id: 'existing', factId: 'existing-fact');
    final store = ExpenseStore(
      load: (_) async => jsonEncode([existing.toJson(), 'invalid-record']),
      saveVerified: (_, value) async {
        writes++;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );

    await expectLater(store.load(), throwsFormatException);
    await expectLater(store.addExpenseVerified(_expense()), throwsStateError);
    expect(store.isLoaded, isFalse);
    expect(store.all, isEmpty);
    expect(writes, 0);
  });

  test('successfully loaded empty store permits mutation', () async {
    var writes = 0;
    final store = ExpenseStore(
      load: (_) async => '[]',
      saveVerified: (_, value) async {
        writes++;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );

    await store.load();
    final result = await store.addExpenseVerified(_expense());

    expect(store.isLoaded, isTrue);
    expect(result.status, VerifiedExpenseAddStatus.added);
    expect(writes, 1);
  });
}

RealExpense _expense({
  String id = 'new-expense',
  String? factId = 'new-fact',
}) => RealExpense(
  id: id,
  balanceId: 'balance',
  balanceName: 'Banca',
  amount: 10,
  description: 'Spesa',
  category: 'Categoria',
  date: DateTime(2026, 9, 28),
  subject: FinanceSubject.matteo,
  economicFactId: factId,
);
