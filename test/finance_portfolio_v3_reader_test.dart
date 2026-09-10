import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_lifecycle_loader.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
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

  test('valid V3 prevails over V2 and legacy linked items', () async {
    final v3 = _portfolio(label: 'V3', linkedId: 'linked_v3');
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': jsonEncode(
        FinancePortfolioV3Contract.build(v3),
      ),
      'frododesk_finance_portfolio_v2': jsonEncode(_v2(label: 'V2')),
      'frododesk_finance_account_linked_items': jsonEncode([
        _linked(id: 'linked_legacy', balanceId: 'balance_v2').toJson(),
      ]),
    });

    final store = FinanceStore();
    await store.loadInitialRealData();

    expect(store.isPortfolioV3Authoritative, isTrue);
    expect(store.balances.single.name, 'Balance V3');
    expect(store.funds.single.name, 'Fund V3');
    expect(store.assetMovements.single.id, 'movement_v3');
    expect(store.transactions.single.id, 'transaction_v3');
    expect(store.fundTransactions.single.id, 'fund_transaction_v3');
    expect(store.linkedItems.single.id, 'linked_v3');
  });

  test('absent V3 preserves V2 plus legacy linked fallback', () async {
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': jsonEncode(_v2(label: 'V2')),
      'frododesk_finance_account_linked_items': jsonEncode([
        _linked(id: 'linked_legacy', balanceId: 'balance_v2').toJson(),
      ]),
    });

    final store = FinanceStore();
    await store.loadInitialRealData();

    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(store.balances.single.name, 'Balance V2');
    expect(store.linkedItems.single.id, 'linked_legacy');
  });

  test('valid empty V3 is authoritative over populated V2', () async {
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': jsonEncode(
        FinancePortfolioV3Contract.build(_emptyPortfolio()),
      ),
      'frododesk_finance_portfolio_v2': jsonEncode(_v2(label: 'V2')),
      'frododesk_finance_account_linked_items': jsonEncode([
        _linked(id: 'linked_legacy', balanceId: 'balance_v2').toJson(),
      ]),
    });

    final store = FinanceStore(initialBalances: [_balance('old', 'Old')]);
    await store.loadInitialRealData();

    expect(store.isPortfolioV3Authoritative, isTrue);
    expect(store.balances, isEmpty);
    expect(store.funds, isEmpty);
    expect(store.assetMovements, isEmpty);
    expect(store.transactions, isEmpty);
    expect(store.fundTransactions, isEmpty);
    expect(store.linkedItems, isEmpty);
  });

  test('invalid V3 never falls back to valid V2', () async {
    final invalid = FinancePortfolioV3Contract.build(
      _portfolio(label: 'Invalid', linkedId: 'linked_invalid'),
    )..['version'] = 2;
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': jsonEncode(invalid),
      'frododesk_finance_portfolio_v2': jsonEncode(_v2(label: 'V2')),
    });

    final store = FinanceStore();

    await expectLater(store.loadInitialRealData(), throwsFormatException);
    expect(store.balances, isEmpty);
    expect(store.isPortfolioV3Authoritative, isFalse);
  });

  test('every invalid V3 form reports a controlled failure', () async {
    final invalidReference = FinancePortfolioV3Contract.build(
      _portfolio(label: 'Invalid', linkedId: 'linked_invalid'),
    );
    final linked =
        (invalidReference['linkedItems'] as List).single
            as Map<String, dynamic>;
    linked['balanceId'] = 'missing';

    final invalidValues = <String>[
      '{invalid-json',
      jsonEncode(['not-an-object']),
      jsonEncode({'version': 3}),
      jsonEncode(invalidReference),
    ];

    for (final raw in invalidValues) {
      SharedPreferences.setMockInitialValues({
        'frododesk_finance_portfolio_v3': raw,
        'frododesk_finance_portfolio_v2': jsonEncode(_v2(label: 'V2')),
      });

      final store = FinanceStore();
      await expectLater(store.loadInitialRealData(), throwsFormatException);
      expect(store.balances, isEmpty);
    }
  });

  test('invalid V3 does not publish partially parsed state', () async {
    final invalid = FinancePortfolioV3Contract.build(
      _portfolio(label: 'Invalid', linkedId: 'linked_invalid'),
    );
    final linked =
        (invalid['linkedItems'] as List).single as Map<String, dynamic>;
    linked['autonomousBalanceId'] = 'missing';
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': jsonEncode(invalid),
    });
    final initialBalance = _balance('initial_balance', 'Initial');
    final initialLinked = _linked(
      id: 'initial_linked',
      balanceId: 'initial_balance',
    );
    final store = FinanceStore(
      initialBalances: [initialBalance],
      initialLinkedItems: [initialLinked],
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await expectLater(store.loadInitialRealData(), throwsFormatException);

    expect(store.balances.single.balanceId, 'initial_balance');
    expect(store.linkedItems.single.id, 'initial_linked');
    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(notifications, 0);
  });

  test('reloading the same V3 is idempotent and does not duplicate', () async {
    final raw = jsonEncode(
      FinancePortfolioV3Contract.build(
        _portfolio(label: 'V3', linkedId: 'linked_v3'),
      ),
    );
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v3': raw,
    });
    final store = FinanceStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    expect(await store.loadSavedPortfolioV3(), isTrue);
    expect(await store.loadSavedPortfolioV3(), isTrue);

    expect(store.balances, hasLength(1));
    expect(store.linkedItems, hasLength(1));
    expect(notifications, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v3'), raw);
  });

  test(
    'V3 bootstrap writes neither V3 nor existing V2 and legacy balances',
    () async {
      final v3Raw = jsonEncode(
        FinancePortfolioV3Contract.build(
          _portfolio(label: 'V3', linkedId: 'linked_v3'),
        ),
      );
      final v2Raw = jsonEncode(_v2(label: 'V2'));
      final legacyBalancesRaw = jsonEncode([
        _balance('legacy_balance', 'Legacy').toJson(),
      ]);
      final legacyFundsRaw = jsonEncode([_fund('legacy', 'Legacy').toJson()]);
      SharedPreferences.setMockInitialValues({
        'frododesk_finance_portfolio_v3': v3Raw,
        'frododesk_finance_portfolio_v2': v2Raw,
        'frododesk_finance_balances': legacyBalancesRaw,
        'frododesk_finance_funds': legacyFundsRaw,
      });

      await FinanceLifecycleLoader(
        financeStore: FinanceStore(),
        refresh: () {},
      ).load();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('frododesk_finance_portfolio_v3'), v3Raw);
      expect(prefs.getString('frododesk_finance_portfolio_v2'), v2Raw);
      expect(prefs.getString('frododesk_finance_balances'), legacyBalancesRaw);
      expect(prefs.getString('frododesk_finance_funds'), legacyFundsRaw);
    },
  );
}

FinancePortfolioV3 _portfolio({
  required String label,
  required String linkedId,
}) {
  final balance = _balance('balance_${label.toLowerCase()}', 'Balance $label');
  final fund = _fund('fund_${label.toLowerCase()}', 'Fund $label');
  return FinancePortfolioV3(
    balances: [balance],
    funds: [fund],
    assetMovements: [
      FinanceAssetMovement(
        id: 'movement_${label.toLowerCase()}',
        fundId: fund.id,
        kind: FinanceAssetMovementKind.fundOpening,
        description: label,
        occurredAt: DateTime.utc(2026, 9, 10),
        legs: [
          FinanceAssetLeg(
            type: FinanceAssetLegType.openingBalance,
            delta: -fund.amount,
          ),
          FinanceAssetLeg(
            type: FinanceAssetLegType.fund,
            referenceId: fund.id,
            delta: fund.amount,
          ),
        ],
      ),
    ],
    transactions: [
      FinanceTransaction(
        id: 'transaction_${label.toLowerCase()}',
        balanceId: balance.balanceId,
        amount: 10,
        date: DateTime.utc(2026, 9, 10),
        isIncome: false,
        subject: FinanceSubject.shared,
        description: label,
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.manual,
      ),
    ],
    fundTransactions: [
      FundTransaction(
        id: 'fund_transaction_${label.toLowerCase()}',
        fundId: fund.id,
        description: label,
        amount: fund.amount,
        date: DateTime.utc(2026, 9, 10),
        type: FundTransactionType.deposit,
      ),
    ],
    linkedItems: [_linked(id: linkedId, balanceId: balance.balanceId)],
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

Map<String, dynamic> _v2({required String label}) {
  final balance = _balance('balance_${label.toLowerCase()}', 'Balance $label');
  return {
    'version': 2,
    'balances': [balance.toJson()],
    'funds': const [],
    'assetMovements': const [],
    'transactions': const [],
    'fundTransactions': const [],
  };
}

FinanceBalance _balance(String id, String name) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: name,
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime.utc(2026, 9, 10),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceFund _fund(String id, String name) => FinanceFund(
  id: id,
  name: name,
  description: '',
  amount: 20,
  protected: false,
  category: FinanceFundCategory.generic,
);

FinanceAccountLinkedItem _linked({
  required String id,
  required String balanceId,
}) => FinanceAccountLinkedItem(
  id: id,
  balanceId: balanceId,
  type: FinanceAccountLinkedItemType.debitCard,
  name: id,
  description: '',
);
