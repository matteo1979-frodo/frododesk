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

  test('addBalance on authoritative V3 persists before one publish', () async {
    final initial = _portfolio();
    await _seedV3(initial);
    String? written;
    final store = FinanceStore(
      portfolioV3Writer: _successfulWriter((value) => written = value),
    );
    expect(await store.loadSavedPortfolioV3(), isTrue);
    var notifications = 0;
    store.addListener(() => notifications++);

    expect(await store.addBalance(_balance('new')), isTrue);

    expect(store.balances.map((item) => item.balanceId), contains('new'));
    expect(store.isPortfolioV3Authoritative, isTrue);
    expect(notifications, 1);
    final json = jsonDecode(written!) as Map<String, dynamic>;
    expect(json['version'], 3);
    expect(json['balances'], hasLength(initial.balances.length + 1));
    expect(json['funds'], hasLength(initial.funds.length));
    expect(json['assetMovements'], hasLength(initial.assetMovements.length));
    expect(json['transactions'], hasLength(initial.transactions.length));
    expect(
      json['fundTransactions'],
      hasLength(initial.fundTransactions.length),
    );
    expect(json['linkedItems'], hasLength(initial.linkedItems.length));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v2'), isNull);
  });

  test(
    'addBalance V3 failure leaves memory unchanged and sends no notification',
    () async {
      final initial = _portfolio();
      await _seedV3(initial);
      final store = FinanceStore(portfolioV3Writer: _failingWriter());
      expect(await store.loadSavedPortfolioV3(), isTrue);
      final before = _state(store);
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(store.addBalance(_balance('new')), throwsStateError);

      expect(_state(store), before);
      expect(store.isPortfolioV3Authoritative, isTrue);
      expect(notifications, 0);
    },
  );

  test(
    'replaceBalance on authoritative V3 persists and publishes once',
    () async {
      final initial = _portfolio();
      await _seedV3(initial);
      final store = FinanceStore();
      expect(await store.loadSavedPortfolioV3(), isTrue);
      final current = store.balances.first;
      final replacement = _copyBalance(current, name: 'Updated');
      var notifications = 0;
      store.addListener(() => notifications++);

      expect(await store.replaceBalance(replacement), isTrue);

      expect(store.balances.first.name, 'Updated');
      expect(notifications, 1);
      final reloaded = FinanceStore();
      expect(await reloaded.loadSavedPortfolioV3(), isTrue);
      expect(reloaded.balances.first.name, 'Updated');
    },
  );

  test('replaceBalance V3 failure preserves the previous balance', () async {
    final initial = _portfolio();
    await _seedV3(initial);
    final store = FinanceStore(portfolioV3Writer: _failingWriter());
    expect(await store.loadSavedPortfolioV3(), isTrue);
    final current = store.balances.first;
    var notifications = 0;
    store.addListener(() => notifications++);

    await expectLater(
      store.replaceBalance(_copyBalance(current, name: 'Rejected')),
      throwsStateError,
    );

    expect(store.balances.first.name, current.name);
    expect(notifications, 0);
  });

  test('setBalanceActive is atomic on success and writer failure', () async {
    final initial = _portfolio();
    await _seedV3(initial);
    final successful = FinanceStore();
    expect(await successful.loadSavedPortfolioV3(), isTrue);
    var successNotifications = 0;
    successful.addListener(() => successNotifications++);

    expect(
      await successful.setBalanceActive(
        initial.balances.first.balanceId,
        false,
      ),
      isTrue,
    );
    expect(successful.balances.first.active, isFalse);
    expect(successNotifications, 1);

    await _seedV3(initial);
    final failing = FinanceStore(portfolioV3Writer: _failingWriter());
    expect(await failing.loadSavedPortfolioV3(), isTrue);
    var failureNotifications = 0;
    failing.addListener(() => failureNotifications++);

    await expectLater(
      failing.setBalanceActive(initial.balances.first.balanceId, false),
      throwsStateError,
    );
    expect(failing.balances.first.active, isTrue);
    expect(failureNotifications, 0);
  });

  test(
    'identical and missing balance operations remain write-free no-ops',
    () async {
      final initial = _portfolio();
      await _seedV3(initial);
      var writes = 0;
      final store = FinanceStore(
        portfolioV3Writer: _successfulWriter((_) => writes++),
      );
      expect(await store.loadSavedPortfolioV3(), isTrue);
      var notifications = 0;
      store.addListener(() => notifications++);

      expect(await store.addBalance(initial.balances.first), isFalse);
      expect(await store.replaceBalance(initial.balances.first), isFalse);
      expect(await store.replaceBalance(_balance('missing')), isFalse);
      expect(await store.setBalanceActive('missing', false), isFalse);
      expect(
        await store.setBalanceActive(initial.balances.first.balanceId, true),
        isFalse,
      );

      expect(writes, 0);
      expect(notifications, 0);
    },
  );

  test('V2 mode keeps the legacy balance path and does not promote', () async {
    final initial = _portfolio();
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': jsonEncode({
        'version': 2,
        'balances': initial.balances.map((item) => item.toJson()).toList(),
        'funds': initial.funds.map((item) => item.toJson()).toList(),
        'assetMovements': initial.assetMovements
            .map((item) => item.toJson())
            .toList(),
        'transactions': initial.transactions
            .map((item) => item.toJson())
            .toList(),
        'fundTransactions': initial.fundTransactions
            .map((item) => item.toJson())
            .toList(),
      }),
      'frododesk_finance_account_linked_items': jsonEncode(
        initial.linkedItems.map((item) => item.toJson()).toList(),
      ),
    });
    final store = FinanceStore();
    await store.loadInitialRealData();

    expect(await store.addBalance(_balance('legacy_new')), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(
      store.balances.map((item) => item.balanceId),
      contains('legacy_new'),
    );
  });

  test('linked item mutations remain on the legacy path', () async {
    final item = FinanceAccountLinkedItem(
      id: 'linked_only',
      balanceId: 'parent',
      type: FinanceAccountLinkedItemType.debitCard,
      name: 'Linked only',
      description: '',
    );
    final store = FinanceStore(initialBalances: [_balance('parent')]);

    expect(await store.addLinkedItem(item), isTrue);
    expect(
      await store.replaceLinkedItem(item.copyWith(name: 'Updated')),
      isTrue,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('frododesk_finance_account_linked_items'),
      isNotNull,
    );
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
  });

  test('read-only V2 bootstrap still does not create V3', () async {
    SharedPreferences.setMockInitialValues({
      'frododesk_finance_portfolio_v2': jsonEncode({
        'version': 2,
        'balances': [_balance('legacy').toJson()],
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
      FinanceAccountLinkedItem(
        id: 'linked',
        balanceId: parent.balanceId,
        autonomousBalanceId: prepaid.balanceId,
        type: FinanceAccountLinkedItemType.prepaidCard,
        name: 'Linked prepaid',
        description: '',
      ),
    ],
  );
}

FinanceBalance _balance(
  String id, {
  FinanceBalanceType type = FinanceBalanceType.bankAccount,
}) => FinanceBalance(
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
