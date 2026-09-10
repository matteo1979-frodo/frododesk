import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/finance/finance_prepaid_creation.dart';
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
    'creates zero prepaid and linked item in one verified V3 write',
    () async {
      final initial = _portfolio();
      var writes = 0;
      String? payload;
      final store = await _authoritativeStore(
        initial,
        writer: _writer((value) {
          writes++;
          payload = value;
        }),
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      final result = await store.createLinkedPrepaid(_input(amount: 0));

      expect(result.isSuccess, isTrue);
      expect(writes, 1);
      expect(notifications, 1);
      expect(store.balances, hasLength(initial.balances.length + 1));
      expect(store.linkedItems, hasLength(initial.linkedItems.length + 1));
      final balance = result.records!.balance;
      final linked = result.records!.linkedItem;
      expect(balance.balanceType, FinanceBalanceType.prepaidCard);
      expect(balance.initialAmount, 0);
      expect(balance.currentAmount, 0);
      expect(linked.balanceId, 'parent');
      expect(linked.autonomousBalanceId, balance.balanceId);
      expect(linked.id, isNot(balance.balanceId));
      expect(store.transactions, hasLength(initial.transactions.length));
      expect(store.assetMovements, hasLength(initial.assetMovements.length));
      expect(
        store.fundTransactions,
        hasLength(initial.fundTransactions.length),
      );
      final json = jsonDecode(payload!) as Map<String, dynamic>;
      expect(json['balances'], hasLength(initial.balances.length + 1));
      expect(json['linkedItems'], hasLength(initial.linkedItems.length + 1));
    },
  );

  test(
    'positive initial amount increases total without a transaction',
    () async {
      final initial = _portfolio();
      final store = await _authoritativeStore(initial);
      final beforeTotal = store.totalBalance();
      final beforeTransactions = store.transactions.length;

      final result = await store.createLinkedPrepaid(_input(amount: 10));

      expect(result.isSuccess, isTrue);
      expect(result.records!.balance.currentAmount, 10);
      expect(store.totalBalance(), beforeTotal + 10);
      expect(store.transactions, hasLength(beforeTransactions));
      expect(
        store.fundTransactions,
        hasLength(initial.fundTransactions.length),
      );
      expect(store.assetMovements, hasLength(initial.assetMovements.length));
      expect(store.balances.first.currentAmount, 100);
    },
  );

  test('preserves complete payload and existing legacy linked items', () async {
    final initial = _portfolio();
    final before = _collectionState(initial);
    final store = await _authoritativeStore(initial);

    final result = await store.createLinkedPrepaid(_input(amount: 4));

    expect(result.isSuccess, isTrue);
    expect(store.funds.map((item) => item.toJson()).toList(), before['funds']);
    expect(
      store.assetMovements.map((item) => item.toJson()).toList(),
      before['assetMovements'],
    );
    expect(
      store.transactions.map((item) => item.toJson()).toList(),
      before['transactions'],
    );
    expect(
      store.fundTransactions.map((item) => item.toJson()).toList(),
      before['fundTransactions'],
    );
    expect(store.linkedItems.first.id, 'legacy');
    expect(store.linkedItems.first.autonomousBalanceId, isNull);
  });

  test(
    'writer failure keeps complete memory unchanged and does not notify',
    () async {
      final initial = _portfolio();
      final store = await _authoritativeStore(
        initial,
        writer: _failingWriter(),
      );
      final before = _storeState(store);
      var notifications = 0;
      store.addListener(() => notifications++);

      final result = await store.createLinkedPrepaid(_input(amount: 10));

      expect(result.failure, FinancePrepaidCreationFailure.commitFailed);
      expect(_storeState(store), before);
      expect(notifications, 0);
    },
  );

  test(
    'candidate validation failure does not call writer or publish',
    () async {
      final initial = _portfolio();
      var writes = 0;
      final store = await _authoritativeStore(
        initial,
        builder: FinancePrepaidCreationBuilder(
          idTokenGenerator: () => 'parent',
        ),
        writer: _writer((_) => writes++),
      );
      // The token creates IDs that collide with the explicit records below.
      final collisionPortfolio = FinancePortfolioV3(
        balances: [
          ...initial.balances,
          _balance(
            'balance_prepaid_parent',
            type: FinanceBalanceType.prepaidCard,
          ),
        ],
        funds: initial.funds,
        assetMovements: initial.assetMovements,
        transactions: initial.transactions,
        fundTransactions: initial.fundTransactions,
        linkedItems: initial.linkedItems,
      );
      await _seed(collisionPortfolio);
      final collisionStore = FinanceStore(
        prepaidCreationBuilder: FinancePrepaidCreationBuilder(
          idTokenGenerator: () => 'parent',
        ),
        portfolioV3Writer: _writer((_) => writes++),
      );
      expect(await collisionStore.loadSavedPortfolioV3(), isTrue);
      final before = _storeState(collisionStore);
      var notifications = 0;
      collisionStore.addListener(() => notifications++);

      final result = await collisionStore.createLinkedPrepaid(
        _input(amount: 0),
      );

      expect(result.failure, FinancePrepaidCreationFailure.commitFailed);
      expect(
        result.errors,
        contains('Duplicate balanceId: balance_prepaid_parent'),
      );
      expect(writes, 0);
      expect(_storeState(collisionStore), before);
      expect(notifications, 0);
      store.dispose();
    },
  );

  test(
    'missing parent and person mismatch fail before ID generation',
    () async {
      var generated = 0;
      final store = await _authoritativeStore(
        _portfolio(),
        builder: FinancePrepaidCreationBuilder(
          idTokenGenerator: () {
            generated++;
            return 'unused';
          },
        ),
      );

      final missing = await store.createLinkedPrepaid(
        _input(parentBalanceId: 'missing'),
      );
      final mismatch = await store.createLinkedPrepaid(
        _input(personId: 'chiara'),
      );

      expect(missing.failure, FinancePrepaidCreationFailure.parentNotFound);
      expect(mismatch.failure, FinancePrepaidCreationFailure.personMismatch);
      expect(generated, 0);
    },
  );

  test('same names never reuse or associate existing records', () async {
    final initial = _portfolio(sameNames: true);
    final store = await _authoritativeStore(initial);

    final result = await store.createLinkedPrepaid(
      _input(prepaidName: 'Same name', linkedItemName: 'Same name'),
    );

    expect(result.isSuccess, isTrue);
    expect(result.records!.balance.balanceId, 'balance_prepaid_token');
    expect(result.records!.linkedItem.id, 'linked_prepaid_token');
    expect(
      store.balances.where((item) => item.name == 'Same name'),
      hasLength(2),
    );
    expect(
      store.linkedItems.where((item) => item.name == 'Same name'),
      hasLength(2),
    );
  });

  test('V3 is required and legacy persistence is never used', () async {
    var generated = 0;
    final store = FinanceStore(
      initialBalances: [_balance('parent')],
      prepaidCreationBuilder: FinancePrepaidCreationBuilder(
        idTokenGenerator: () {
          generated++;
          return 'unused';
        },
      ),
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    final result = await store.createLinkedPrepaid(_input(amount: 0));

    expect(result.failure, FinancePrepaidCreationFailure.v3Required);
    expect(generated, 0);
    expect(notifications, 0);
    expect(store.balances, hasLength(1));
    expect(store.linkedItems, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
    expect(prefs.getString('frododesk_finance_portfolio_v2'), isNull);
    expect(prefs.getString('frododesk_finance_balances'), isNull);
    expect(prefs.getString('frododesk_finance_account_linked_items'), isNull);
  });

  test('T2 and T3 mutation paths remain operational', () async {
    final store = await _authoritativeStore(_portfolio());
    final balance = _balance('extra');
    expect(await store.addBalance(balance), isTrue);
    expect(
      await store.replaceBalance(_copyBalance(balance, name: 'Changed')),
      isTrue,
    );
    expect(await store.setBalanceActive(balance.balanceId, false), isTrue);
    final linked = FinanceAccountLinkedItem(
      id: 'extra_linked',
      balanceId: 'parent',
      type: FinanceAccountLinkedItemType.debitCard,
      name: 'Extra',
      description: '',
    );
    expect(await store.addLinkedItem(linked), isTrue);
    expect(
      await store.replaceLinkedItem(linked.copyWith(name: 'Changed')),
      isTrue,
    );
    expect(await store.setLinkedItemActive(linked.id, false), isTrue);
  });
}

Future<FinanceStore> _authoritativeStore(
  FinancePortfolioV3 portfolio, {
  FinancePortfolioV3Writer? writer,
  FinancePrepaidCreationBuilder? builder,
}) async {
  await _seed(portfolio);
  final store = FinanceStore(
    portfolioV3Writer: writer,
    prepaidCreationBuilder:
        builder ??
        FinancePrepaidCreationBuilder(idTokenGenerator: () => 'token'),
  );
  expect(await store.loadSavedPortfolioV3(), isTrue);
  return store;
}

Future<void> _seed(FinancePortfolioV3 portfolio) async {
  SharedPreferences.setMockInitialValues({
    'frododesk_finance_portfolio_v3': jsonEncode(
      FinancePortfolioV3Contract.build(portfolio),
    ),
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

FinancePrepaidCreationInput _input({
  String parentBalanceId = 'parent',
  String personId = 'matteo',
  String prepaidName = 'Prepaid',
  String linkedItemName = 'Physical card',
  double amount = 0,
}) => FinancePrepaidCreationInput(
  parentBalanceId: parentBalanceId,
  personId: personId,
  prepaidName: prepaidName,
  amount: amount,
  linkedItemName: linkedItemName,
  description: 'Test',
  expirationDate: DateTime.utc(2030, 1),
  occurredAt: DateTime.utc(2026, 9, 10),
);

FinancePortfolioV3 _portfolio({bool sameNames = false}) {
  final parent = _balance('parent');
  final fund = FinanceFund(
    id: 'fund',
    name: 'Fund',
    description: '',
    amount: 20,
    protected: false,
    category: FinanceFundCategory.generic,
  );
  return FinancePortfolioV3(
    balances: [
      parent,
      if (sameNames)
        _balance(
          'existing_prepaid',
          name: 'Same name',
          type: FinanceBalanceType.prepaidCard,
        ),
    ],
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
      FinanceAccountLinkedItem(
        id: 'legacy',
        balanceId: parent.balanceId,
        type: FinanceAccountLinkedItemType.prepaidCard,
        name: sameNames ? 'Same name' : 'Legacy',
        description: '',
      ),
    ],
  );
}

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

Map<String, dynamic> _collectionState(FinancePortfolioV3 portfolio) => {
  'funds': portfolio.funds.map((item) => item.toJson()).toList(),
  'assetMovements': portfolio.assetMovements
      .map((item) => item.toJson())
      .toList(),
  'transactions': portfolio.transactions.map((item) => item.toJson()).toList(),
  'fundTransactions': portfolio.fundTransactions
      .map((item) => item.toJson())
      .toList(),
};

String _storeState(FinanceStore store) => jsonEncode({
  'balances': store.balances.map((item) => item.toJson()).toList(),
  'funds': store.funds.map((item) => item.toJson()).toList(),
  'assetMovements': store.assetMovements.map((item) => item.toJson()).toList(),
  'transactions': store.transactions.map((item) => item.toJson()).toList(),
  'fundTransactions': store.fundTransactions
      .map((item) => item.toJson())
      .toList(),
  'linkedItems': store.linkedItems.map((item) => item.toJson()).toList(),
});
