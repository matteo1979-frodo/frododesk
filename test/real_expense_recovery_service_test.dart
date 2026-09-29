import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/real_expense_recovery_service.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/finite_financial_plan.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/expense_store.dart';

void main() {
  test('preview selects only 12 certified candidates and never writes', () async {
    final fixture = await _fixture();
    final before = jsonEncode(FinancePortfolioV3Contract.build(fixture.portfolio));

    final preview = fixture.service.preview(
      portfolio: fixture.portfolio,
      finitePlans: [fixture.plan],
    );

    expect(preview.ready, isTrue);
    expect(preview.existing, hasLength(1));
    expect(preview.candidates, hasLength(12));
    expect(preview.finalExpenses, hasLength(13));
    expect(preview.candidates.where((item) => item.producer == 'composite'), hasLength(9));
    expect(preview.candidates.where((item) => item.producer == 'expense replacement'), hasLength(1));
    expect(preview.candidates.where((item) => item.producer.startsWith('finite plan')), hasLength(2));
    final recoveredFacts = preview.candidates
        .map((item) => item.expense.economicFactId)
        .toSet();
    expect(recoveredFacts, isNot(contains('economic_fact_spese_legacy')));
    expect(recoveredFacts, isNot(contains('transfer-fact')));
    expect(recoveredFacts, isNot(contains('compensation-fact')));
    expect(recoveredFacts, isNot(contains('unsupported-fact')));
    expect(preview.existing.single.economicFactId, 'keep-fact');
    expect(fixture.writes, 0);
    expect(jsonEncode(FinancePortfolioV3Contract.build(fixture.portfolio)), before);
  });

  test('verified recovery is atomic and second run is idempotent', () async {
    final fixture = await _fixture();
    final preview = fixture.service.preview(
      portfolio: fixture.portfolio,
      finitePlans: [fixture.plan],
    );
    final result = await fixture.service.recover(preview);
    expect(result.status, VerifiedExpenseRecoveryStatus.committed);
    expect(fixture.store.all, hasLength(13));
    expect(fixture.writes, 1);

    final second = fixture.service.preview(
      portfolio: fixture.portfolio,
      finitePlans: [fixture.plan],
    );
    expect(second.noEconomicFactCollision, isTrue);
    expect(second.alreadyRecovered, isTrue);
    expect(second.candidates, isEmpty);
    final retry = await fixture.service.recover(second);
    expect(retry.status, VerifiedExpenseRecoveryStatus.alreadyCoherent);
    expect(fixture.writes, 1);
  });

  test('not loaded store and identity collision abort without writes', () async {
    final unloaded = ExpenseStore(
      load: (_) async => '[]',
      saveVerified: (_, value) async => PersistenceWriteVerification(
        backendAccepted: true,
        readBack: value,
      ),
    );
    final base = await _fixture();
    final preview = RealExpenseRecoveryService(expenseStore: unloaded).preview(
      portfolio: base.portfolio,
      finitePlans: [base.plan],
    );
    expect(preview.ready, isFalse);
    expect((await RealExpenseRecoveryService(expenseStore: unloaded).recover(preview)).isSuccess, isFalse);

    final candidate = base.portfolio.transactions[1];
    final duplicate = _portfolio([...base.portfolio.transactions, candidate]);
    final collision = base.service.preview(
      portfolio: duplicate,
      finitePlans: [base.plan],
    );
    expect(collision.ready, isFalse);
    expect(collision.noEconomicFactCollision, isFalse);
    expect(base.writes, 0);
  });

  test('duplicate transfer legs are excluded without blocking recovery', () async {
    final fixture = await _fixture();

    final preview = fixture.service.preview(
      portfolio: fixture.portfolio,
      finitePlans: [fixture.plan],
    );

    expect(preview.existing, hasLength(1));
    expect(preview.candidates, hasLength(12));
    expect(preview.finalExpenses, hasLength(13));
    expect(preview.noEconomicFactCollision, isTrue);
    expect(preview.ready, isTrue);
    expect(
      preview.candidates.map((item) => item.expense.economicFactId),
      isNot(contains('transfer-fact')),
    );
  });

  test('incompatible candidate overlapping an existing expense blocks recovery', () async {
    final fixture = await _fixture();
    final overlap = _compositeForFact('keep-fact', 99);

    final preview = fixture.service.preview(
      portfolio: _portfolio([...fixture.portfolio.transactions, overlap]),
      finitePlans: [fixture.plan],
    );

    expect(preview.noEconomicFactCollision, isFalse);
    expect(preview.ready, isFalse);
    expect(preview.errors, contains('Economic fact identity collision'));
    expect(fixture.writes, 0);
  });

  test('duplicate existing economic fact blocks recovery', () async {
    final base = await _fixture();
    final first = _expense('duplicate-a', 'duplicate-fact', 1);
    final second = _expense('duplicate-b', 'duplicate-fact', 2);
    final store = ExpenseStore(
      load: (_) async => jsonEncode([first.toJson(), second.toJson()]),
      saveVerified: (_, value) async => PersistenceWriteVerification(
        backendAccepted: true,
        readBack: value,
      ),
    );
    await store.load();

    final preview = RealExpenseRecoveryService(expenseStore: store).preview(
      portfolio: base.portfolio,
      finitePlans: [base.plan],
    );

    expect(preview.noEconomicFactCollision, isFalse);
    expect(preview.ready, isFalse);
    expect(preview.errors, contains('Economic fact identity collision'));
  });

}

class _Fixture {
  final ExpenseStore store;
  final RealExpenseRecoveryService service;
  final FinancePortfolioV3 portfolio;
  final FiniteFinancialPlan plan;
  final int Function() _writes;

  const _Fixture(this.store, this.service, this.portfolio, this.plan, this._writes);
  int get writes => _writes();
}

Future<_Fixture> _fixture() async {
  final existing = _expense('keep', 'keep-fact', 40);
  var raw = jsonEncode([existing.toJson()]);
  var writes = 0;
  final store = ExpenseStore(
    load: (_) async => raw,
    saveVerified: (_, value) async {
      writes++;
      raw = value;
      return PersistenceWriteVerification(backendAccepted: true, readBack: value);
    },
  );
  await store.load();
  final plan = FiniteFinancialPlan(
    id: 'finite_plan_test',
    name: 'Plan',
    subject: FinanceSubject.matteo,
    debitBalanceId: 'balance',
    totalInstallments: 12,
    expectedInstallmentAmount: 386,
    firstInstallmentDate: DateTime(2026, 7, 15),
  );
  final encodedPlan = base64Url.encode(utf8.encode(plan.id));
  final transactions = <FinanceTransaction>[
    _transaction(id: 'real_expense_keep', fact: 'keep-fact', amount: 40),
    for (var index = 0; index < 9; index++) _composite(index),
    _replacement(),
    _finite(encodedPlan, 'main', 386),
    _finite(encodedPlan, 'fee', 1),
    _legacyReview(),
    _transfer(),
    _transferIn(),
    _compensation(),
    _unsupportedReview(),
  ];
  final portfolio = _portfolio(transactions);
  return _Fixture(
    store,
    RealExpenseRecoveryService(expenseStore: store),
    portfolio,
    plan,
    () => writes,
  );
}

FinancePortfolioV3 _portfolio(List<FinanceTransaction> transactions) =>
    FinancePortfolioV3(
      balances: [_balance()],
      funds: const [],
      assetMovements: const [],
      transactions: transactions,
      fundTransactions: const [],
      linkedItems: const [],
    );

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'balance',
  name: 'Banca',
  initialAmount: 1000,
  currentAmount: 1000,
  updatedAt: DateTime(2026, 9, 28),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceTransaction _composite(int index) {
  final fact = 'composite-fact-$index';
  return _compositeForFact(fact, index);
}

FinanceTransaction _compositeForFact(String fact, int index) {
  return _transaction(
    id: 'finance_transaction:composite:${base64Url.encode(utf8.encode(fact))}',
    fact: fact,
    amount: index + 1,
    metadata: EconomicOperationMetadata(
      operationId: 'operation-${index ~/ 3}',
      role: index % 3 == 0 ? OperationRole.main : OperationRole.accessory,
      context: OperationContext.utilityBill,
      accessoryCostType: index % 3 == 0
          ? null
          : index.isEven
          ? AccessoryCostType.bankCommission
          : AccessoryCostType.postalAcceptanceCharge,
    ),
  );
}

FinanceTransaction _replacement() {
  const command = 'expense_replacement_token_replacement';
  const fact = 'economic_fact_spese_$command';
  return _transaction(
    id: 'real_expense_spese_${base64Url.encode(utf8.encode(fact))}',
    fact: fact,
    amount: 13.30,
  );
}

FinanceTransaction _finite(String encodedPlan, String role, double amount) {
  final identity = 'finite_plan_installment:$encodedPlan:3';
  return _transaction(
    id: 'finance_transaction:$identity:$role',
    fact: 'economic_fact:$identity:$role',
    amount: amount,
  );
}

FinanceTransaction _legacyReview() =>
    _transaction(id: 'real_expense_legacy', fact: 'economic_fact_spese_legacy', amount: 50);

FinanceTransaction _transfer() => FinanceTransaction(
  id: 'transfer_out',
  balanceId: 'balance',
  amount: 10,
  date: DateTime(2026, 9, 28),
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: 'Transfer',
  type: FinanceTransactionType.transfer,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: 'transfer-fact',
);

FinanceTransaction _transferIn() => FinanceTransaction(
  id: 'transfer_in',
  balanceId: 'balance',
  amount: 10,
  date: DateTime(2026, 9, 28),
  isIncome: true,
  subject: FinanceSubject.matteo,
  description: 'Transfer',
  type: FinanceTransactionType.transfer,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: 'transfer-fact',
);

FinanceTransaction _compensation() => FinanceTransaction(
  id: 'compensation',
  balanceId: 'balance',
  amount: 10,
  date: DateTime(2026, 9, 28),
  isIncome: true,
  subject: FinanceSubject.matteo,
  description: 'Compensation',
  type: FinanceTransactionType.income,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: 'compensation-fact',
);

FinanceTransaction _unsupportedReview() => _transaction(
  id: 'unsupported_expense',
  fact: 'unsupported-fact',
  amount: 10,
);

FinanceTransaction _transaction({
  required String id,
  required String fact,
  required double amount,
  EconomicOperationMetadata? metadata,
}) => FinanceTransaction(
  id: id,
  balanceId: 'balance',
  amount: amount,
  date: DateTime(2026, 9, 28),
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: 'Expense',
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  notes: 'Category',
  economicFactId: fact,
  operationMetadata: metadata,
);

RealExpense _expense(String id, String fact, double amount) => RealExpense(
  id: id,
  balanceId: 'balance',
  balanceName: 'Banca',
  amount: amount,
  description: 'Existing',
  category: 'Category',
  date: DateTime(2026, 9, 28),
  subject: FinanceSubject.matteo,
  economicFactId: fact,
);
