import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'new record is verified, published once, and preserves others',
    () async {
      final store = ExpenseStore();
      await store.load();
      await store.addExpense(_expense(id: 'existing', factId: 'fact-existing'));
      var notifications = 0;
      store.addListener(() => notifications++);

      final result = await store.addExpenseVerified(_expense());

      expect(result.status, VerifiedExpenseAddStatus.added);
      expect(store.all.map((item) => item.id), ['existing', 'expense-main']);
      expect(notifications, 1);
      final prefs = await SharedPreferences.getInstance();
      final persisted =
          jsonDecode(prefs.getString('frododesk_real_expenses_v1')!) as List;
      expect(persisted, hasLength(2));
      expect(persisted.last, _expense().toJson());
    },
  );

  test('identical retry is coherent without write or notification', () async {
    var writes = 0;
    final expense = _expense();
    final store = ExpenseStore(
      saveVerified: (key, value) async {
        writes++;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );
    await store.load();
    expect(
      (await store.addExpenseVerified(expense)).status,
      VerifiedExpenseAddStatus.added,
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    final retry = await store.addExpenseVerified(_expense());

    expect(retry.status, VerifiedExpenseAddStatus.alreadyCoherent);
    expect(writes, 1);
    expect(notifications, 0);
    expect(store.all, hasLength(1));
  });

  test('same id with incompatible semantic fields is a conflict', () async {
    final changes = <RealExpense>[
      _expense(amount: 387),
      _expense(date: DateTime(2026, 9, 17)),
      _expense(description: 'Diversa'),
      _expense(subject: FinanceSubject.chiara),
      _expense(category: 'Altra'),
      _expense(balanceId: 'other-balance'),
      _expense(balanceName: 'Altro conto'),
      _expense(nonTrackedCash: true),
      _expense(isCashWithdrawal: true, cashWalletId: 'wallet_matteo'),
      _expense(isIncome: true),
      _expense(factId: 'different-fact'),
    ];

    for (final changed in changes) {
      var writes = 0;
      final store = ExpenseStore(
        saveVerified: (key, value) async {
          writes++;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      );
      await store.load();
      await store.addExpenseVerified(_expense());
      final result = await store.addExpenseVerified(changed);
      expect(result.status, VerifiedExpenseAddStatus.conflict);
      expect(writes, 1);
      expect(store.all.single.toJson(), _expense().toJson());
    }
  });

  test('same economic fact with a different id is a conflict', () async {
    final store = ExpenseStore();
    await store.load();
    await store.addExpenseVerified(_expense());

    final result = await store.addExpenseVerified(_expense(id: 'different-id'));

    expect(result.status, VerifiedExpenseAddStatus.conflict);
    expect(store.all, hasLength(1));
  });

  test('pre-existing duplicates of either identity are a conflict', () async {
    final duplicateIdStore = ExpenseStore();
    await duplicateIdStore.load();
    await duplicateIdStore.addExpense(_expense());
    await duplicateIdStore.addExpense(_expense(factId: 'other-fact'));
    expect(
      (await duplicateIdStore.addExpenseVerified(_expense())).status,
      VerifiedExpenseAddStatus.conflict,
    );

    final duplicateFactStore = ExpenseStore();
    await duplicateFactStore.load();
    await duplicateFactStore.addExpense(_expense());
    await duplicateFactStore.addExpense(_expense(id: 'other-id'));
    expect(
      (await duplicateFactStore.addExpenseVerified(_expense())).status,
      VerifiedExpenseAddStatus.conflict,
    );
  });

  test('writer failures leave memory unchanged and do not notify', () async {
    final failures = <ExpenseVerifiedSave>[
      (key, value) async => const PersistenceWriteVerification(
        backendAccepted: false,
        readBack: null,
      ),
      (key, value) async => const PersistenceWriteVerification(
        backendAccepted: true,
        readBack: null,
      ),
      (key, value) async => const PersistenceWriteVerification(
        backendAccepted: true,
        readBack: 'different',
      ),
      (key, value) async => throw StateError('failed'),
    ];

    for (final failure in failures) {
      final store = ExpenseStore(saveVerified: failure);
      await store.load();
      await store.addExpense(_expense(id: 'existing', factId: 'existing-fact'));
      var notifications = 0;
      store.addListener(() => notifications++);

      final result = await store.addExpenseVerified(_expense());

      expect(result.status, VerifiedExpenseAddStatus.writerFailed);
      expect(store.all.map((item) => item.id), ['existing']);
      expect(notifications, 0);
    }
  });

  test(
    'successful record reloads and remains coherently recognizable',
    () async {
      final store = ExpenseStore();
      await store.load();
      expect(
        (await store.addExpenseVerified(_expense())).status,
        VerifiedExpenseAddStatus.added,
      );

      final restored = ExpenseStore();
      await restored.load();
      expect(restored.all.single.toJson(), _expense().toJson());
      expect(
        (await restored.addExpenseVerified(_expense())).status,
        VerifiedExpenseAddStatus.alreadyCoherent,
      );
      expect(restored.all, hasLength(1));
    },
  );

  test('null economic fact uses only structural id identity', () async {
    final store = ExpenseStore();
    await store.load();
    final first = _expense(id: 'without-fact', factId: null);
    expect(
      (await store.addExpenseVerified(first)).status,
      VerifiedExpenseAddStatus.added,
    );
    expect(
      (await store.addExpenseVerified(first)).status,
      VerifiedExpenseAddStatus.alreadyCoherent,
    );
    expect(
      (await store.addExpenseVerified(
        _expense(id: 'second-without-fact', factId: null),
      )).status,
      VerifiedExpenseAddStatus.added,
    );
    expect(store.all, hasLength(2));
  });
}

RealExpense _expense({
  String id = 'expense-main',
  String? factId = 'economic-fact-main',
  String balanceId = 'balance-bank',
  String balanceName = 'Banca',
  double amount = 386,
  DateTime? date,
  String description = 'Rata INPS 3/12',
  String category = 'Tributi',
  FinanceSubject subject = FinanceSubject.matteo,
  bool nonTrackedCash = false,
  bool isCashWithdrawal = false,
  bool isIncome = false,
  String? cashWalletId,
}) => RealExpense(
  id: id,
  economicFactId: factId,
  balanceId: balanceId,
  balanceName: balanceName,
  amount: amount,
  description: description,
  category: category,
  date: date ?? DateTime(2026, 9, 16),
  subject: subject,
  nonTrackedCash: nonTrackedCash,
  isCashWithdrawal: isCashWithdrawal,
  isIncome: isIncome,
  cashWalletId: cashWalletId,
);
