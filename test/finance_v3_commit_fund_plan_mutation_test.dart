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
import 'package:frododesk/models/finance_fund_mutation_plan.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/fund_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('V3 fund plan persists complete candidate before one publish', () async {
    final initial = _portfolio('initial');
    final completer = Completer<PersistenceWriteVerification>();
    String? payload;
    final store = await _v3Store(
      initial,
      writer: FinancePortfolioV3Writer(
        saveVerified: (key, value) {
          payload = value;
          return completer.future;
        },
      ),
    );
    final before = _state(store);
    var notifications = 0;
    store.addListener(() => notifications++);
    final updated = _portfolio('updated');

    final pending = store.commitFundPlan(_plan(updated));
    await Future<void>.delayed(Duration.zero);

    expect(_state(store), before);
    expect(notifications, 0);
    final written = jsonDecode(payload!) as Map<String, dynamic>;
    expect((written['balances'] as List).single['balanceId'], 'balance');
    expect((written['balances'] as List).single['currentAmount'], 80);
    expect((written['funds'] as List).single['id'], 'fund');
    expect((written['funds'] as List).single['amount'], 20);
    expect((written['assetMovements'] as List).single['id'], 'updated_movement');
    expect((written['transactions'] as List).single['id'], 'updated_transaction');
    expect(
      (written['fundTransactions'] as List).single['id'],
      'initial_fund_transaction',
    );
    expect((written['linkedItems'] as List).single['id'], 'initial_linked');

    completer.complete(
      PersistenceWriteVerification(backendAccepted: true, readBack: payload),
    );
    await pending;

    expect(store.balances.single.balanceId, 'balance');
    expect(store.balances.single.currentAmount, 80);
    expect(store.funds.single.id, 'fund');
    expect(store.funds.single.amount, 20);
    expect(store.assetMovements.single.id, 'updated_movement');
    expect(store.transactions.single.id, 'updated_transaction');
    expect(store.fundTransactions.single.id, 'initial_fund_transaction');
    expect(store.linkedItems.single.id, 'initial_linked');
    expect(notifications, 1);
  });

  test('V3 fund plan writer failure leaves memory and notifications unchanged', () async {
    final store = await _v3Store(
      _portfolio('initial'),
      writer: FinancePortfolioV3Writer(
        saveVerified: (_, _) async => const PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      ),
    );
    final before = _state(store);
    var notifications = 0;
    store.addListener(() => notifications++);

    await expectLater(
      store.commitFundPlan(_plan(_portfolio('updated'))),
      throwsStateError,
    );

    expect(_state(store), before);
    expect(notifications, 0);
  });

  test('V3 identical fund plan remains a write and notification no-op', () async {
    final initial = _portfolio('initial');
    var writes = 0;
    final store = await _v3Store(
      initial,
      writer: _writer((_) => writes++),
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.commitFundPlan(_plan(initial));

    expect(writes, 0);
    expect(notifications, 0);
  });

  test('legacy fund plan keeps V2 persistence and notification behavior', () async {
    final initial = _portfolio('initial');
    final updated = _portfolio('updated');
    final store = FinanceStore(
      initialBalances: initial.balances,
      initialFunds: initial.funds,
      initialAssetMovements: initial.assetMovements,
      initialTransactions: initial.transactions,
      initialFundTransactions: initial.fundTransactions,
      initialLinkedItems: initial.linkedItems,
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.commitFundPlan(_plan(updated));

    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(store.balances.single.balanceId, 'balance');
    expect(store.balances.single.currentAmount, 80);
    expect(store.funds.single.id, 'fund');
    expect(store.funds.single.amount, 20);
    expect(store.assetMovements.single.id, 'updated_movement');
    expect(store.transactions.single.id, 'updated_transaction');
    expect(store.fundTransactions.single.id, 'initial_fund_transaction');
    expect(store.linkedItems.single.id, 'initial_linked');
    expect(notifications, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v2'), isNotNull);
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
  });
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
  final store = FinanceStore(portfolioV3Writer: writer);
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

FinanceFundMutationPlan _plan(FinancePortfolioV3 portfolio) =>
    FinanceFundMutationPlan(
      balances: portfolio.balances,
      funds: portfolio.funds,
      movements: portfolio.assetMovements,
      transactions: portfolio.transactions,
    );

FinancePortfolioV3 _portfolio(String label) {
  final balance = FinanceBalance(
    personId: 'matteo',
    balanceId: 'balance',
    name: '$label balance',
    initialAmount: 100,
    currentAmount: label == 'initial' ? 90 : 80,
    updatedAt: DateTime.utc(2026, 9, 11),
    balanceType: FinanceBalanceType.bankAccount,
    operational: true,
    active: true,
    reservedAmount: 0,
    warningThreshold: 0,
    persistentStressDays: 0,
    recoveryDays: 0,
  );
  final fund = FinanceFund(
    id: 'fund',
    name: '$label fund',
    description: label,
    amount: label == 'initial' ? 10 : 20,
    protected: false,
    category: FinanceFundCategory.generic,
  );
  return FinancePortfolioV3(
    balances: [balance],
    funds: [fund],
    assetMovements: [
      FinanceAssetMovement(
        id: '${label}_movement',
        fundId: fund.id,
        kind: FinanceAssetMovementKind.fundAllocation,
        description: label,
        occurredAt: DateTime.utc(2026, 9, 11),
        economicFactId: '${label}_fact',
        legs: [
          FinanceAssetLeg(
            type: FinanceAssetLegType.balance,
            referenceId: balance.balanceId,
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
        id: '${label}_transaction',
        balanceId: balance.balanceId,
        amount: 10,
        date: DateTime.utc(2026, 9, 11),
        isIncome: false,
        subject: FinanceSubject.matteo,
        description: label,
        type: FinanceTransactionType.transfer,
        origin: FinanceTransactionOrigin.fund,
        economicFactId: '${label}_fact',
      ),
    ],
    fundTransactions: [
      FundTransaction(
        id: '${label}_fund_transaction',
        fundId: fund.id,
        description: label,
        amount: 10,
        date: DateTime.utc(2026, 9, 11),
        type: FundTransactionType.deposit,
      ),
    ],
    linkedItems: [
      FinanceAccountLinkedItem(
        id: '${label}_linked',
        balanceId: balance.balanceId,
        type: FinanceAccountLinkedItemType.debitCard,
        name: label,
        description: '',
      ),
    ],
  );
}

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
