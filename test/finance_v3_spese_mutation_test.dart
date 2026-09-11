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

  for (final mutation in _mutations) {
    test('V3 ${mutation.name} commits balance and transaction once', () async {
      var writes = 0;
      String? payload;
      final initial = _portfolio();
      final store = await _v3Store(
        writer: _writer((value) {
          writes++;
          payload = value;
        }),
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await mutation.invoke(store, 'account');

      expect(writes, 1);
      expect(notifications, 1);
      expect(store.balances.single.currentAmount, 100 + mutation.delta);
      expect(store.transactions, hasLength(initial.transactions.length + 1));
      final transaction = store.transactions.last;
      expect(transaction.id, startsWith(mutation.idPrefix));
      expect(transaction.balanceId, 'account');
      expect(transaction.amount, mutation.amount);
      expect(transaction.isIncome, mutation.isIncome);
      expect(transaction.type, mutation.type);
      expect(transaction.origin, FinanceTransactionOrigin.manual);
      expect(transaction.description, mutation.expectedDescription);
      expect(transaction.notes, mutation.expectedNotes);
      expect(transaction.economicFactId, mutation.expectedFactId);

      final json = jsonDecode(payload!) as Map<String, dynamic>;
      expect(json['balances'], hasLength(1));
      expect(json['transactions'], hasLength(initial.transactions.length + 1));
      expect(json['funds'], hasLength(initial.funds.length));
      expect(json['assetMovements'], hasLength(initial.assetMovements.length));
      expect(
        json['fundTransactions'],
        hasLength(initial.fundTransactions.length),
      );
      expect(json['linkedItems'], hasLength(initial.linkedItems.length));
    });

    test('V3 ${mutation.name} failure keeps Finance memory unchanged', () async {
      final store = await _v3Store(writer: _failingWriter());
      final before = _state(store);
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(
        mutation.invoke(store, 'account'),
        throwsStateError,
      );

      expect(_state(store), before);
      expect(notifications, 0);
    });

    test('V3 ${mutation.name} missing balance remains a no-op', () async {
      var writes = 0;
      final store = await _v3Store(writer: _writer((_) => writes++));
      final before = _state(store);
      var notifications = 0;
      store.addListener(() => notifications++);

      await mutation.invoke(store, 'missing');

      expect(_state(store), before);
      expect(writes, 0);
      expect(notifications, 0);
    });
  }

  test('legacy Spese mutations retain order, identities and V2 persistence', () async {
    final store = FinanceStore(
      economicFactIdGenerator: EconomicFactIdGenerator.from(
        () => 'generated_fact',
      ),
      initialBalances: [_balance()],
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    for (final mutation in _mutations) {
      await mutation.invoke(store, 'account');
    }

    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(store.balances.single.currentAmount, 112);
    expect(notifications, 4);
    expect(
      store.transactions.map((item) => item.id),
      orderedEquals(_mutations.map((item) => startsWith(item.idPrefix))),
    );
    expect(
      store.transactions.map((item) => item.economicFactId),
      ['provided_expense_fact', 'provided_income_fact', 'generated_fact', 'generated_fact'],
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_balances'), isNotNull);
    expect(prefs.getString('frododesk_finance_transactions'), isNotNull);
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
  });
}

final _mutations = <_MutationCase>[
  _MutationCase(
    name: 'registerRealExpense',
    amount: 10,
    delta: -10,
    idPrefix: 'real_expense_',
    isIncome: false,
    type: FinanceTransactionType.expense,
    expectedDescription: 'Spesa test',
    expectedNotes: 'Categoria test',
    expectedFactId: 'provided_expense_fact',
    invoke: (store, balanceId) => store.registerRealExpense(
      balanceId: balanceId,
      amount: 10,
      description: 'Spesa test',
      notes: 'Categoria test',
      economicFactId: 'provided_expense_fact',
    ),
  ),
  _MutationCase(
    name: 'registerExtraIncome',
    amount: 20,
    delta: 20,
    idPrefix: 'extra_income_',
    isIncome: true,
    type: FinanceTransactionType.income,
    expectedDescription: 'Entrata test',
    expectedNotes: 'Nota entrata',
    expectedFactId: 'provided_income_fact',
    invoke: (store, balanceId) => store.registerExtraIncome(
      balanceId: balanceId,
      amount: 20,
      description: 'Entrata test',
      notes: 'Nota entrata',
      economicFactId: 'provided_income_fact',
    ),
  ),
  _MutationCase(
    name: 'removeExtraIncome',
    amount: 5,
    delta: -5,
    idPrefix: 'remove_extra_income_',
    isIncome: false,
    type: FinanceTransactionType.expense,
    expectedDescription: 'Annullamento Entrata test',
    expectedNotes: 'Rimozione entrata extra',
    expectedFactId: 'generated_fact',
    invoke: (store, balanceId) => store.removeExtraIncome(
      balanceId: balanceId,
      amount: 5,
      description: 'Entrata test',
    ),
  ),
  _MutationCase(
    name: 'restoreRealExpense',
    amount: 7,
    delta: 7,
    idPrefix: 'restore_expense_',
    isIncome: true,
    type: FinanceTransactionType.income,
    expectedDescription: 'Annullamento Spesa test',
    expectedNotes: 'Ripristino movimento eliminato',
    expectedFactId: 'generated_fact',
    invoke: (store, balanceId) => store.restoreRealExpense(
      balanceId: balanceId,
      amount: 7,
      description: 'Spesa test',
    ),
  ),
];

class _MutationCase {
  final String name;
  final double amount;
  final double delta;
  final String idPrefix;
  final bool isIncome;
  final FinanceTransactionType type;
  final String expectedDescription;
  final String expectedNotes;
  final String expectedFactId;
  final Future<void> Function(FinanceStore store, String balanceId) invoke;

  const _MutationCase({
    required this.name,
    required this.amount,
    required this.delta,
    required this.idPrefix,
    required this.isIncome,
    required this.type,
    required this.expectedDescription,
    required this.expectedNotes,
    required this.expectedFactId,
    required this.invoke,
  });
}

Future<FinanceStore> _v3Store({required FinancePortfolioV3Writer writer}) async {
  final portfolio = _portfolio();
  SharedPreferences.setMockInitialValues({
    'frododesk_finance_portfolio_v3': jsonEncode(
      FinancePortfolioV3Contract.build(portfolio),
    ),
  });
  final store = FinanceStore(
    economicFactIdGenerator: EconomicFactIdGenerator.from(
      () => 'generated_fact',
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
        kind: FinanceAssetMovementKind.fundAllocation,
        description: 'Movement',
        occurredAt: DateTime.utc(2026, 9, 11),
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
        id: 'existing',
        balanceId: balance.balanceId,
        amount: 1,
        date: DateTime.utc(2026, 9, 10),
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
        description: 'Fund transaction',
        amount: 10,
        date: DateTime.utc(2026, 9, 10),
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
  updatedAt: DateTime.utc(2026, 9, 10),
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
