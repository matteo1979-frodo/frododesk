import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_commit.dart';
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

  test('candidate stays detached until verified write succeeds', () async {
    final initial = _portfolio('initial');
    final completer = Completer<PersistenceWriteVerification>();
    String? serialized;
    final store = _store(
      initial,
      writer: FinancePortfolioV3Writer(
        saveVerified: (key, value) {
          serialized = value;
          return completer.future;
        },
      ),
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    final pending = store.commitPortfolioV3Candidate(
      (current) => _with(
        current,
        balances: [...current.balances, _balance('candidate_extra')],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(_state(store), _stateOf(initial));
    expect(notifications, 0);
    expect(
      (jsonDecode(serialized!) as Map<String, dynamic>)['balances'],
      hasLength(3),
    );

    completer.complete(
      PersistenceWriteVerification(backendAccepted: true, readBack: serialized),
    );
    expect((await pending).isSuccess, isTrue);
    expect(store.balances, hasLength(3));
    expect(store.isPortfolioV3Authoritative, isTrue);
    expect(notifications, 1);
  });

  test('success publishes all six candidate collections together', () async {
    final initial = _portfolio('initial');
    final candidate = _portfolio('candidate');
    final store = _store(initial);
    var notifications = 0;
    store.addListener(() => notifications++);

    final result = await store.commitPortfolioV3Candidate((_) => candidate);

    expect(result.isSuccess, isTrue);
    expect(_state(store), _stateOf(candidate));
    expect(store.isPortfolioV3Authoritative, isTrue);
    expect(notifications, 1);
  });

  test(
    'transformation exception leaves state and authority untouched',
    () async {
      final initial = _portfolio('initial');
      var writerCalled = false;
      final store = _store(
        initial,
        writer: _trackingWriter(() => writerCalled = true),
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      final result = await store.commitPortfolioV3Candidate(
        (_) => throw StateError('candidate failure'),
      );

      expect(
        result.failure,
        FinancePortfolioV3CommitFailure.transformationFailed,
      );
      expect(writerCalled, isFalse);
      expect(_state(store), _stateOf(initial));
      expect(store.isPortfolioV3Authoritative, isFalse);
      expect(notifications, 0);
    },
  );

  test('validation failure never calls writer or publishes state', () async {
    final initial = _portfolio('initial');
    var writerCalled = false;
    final store = _store(
      initial,
      writer: _trackingWriter(() => writerCalled = true),
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    final result = await store.commitPortfolioV3Candidate(
      (current) => _with(
        current,
        linkedItems: [
          FinanceAccountLinkedItem(
            id: 'invalid',
            balanceId: 'missing',
            type: FinanceAccountLinkedItemType.debitCard,
            name: 'Invalid',
            description: '',
          ),
        ],
      ),
    );

    expect(result.failure, FinancePortfolioV3CommitFailure.validationFailed);
    expect(writerCalled, isFalse);
    expect(_state(store), _stateOf(initial));
    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(notifications, 0);
  });

  test(
    'backend writer failure leaves memory and notifications unchanged',
    () async {
      final initial = _portfolio('initial');
      final store = _store(
        initial,
        writer: FinancePortfolioV3Writer(
          saveVerified: (key, value) async =>
              const PersistenceWriteVerification(
                backendAccepted: false,
                readBack: null,
              ),
        ),
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      final result = await store.commitPortfolioV3Candidate(
        (_) => _portfolio('candidate'),
      );

      expect(result.failure, FinancePortfolioV3CommitFailure.writerFailed);
      expect(
        result.writeResult?.failure,
        FinancePortfolioV3WriteFailure.backendRejected,
      );
      expect(_state(store), _stateOf(initial));
      expect(store.isPortfolioV3Authoritative, isFalse);
      expect(notifications, 0);
    },
  );

  test(
    'read-back writer failure leaves memory and authority unchanged',
    () async {
      final initial = _portfolio('initial');
      final store = _store(
        initial,
        writer: FinancePortfolioV3Writer(
          saveVerified: (key, value) async =>
              const PersistenceWriteVerification(
                backendAccepted: true,
                readBack: 'different',
              ),
        ),
      );

      final result = await store.commitPortfolioV3Candidate(
        (_) => _portfolio('candidate'),
      );

      expect(result.failure, FinancePortfolioV3CommitFailure.writerFailed);
      expect(
        result.writeResult?.failure,
        FinancePortfolioV3WriteFailure.mismatchedReadBack,
      );
      expect(_state(store), _stateOf(initial));
      expect(store.isPortfolioV3Authoritative, isFalse);
    },
  );

  test('one-list change writes a complete six-list portfolio', () async {
    final initial = _portfolio('initial');
    String? serialized;
    final store = _store(
      initial,
      writer: FinancePortfolioV3Writer(
        saveVerified: (key, value) async {
          serialized = value;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      ),
    );

    final result = await store.commitPortfolioV3Candidate(
      (current) =>
          _with(current, balances: [...current.balances, _balance('extra')]),
    );

    expect(result.isSuccess, isTrue);
    final json = jsonDecode(serialized!) as Map<String, dynamic>;
    expect(json['version'], 3);
    expect(json['balances'], hasLength(3));
    expect(json['funds'], hasLength(initial.funds.length));
    expect(json['assetMovements'], hasLength(initial.assetMovements.length));
    expect(json['transactions'], hasLength(initial.transactions.length));
    expect(
      json['fundTransactions'],
      hasLength(initial.fundTransactions.length),
    );
    expect(json['linkedItems'], hasLength(initial.linkedItems.length));
  });

  test(
    'legacy null and matching names do not invent autonomous relation',
    () async {
      final parent = _balance('same_name', name: 'Same name');
      final prepaid = _balance(
        'prepaid',
        name: 'Same name',
        type: FinanceBalanceType.prepaidCard,
      );
      final linked = FinanceAccountLinkedItem(
        id: 'linked',
        balanceId: parent.balanceId,
        type: FinanceAccountLinkedItemType.prepaidCard,
        name: 'Same name',
        description: '',
      );
      final store = _store(
        FinancePortfolioV3(
          balances: [parent, prepaid],
          funds: const [],
          assetMovements: const [],
          transactions: const [],
          fundTransactions: const [],
          linkedItems: [linked],
        ),
      );

      expect(
        (await store.commitPortfolioV3Candidate(
          (current) => current,
        )).isSuccess,
        isTrue,
      );

      expect(store.linkedItems.single.autonomousBalanceId, isNull);
    },
  );

  test('executor writes neither V2 nor legacy keys', () async {
    const v2 = '{"version":2,"sentinel":true}';
    const balances = '[{"sentinel":"balances"}]';
    const funds = '[{"sentinel":"funds"}]';
    const transactions = '[{"sentinel":"transactions"}]';
    const fundTransactions = '[{"sentinel":"fundTransactions"}]';
    const linked = '[{"sentinel":"linked"}]';
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': v2,
      'frododesk_finance_balances': balances,
      'frododesk_finance_funds': funds,
      'frododesk_finance_transactions': transactions,
      'frododesk_finance_fund_transactions': fundTransactions,
      'frododesk_finance_account_linked_items': linked,
    });

    final store = _store(_portfolio('initial'));
    expect(
      (await store.commitPortfolioV3Candidate((current) => current)).isSuccess,
      isTrue,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v2'), v2);
    expect(prefs.getString('frododesk_finance_balances'), balances);
    expect(prefs.getString('frododesk_finance_funds'), funds);
    expect(prefs.getString('frododesk_finance_transactions'), transactions);
    expect(
      prefs.getString('frododesk_finance_fund_transactions'),
      fundTransactions,
    );
    expect(prefs.getString('frododesk_finance_account_linked_items'), linked);
  });

  test('existing productive mutation remains on its legacy path', () async {
    final store = FinanceStore();

    expect(await store.addBalance(_balance('legacy')), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_balances'), isNotNull);
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
    expect(store.isPortfolioV3Authoritative, isFalse);
  });

  test('read-only V2 bootstrap does not create V3', () async {
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': jsonEncode({
        'version': 2,
        'balances': [_balance('legacy').toJson()],
        'funds': const [],
        'assetMovements': const [],
        'transactions': const [],
        'fundTransactions': const [],
      }),
      'frododesk_finance_account_linked_items': jsonEncode([
        FinanceAccountLinkedItem(
          id: 'legacy_linked',
          balanceId: 'legacy',
          type: FinanceAccountLinkedItemType.debitCard,
          name: 'Legacy linked',
          description: '',
        ).toJson(),
      ]),
    });

    final store = FinanceStore();
    await store.loadInitialRealData();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
    expect(store.isPortfolioV3Authoritative, isFalse);
  });
}

FinancePortfolioV3Writer _trackingWriter(void Function() onCall) {
  return FinancePortfolioV3Writer(
    saveVerified: (key, value) async {
      onCall();
      return PersistenceWriteVerification(
        backendAccepted: true,
        readBack: value,
      );
    },
  );
}

FinanceStore _store(
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

FinancePortfolioV3 _portfolio(String label) {
  final parent = _balance('${label}_parent');
  final prepaid = _balance(
    '${label}_prepaid',
    type: FinanceBalanceType.prepaidCard,
  );
  final fund = FinanceFund(
    id: '${label}_fund',
    name: '$label fund',
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
        id: '${label}_movement',
        fundId: fund.id,
        kind: FinanceAssetMovementKind.fundOpening,
        description: label,
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
        id: '${label}_transaction',
        balanceId: parent.balanceId,
        amount: 5,
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
        id: '${label}_fund_transaction',
        fundId: fund.id,
        description: label,
        amount: 20,
        date: DateTime.utc(2026, 9, 10),
        type: FundTransactionType.deposit,
      ),
    ],
    linkedItems: [
      FinanceAccountLinkedItem(
        id: '${label}_linked',
        balanceId: parent.balanceId,
        autonomousBalanceId: prepaid.balanceId,
        type: FinanceAccountLinkedItemType.prepaidCard,
        name: '$label linked',
        description: '',
      ),
    ],
  );
}

FinancePortfolioV3 _with(
  FinancePortfolioV3 current, {
  Iterable<FinanceBalance>? balances,
  Iterable<FinanceFund>? funds,
  Iterable<FinanceAssetMovement>? assetMovements,
  Iterable<FinanceTransaction>? transactions,
  Iterable<FundTransaction>? fundTransactions,
  Iterable<FinanceAccountLinkedItem>? linkedItems,
}) => FinancePortfolioV3(
  balances: balances ?? current.balances,
  funds: funds ?? current.funds,
  assetMovements: assetMovements ?? current.assetMovements,
  transactions: transactions ?? current.transactions,
  fundTransactions: fundTransactions ?? current.fundTransactions,
  linkedItems: linkedItems ?? current.linkedItems,
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

String _stateOf(FinancePortfolioV3 portfolio) => jsonEncode({
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
