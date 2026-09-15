import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/economics/economic_fact_id_generator.dart';
import 'package:frododesk/models/finance_account_linked_item.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_fund_mutation_plan.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_snapshot.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/fund_transaction.dart';
import 'package:frododesk/stores/finance_demo_data.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('FinanceStore is Listenable and reads do not notify', () {
    final store = FinanceStore(initialBalances: [_balance()]);
    var notifications = 0;
    store.addListener(() => notifications++);

    expect(store, isA<ChangeNotifier>());
    expect(store, isA<Listenable>());
    expect(store.balances.single.name, 'Conto');
    expect(store.linkedItems, isEmpty);
    expect(notifications, 0);
  });

  test('balance and linked item views are immutable defensive copies', () {
    final source = [_balance()];
    final store = FinanceStore(initialBalances: source);
    source.clear();

    expect(store.balances, hasLength(1));
    expect(
      () => store.balances.add(_balance(id: 'other')),
      throwsUnsupportedError,
    );
    expect(() => store.linkedItems.add(_linkedItem()), throwsUnsupportedError);
  });

  test(
    'transaction, recurrence and snapshot views are defensive and immutable',
    () {
      final transactions = [_transaction()];
      final recurringItems = [demoRecurringItems.first];
      final snapshots = [_snapshot()];
      final store = FinanceStore(
        initialTransactions: transactions,
        initialRecurringItems: recurringItems,
        initialSnapshots: snapshots,
      );

      transactions.clear();
      recurringItems.clear();
      snapshots.clear();

      expect(store.transactions, hasLength(1));
      expect(store.recurringItems, hasLength(1));
      expect(store.snapshots, hasLength(1));
      expect(
        () => store.transactions.add(_transaction(id: 'other')),
        throwsUnsupportedError,
      );
      expect(() => store.recurringItems.clear(), throwsUnsupportedError);
      expect(() => store.snapshots.removeLast(), throwsUnsupportedError);
    },
  );

  test(
    'adding a balance persists and notifies once; duplicate is a no-op',
    () async {
      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      expect(await store.addBalance(_balance()), isTrue);
      expect(notifications, 1);
      expect(await store.addBalance(_balance()), isFalse);
      expect(notifications, 1);

      final restored = FinanceStore();
      expect(await restored.loadSavedBalances(), isTrue);
      expect(restored.balances.single.balanceId, 'account');
    },
  );

  test(
    'profile replacement preserves identity and creates no adjustment',
    () async {
      final store = FinanceStore(initialBalances: [_balance()]);
      var notifications = 0;
      store.addListener(() => notifications++);
      final updated = _balance(name: 'Conto famiglia', active: false);

      expect(await store.replaceBalance(updated), isTrue);
      expect(store.balances.single.balanceId, 'account');
      expect(store.balances.single.name, 'Conto famiglia');
      expect(store.transactions, isEmpty);
      expect(notifications, 1);
      expect(await store.replaceBalance(updated), isFalse);
      expect(notifications, 1);
    },
  );

  test(
    'activation is semantic, persistent and does not notify on no-op',
    () async {
      final store = FinanceStore(initialBalances: [_balance()]);
      var notifications = 0;
      store.addListener(() => notifications++);

      expect(await store.setBalanceActive('account', false), isTrue);
      expect(store.balances.single.active, isFalse);
      expect(notifications, 1);
      expect(await store.setBalanceActive('account', false), isFalse);
      expect(await store.setBalanceActive('missing', false), isFalse);
      expect(notifications, 1);
    },
  );

  test(
    'amount and profile update emits one adjustment and one notification',
    () async {
      final store = FinanceStore(initialBalances: [_balance()]);
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.updateBalanceDetailsAndAmount(
        details: _balance(name: 'Conto aggiornato'),
        newAmount: 80,
      );

      expect(store.balances.single.name, 'Conto aggiornato');
      expect(store.balances.single.currentAmount, 80);
      expect(store.transactions, hasLength(1));
      expect(notifications, 1);
    },
  );

  test(
    'linked item APIs add, replace and deactivate with no-op semantics',
    () async {
      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);
      final item = _linkedItem();

      expect(await store.addLinkedItem(item), isTrue);
      expect(await store.addLinkedItem(item), isFalse);
      expect(
        await store.replaceLinkedItem(item.copyWith(name: 'Carta nuova')),
        isTrue,
      );
      expect(await store.setLinkedItemActive(item.id, false), isTrue);
      expect(await store.setLinkedItemActive(item.id, false), isFalse);
      expect(store.linkedItems.single.id, item.id);
      expect(store.linkedItems.single.active, isFalse);
      expect(notifications, 3);
    },
  );

  test(
    'batching is nested, skips empty batches and restores after errors',
    () async {
      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.runInNotificationBatch(() async {});
      expect(notifications, 0);
      await store.runInNotificationBatch(() async {
        await store.addBalance(_balance());
        await store.runInNotificationBatch(() async {
          await store.addLinkedItem(_linkedItem());
        });
      });
      expect(notifications, 1);

      await expectLater(
        store.runInNotificationBatch<void>(() async {
          throw StateError('batch failure');
        }),
        throwsStateError,
      );
      await store.addLinkedItem(_linkedItem(id: 'second'));
      expect(notifications, 2);
    },
  );

  test(
    'persistence failure propagates and observable memory stays visible',
    () async {
      final store = _FailingFinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(store.addBalance(_balance()), throwsStateError);
      expect(store.balances.single.balanceId, 'account');
      expect(notifications, 1);
    },
  );

  test(
    'non-fund transaction operations each notify once after persistence',
    () async {
      Future<void> verify(
        Future<void> Function(FinanceStore store) operation, {
        int balances = 1,
      }) async {
        final store = FinanceStore(
          initialBalances: [
            _balance(),
            if (balances == 2) _balance(id: 'other'),
          ],
        );
        var notifications = 0;
        store.addListener(() => notifications++);

        await operation(store);

        expect(notifications, 1);
      }

      await verify(
        (store) => store.updateBalance(balanceId: 'account', newAmount: 90),
      );
      await verify(
        (store) => store.registerRealExpense(
          balanceId: 'account',
          amount: 10,
          description: 'Spesa',
        ),
      );
      await verify(
        (store) => store.registerExtraIncome(
          balanceId: 'account',
          amount: 10,
          description: 'Entrata',
        ),
      );
      await verify(
        (store) => store.removeExtraIncome(
          balanceId: 'account',
          amount: 10,
          description: 'Entrata',
        ),
      );
      await verify(
        (store) => store.restoreRealExpense(
          balanceId: 'account',
          amount: 10,
          description: 'Spesa',
        ),
      );
      await verify(
        (store) => store.transferBetweenBalances(
          fromBalanceId: 'account',
          toBalanceId: 'other',
          amount: 10,
        ),
        balances: 2,
      );
    },
  );

  test('invalid non-fund operations remain notification no-ops', () async {
    final store = FinanceStore(initialBalances: [_balance()]);
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.updateBalance(balanceId: 'missing', newAmount: 10);
    await store.registerRealExpense(
      balanceId: 'missing',
      amount: 10,
      description: 'Spesa',
    );
    await store.transferBetweenBalances(
      fromBalanceId: 'missing',
      toBalanceId: 'account',
      amount: 10,
    );

    expect(notifications, 0);
  });

  test(
    'transaction semantics, order and transfer identity remain unchanged',
    () async {
      final generated = ['adjustment-fact', 'transfer-fact'];
      var index = 0;
      final store = FinanceStore(
        economicFactIdGenerator: EconomicFactIdGenerator.from(
          () => generated[index++],
        ),
        initialBalances: [
          _balance(),
          _balance(id: 'other'),
        ],
        initialTransactions: [_transaction(id: 'existing')],
      );

      await store.updateBalance(balanceId: 'account', newAmount: 90);
      await store.transferBetweenBalances(
        fromBalanceId: 'account',
        toBalanceId: 'other',
        amount: 20,
      );

      expect(store.transactions.first.id, 'existing');
      final adjustment = store.transactions[1];
      expect(adjustment.amount, 10);
      expect(adjustment.isIncome, isFalse);
      expect(adjustment.type, FinanceTransactionType.expense);
      expect(adjustment.origin, FinanceTransactionOrigin.adjustment);
      expect(adjustment.economicFactId, 'adjustment-fact');
      final transfer = store.transactions.skip(2).toList();
      expect(transfer, hasLength(2));
      expect(transfer.map((item) => item.isIncome), [false, true]);
      expect(transfer.map((item) => item.economicFactId).toSet(), {
        'transfer-fact',
      });
    },
  );

  test(
    'recurrence add, update and remove notify once and skip no-ops',
    () async {
      final item = demoRecurringItems.first;
      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.addRecurringItem(item);
      expect(notifications, 1);
      await store.updateRecurringItem(item);
      await store.updateRecurringItem(item.copyWith(name: 'Voce aggiornata'));
      expect(notifications, 2);
      await store.removeRecurringItem('missing');
      await store.removeRecurringItem(item.id);
      expect(notifications, 3);
      await store.confirmRecurringItem('missing');
      expect(notifications, 3);
    },
  );

  test(
    'recurrence confirmation batches balance, transaction and recurrence',
    () async {
      final item = demoRecurringItems.first.copyWith(balanceId: 'account');
      final store = FinanceStore(
        initialBalances: [_balance()],
        initialRecurringItems: [item],
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.confirmRecurringItem(item.id, realAmount: 25);

      expect(store.transactions, hasLength(1));
      expect(store.transactions.single.amount, 25);
      expect(store.transactions.single.recurringItemId, item.id);
      expect(store.balances.single.currentAmount, item.isIncome ? 125 : 75);
      expect(store.recurringItems.first.confirmed, isTrue);
      expect(notifications, 1);
    },
  );

  test(
    'recurring occurrences retain links, dates and distinct economic facts',
    () async {
      final facts = ['occurrence-1', 'occurrence-2'];
      var factIndex = 0;
      final item = demoRecurringItems.first.copyWith(balanceId: 'account');
      final store = FinanceStore(
        economicFactIdGenerator: EconomicFactIdGenerator.from(
          () => facts[factIndex++],
        ),
        initialBalances: [_balance()],
        initialRecurringItems: [item],
      );

      await store.confirmRecurringItem(item.id);
      final next = store.recurringItems.singleWhere(
        (entry) => !entry.confirmed,
      );
      expect(next.nextDueDate, store.nextDueDateAfterConfirmation(item));
      expect(next.recurringType, item.recurringType);
      await store.confirmRecurringItem(next.id);

      expect(store.transactions.map((entry) => entry.recurringItemId), [
        item.id,
        next.id,
      ]);
      expect(store.transactions.map((entry) => entry.economicFactId), facts);
      final restored = FinanceStore();
      expect(await restored.loadSavedRecurringItems(), isTrue);
      expect(
        restored.recurringItems.map((entry) => entry.toJson()),
        store.recurringItems.map((entry) => entry.toJson()),
      );
    },
  );

  test(
    'confirmed recurring occurrence cannot be confirmed a second time',
    () async {
      final item = demoRecurringItems.first.copyWith(
        id: 'guarded-occurrence',
        nextDueDate: DateTime(2026, 8, 19),
        balanceId: 'account',
      );
      final store = _TrackingRecurringFinanceStore(
        initialBalances: [_balance()],
        initialRecurringItems: [item],
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.confirmRecurringItem(item.id, realAmount: 10);
      final balanceAfterFirstConfirmation = store.balances.single.currentAmount;
      expect(store.transactions, hasLength(1));
      expect(store.recurringItems, hasLength(2));
      expect(notifications, 1);
      expect(store.saveBalancesCalls, 1);
      expect(store.saveTransactionsCalls, 1);
      expect(store.saveRecurringItemsCalls, 1);

      await store.confirmRecurringItem(item.id, realAmount: 10);

      expect(
        store.balances.single.currentAmount,
        balanceAfterFirstConfirmation,
      );
      expect(store.transactions, hasLength(1));
      expect(store.recurringItems, hasLength(2));
      expect(
        store.recurringItems.where(
          (entry) =>
              !entry.confirmed && entry.nextDueDate == DateTime(2026, 9, 19),
        ),
        hasLength(1),
      );
      expect(notifications, 1);
      expect(store.saveBalancesCalls, 1);
      expect(store.saveTransactionsCalls, 1);
      expect(store.saveRecurringItemsCalls, 1);
    },
  );

  test('recurring history and next active occurrence survive reload', () async {
    final item = demoRecurringItems.first.copyWith(
      id: 'persistent-occurrence',
      nextDueDate: DateTime(2026, 8, 19),
      balanceId: 'account',
    );
    final store = FinanceStore(
      initialBalances: [_balance()],
      initialRecurringItems: [item],
    );
    await store.saveBalances();
    await store.saveRecurringItems();
    await store.confirmRecurringItem(item.id, realAmount: 10);

    final restored = FinanceStore();
    expect(await restored.loadSavedBalances(), isTrue);
    expect(await restored.loadSavedTransactions(), isTrue);
    expect(await restored.loadSavedRecurringItems(), isTrue);

    expect(restored.transactions, hasLength(1));
    expect(
      restored.recurringItems.where((entry) => entry.confirmed),
      hasLength(1),
    );
    final active = restored.recurringItems.where((entry) => !entry.confirmed);
    expect(active, hasLength(1));
    expect(active.single.nextDueDate, DateTime(2026, 9, 19));
    expect(restored.pastRecurringItems(), hasLength(1));
    expect(restored.presentRecurringItems(), isEmpty);
    expect(restored.futureRecurringItems(), hasLength(1));
    expect(
      restored.futureRecurringItems().single.nextDueDate,
      DateTime(2026, 9, 19),
    );
    expect(
      restored.balances.single.currentAmount,
      store.balances.single.currentAmount,
    );
  });

  test(
    'snapshot save notifies once, skips identical replacement and respects dispose',
    () async {
      final store = FinanceStore(initialBalances: [_balance()]);
      var notifications = 0;
      store.addListener(() => notifications++);
      final day = DateTime(2026, 8, 19);

      await store.saveSnapshot(day);
      await store.saveSnapshot(day);

      expect(store.snapshots, hasLength(1));
      expect(store.snapshots.single.date, day);
      expect(store.snapshots.single.totalBalance, 100);
      expect(notifications, 1);

      final restored = FinanceStore();
      expect(await restored.loadSavedSnapshots(), isTrue);
      expect(
        restored.snapshots.single.toJson(),
        store.snapshots.single.toJson(),
      );

      final delayed = _DelayedSnapshotFinanceStore();
      var delayedNotifications = 0;
      delayed.addListener(() => delayedNotifications++);
      final pending = delayed.saveSnapshot(day);
      delayed.dispose();
      delayed.completeSave();
      await pending;
      expect(delayedNotifications, 0);
    },
  );

  test(
    'transaction persistence failure propagates after notifying visible memory',
    () async {
      final store = _FailingTransactionFinanceStore(
        initialBalances: [_balance()],
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(
        store.registerRealExpense(
          balanceId: 'account',
          amount: 10,
          description: 'Spesa',
        ),
        throwsStateError,
      );

      expect(store.transactions, hasLength(1));
      expect(store.balances.single.currentAmount, 90);
      expect(notifications, 1);
    },
  );

  test(
    'transaction notification is emitted only after complete persistence',
    () async {
      final store = _DelayedTransactionFinanceStore(
        initialBalances: [_balance()],
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      final pending = store.registerRealExpense(
        balanceId: 'account',
        amount: 10,
        description: 'Spesa',
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 0);
      store.completeSave();
      await pending;
      expect(notifications, 1);
    },
  );

  test(
    'disposed store rejects new listeners through ChangeNotifier contract',
    () {
      final store = FinanceStore()..dispose();

      expect(() => store.addListener(() {}), throwsFlutterError);
    },
  );

  test('fund and portfolio collections are externally immutable', () {
    final funds = [_fund()];
    final transactions = [_fundTransaction()];
    final movements = [_assetMovement()];
    final store = FinanceStore(
      initialFunds: funds,
      initialFundTransactions: transactions,
      initialAssetMovements: movements,
    );
    funds.clear();
    transactions.clear();
    movements.clear();

    expect(store.funds, hasLength(1));
    expect(store.fundTransactions, hasLength(1));
    expect(store.assetMovements, hasLength(1));
    expect(() => store.funds.add(_fund(id: 'other')), throwsUnsupportedError);
    expect(() => store.fundTransactions.clear(), throwsUnsupportedError);
    expect(() => store.assetMovements.removeLast(), throwsUnsupportedError);
  });

  test('fund plan notifies once and only after persistence', () async {
    final store = _DelayedFundPortfolioFinanceStore();
    var notifications = 0;
    store.addListener(() => notifications++);
    final plan = FinanceFundMutationPlan(
      balances: const [],
      funds: [_fund()],
      movements: [_assetMovement()],
      transactions: const [],
    );

    final pending = store.commitFundPlan(plan);
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 0);
    store.completeSave();
    await pending;

    expect(store.funds.single.id, 'fund');
    expect(store.assetMovements.single.id, 'movement');
    expect(notifications, 1);
  });

  test(
    'fund persistence error propagates and notifies mutated memory',
    () async {
      final store = _FailingFundPortfolioFinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(
        store.commitFundPlan(
          FinanceFundMutationPlan(
            balances: const [],
            funds: [_fund()],
            movements: [_assetMovement()],
            transactions: const [],
          ),
        ),
        throwsStateError,
      );

      expect(store.funds.single.id, 'fund');
      expect(notifications, 1);
    },
  );

  test('identical fund plan is a persistence and notification no-op', () async {
    final store = _DelayedFundPortfolioFinanceStore(
      initialFunds: [_fund()],
      initialAssetMovements: [_assetMovement()],
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.commitFundPlan(
      FinanceFundMutationPlan(
        balances: const [],
        funds: [_fund()],
        movements: [_assetMovement()],
        transactions: const [],
      ),
    );

    expect(store.saveCalls, 0);
    expect(notifications, 0);
  });

  test('legacy fund mutations notify once and skip semantic no-ops', () async {
    final store = FinanceStore(initialFunds: [_fund()]);
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.updateFundAmount(fundId: 'missing', newAmount: 100);
    await store.updateFundAmount(fundId: 'fund', newAmount: 100);
    await store.updateFund(_fund());
    await store.removeFund('missing');
    expect(notifications, 0);

    await store.updateFund(_fund(amount: 120));
    expect(notifications, 1);
    await store.addFundTransaction(
      fundId: 'fund',
      description: 'Prelievo',
      amount: 20,
      type: FundTransactionType.withdraw,
    );
    expect(notifications, 2);
    expect(store.funds.single.amount, 100);
    expect(store.fundTransactions, hasLength(1));
    expect(store.transactions, hasLength(1));

    await store.removeFund('fund');
    expect(notifications, 3);
    expect(store.funds, isEmpty);
    expect(store.fundTransactions, isEmpty);
    expect(store.transactions, isEmpty);
  });

  test(
    'Home alone disposes FinanceStore and production call sites are sealed',
    () {
      final home = File('lib/screens/home_screen.dart').readAsStringSync();
      final accounts = File(
        'lib/widgets/finance/finance_accounts_panel.dart',
      ).readAsStringSync();
      final person = File(
        'lib/screens/person_finance_screen.dart',
      ).readAsStringSync();
      final detail = File(
        'lib/screens/account_detail_screen.dart',
      ).readAsStringSync();
      final ledger = File(
        'lib/screens/finance/finance_ledger_page.dart',
      ).readAsStringSync();
      final storeSource = File(
        'lib/stores/finance_store.dart',
      ).readAsStringSync();
      final productionOutsideStore = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.dart') &&
                !file.path
                    .replaceAll('\\', '/')
                    .endsWith('/stores/finance_store.dart'),
          )
          .map((file) => file.readAsStringSync())
          .join('\n');
      final consumers = '$accounts\n$person\n$detail';

      expect(
        RegExp(r'financeStore\.dispose\s*\(\s*\)').allMatches(home),
        hasLength(1),
      );
      expect(
        consumers,
        isNot(matches(RegExp(r'\.balances\s*(?:\.add|\[[^]]+\]\s*=)'))),
      );
      expect(
        consumers,
        isNot(matches(RegExp(r'\.linkedItems\s*(?:\.add|\[[^]]+\]\s*=)'))),
      );
      expect(
        consumers,
        isNot(matches(RegExp(r'\.transactions\s*(?:\.add|\[[^]]+\]\s*=)'))),
      );
      expect(
        consumers,
        isNot(matches(RegExp(r'\.recurringItems\s*(?:\.add|\[[^]]+\]\s*=)'))),
      );
      expect(
        consumers,
        isNot(matches(RegExp(r'\.snapshots\s*(?:\.add|\[[^]]+\]\s*=)'))),
      );
      expect(consumers, isNot(contains('financeStore.dispose()')));
      expect(
        productionOutsideStore,
        isNot(
          matches(
            RegExp(
              r'\.(?:transactions|recurringItems|snapshots)\s*'
              r'(?:\.\.|\.add|\.remove|\.clear|\[[^]]+\]\s*=)',
            ),
          ),
        ),
      );
      expect(storeSource, isNot(contains('mutableTransactionsForTest')));
      expect(storeSource, isNot(contains('mutableRecurringItemsForTest')));
      expect(storeSource, isNot(contains('mutableSnapshotsForTest')));
      expect(ledger, contains('FinanceLedgerPresentationCoordinator'));
      expect(ledger, isNot(contains('LedgerSnapshot')));
    },
  );
}

class _FailingFinanceStore extends FinanceStore {
  @override
  Future<void> saveBalances() => Future.error(StateError('save failure'));
}

class _FailingTransactionFinanceStore extends FinanceStore {
  _FailingTransactionFinanceStore({super.initialBalances});

  @override
  Future<void> saveTransactions() => Future.error(StateError('save failure'));
}

class _DelayedSnapshotFinanceStore extends FinanceStore {
  final Completer<void> _saveCompleter = Completer<void>();

  @override
  Future<void> saveSnapshots() => _saveCompleter.future;

  void completeSave() => _saveCompleter.complete();
}

class _DelayedTransactionFinanceStore extends FinanceStore {
  _DelayedTransactionFinanceStore({super.initialBalances});

  final Completer<void> _saveCompleter = Completer<void>();

  @override
  Future<void> saveTransactions() => _saveCompleter.future;

  void completeSave() => _saveCompleter.complete();
}

class _TrackingRecurringFinanceStore extends FinanceStore {
  _TrackingRecurringFinanceStore({
    super.initialBalances,
    super.initialRecurringItems,
  });

  int saveBalancesCalls = 0;
  int saveTransactionsCalls = 0;
  int saveRecurringItemsCalls = 0;

  @override
  Future<void> saveBalances() {
    saveBalancesCalls++;
    return super.saveBalances();
  }

  @override
  Future<void> saveTransactions() {
    saveTransactionsCalls++;
    return super.saveTransactions();
  }

  @override
  Future<void> saveRecurringItems() {
    saveRecurringItemsCalls++;
    return super.saveRecurringItems();
  }
}

class _DelayedFundPortfolioFinanceStore extends FinanceStore {
  _DelayedFundPortfolioFinanceStore({
    super.initialFunds,
    super.initialAssetMovements,
  });

  final Completer<void> _saveCompleter = Completer<void>();
  int saveCalls = 0;

  @override
  Future<void> savePortfolio() {
    saveCalls++;
    return _saveCompleter.future;
  }

  void completeSave() => _saveCompleter.complete();
}

class _FailingFundPortfolioFinanceStore extends FinanceStore {
  @override
  Future<void> savePortfolio() => Future.error(StateError('save failure'));
}

FinanceBalance _balance({
  String id = 'account',
  String name = 'Conto',
  bool active = true,
}) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: name,
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime(2026, 8, 18),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: active,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceAccountLinkedItem _linkedItem({String id = 'linked'}) =>
    FinanceAccountLinkedItem(
      id: id,
      balanceId: 'account',
      type: FinanceAccountLinkedItemType.debitCard,
      name: 'Carta',
      description: '',
    );

FinanceTransaction _transaction({String id = 'transaction'}) =>
    FinanceTransaction(
      id: id,
      balanceId: 'account',
      amount: 10,
      date: DateTime(2026, 8, 19),
      isIncome: false,
      subject: FinanceSubject.matteo,
      description: 'Spesa',
      type: FinanceTransactionType.expense,
      origin: FinanceTransactionOrigin.manual,
    );

FinanceSnapshot _snapshot() => FinanceSnapshot(
  date: DateTime(2026, 8, 19),
  totalBalance: 100,
  totalFunds: 0,
  familyNetWorth: 100,
  projectedMonthlyIncome: 0,
  projectedMonthlyExpenses: 0,
  projectedMonthlyMargin: 0,
  underPressure: false,
  operationalBalance: 100,
  operationalStressRatio: 0,
  operationalStressLevel: 'stable',
  vitalityState: 'stable',
  economicTrend: 'stable',
  resilienceRatio: 1,
  recovering: false,
  fatigued: false,
  degrading: false,
  losingControl: false,
  drowning: false,
);

FinanceFund _fund({String id = 'fund', double amount = 100}) => FinanceFund(
  id: id,
  name: 'Fondo',
  description: '',
  amount: amount,
  protected: false,
  category: FinanceFundCategory.generic,
);

FundTransaction _fundTransaction() => FundTransaction(
  id: 'fund-transaction',
  fundId: 'fund',
  description: 'Versamento',
  amount: 100,
  date: DateTime(2026, 8, 21),
  type: FundTransactionType.deposit,
);

FinanceAssetMovement _assetMovement() => FinanceAssetMovement(
  id: 'movement',
  fundId: 'fund',
  kind: FinanceAssetMovementKind.fundOpening,
  description: 'Versamento',
  occurredAt: DateTime(2026, 8, 21),
  legs: const [
    FinanceAssetLeg(
      type: FinanceAssetLegType.openingBalance,
      referenceId: 'opening',
      delta: -100,
    ),
    FinanceAssetLeg(
      type: FinanceAssetLegType.fund,
      referenceId: 'fund',
      delta: 100,
    ),
  ],
);
