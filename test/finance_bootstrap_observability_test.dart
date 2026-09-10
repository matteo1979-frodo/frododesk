import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_lifecycle_loader.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Portfolio V2 load notifies once with a complete stable state',
    () async {
      final seed = FinanceStore(
        initialBalances: [_balance()],
        initialFunds: [_fund()],
        initialAssetMovements: [_movement()],
        initialTransactions: [_transaction()],
      );
      await seed.savePortfolio();

      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() {
        notifications++;
        expect(store.balances, hasLength(1));
        expect(store.funds, hasLength(1));
        expect(store.assetMovements, hasLength(1));
        expect(store.transactions, hasLength(1));
      });

      expect(await store.loadSavedPortfolio(), isTrue);
      expect(notifications, 1);
      expect(await store.loadSavedPortfolio(), isTrue);
      expect(notifications, 1);
    },
  );

  test('legacy bootstrap migrates and emits one stable notification', () async {
    final legacy = FinanceStore(
      initialBalances: [_balance()],
      initialFunds: [_fund()],
    );
    await legacy.saveBalances();
    await legacy.saveFunds();

    final store = FinanceStore();
    var notifications = 0;
    store.addListener(() {
      notifications++;
      expect(store.balances, isNotEmpty);
      expect(store.funds, isNotEmpty);
      expect(store.assetMovements, isNotEmpty);
    });

    await store.loadInitialRealData();

    expect(notifications, 1);
    final restored = FinanceStore();
    expect(await restored.loadSavedPortfolio(), isTrue);
    expect(restored.funds.single.id, 'fund');
  });

  test(
    'empty persistence creates demo once and identical reload is silent',
    () async {
      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() {
        notifications++;
        expect(store.balances, isNotEmpty);
        expect(store.funds, isNotEmpty);
        expect(store.recurringItems, isNotEmpty);
        expect(store.assetMovements, isNotEmpty);
      });

      await store.loadInitialRealData();
      expect(notifications, 1);
      final firstState = store.balances.map((item) => item.toJson()).toList();

      await store.loadInitialRealData();
      expect(notifications, 1);
      expect(store.balances.map((item) => item.toJson()).toList(), firstState);
    },
  );

  test(
    'Portfolio V2 remains authoritative when legacy data also exists',
    () async {
      final portfolio = FinanceStore(
        initialBalances: [_balance()],
        initialFunds: [_fund()],
      );
      await portfolio.savePortfolio();
      final legacy = FinanceStore(
        initialBalances: [_balance(name: 'Conto legacy')],
        initialFunds: [
          const FinanceFund(
            id: 'legacy',
            name: 'Legacy',
            description: '',
            amount: 999,
            protected: false,
            category: FinanceFundCategory.generic,
          ),
        ],
      );
      await legacy.saveBalances();
      await legacy.saveFunds();

      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);
      await store.loadInitialRealData();

      expect(notifications, 1);
      expect(store.balances.single.name, 'Conto');
      expect(store.funds.single.id, 'fund');
    },
  );

  test('load errors notify only when parsing already changed memory', () async {
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': jsonEncode({
        'version': 2,
        'balances': [_balance().toJson()],
        'funds': 'invalid',
        'assetMovements': const [],
        'transactions': const [],
      }),
    });
    final partiallyLoaded = FinanceStore();
    var partialNotifications = 0;
    partiallyLoaded.addListener(() => partialNotifications++);

    await expectLater(
      partiallyLoaded.loadSavedPortfolio(),
      throwsA(isA<TypeError>()),
    );
    expect(partiallyLoaded.balances, hasLength(1));
    expect(partialNotifications, 1);

    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': '{invalid-json',
    });
    final untouched = FinanceStore();
    var untouchedNotifications = 0;
    untouched.addListener(() => untouchedNotifications++);

    await expectLater(untouched.loadSavedPortfolio(), throwsFormatException);
    expect(untouchedNotifications, 0);
  });

  test(
    'migration error propagates after exposing mutated memory once',
    () async {
      final store = _FailingMigrationFinanceStore(initialFunds: [_fund()]);
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(store.migrateLegacyPortfolio(), throwsStateError);

      expect(store.assetMovements, hasLength(1));
      expect(notifications, 1);
    },
  );

  test(
    'lifecycle batches bootstrap and snapshot into one notification',
    () async {
      final store = FinanceStore();
      var notifications = 0;
      var refreshes = 0;
      store.addListener(() {
        notifications++;
        expect(store.balances, isNotEmpty);
        expect(store.snapshots, hasLength(1));
      });

      await FinanceLifecycleLoader(
        financeStore: store,
        refresh: () => refreshes++,
      ).load();

      expect(notifications, 1);
      expect(refreshes, 1);

      await FinanceLifecycleLoader(
        financeStore: store,
        refresh: () => refreshes++,
      ).load();
      expect(notifications, 1);
      expect(refreshes, 2);
    },
  );
}

class _FailingMigrationFinanceStore extends FinanceStore {
  _FailingMigrationFinanceStore({super.initialFunds});

  @override
  Future<void> savePortfolio() => Future.error(StateError('save failure'));
}

FinanceBalance _balance({String name = 'Conto'}) => FinanceBalance(
  personId: 'matteo',
  balanceId: 'account',
  name: name,
  initialAmount: 1000,
  currentAmount: 1000,
  updatedAt: DateTime(2026, 8, 23),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceFund _fund() => const FinanceFund(
  id: 'fund',
  name: 'Fondo',
  description: '',
  amount: 100,
  protected: false,
  category: FinanceFundCategory.generic,
);

FinanceAssetMovement _movement() => FinanceAssetMovement(
  id: 'movement',
  fundId: 'fund',
  kind: FinanceAssetMovementKind.fundOpening,
  description: 'Apertura',
  occurredAt: DateTime(2026, 8, 23),
  legs: const [
    FinanceAssetLeg(type: FinanceAssetLegType.openingBalance, delta: -100),
    FinanceAssetLeg(
      type: FinanceAssetLegType.fund,
      referenceId: 'fund',
      delta: 100,
    ),
  ],
);

FinanceTransaction _transaction() => FinanceTransaction(
  id: 'transaction',
  balanceId: 'account',
  amount: 10,
  date: DateTime(2026, 8, 23),
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: 'Spesa',
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: 'fact',
);
