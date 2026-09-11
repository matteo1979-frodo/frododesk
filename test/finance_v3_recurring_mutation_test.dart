import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/economics/economic_fact_id_generator.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/finance_account_linked_item.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/fund_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('V3 confirm commits Finance before recurring and preserves payload', () async {
    String? payload;
    final recurring = _recurring(recurringType: FinanceRecurringType.monthly);
    final store = await _v3Store(
      portfolio: _portfolio(),
      recurringItems: [recurring],
      writer: _writer((value) => payload = value),
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.confirmRecurringItem(recurring.id, realAmount: 25);

    expect(store.balances.single.currentAmount, 75);
    expect(store.transactions.map((item) => item.id), [
      'existing_transaction',
      startsWith('transaction_'),
    ]);
    final transaction = store.transactions.last;
    expect(transaction.recurringItemId, recurring.id);
    expect(transaction.amount, 25);
    expect(transaction.isIncome, isFalse);
    expect(transaction.origin, FinanceTransactionOrigin.recurringItem);
    expect(transaction.economicFactId, 'recurring_fact');
    expect(store.recurringItems, hasLength(2));
    expect(store.recurringItems.first.confirmed, isTrue);
    expect(store.recurringItems.first.realAmount, 25);
    expect(store.recurringItems.last.id, startsWith('recurring_'));
    expect(store.recurringItems.last.confirmed, isFalse);
    expect(notifications, 1);

    final json = jsonDecode(payload!) as Map<String, dynamic>;
    expect(json['balances'], hasLength(1));
    expect(json['transactions'], hasLength(2));
    expect(json['funds'], hasLength(1));
    expect(json['assetMovements'], hasLength(1));
    expect(json['fundTransactions'], hasLength(1));
    expect(json['linkedItems'], hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    final savedRecurring = jsonDecode(
      prefs.getString('frododesk_finance_recurring_items')!,
    ) as List<dynamic>;
    expect(savedRecurring, hasLength(2));
  });

  test('V3 remove restores balance and removes linked transactions', () async {
    String? payload;
    final recurring = _recurring();
    final portfolio = _portfolio(
      balanceAmount: 75,
      recurringTransaction: _recurringTransaction(recurring.id),
    );
    final store = await _v3Store(
      portfolio: portfolio,
      recurringItems: [recurring.copyWith(confirmed: true, realAmount: 25)],
      writer: _writer((value) => payload = value),
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.removeRecurringItem(recurring.id);

    expect(store.balances.single.currentAmount, 100);
    expect(store.transactions.map((item) => item.id), ['existing_transaction']);
    expect(store.recurringItems, isEmpty);
    expect(notifications, 1);
    final json = jsonDecode(payload!) as Map<String, dynamic>;
    expect((json['balances'] as List).single['currentAmount'], 100);
    expect(
      (json['transactions'] as List).map((item) => item['id']),
      ['existing_transaction'],
    );
    expect(json['funds'], hasLength(1));
    expect(json['assetMovements'], hasLength(1));
    expect(json['fundTransactions'], hasLength(1));
    expect(json['linkedItems'], hasLength(1));
  });

  for (final operation in ['confirm', 'remove']) {
    test('V3 $operation writer failure leaves all memory unchanged', () async {
      final recurring = _recurring();
      final store = await _v3Store(
        portfolio: operation == 'remove'
            ? _portfolio(
                balanceAmount: 75,
                recurringTransaction: _recurringTransaction(recurring.id),
              )
            : _portfolio(),
        recurringItems: [recurring],
        writer: _failingWriter(),
      );
      final before = _state(store);
      var notifications = 0;
      store.addListener(() => notifications++);

      final action = operation == 'confirm'
          ? store.confirmRecurringItem(recurring.id)
          : store.removeRecurringItem(recurring.id);
      await expectLater(action, throwsStateError);

      expect(_state(store), before);
      expect(notifications, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('frododesk_finance_recurring_items'), isNull);
    });
  }

  test('V3 confirm without a resolvable balance keeps recurring semantics', () async {
    var writes = 0;
    final recurring = _recurring(balanceId: 'missing');
    final store = await _v3Store(
      portfolio: _portfolio(),
      recurringItems: [recurring],
      writer: _writer((_) => writes++),
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.confirmRecurringItem(recurring.id);

    expect(writes, 0);
    expect(store.balances.single.currentAmount, 100);
    expect(store.transactions, hasLength(1));
    expect(store.recurringItems.single.confirmed, isTrue);
    expect(notifications, 1);
  });

  test('missing and already confirmed recurring items remain no-ops', () async {
    var writes = 0;
    final recurring = _recurring();
    final store = await _v3Store(
      portfolio: _portfolio(),
      recurringItems: [recurring.copyWith(confirmed: true)],
      writer: _writer((_) => writes++),
    );
    final before = _state(store);
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.confirmRecurringItem(recurring.id);
    await store.confirmRecurringItem('missing');
    await store.removeRecurringItem('missing');

    expect(_state(store), before);
    expect(writes, 0);
    expect(notifications, 0);
  });

  test('legacy recurring mutations retain separate persistence', () async {
    final recurring = _recurring();
    final store = FinanceStore(
      economicFactIdGenerator: EconomicFactIdGenerator.from(
        () => 'recurring_fact',
      ),
      initialBalances: [_balance()],
      initialRecurringItems: [recurring],
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.confirmRecurringItem(recurring.id, realAmount: 25);
    await store.removeRecurringItem(recurring.id);

    expect(store.isPortfolioV3Authoritative, isFalse);
    expect(store.balances.single.currentAmount, 100);
    expect(store.transactions, isEmpty);
    expect(store.recurringItems, isEmpty);
    expect(notifications, 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('frododesk_finance_balances'), isNotNull);
    expect(prefs.getString('frododesk_finance_transactions'), isNotNull);
    expect(prefs.getString('frododesk_finance_recurring_items'), isNotNull);
    expect(prefs.getString('frododesk_finance_portfolio_v3'), isNull);
  });
}

Future<FinanceStore> _v3Store({
  required FinancePortfolioV3 portfolio,
  required List<FinanceRecurringItem> recurringItems,
  required FinancePortfolioV3Writer writer,
}) async {
  SharedPreferences.setMockInitialValues({
    'frododesk_finance_portfolio_v3': jsonEncode(
      FinancePortfolioV3Contract.build(portfolio),
    ),
  });
  final store = FinanceStore(
    economicFactIdGenerator: EconomicFactIdGenerator.from(
      () => 'recurring_fact',
    ),
    initialRecurringItems: recurringItems,
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

FinancePortfolioV3 _portfolio({
  double balanceAmount = 100,
  FinanceTransaction? recurringTransaction,
}) {
  final balance = _balance(amount: balanceAmount);
  final transactions = <FinanceTransaction>[
    FinanceTransaction(
      id: 'existing_transaction',
      balanceId: balance.balanceId,
      amount: 1,
      date: DateTime.utc(2026, 9, 10),
      isIncome: false,
      subject: FinanceSubject.matteo,
      description: 'Existing',
      type: FinanceTransactionType.expense,
      origin: FinanceTransactionOrigin.manual,
    ),
  ];
  if (recurringTransaction != null) {
    transactions.add(recurringTransaction);
  }
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
    transactions: transactions,
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

FinanceBalance _balance({double amount = 100}) => FinanceBalance(
  personId: 'matteo',
  balanceId: 'account',
  name: 'Account',
  initialAmount: 100,
  currentAmount: amount,
  updatedAt: DateTime.utc(2026, 9, 10),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceRecurringItem _recurring({
  String balanceId = 'account',
  FinanceRecurringType recurringType = FinanceRecurringType.oneShot,
}) => FinanceRecurringItem(
  id: 'recurring_item',
  name: 'Recurring expense',
  description: 'Recurring note',
  expectedAmount: 20,
  nextDueDate: DateTime.utc(2026, 9, 11),
  isIncome: false,
  recurringType: recurringType,
  category: FinanceCategory.generic,
  requiresManualConfirmation: true,
  mandatory: false,
  pressureLevel: FinancePressureLevel.low,
  confirmed: false,
  variability: FinanceVariability.fixed,
  paymentPriority: FinancePaymentPriority.normal,
  protectionLevel: FinanceProtectionLevel.none,
  paymentOwner: FinancePaymentOwner.matteo,
  subject: FinanceSubject.matteo,
  balanceId: balanceId,
  paymentMethod: FinancePaymentMethod.manual,
  stability: FinanceStability.stable,
  suspensionRisk: FinanceSuspensionRisk.low,
  originType: FinanceOriginType.manual,
  splits: const [],
);

FinanceTransaction _recurringTransaction(String recurringItemId) =>
    FinanceTransaction(
      id: 'recurring_transaction',
      balanceId: 'account',
      amount: 25,
      date: DateTime.utc(2026, 9, 11),
      isIncome: false,
      subject: FinanceSubject.matteo,
      description: 'Recurring expense',
      type: FinanceTransactionType.expense,
      origin: FinanceTransactionOrigin.recurringItem,
      recurringItemId: recurringItemId,
      economicFactId: 'existing_recurring_fact',
    );

String _state(FinanceStore store) => jsonEncode({
  'balances': store.balances.map((item) => item.toJson()).toList(),
  'transactions': store.transactions.map((item) => item.toJson()).toList(),
  'recurringItems': store.recurringItems.map((item) => item.toJson()).toList(),
});
