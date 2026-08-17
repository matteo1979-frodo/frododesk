import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/finance_fund_movement_builder.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_fund_mutation_plan.dart';

void main() {
  const builder = FinanceFundMovementBuilder();
  final observedAt = DateTime(2026, 8, 11, 10);

  test('opening from multiple accounts preserves family net worth', () {
    final balances = [_balance('cash', 300), _balance('chiara', 1000)];
    final before = _wealth(balances, const []);
    final plan = builder.open(
      balances: balances,
      funds: const [],
      movements: const [],
      transactions: const [],
      fund: _fund('vacanze', 500),
      sources: const [
        FinanceMoneyPortion(balanceId: 'cash', amount: 100),
        FinanceMoneyPortion(balanceId: 'chiara', amount: 400),
      ],
      preExisting: false,
      occurredAt: observedAt,
    );

    expect(plan.balances.map((item) => item.currentAmount), [200, 600]);
    expect(plan.funds.single.amount, 500);
    expect(_wealth(plan.balances, plan.funds), before);
    expect(plan.movements.single.accountingDelta, closeTo(0, 0.001));
  });

  test('pre-existing opening leaves accounts unchanged and is not income', () {
    final balances = [_balance('matteo', 1000)];
    final plan = builder.open(
      balances: balances,
      funds: const [],
      movements: const [],
      transactions: const [],
      fund: _fund('emergenze', 5000),
      sources: const [],
      preExisting: true,
      occurredAt: observedAt,
    );

    expect(plan.balances.single.currentAmount, 1000);
    expect(plan.transactions, isEmpty);
    expect(plan.movements.single.kind, FinanceAssetMovementKind.fundOpening);
    expect(plan.movements.single.ownedWealthDelta, 5000);
  });

  test('closing to multiple accounts preserves history and net worth', () {
    final balances = [_balance('matteo', 100), _balance('chiara', 200)];
    final funds = [_fund('vacanze', 500)];
    final opening = _legacyMovement('vacanze', 500, observedAt);
    final before = _wealth(balances, funds);
    final plan = builder.release(
      balances: balances,
      funds: funds,
      movements: [opening],
      transactions: const [],
      fundId: 'vacanze',
      destinations: const [
        FinanceMoneyPortion(balanceId: 'matteo', amount: 200),
        FinanceMoneyPortion(balanceId: 'chiara', amount: 300),
      ],
      description: 'Chiusura vacanze',
      occurredAt: observedAt,
      close: true,
    );

    expect(plan.funds.single.amount, 0);
    expect(plan.funds.single.status, FinanceFundStatus.closed);
    expect(plan.movements, hasLength(2));
    expect(_wealth(plan.balances, plan.funds), before);
  });

  test('closing as consumed records one real expense', () {
    final plan = builder.spend(
      balances: [_balance('matteo', 100)],
      funds: [_fund('vacanze', 500)],
      movements: const [],
      transactions: const [],
      fundId: 'vacanze',
      amount: 500,
      description: 'Vacanza',
      occurredAt: observedAt,
      close: true,
    );

    expect(plan.funds.single.status, FinanceFundStatus.closed);
    expect(plan.transactions.single.amount, 500);
    expect(plan.transactions.single.isIncome, isFalse);
    expect(plan.movements.single.ownedWealthDelta, -500);
  });

  test('partial expense keeps fund open and rejects overspending', () {
    final plan = builder.spend(
      balances: const [],
      funds: [_fund('auto', 3000)],
      movements: const [],
      transactions: const [],
      fundId: 'auto',
      amount: 700,
      description: 'Meccanico',
      occurredAt: observedAt,
    );
    expect(plan.funds.single.amount, 2300);
    expect(plan.funds.single.status, FinanceFundStatus.active);
    expect(
      () => builder.spend(
        balances: const [],
        funds: [_fund('auto', 3000)],
        movements: const [],
        transactions: const [],
        fundId: 'auto',
        amount: 3001,
        description: 'Errore',
        occurredAt: observedAt,
      ),
      throwsArgumentError,
    );
  });

  test('direct fund transfer is atomic and preserves family net worth', () {
    final funds = [_fund('vacanze', 900), _fund('auto', 300)];
    final before = _wealth(const [], funds);
    final plan = builder.transferBetweenFunds(
      balances: const [],
      funds: funds,
      movements: const [],
      transactions: const [],
      sourceFundId: 'vacanze',
      destinationFundId: 'auto',
      amount: 250,
      description: 'Cambio obiettivo',
      occurredAt: observedAt,
    );

    expect(plan.funds.map((fund) => fund.amount), [650, 550]);
    expect(_wealth(plan.balances, plan.funds), before);
    expect(plan.balances, isEmpty);
    expect(plan.transactions, isEmpty);
    expect(plan.movements, hasLength(2));
    expect(plan.movements.map((item) => item.kind), [
      FinanceAssetMovementKind.fundTransferOut,
      FinanceAssetMovementKind.fundTransferIn,
    ]);
    expect(plan.movements.map((item) => item.fundId), ['vacanze', 'auto']);
    expect(plan.movements.map((item) => item.accountingDelta), [0, 0]);
    expect(plan.movements.map((item) => item.id).toSet(), hasLength(2));
  });

  test('direct fund transfer rejects invalid destinations and amounts', () {
    final funds = [_fund('vacanze', 900), _fund('auto', 300)];
    FinanceFundMutationPlan transfer({
      required String destination,
      required double amount,
    }) => builder.transferBetweenFunds(
      balances: const [],
      funds: funds,
      movements: const [],
      transactions: const [],
      sourceFundId: 'vacanze',
      destinationFundId: destination,
      amount: amount,
      description: '',
      occurredAt: observedAt,
    );

    expect(
      () => transfer(destination: 'vacanze', amount: 100),
      throwsArgumentError,
    );
    expect(
      () => transfer(destination: 'auto', amount: 901),
      throwsArgumentError,
    );
    expect(
      () => transfer(destination: 'missing', amount: 100),
      throwsArgumentError,
    );
  });

  test('an empty fund closes without creating a fake operation', () {
    final plan = builder.closeEmpty(
      balances: [_balance('matteo', 100)],
      funds: [_fund('vacanze', 0)],
      movements: const [],
      transactions: const [],
      fundId: 'vacanze',
      occurredAt: observedAt,
    );

    expect(plan.funds.single.status, FinanceFundStatus.closed);
    expect(plan.movements, isEmpty);
    expect(plan.transactions, isEmpty);
  });

  test('builder stays pure and coordinator contains orchestration only', () {
    final builderSource = File(
      'lib/logic/finance/builders/finance_fund_movement_builder.dart',
    ).readAsStringSync();
    final coordinatorSource = File(
      'lib/logic/finance/finance_fund_lifecycle_coordinator.dart',
    ).readAsStringSync();
    expect(builderSource, isNot(contains('PersistenceStore')));
    expect(builderSource, isNot(contains('package:flutter')));
    expect(builderSource, isNot(contains('DateTime.now')));
    expect(coordinatorSource, contains('movementBuilder.'));
    expect(coordinatorSource, contains('commitFundPlan'));
    expect(coordinatorSource, isNot(contains('currentAmount +')));
    expect(coordinatorSource, isNot(contains('currentAmount -')));
  });
}

FinanceBalance _balance(String id, double amount) => FinanceBalance(
  balanceId: id,
  personId: id,
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

FinanceFund _fund(String id, double amount) => FinanceFund(
  id: id,
  name: id,
  description: '',
  amount: amount,
  protected: false,
  category: FinanceFundCategory.generic,
);

FinanceAssetMovement _legacyMovement(String id, double amount, DateTime date) =>
    FinanceAssetMovement(
      id: 'legacy',
      fundId: id,
      kind: FinanceAssetMovementKind.legacyOpening,
      description: 'Saldo precedente',
      occurredAt: date,
      legs: [
        FinanceAssetLeg(
          type: FinanceAssetLegType.openingBalance,
          delta: -amount,
        ),
        FinanceAssetLeg(
          type: FinanceAssetLegType.fund,
          referenceId: id,
          delta: amount,
        ),
      ],
    );

double _wealth(List<FinanceBalance> balances, List<FinanceFund> funds) =>
    balances.fold<double>(0, (sum, item) => sum + item.currentAmount) +
    funds.fold<double>(0, (sum, item) => sum + item.amount);
