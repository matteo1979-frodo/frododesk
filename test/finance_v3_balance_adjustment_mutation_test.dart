import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/economics/economic_fact_id_generator.dart';
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
    'V3 updateBalance commits amount and one adjustment atomically',
    () async {
      final initial = _portfolio();
      var writes = 0;
      String? payload;
      final store = await _store(
        initial,
        writer: _writer((value) {
          writes++;
          payload = value;
        }),
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.updateBalance(balanceId: 'account', newAmount: 80);

      expect(writes, 1);
      expect(notifications, 1);
      expect(store.balances.first.currentAmount, 80);
      expect(store.transactions, hasLength(initial.transactions.length + 1));
      final adjustment = store.transactions.last;
      expect(adjustment.amount, 20);
      expect(adjustment.isIncome, isFalse);
      expect(adjustment.type, FinanceTransactionType.expense);
      expect(adjustment.origin, FinanceTransactionOrigin.adjustment);
      expect(adjustment.economicFactId, 'adjustment_fact');
      final json = jsonDecode(payload!) as Map<String, dynamic>;
      expect(json['funds'], hasLength(initial.funds.length));
      expect(json['assetMovements'], hasLength(initial.assetMovements.length));
      expect(
        json['fundTransactions'],
        hasLength(initial.fundTransactions.length),
      );
      expect(json['linkedItems'], hasLength(initial.linkedItems.length));
    },
  );

  test(
    'V3 updateBalance writer failure keeps memory and notifications unchanged',
    () async {
      final store = await _store(_portfolio(), writer: _failingWriter());
      final before = _state(store);
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(
        store.updateBalance(balanceId: 'account', newAmount: 80),
        throwsStateError,
      );

      expect(_state(store), before);
      expect(notifications, 0);
    },
  );

  test(
    'V3 equal amount preserves updatedAt persistence semantics without transaction',
    () async {
      final initial = _portfolio();
      var writes = 0;
      final store = await _store(initial, writer: _writer((_) => writes++));
      final beforeUpdatedAt = store.balances.first.updatedAt;
      final beforeTransactions = store.transactions.length;
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.updateBalance(balanceId: 'account', newAmount: 100);

      expect(store.balances.first.updatedAt.isAfter(beforeUpdatedAt), isTrue);
      expect(store.transactions, hasLength(beforeTransactions));
      expect(writes, 1);
      expect(notifications, 1);
    },
  );

  test('V3 profile-only update commits once without adjustment', () async {
    final initial = _portfolio();
    var writes = 0;
    final store = await _store(initial, writer: _writer((_) => writes++));
    var notifications = 0;
    store.addListener(() => notifications++);

    final changed = await store.updateBalanceDetailsAndAmount(
      details: _copyBalance(store.balances.first, name: 'Renamed'),
      newAmount: 100,
    );

    expect(changed, isTrue);
    expect(store.balances.first.name, 'Renamed');
    expect(store.transactions, hasLength(initial.transactions.length));
    expect(writes, 1);
    expect(notifications, 1);
  });

  test(
    'V3 profile and amount share one candidate, write and notification',
    () async {
      final initial = _portfolio();
      var writes = 0;
      final store = await _store(initial, writer: _writer((_) => writes++));
      var notifications = 0;
      store.addListener(() => notifications++);

      final changed = await store.updateBalanceDetailsAndAmount(
        details: _copyBalance(store.balances.first, name: 'Renamed'),
        newAmount: 125,
      );

      expect(changed, isTrue);
      expect(store.balances.first.name, 'Renamed');
      expect(store.balances.first.currentAmount, 125);
      expect(store.transactions, hasLength(initial.transactions.length + 1));
      expect(store.transactions.last.amount, 25);
      expect(store.transactions.last.isIncome, isTrue);
      expect(writes, 1);
      expect(notifications, 1);
    },
  );

  test('V3 profile and amount failure exposes no partial profile', () async {
    final store = await _store(_portfolio(), writer: _failingWriter());
    final before = _state(store);
    var notifications = 0;
    store.addListener(() => notifications++);

    await expectLater(
      store.updateBalanceDetailsAndAmount(
        details: _copyBalance(store.balances.first, name: 'Rejected'),
        newAmount: 125,
      ),
      throwsStateError,
    );

    expect(_state(store), before);
    expect(notifications, 0);
  });

  test('legacy adjustment behavior and persistence remain unchanged', () async {
    final store = FinanceStore(
      economicFactIdGenerator: EconomicFactIdGenerator.from(
        () => 'legacy_fact',
      ),
      initialBalances: [_balance()],
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    final changed = await store.updateBalanceDetailsAndAmount(
      details: _copyBalance(store.balances.first, name: 'Legacy renamed'),
      newAmount: 90,
    );

    expect(changed, isTrue);
    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(store.balances.single.name, 'Legacy renamed');
    expect(store.balances.single.currentAmount, 90);
    expect(store.transactions.single.economicFactId, 'legacy_fact');
    expect(notifications, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_balances'), isNotNull);
    expect(prefs.getString('frododesk_finance_transactions'), isNotNull);
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
  });
}

Future<FinanceStore> _store(
  FinancePortfolioV3 portfolio, {
  FinancePortfolioV3Writer? writer,
}) async {
  SharedPreferences.setMockInitialValues({
    'frododesk_finance_portfolio_v3': jsonEncode(
      FinancePortfolioV3Contract.build(portfolio),
    ),
  });
  final store = FinanceStore(
    economicFactIdGenerator: EconomicFactIdGenerator.from(
      () => 'adjustment_fact',
    ),
    portfolioV3Writer: writer,
  );
  expect(await store.loadSavedPortfolioV3(), isTrue);
  return store;
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

FinancePortfolioV3 _portfolio() {
  final balance = _balance();
  final fund = FinanceFund(
    id: 'fund',
    name: 'Fund',
    description: '',
    amount: 10,
    protected: false,
    category: FinanceFundCategory.generic,
  );
  return FinancePortfolioV3(
    balances: [balance],
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
            delta: -10,
          ),
          FinanceAssetLeg(
            type: FinanceAssetLegType.fund,
            referenceId: fund.id,
            delta: 10,
          ),
        ],
      ),
    ],
    transactions: [
      FinanceTransaction(
        id: 'existing',
        balanceId: balance.balanceId,
        amount: 1,
        date: DateTime.utc(2026, 9, 9),
        isIncome: false,
        subject: FinanceSubject.matteo,
        description: 'Existing',
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
      ),
    ],
    fundTransactions: [
      FundTransaction(
        id: 'fund_transaction',
        fundId: fund.id,
        description: 'Existing',
        amount: 10,
        date: DateTime.utc(2026, 9, 9),
        type: FundTransactionType.deposit,
      ),
    ],
    linkedItems: [
      FinanceAccountLinkedItem(
        id: 'linked',
        balanceId: balance.balanceId,
        type: FinanceAccountLinkedItemType.debitCard,
        name: 'Card',
        description: '',
      ),
    ],
  );
}

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'account',
  name: 'Account',
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime.utc(2026, 1, 1),
  balanceType: FinanceBalanceType.bankAccount,
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
      updatedAt: DateTime.utc(2026, 9, 10),
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
