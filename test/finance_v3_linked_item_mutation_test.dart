import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_account_linked_item.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/fund_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'addLinkedItem with null relation writes complete V3 then publishes',
    () async {
      final initial = _portfolio();
      await _seedV3(initial);
      String? written;
      final store = FinanceStore(
        portfolioV3Writer: _successfulWriter((value) => written = value),
      );
      expect(await store.loadSavedPortfolioV3(), isTrue);
      var notifications = 0;
      store.addListener(() => notifications++);
      final item = _linked(id: 'new_linked');

      expect(await store.addLinkedItem(item), isTrue);

      expect(store.linkedItems.last.id, item.id);
      expect(store.linkedItems.last.balanceId, 'parent');
      expect(store.linkedItems.last.autonomousBalanceId, isNull);
      expect(notifications, 1);
      final json = jsonDecode(written!) as Map<String, dynamic>;
      expect(json['version'], 3);
      expect(json['balances'], hasLength(initial.balances.length));
      expect(json['funds'], hasLength(initial.funds.length));
      expect(json['assetMovements'], hasLength(initial.assetMovements.length));
      expect(json['transactions'], hasLength(initial.transactions.length));
      expect(
        json['fundTransactions'],
        hasLength(initial.fundTransactions.length),
      );
      expect(json['linkedItems'], hasLength(initial.linkedItems.length + 1));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('frododesk_finance_portfolio_v2'), isNull);
      expect(prefs.getString('frododesk_finance_account_linked_items'), isNull);
    },
  );

  test('explicit valid autonomous balance relation is preserved', () async {
    final initial = _portfolio();
    await _seedV3(initial);
    final store = FinanceStore();
    expect(await store.loadSavedPortfolioV3(), isTrue);
    final item = _linked(
      id: 'autonomous_linked',
      autonomousBalanceId: 'prepaid',
      name: 'A name unrelated to either balance',
    );

    expect(await store.addLinkedItem(item), isTrue);

    final saved = store.linkedItems.last;
    expect(saved.balanceId, 'parent');
    expect(saved.autonomousBalanceId, 'prepaid');
  });

  test('addLinkedItem writer failure leaves all memory unchanged', () async {
    final initial = _portfolio();
    await _seedV3(initial);
    final store = FinanceStore(portfolioV3Writer: _failingWriter());
    expect(await store.loadSavedPortfolioV3(), isTrue);
    final before = _state(store);
    var notifications = 0;
    store.addListener(() => notifications++);

    await expectLater(
      store.addLinkedItem(_linked(id: 'rejected')),
      throwsStateError,
    );

    expect(_state(store), before);
    expect(store.isPortfolioV3Authoritative, isTrue);
    expect(notifications, 0);
  });

  test(
    'invalid autonomous targets fail validation without writer call',
    () async {
      for (final target in ['missing', 'parent']) {
        final initial = _portfolio();
        await _seedV3(initial);
        var writes = 0;
        final store = FinanceStore(
          portfolioV3Writer: _successfulWriter((_) => writes++),
        );
        expect(await store.loadSavedPortfolioV3(), isTrue);
        final before = _state(store);
        var notifications = 0;
        store.addListener(() => notifications++);

        await expectLater(
          store.addLinkedItem(
            _linked(id: 'invalid_$target', autonomousBalanceId: target),
          ),
          throwsStateError,
        );

        expect(writes, 0);
        expect(_state(store), before);
        expect(notifications, 0);
      }
    },
  );

  test('parent and autonomous self reference is rejected', () async {
    final prepaidOnly = _balance(
      'prepaid',
      type: FinanceBalanceType.prepaidCard,
    );
    final initial = FinancePortfolioV3(
      balances: [prepaidOnly],
      funds: const [],
      assetMovements: const [],
      transactions: const [],
      fundTransactions: const [],
      linkedItems: const [],
    );
    await _seedV3(initial);
    var writes = 0;
    final store = FinanceStore(
      portfolioV3Writer: _successfulWriter((_) => writes++),
    );
    expect(await store.loadSavedPortfolioV3(), isTrue);

    await expectLater(
      store.addLinkedItem(
        _linked(
          id: 'self',
          parentBalanceId: 'prepaid',
          autonomousBalanceId: 'prepaid',
        ),
      ),
      throwsStateError,
    );

    expect(writes, 0);
    expect(store.linkedItems, isEmpty);
  });

  test(
    'replace and deactivate publish once only after verified V3 write',
    () async {
      final initial = _portfolio();
      await _seedV3(initial);
      final store = FinanceStore();
      expect(await store.loadSavedPortfolioV3(), isTrue);
      var notifications = 0;
      store.addListener(() => notifications++);
      final current = store.linkedItems.single;
      final replacement = current.copyWith(
        name: 'Updated card',
        description: 'Updated description',
        expirationDate: DateTime.utc(2030, 1),
      );

      expect(await store.replaceLinkedItem(replacement), isTrue);
      expect(store.linkedItems.single.name, 'Updated card');
      expect(await store.setLinkedItemActive(current.id, false), isTrue);
      expect(store.linkedItems.single.active, isFalse);
      expect(notifications, 2);

      final reloaded = FinanceStore();
      expect(await reloaded.loadSavedPortfolioV3(), isTrue);
      expect(reloaded.linkedItems.single.name, 'Updated card');
      expect(reloaded.linkedItems.single.active, isFalse);
    },
  );

  test(
    'replace and deactivate failure preserve previous linked item',
    () async {
      final initial = _portfolio();
      await _seedV3(initial);
      final store = FinanceStore(portfolioV3Writer: _failingWriter());
      expect(await store.loadSavedPortfolioV3(), isTrue);
      final current = store.linkedItems.single;
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(
        store.replaceLinkedItem(current.copyWith(name: 'Rejected')),
        throwsStateError,
      );
      await expectLater(
        store.setLinkedItemActive(current.id, false),
        throwsStateError,
      );

      expect(store.linkedItems.single.name, current.name);
      expect(store.linkedItems.single.active, isTrue);
      expect(notifications, 0);
    },
  );

  test('replace can explicitly clear autonomousBalanceId', () async {
    final initial = _portfolio();
    await _seedV3(initial);
    final store = FinanceStore();
    expect(await store.loadSavedPortfolioV3(), isTrue);
    final current = store.linkedItems.single;
    expect(current.autonomousBalanceId, 'prepaid');

    expect(
      await store.replaceLinkedItem(
        current.copyWith(clearAutonomousBalanceId: true),
      ),
      isTrue,
    );

    expect(store.linkedItems.single.autonomousBalanceId, isNull);
    final reloaded = FinanceStore();
    expect(await reloaded.loadSavedPortfolioV3(), isTrue);
    expect(reloaded.linkedItems.single.autonomousBalanceId, isNull);
  });

  test(
    'identical and missing linked operations remain write-free no-ops',
    () async {
      final initial = _portfolio();
      await _seedV3(initial);
      var writes = 0;
      final store = FinanceStore(
        portfolioV3Writer: _successfulWriter((_) => writes++),
      );
      expect(await store.loadSavedPortfolioV3(), isTrue);
      final current = store.linkedItems.single;
      var notifications = 0;
      store.addListener(() => notifications++);

      expect(await store.addLinkedItem(current), isFalse);
      expect(await store.replaceLinkedItem(current), isFalse);
      expect(await store.replaceLinkedItem(_linked(id: 'missing')), isFalse);
      expect(await store.setLinkedItemActive('missing', false), isFalse);
      expect(await store.setLinkedItemActive(current.id, true), isFalse);

      expect(writes, 0);
      expect(notifications, 0);
    },
  );

  test('V2 mode keeps linked legacy persistence without promotion', () async {
    final initial = _portfolio();
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': jsonEncode(_v2(initial)),
      'frododesk_finance_account_linked_items': jsonEncode(
        initial.linkedItems.map((item) => item.toJson()).toList(),
      ),
    });
    final store = FinanceStore();
    await store.loadInitialRealData();
    final added = _linked(id: 'legacy_added');

    expect(await store.addLinkedItem(added), isTrue);
    expect(
      await store.replaceLinkedItem(added.copyWith(name: 'Legacy updated')),
      isTrue,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
    final legacy =
        jsonDecode(prefs.getString('frododesk_finance_account_linked_items')!)
            as List;
    expect(legacy, hasLength(initial.linkedItems.length + 1));
    expect(legacy.last['name'], 'Legacy updated');
    expect(store.isPortfolioV3Authoritative, isFalse);
  });

  test(
    'read-only bootstrap preserves null relation and does not create V3',
    () async {
      final parent = _balance('parent', name: 'Matching name');
      final linked = _linked(id: 'legacy', name: 'Matching name');
      final portfolio = FinancePortfolioV3(
        balances: [parent],
        funds: const [],
        assetMovements: const [],
        transactions: const [],
        fundTransactions: const [],
        linkedItems: [linked],
      );
      SharedPreferences.setMockInitialValues({
        'frododesk_finance_portfolio_v2': jsonEncode(_v2(portfolio)),
        'frododesk_finance_account_linked_items': jsonEncode([linked.toJson()]),
      });

      final store = FinanceStore();
      await store.loadInitialRealData();

      expect(store.linkedItems.single.autonomousBalanceId, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
    },
  );

  test('T2 authoritative balance mutation paths remain operational', () async {
    final initial = _portfolio();
    await _seedV3(initial);
    final store = FinanceStore();
    expect(await store.loadSavedPortfolioV3(), isTrue);

    expect(await store.addBalance(_balance('new_balance')), isTrue);
    final added = store.balances.last;
    expect(
      await store.replaceBalance(_copyBalance(added, name: 'Updated balance')),
      isTrue,
    );
    expect(await store.setBalanceActive(added.balanceId, false), isTrue);

    expect(store.balances.last.name, 'Updated balance');
    expect(store.balances.last.active, isFalse);
  });
}

FinancePortfolioV3Writer _successfulWriter(void Function(String) onWrite) {
  return FinancePortfolioV3Writer(
    saveVerified: (key, value) async {
      onWrite(value);
      final prefs = await SharedPreferences.getInstance();
      final accepted = await prefs.setString('frododesk_$key', value);
      return PersistenceWriteVerification(
        backendAccepted: accepted,
        readBack: prefs.getString('frododesk_$key'),
      );
    },
  );
}

FinancePortfolioV3Writer _failingWriter() => FinancePortfolioV3Writer(
  saveVerified: (key, value) async => const PersistenceWriteVerification(
    backendAccepted: false,
    readBack: null,
  ),
);

Future<void> _seedV3(FinancePortfolioV3 portfolio) async {
  SharedPreferences.setMockInitialValues({
    'frododesk_finance_portfolio_v3': jsonEncode(
      FinancePortfolioV3Contract.build(portfolio),
    ),
  });
}

Map<String, dynamic> _v2(FinancePortfolioV3 portfolio) => {
  'version': 2,
  'balances': portfolio.balances.map((item) => item.toJson()).toList(),
  'funds': portfolio.funds.map((item) => item.toJson()).toList(),
  'assetMovements': portfolio.assetMovements
      .map((item) => item.toJson())
      .toList(),
  'transactions': portfolio.transactions.map((item) => item.toJson()).toList(),
  'fundTransactions': portfolio.fundTransactions
      .map((item) => item.toJson())
      .toList(),
};

FinancePortfolioV3 _portfolio() {
  final parent = _balance('parent');
  final prepaid = _balance('prepaid', type: FinanceBalanceType.prepaidCard);
  final fund = FinanceFund(
    id: 'fund',
    name: 'Fund',
    description: '',
    amount: 20,
    protected: false,
    category: FinanceFundCategory.generic,
  );
  return FinancePortfolioV3(
    balances: [parent, prepaid],
    funds: [fund],
    assetMovements: [
      FinanceAssetMovement(
        id: 'movement',
        fundId: fund.id,
        kind: FinanceAssetMovementKind.fundOpening,
        description: 'Opening',
        occurredAt: DateTime.utc(2026, 9, 10),
        legs: [
          const FinanceAssetLeg(
            type: FinanceAssetLegType.openingBalance,
            delta: -20,
          ),
          FinanceAssetLeg(
            type: FinanceAssetLegType.fund,
            referenceId: fund.id,
            delta: 20,
          ),
        ],
      ),
    ],
    transactions: [
      FinanceTransaction(
        id: 'transaction',
        balanceId: parent.balanceId,
        amount: 5,
        date: DateTime.utc(2026, 9, 10),
        isIncome: false,
        subject: FinanceSubject.shared,
        description: 'Expense',
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
      ),
    ],
    fundTransactions: [
      FundTransaction(
        id: 'fund_transaction',
        fundId: fund.id,
        description: 'Deposit',
        amount: 20,
        date: DateTime.utc(2026, 9, 10),
        type: FundTransactionType.deposit,
      ),
    ],
    linkedItems: [
      _linked(id: 'existing', autonomousBalanceId: prepaid.balanceId),
    ],
  );
}

FinanceAccountLinkedItem _linked({
  required String id,
  String parentBalanceId = 'parent',
  String? autonomousBalanceId,
  String? name,
}) => FinanceAccountLinkedItem(
  id: id,
  balanceId: parentBalanceId,
  autonomousBalanceId: autonomousBalanceId,
  type: FinanceAccountLinkedItemType.prepaidCard,
  name: name ?? id,
  description: '',
);

FinanceBalance _balance(
  String id, {
  String? name,
  FinanceBalanceType type = FinanceBalanceType.bankAccount,
}) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: name ?? id,
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime.utc(2026, 9, 10),
  balanceType: type,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceBalance _copyBalance(FinanceBalance current, {required String name}) =>
    FinanceBalance(
      personId: current.personId,
      balanceId: current.balanceId,
      name: name,
      initialAmount: current.initialAmount,
      currentAmount: current.currentAmount,
      updatedAt: current.updatedAt,
      balanceType: current.balanceType,
      operational: current.operational,
      active: current.active,
      reservedAmount: current.reservedAmount,
      warningThreshold: current.warningThreshold,
      persistentStressDays: current.persistentStressDays,
      recoveryDays: current.recoveryDays,
    );

String _state(FinanceStore store) => jsonEncode({
  'balances': store.balances.map((item) => item.toJson()).toList(),
  'funds': store.funds.map((item) => item.toJson()).toList(),
  'assetMovements': store.assetMovements.map((item) => item.toJson()).toList(),
  'transactions': store.transactions.map((item) => item.toJson()).toList(),
  'fundTransactions': store.fundTransactions
      .map((item) => item.toJson())
      .toList(),
  'linkedItems': store.linkedItems.map((item) => item.toJson()).toList(),
});
