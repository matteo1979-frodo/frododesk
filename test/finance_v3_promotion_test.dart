import 'dart:async';
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

  test('promotes hydrated V2 plus legacy linked data without visible changes', () async {
    final fixture = _fixture();
    final legacy = _legacyValues(fixture);
    SharedPreferences.setMockInitialValues(legacy);
    String? payload;
    final promotedStore = FinanceStore(
      portfolioV3Writer: _writer((value) => payload = value),
    );
    await promotedStore.loadInitialRealData();
    final before = _state(promotedStore);
    var notifications = 0;
    promotedStore.addListener(() => notifications++);

    final result = await promotedStore.promotePortfolioV3();

    expect(result.status, FinancePortfolioV3PromotionStatus.promoted);
    expect(result.isSuccess, isTrue);
    expect(promotedStore.isPortfolioV3Authoritative, isTrue);
    expect(_state(promotedStore), before);
    expect(notifications, 0);
    final json = jsonDecode(payload!) as Map<String, dynamic>;
    expect(json['balances'], hasLength(1));
    expect(json['funds'], hasLength(1));
    expect(json['assetMovements'], hasLength(1));
    expect(json['transactions'], hasLength(1));
    expect(json['fundTransactions'], hasLength(1));
    expect(json['linkedItems'], hasLength(1));
    expect((json['linkedItems'] as List).single['autonomousBalanceId'], isNull);
    final prefs = await SharedPreferences.getInstance();
    for (final entry in legacy.entries) {
      expect(prefs.getString(entry.key), entry.value);
    }
  });

  test('verified write completes before V3 becomes authoritative', () async {
    final fixture = _fixture();
    SharedPreferences.setMockInitialValues(_legacyValues(fixture));
    final completer = Completer<PersistenceWriteVerification>();
    String? payload;
    final store = FinanceStore(
      portfolioV3Writer: FinancePortfolioV3Writer(
        saveVerified: (_, value) {
          payload = value;
          return completer.future;
        },
      ),
    );
    await store.loadInitialRealData();
    var notifications = 0;
    store.addListener(() => notifications++);

    final pending = store.promotePortfolioV3();
    await Future<void>.delayed(Duration.zero);

    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(notifications, 0);
    completer.complete(
      PersistenceWriteVerification(backendAccepted: true, readBack: payload),
    );
    expect((await pending).isSuccess, isTrue);
    expect(store.isPortfolioV3Authoritative, isTrue);
    expect(notifications, 0);
  });

  test('writer failure preserves memory, legacy authority and notifications', () async {
    final fixture = _fixture();
    SharedPreferences.setMockInitialValues(_legacyValues(fixture));
    final store = FinanceStore(portfolioV3Writer: _failingWriter());
    await store.loadInitialRealData();
    final before = _state(store);
    var notifications = 0;
    store.addListener(() => notifications++);

    final result = await store.promotePortfolioV3();

    expect(result.status, FinancePortfolioV3PromotionStatus.writerFailed);
    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(_state(store), before);
    expect(notifications, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
  });

  test('invalid candidate is rejected before the writer', () async {
    final fixture = _fixture(
      linked: _linked(parentId: 'missing'),
    );
    SharedPreferences.setMockInitialValues(_legacyValues(fixture));
    var writes = 0;
    final store = FinanceStore(
      portfolioV3Writer: _writer((_) => writes++),
    );
    await store.loadInitialRealData();
    final before = _state(store);

    final result = await store.promotePortfolioV3();

    expect(result.status, FinancePortfolioV3PromotionStatus.invalidCandidate);
    expect(result.errors, contains(contains('missing parent balance')));
    expect(writes, 0);
    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(_state(store), before);
  });

  test('not-ready and already-authoritative guards are write-free', () async {
    var writes = 0;
    final notReady = FinanceStore(
      portfolioV3Writer: _writer((_) => writes++),
      initialBalances: [_balance()],
    );
    expect(
      (await notReady.promotePortfolioV3()).status,
      FinancePortfolioV3PromotionStatus.notReady,
    );
    expect(writes, 0);

    final fixture = _fixture();
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': jsonEncode(
        FinancePortfolioV3Contract.build(fixture),
      ),
    });
    final authoritative = FinanceStore(
      portfolioV3Writer: _writer((_) => writes++),
    );
    expect(await authoritative.loadSavedPortfolioV3(), isTrue);
    final result = await authoritative.promotePortfolioV3();
    expect(result.status, FinancePortfolioV3PromotionStatus.alreadyAuthoritative);
    expect(result.isSuccess, isTrue);
    expect(writes, 0);
  });

  test('V2 alone is not promotable before linked legacy hydration', () async {
    final fixture = _fixture();
    SharedPreferences.setMockInitialValues(_legacyValues(fixture));
    var writes = 0;
    final store = FinanceStore(
      portfolioV3Writer: _writer((_) => writes++),
    );
    expect(await store.loadSavedPortfolio(), isTrue);

    final result = await store.promotePortfolioV3();

    expect(result.status, FinancePortfolioV3PromotionStatus.notReady);
    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(writes, 0);
  });

  test('converted mutation uses V3 after promotion and leaves legacy unchanged', () async {
    final fixture = _fixture();
    final legacy = _legacyValues(fixture);
    SharedPreferences.setMockInitialValues(legacy);
    var writes = 0;
    final store = FinanceStore(
      portfolioV3Writer: _writer((_) => writes++),
    );
    await store.loadInitialRealData();
    expect((await store.promotePortfolioV3()).isSuccess, isTrue);

    expect(await store.addBalance(_balance(id: 'new_balance')), isTrue);

    expect(writes, 2);
    expect(store.balances, hasLength(2));
    final prefs = await SharedPreferences.getInstance();
    for (final entry in legacy.entries) {
      expect(prefs.getString(entry.key), entry.value);
    }
  });

  test('next bootstrap uses promoted V3 only and never mixes legacy data', () async {
    final fixture = _fixture();
    SharedPreferences.setMockInitialValues(_legacyValues(fixture));
    final store = FinanceStore();
    await store.loadInitialRealData();
    expect((await store.promotePortfolioV3()).isSuccess, isTrue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'frododesk_finance_portfolio_v2',
      jsonEncode(_v2(_fixture(balance: _balance(id: 'conflicting_v2')))),
    );
    await prefs.setString(
      'frododesk_finance_account_linked_items',
      jsonEncode([_linked(id: 'conflicting_linked').toJson()]),
    );

    final reloaded = FinanceStore();
    await reloaded.loadInitialRealData();

    expect(reloaded.isPortfolioV3Authoritative, isTrue);
    expect(reloaded.balances.single.balanceId, fixture.balances.single.balanceId);
    expect(reloaded.linkedItems.single.id, fixture.linkedItems.single.id);
  });

  test('invalid persisted V3 still blocks fallback to valid V2', () async {
    final fixture = _fixture();
    final values = _legacyValues(fixture)
      ..['frododesk_finance_portfolio_v3'] = jsonEncode({
        ...FinancePortfolioV3Contract.build(fixture),
        'version': 2,
      });
    SharedPreferences.setMockInitialValues(values);
    final store = FinanceStore();

    await expectLater(store.loadInitialRealData(), throwsFormatException);

    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(store.balances, isEmpty);
    expect(store.linkedItems, isEmpty);
  });
}

FinancePortfolioV3Writer _writer(void Function(String) onWrite) =>
    FinancePortfolioV3Writer(
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

FinancePortfolioV3Writer _failingWriter() => FinancePortfolioV3Writer(
  saveVerified: (_, _) async => const PersistenceWriteVerification(
    backendAccepted: false,
    readBack: null,
  ),
);

Map<String, String> _legacyValues(FinancePortfolioV3 fixture) => {
  'frododesk_finance_portfolio_v2': jsonEncode(_v2(fixture)),
  'frododesk_finance_account_linked_items': jsonEncode(
    fixture.linkedItems.map((item) => item.toJson()).toList(),
  ),
};

Map<String, dynamic> _v2(FinancePortfolioV3 fixture) => {
  'version': 2,
  'balances': fixture.balances.map((item) => item.toJson()).toList(),
  'funds': fixture.funds.map((item) => item.toJson()).toList(),
  'assetMovements': fixture.assetMovements.map((item) => item.toJson()).toList(),
  'transactions': fixture.transactions.map((item) => item.toJson()).toList(),
  'fundTransactions': fixture.fundTransactions
      .map((item) => item.toJson())
      .toList(),
};

FinancePortfolioV3 _fixture({
  FinanceBalance? balance,
  FinanceAccountLinkedItem? linked,
}) {
  final currentBalance = balance ?? _balance();
  final fund = FinanceFund(
    id: 'fund',
    name: 'Fund',
    description: '',
    amount: 20,
    protected: false,
    category: FinanceFundCategory.generic,
  );
  return FinancePortfolioV3(
    balances: [currentBalance],
    funds: [fund],
    assetMovements: [
      FinanceAssetMovement(
        id: 'movement',
        fundId: fund.id,
        kind: FinanceAssetMovementKind.fundAllocation,
        description: 'Movement',
        occurredAt: DateTime.utc(2026, 9, 11),
        legs: [
          FinanceAssetLeg(
            type: FinanceAssetLegType.balance,
            referenceId: currentBalance.balanceId,
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
        balanceId: currentBalance.balanceId,
        amount: 20,
        date: DateTime.utc(2026, 9, 11),
        isIncome: false,
        subject: FinanceSubject.matteo,
        description: 'Transaction',
        type: FinanceTransactionType.transfer,
        origin: FinanceTransactionOrigin.fund,
      ),
    ],
    fundTransactions: [
      FundTransaction(
        id: 'fund_transaction',
        fundId: fund.id,
        description: 'Fund transaction',
        amount: 20,
        date: DateTime.utc(2026, 9, 11),
        type: FundTransactionType.deposit,
      ),
    ],
    linkedItems: [linked ?? _linked(parentId: currentBalance.balanceId)],
  );
}

FinanceBalance _balance({String id = 'balance'}) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: id,
  initialAmount: 100,
  currentAmount: 80,
  updatedAt: DateTime.utc(2026, 9, 11),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceAccountLinkedItem _linked({
  String id = 'linked',
  String parentId = 'balance',
}) => FinanceAccountLinkedItem(
  id: id,
  balanceId: parentId,
  type: FinanceAccountLinkedItemType.prepaidCard,
  name: 'Linked prepaid',
  description: '',
);

String _state(FinanceStore store) => jsonEncode({
  'balances': store.balances.map((item) => item.toJson()).toList(),
  'funds': store.funds.map((item) => item.toJson()).toList(),
  'assetMovements': store.assetMovements.map((item) => item.toJson()).toList(),
  'transactions': store.transactions.map((item) => item.toJson()).toList(),
  'fundTransactions': store.fundTransactions.map((item) => item.toJson()).toList(),
  'linkedItems': store.linkedItems.map((item) => item.toJson()).toList(),
});
