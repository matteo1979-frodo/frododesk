import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_account_linked_item.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'updates linked prepaid and autonomous balance in one V3 commit',
    () async {
      final portfolio = _portfolio();
      var writes = 0;
      final store = await _store(portfolio, writer: _writer((_) => writes++));
      final beforeTransaction = store.transactions.single.toJson();
      final beforeParent = store.balances.first.toJson();
      var notifications = 0;
      store.addListener(() => notifications++);

      final result = await store.updateLinkedPrepaidPair(
        linkedItemId: 'linked_prepaid',
        name: 'Prepagata reale',
        description: 'scadenza carta 06/29',
        expirationDate: DateTime(2029, 6, 1),
        amount: 0,
      );

      expect(result.isSuccess, isTrue);
      expect(writes, 1);
      expect(notifications, 1);
      final linked = store.linkedItems.single;
      final prepaid = store.balances.singleWhere(
        (item) => item.balanceId == 'prepaid',
      );
      expect(linked.name, 'Prepagata reale');
      expect(linked.description, 'scadenza carta 06/29');
      expect(linked.expirationDate, DateTime(2029, 6, 1));
      expect(linked.amount, 0);
      expect(linked.id, 'linked_prepaid');
      expect(linked.balanceId, 'parent');
      expect(linked.autonomousBalanceId, 'prepaid');
      expect(linked.type, FinanceAccountLinkedItemType.prepaidCard);
      expect(linked.active, isTrue);
      expect(prepaid.name, 'Prepagata reale');
      expect(prepaid.initialAmount, 10);
      expect(prepaid.currentAmount, 7);
      expect(prepaid.updatedAt, DateTime.utc(2026, 9, 1));
      expect(store.balances.first.toJson(), beforeParent);
      expect(store.transactions.single.toJson(), beforeTransaction);
    },
  );

  test(
    'writer failure keeps all memory unchanged and emits no notification',
    () async {
      final store = await _store(_portfolio(), writer: _failingWriter());
      final before = _state(store);
      var notifications = 0;
      store.addListener(() => notifications++);

      final result = await store.updateLinkedPrepaidPair(
        linkedItemId: 'linked_prepaid',
        name: 'Changed',
        description: 'Changed',
        expirationDate: null,
        amount: null,
      );

      expect(result.isSuccess, isFalse);
      expect(_state(store), before);
      expect(notifications, 0);
    },
  );

  test(
    'missing relation and missing autonomous balance fail without matching names',
    () async {
      final legacy = _linked(autonomousBalanceId: null);
      final legacyStore = await _store(_portfolio(linked: legacy));
      final missingRelation = await legacyStore.updateLinkedPrepaidPair(
        linkedItemId: legacy.id,
        name: 'Prepaid',
        description: '',
        expirationDate: null,
        amount: 0,
      );
      expect(missingRelation.isSuccess, isFalse);
      expect(missingRelation.errors.single, contains('no autonomous balance'));

      final missingStore = _AuthoritativeTestStore(
        initialBalances: [_balance('parent')],
        initialLinkedItems: [
          FinanceAccountLinkedItem(
            id: 'linked_prepaid',
            balanceId: 'parent',
            autonomousBalanceId: 'missing',
            type: FinanceAccountLinkedItemType.prepaidCard,
            name: 'Same visible name',
            description: '',
          ),
        ],
      );
      final missingBalance = await missingStore.updateLinkedPrepaidPair(
        linkedItemId: 'linked_prepaid',
        name: 'Same visible name',
        description: '',
        expirationDate: null,
        amount: 0,
      );
      expect(missingBalance.isSuccess, isFalse);
      expect(missingBalance.errors.single, contains('not found: missing'));
    },
  );

  test('non-prepaid linked item is rejected by ID', () async {
    final store = _AuthoritativeTestStore(
      initialBalances: [_balance('parent')],
      initialLinkedItems: [
        FinanceAccountLinkedItem(
          id: 'linked_debit',
          balanceId: 'parent',
          autonomousBalanceId: 'missing',
          type: FinanceAccountLinkedItemType.debitCard,
          name: 'Same visible name',
          description: '',
        ),
      ],
    );
    final result = await store.updateLinkedPrepaidPair(
      linkedItemId: 'linked_debit',
      name: 'Same visible name',
      description: '',
      expirationDate: null,
      amount: 0,
    );
    expect(result.isSuccess, isFalse);
    expect(result.errors.single, contains('not prepaidCard'));
  });
}

class _AuthoritativeTestStore extends FinanceStore {
  _AuthoritativeTestStore({super.initialBalances, super.initialLinkedItems});

  @override
  bool get isPortfolioV3Authoritative => true;
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
  final store = FinanceStore(portfolioV3Writer: writer);
  expect(await store.loadSavedPortfolioV3(), isTrue);
  return store;
}

FinancePortfolioV3 _portfolio({FinanceAccountLinkedItem? linked}) =>
    FinancePortfolioV3(
      balances: [_balance('parent'), _balance('prepaid', prepaid: true)],
      funds: const [],
      assetMovements: const [],
      transactions: [
        FinanceTransaction(
          id: 'history',
          balanceId: 'prepaid',
          amount: 3,
          date: DateTime.utc(2026, 9, 2),
          isIncome: false,
          subject: FinanceSubject.matteo,
          description: 'History',
          type: FinanceTransactionType.expense,
          origin: FinanceTransactionOrigin.manual,
          economicFactId: 'fact',
        ),
      ],
      fundTransactions: const [],
      linkedItems: [linked ?? _linked()],
    );

FinanceBalance _balance(String id, {bool prepaid = false}) => FinanceBalance(
  balanceId: id,
  personId: 'matteo',
  name: prepaid ? 'Same visible name' : 'Parent',
  initialAmount: prepaid ? 10 : 100,
  currentAmount: prepaid ? 7 : 100,
  updatedAt: DateTime.utc(2026, 9, 1),
  balanceType: prepaid
      ? FinanceBalanceType.prepaidCard
      : FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 25,
  persistentStressDays: 2,
  recoveryDays: 1,
);

FinanceAccountLinkedItem _linked({String? autonomousBalanceId = 'prepaid'}) =>
    FinanceAccountLinkedItem(
      id: 'linked_prepaid',
      balanceId: 'parent',
      autonomousBalanceId: autonomousBalanceId,
      type: FinanceAccountLinkedItemType.prepaidCard,
      name: 'Same visible name',
      description: 'Old',
      expirationDate: DateTime(2028, 1, 1),
      amount: 7,
    );

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

String _state(FinanceStore store) => jsonEncode({
  'balances': store.balances.map((item) => item.toJson()).toList(),
  'linked': store.linkedItems.map((item) => item.toJson()).toList(),
  'transactions': store.transactions.map((item) => item.toJson()).toList(),
});
