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
    'V3 transfer commits both balances and transactions atomically',
    () async {
      final initial = _portfolio();
      var writes = 0;
      String? payload;
      final store = await _v3Store(
        initial,
        writer: _writer((value) {
          writes++;
          payload = value;
        }),
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.transferBetweenBalances(
        fromBalanceId: 'source',
        toBalanceId: 'destination',
        amount: 40,
        description: 'Test transfer',
      );

      expect(writes, 1);
      expect(notifications, 1);
      expect(store.balances[0].currentAmount, 60);
      expect(store.balances[1].currentAmount, 90);
      expect(store.transactions, hasLength(initial.transactions.length + 2));
      final outgoing = store.transactions[initial.transactions.length];
      final incoming = store.transactions[initial.transactions.length + 1];
      expect(outgoing.balanceId, 'source');
      expect(outgoing.isIncome, isFalse);
      expect(incoming.balanceId, 'destination');
      expect(incoming.isIncome, isTrue);
      expect(outgoing.type, FinanceTransactionType.transfer);
      expect(incoming.type, FinanceTransactionType.transfer);
      expect(outgoing.origin, FinanceTransactionOrigin.manual);
      expect(incoming.origin, FinanceTransactionOrigin.manual);
      expect(outgoing.economicFactId, 'transfer_fact');
      expect(incoming.economicFactId, outgoing.economicFactId);
      expect(outgoing.id, startsWith('transfer_out_'));
      expect(incoming.id, 'transfer_in_${outgoing.id.substring(13)}');

      final json = jsonDecode(payload!) as Map<String, dynamic>;
      expect(json['balances'], hasLength(2));
      expect(json['transactions'], hasLength(initial.transactions.length + 2));
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
    'V3 writer failure leaves both balances and transactions unchanged',
    () async {
      final store = await _v3Store(_portfolio(), writer: _failingWriter());
      final before = _state(store);
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(
        store.transferBetweenBalances(
          fromBalanceId: 'source',
          toBalanceId: 'destination',
          amount: 40,
        ),
        throwsStateError,
      );

      expect(_state(store), before);
      expect(notifications, 0);
    },
  );

  test('V3 missing source preserves no-op behavior', () async {
    var writes = 0;
    final store = await _v3Store(
      _portfolio(),
      writer: _writer((_) => writes++),
    );
    final before = _state(store);
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.transferBetweenBalances(
      fromBalanceId: 'missing',
      toBalanceId: 'destination',
      amount: 40,
    );

    expect(_state(store), before);
    expect(writes, 0);
    expect(notifications, 0);
  });

  test('V3 missing destination preserves no-op behavior', () async {
    var writes = 0;
    final store = await _v3Store(
      _portfolio(),
      writer: _writer((_) => writes++),
    );
    final before = _state(store);
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.transferBetweenBalances(
      fromBalanceId: 'source',
      toBalanceId: 'missing',
      amount: 40,
    );

    expect(_state(store), before);
    expect(writes, 0);
    expect(notifications, 0);
  });

  test(
    'legacy transfer keeps persistence and insufficient funds semantics',
    () async {
      final store = FinanceStore(
        economicFactIdGenerator: EconomicFactIdGenerator.from(
          () => 'legacy_transfer_fact',
        ),
        initialBalances: [_balance('source', 10), _balance('destination', 5)],
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.transferBetweenBalances(
        fromBalanceId: 'source',
        toBalanceId: 'destination',
        amount: 25,
      );

      expect(store.isPortfolioV3Authoritative, isFalse);
      expect(store.balances[0].currentAmount, -15);
      expect(store.balances[1].currentAmount, 30);
      expect(store.transactions, hasLength(2));
      expect(store.transactions.map((item) => item.isIncome), [false, true]);
      expect(store.transactions.map((item) => item.economicFactId).toSet(), {
        'legacy_transfer_fact',
      });
      expect(notifications, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('frododesk_finance_balances'), isNotNull);
      expect(prefs.getString('frododesk_finance_transactions'), isNotNull);
      expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
    },
  );
}

Future<FinanceStore> _v3Store(
  FinancePortfolioV3 portfolio, {
  required FinancePortfolioV3Writer writer,
}) async {
  SharedPreferences.setMockInitialValues({
    'frododesk_finance_portfolio_v3': jsonEncode(
      FinancePortfolioV3Contract.build(portfolio),
    ),
  });
  final store = FinanceStore(
    economicFactIdGenerator: EconomicFactIdGenerator.from(
      () => 'transfer_fact',
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
  final source = _balance('source', 100);
  final destination = _balance('destination', 50);
  final fund = FinanceFund(
    id: 'fund',
    name: 'Fund',
    description: '',
    amount: 10,
    protected: false,
    category: FinanceFundCategory.generic,
  );
  return FinancePortfolioV3(
    balances: [source, destination],
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
        balanceId: source.balanceId,
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
        balanceId: source.balanceId,
        type: FinanceAccountLinkedItemType.debitCard,
        name: 'Card',
        description: '',
      ),
    ],
  );
}

FinanceBalance _balance(String id, double amount) => FinanceBalance(
  personId: id == 'source' ? 'matteo' : 'chiara',
  balanceId: id,
  name: id,
  initialAmount: amount,
  currentAmount: amount,
  updatedAt: DateTime.utc(2026, 1, 1),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

String _state(FinanceStore store) => jsonEncode({
  'balances': store.balances.map((item) => item.toJson()).toList(),
  'transactions': store.transactions.map((item) => item.toJson()).toList(),
});
