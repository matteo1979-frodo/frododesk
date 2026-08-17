import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frododesk/logic/economics/adapters/finance_asset_movement_event_adapter.dart';
import 'package:frododesk/logic/economics/adapters/finance_transaction_event_adapter.dart';
import 'package:frododesk/logic/economics/adapters/real_expense_event_adapter.dart';
import 'package:frododesk/logic/economics/economic_fact_id_generator.dart';
import 'package:frododesk/logic/finance/builders/finance_fund_movement_builder.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  final occurredAt = DateTime(2026, 8, 17, 12);

  test('legacy records keep a null economic fact identity', () {
    expect(
      FinanceTransaction.fromJson(_transactionJson()).economicFactId,
      isNull,
    );
    expect(
      FinanceAssetMovement.fromJson(_movementJson()).economicFactId,
      isNull,
    );
    expect(RealExpense.fromJson(_expenseJson()).economicFactId, isNull);
  });

  test('economicFactId persists and adapters preserve it separately', () {
    const factId = 'fact_1';
    final transaction = FinanceTransaction.fromJson({
      ..._transactionJson(),
      'economicFactId': factId,
    });
    final movement = FinanceAssetMovement.fromJson({
      ..._movementJson(),
      'economicFactId': factId,
    });
    final expense = RealExpense.fromJson({
      ..._expenseJson(),
      'economicFactId': factId,
    });

    expect(transaction.toJson()['economicFactId'], factId);
    expect(movement.toJson()['economicFactId'], factId);
    expect(expense.toJson()['economicFactId'], factId);
    expect(
      const FinanceTransactionEventAdapter()
          .adapt(transaction, observedAt: occurredAt)
          .economicFactId,
      factId,
    );
    expect(
      const FinanceAssetMovementEventAdapter()
          .adapt(movement, observedAt: occurredAt)
          .economicFactId,
      factId,
    );
    expect(
      const RealExpenseEventAdapter()
          .adapt(expense, observedAt: occurredAt)
          .economicFactId,
      factId,
    );
  });

  test('fund to fund records share one fact and keep distinct record ids', () {
    const factId = 'fact_fund_transfer';
    final plan = const FinanceFundMovementBuilder().transferBetweenFunds(
      balances: const [],
      funds: [_fund('source', 1000), _fund('destination', 0)],
      movements: const [],
      transactions: const [],
      sourceFundId: 'source',
      destinationFundId: 'destination',
      amount: 100,
      description: 'Trasferimento',
      occurredAt: occurredAt,
      economicFactId: factId,
    );

    expect(plan.movements, hasLength(2));
    expect(plan.movements.map((item) => item.economicFactId), {factId});
    expect(plan.movements.map((item) => item.id).toSet(), hasLength(2));
  });

  test('account and fund transfers preserve the supplied fact identity', () {
    const allocationFactId = 'fact_account_fund';
    const releaseFactId = 'fact_fund_account';
    final builder = const FinanceFundMovementBuilder();
    final balances = [_balance('account', 1000)];
    final funds = [_fund('fund', 500)];

    final allocation = builder.allocate(
      balances: balances,
      funds: funds,
      movements: const [],
      transactions: const [],
      fundId: 'fund',
      sources: const [FinanceMoneyPortion(balanceId: 'account', amount: 100)],
      description: 'Conto a fondo',
      occurredAt: occurredAt,
      economicFactId: allocationFactId,
    );
    final release = builder.release(
      balances: balances,
      funds: funds,
      movements: const [],
      transactions: const [],
      fundId: 'fund',
      destinations: const [
        FinanceMoneyPortion(balanceId: 'account', amount: 100),
      ],
      description: 'Fondo a conto',
      occurredAt: occurredAt,
      economicFactId: releaseFactId,
    );

    expect(allocation.movements.single.economicFactId, allocationFactId);
    expect(release.movements.single.economicFactId, releaseFactId);
    expect(
      allocation.movements.single.economicFactId,
      isNot(release.movements.single.economicFactId),
    );
  });

  test('fund expense movement and transaction share one fact', () {
    const factId = 'fact_fund_expense';
    final plan = const FinanceFundMovementBuilder().spend(
      balances: const [],
      funds: [_fund('source', 1000)],
      movements: const [],
      transactions: const [],
      fundId: 'source',
      amount: 100,
      description: 'Spesa',
      occurredAt: occurredAt,
      economicFactId: factId,
    );

    expect(plan.movements.single.economicFactId, factId);
    expect(plan.transactions.single.economicFactId, factId);
  });

  test('account transfer legs share one newly generated fact', () async {
    SharedPreferences.setMockInitialValues({});
    var sequence = 0;
    final store = FinanceStore(
      economicFactIdGenerator: EconomicFactIdGenerator.from(
        () => 'fact_${sequence++}',
      ),
    );
    store.balances.addAll([_balance('from', 1000), _balance('to', 0)]);

    await store.transferBetweenBalances(
      fromBalanceId: 'from',
      toBalanceId: 'to',
      amount: 100,
    );

    expect(store.transactions, hasLength(2));
    expect(store.transactions.map((item) => item.economicFactId), {'fact_0'});
    expect(store.transactions.map((item) => item.id).toSet(), hasLength(2));
  });

  test('separate occurrences receive separate facts', () {
    var sequence = 0;
    final generator = EconomicFactIdGenerator.from(
      () => 'occurrence_${sequence++}',
    );

    final first = generator.next();
    final second = generator.next();

    expect(first, isNot(second));
  });
}

FinanceFund _fund(String id, double amount) => FinanceFund(
  id: id,
  name: id,
  description: '',
  amount: amount,
  protected: false,
  category: FinanceFundCategory.generic,
  status: FinanceFundStatus.active,
  openingKind: FinanceFundOpeningKind.preExisting,
  openedAt: DateTime(2026),
);

FinanceBalance _balance(String id, double amount) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: id,
  initialAmount: amount,
  currentAmount: amount,
  updatedAt: DateTime(2026),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

Map<String, dynamic> _transactionJson() => {
  'id': 'transaction_1',
  'balanceId': 'account_1',
  'amount': 10.0,
  'date': DateTime(2026).toIso8601String(),
  'isIncome': false,
  'subject': FinanceSubject.shared.name,
  'description': 'Spesa',
  'type': FinanceTransactionType.expense.name,
  'origin': FinanceTransactionOrigin.manual.name,
};

Map<String, dynamic> _movementJson() => {
  'id': 'movement_1',
  'fundId': 'fund_1',
  'kind': FinanceAssetMovementKind.fundExpense.name,
  'description': 'Spesa',
  'occurredAt': DateTime(2026).toIso8601String(),
  'legs': [
    {
      'type': FinanceAssetLegType.fund.name,
      'referenceId': 'fund_1',
      'delta': -10.0,
    },
    {'type': FinanceAssetLegType.expense.name, 'delta': 10.0},
  ],
};

Map<String, dynamic> _expenseJson() => {
  'id': 'expense_1',
  'balanceId': 'account_1',
  'balanceName': 'Conto',
  'amount': 10.0,
  'description': 'Spesa',
  'category': 'Casa',
  'date': DateTime(2026).toIso8601String(),
  'isCashWithdrawal': false,
  'nonTrackedCash': false,
  'isIncome': false,
  'subject': FinanceSubject.shared.name,
};
