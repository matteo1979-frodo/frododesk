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

  test('writes and verifies a complete V3 payload', () async {
    final portfolio = _completePortfolio();
    final store = _storeFrom(portfolio);

    final result = await store.writePortfolioV3();

    expect(result.isSuccess, isTrue);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('frododesk_finance_portfolio_v3');
    expect(raw, isNotNull);
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['version'], 3);
    for (final field in const [
      'balances',
      'funds',
      'assetMovements',
      'transactions',
      'fundTransactions',
      'linkedItems',
    ]) {
      expect(json[field], isA<List>(), reason: field);
      expect(json[field], isNotEmpty, reason: field);
    }
    expect(
      (json['linkedItems'] as List).single['autonomousBalanceId'],
      'prepaid',
    );
  });

  test('writes and verifies an empty V3 payload', () async {
    final result = await FinanceStore().writePortfolioV3();

    expect(result.isSuccess, isTrue);
    final prefs = await SharedPreferences.getInstance();
    final json =
        jsonDecode(prefs.getString('frododesk_finance_portfolio_v3')!)
            as Map<String, dynamic>;
    expect(json['version'], 3);
    expect(
      json.values.whereType<List>().every((items) => items.isEmpty),
      isTrue,
    );
  });

  test('invalid payload is rejected without writing or replacing V3', () async {
    const previous = '{"existing":true}';
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': previous,
    });
    final parent = _balance('parent', FinanceBalanceType.bankAccount);
    final invalidLinked = _linked(autonomousBalanceId: 'missing');
    final store = FinanceStore(
      initialBalances: [parent],
      initialLinkedItems: [invalidLinked],
    );

    final result = await store.writePortfolioV3();

    expect(result.failure, FinancePortfolioV3WriteFailure.invalidPayload);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v3'), previous);
  });

  test('reports backend rejection', () async {
    final writer = FinancePortfolioV3Writer(
      saveVerified: (key, value) async => const PersistenceWriteVerification(
        backendAccepted: false,
        readBack: null,
      ),
    );

    final result = await writer.write(_emptyPortfolio());

    expect(result.failure, FinancePortfolioV3WriteFailure.backendRejected);
  });

  test('reports missing read-back after accepted save', () async {
    final writer = FinancePortfolioV3Writer(
      saveVerified: (key, value) async => const PersistenceWriteVerification(
        backendAccepted: true,
        readBack: null,
      ),
    );

    final result = await writer.write(_emptyPortfolio());

    expect(result.failure, FinancePortfolioV3WriteFailure.missingReadBack);
  });

  test('reports mismatched read-back after accepted save', () async {
    final writer = FinancePortfolioV3Writer(
      saveVerified: (key, value) async => const PersistenceWriteVerification(
        backendAccepted: true,
        readBack: 'different',
      ),
    );

    final result = await writer.write(_emptyPortfolio());

    expect(result.failure, FinancePortfolioV3WriteFailure.mismatchedReadBack);
  });

  test('write failure leaves every in-memory collection unchanged', () async {
    final portfolio = _completePortfolio();
    final store = _storeFrom(
      portfolio,
      writer: FinancePortfolioV3Writer(
        saveVerified: (key, value) async => const PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      ),
    );
    final before = _stateJson(store);

    final result = await store.writePortfolioV3();

    expect(result.isSuccess, isFalse);
    expect(_stateJson(store), before);
  });

  test('writer changes neither V2 nor legacy linked items', () async {
    const v2 = '{"version":2,"sentinel":true}';
    const linkedLegacy = '[{"sentinel":true}]';
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': v2,
      'frododesk_finance_account_linked_items': linkedLegacy,
    });

    expect((await FinanceStore().writePortfolioV3()).isSuccess, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v2'), v2);
    expect(
      prefs.getString('frododesk_finance_account_linked_items'),
      linkedLegacy,
    );
  });

  test('V2 bootstrap does not promote automatically to V3', () async {
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': jsonEncode({
        'version': 2,
        'balances': const [],
        'funds': const [],
        'assetMovements': const [],
        'transactions': const [],
        'fundTransactions': const [],
      }),
    });

    await FinanceStore().loadInitialRealData();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
  });

  test('P3 reader loads a payload written by P4', () async {
    final portfolio = _completePortfolio();
    expect((await _storeFrom(portfolio).writePortfolioV3()).isSuccess, isTrue);

    final reader = FinanceStore();
    expect(await reader.loadSavedPortfolioV3(), isTrue);

    expect(_stateJson(reader), _portfolioJson(portfolio));
    expect(reader.isPortfolioV3Authoritative, isTrue);
  });
}

FinanceStore _storeFrom(
  FinancePortfolioV3 portfolio, {
  FinancePortfolioV3Writer? writer,
}) => FinanceStore(
  portfolioV3Writer: writer,
  initialBalances: portfolio.balances,
  initialFunds: portfolio.funds,
  initialAssetMovements: portfolio.assetMovements,
  initialTransactions: portfolio.transactions,
  initialFundTransactions: portfolio.fundTransactions,
  initialLinkedItems: portfolio.linkedItems,
);

FinancePortfolioV3 _completePortfolio() {
  final parent = _balance('parent', FinanceBalanceType.bankAccount);
  final prepaid = _balance('prepaid', FinanceBalanceType.prepaidCard);
  final fund = FinanceFund(
    id: 'fund',
    name: 'Fund',
    description: '',
    amount: 25,
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
            delta: -25,
          ),
          FinanceAssetLeg(
            type: FinanceAssetLegType.fund,
            referenceId: fund.id,
            delta: 25,
          ),
        ],
      ),
    ],
    transactions: [
      FinanceTransaction(
        id: 'transaction',
        balanceId: parent.balanceId,
        amount: 10,
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
        amount: 25,
        date: DateTime.utc(2026, 9, 10),
        type: FundTransactionType.deposit,
      ),
    ],
    linkedItems: [_linked(autonomousBalanceId: prepaid.balanceId)],
  );
}

FinancePortfolioV3 _emptyPortfolio() => FinancePortfolioV3(
  balances: const [],
  funds: const [],
  assetMovements: const [],
  transactions: const [],
  fundTransactions: const [],
  linkedItems: const [],
);

FinanceBalance _balance(String id, FinanceBalanceType type) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: id,
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

FinanceAccountLinkedItem _linked({String? autonomousBalanceId}) =>
    FinanceAccountLinkedItem(
      id: 'linked',
      balanceId: 'parent',
      autonomousBalanceId: autonomousBalanceId,
      type: FinanceAccountLinkedItemType.prepaidCard,
      name: 'Linked prepaid',
      description: '',
    );

String _stateJson(FinanceStore store) => jsonEncode({
  'balances': store.balances.map((item) => item.toJson()).toList(),
  'funds': store.funds.map((item) => item.toJson()).toList(),
  'assetMovements': store.assetMovements.map((item) => item.toJson()).toList(),
  'transactions': store.transactions.map((item) => item.toJson()).toList(),
  'fundTransactions': store.fundTransactions
      .map((item) => item.toJson())
      .toList(),
  'linkedItems': store.linkedItems.map((item) => item.toJson()).toList(),
});

String _portfolioJson(FinancePortfolioV3 portfolio) => jsonEncode({
  'balances': portfolio.balances.map((item) => item.toJson()).toList(),
  'funds': portfolio.funds.map((item) => item.toJson()).toList(),
  'assetMovements': portfolio.assetMovements
      .map((item) => item.toJson())
      .toList(),
  'transactions': portfolio.transactions.map((item) => item.toJson()).toList(),
  'fundTransactions': portfolio.fundTransactions
      .map((item) => item.toJson())
      .toList(),
  'linkedItems': portfolio.linkedItems.map((item) => item.toJson()).toList(),
});
