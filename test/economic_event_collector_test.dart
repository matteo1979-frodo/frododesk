import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  const collector = EconomicEventCollector();
  final observedAt = DateTime(2026, 8, 20, 12);

  test('collects every legacy source in deterministic source order', () {
    final events = collector.collect(
      transactions: [
        _transaction(
          id: 'income',
          type: FinanceTransactionType.income,
          isIncome: true,
        ),
        _transaction(id: 'expense'),
      ],
      assetMovements: [_fundExpense('fund-expense')],
      realExpenses: [_realExpense('real-expense')],
      observedAt: observedAt,
    );

    expect(events.map((event) => event.id), [
      'finance_transaction:income',
      'finance_transaction:expense',
      'finance_asset_movement:fund-expense',
      'real_expense:real-expense',
    ]);
    expect(events.map((event) => event.nature), [
      EconomicNature.income,
      EconomicNature.outflow,
      EconomicNature.outflow,
      EconomicNature.outflow,
    ]);
  });

  test('preserves source ids, links and effective dates', () {
    final occurredAt = DateTime(2026, 8, 15, 9, 30);
    final events = collector.collect(
      transactions: [_transaction(id: 'transaction', date: occurredAt)],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );
    final event = events.single;

    expect(event.id, 'finance_transaction:transaction');
    expect(
      event.sourceLinks.single.kind,
      EconomicSourceKind.financeTransaction,
    );
    expect(event.sourceLinks.single.recordId, 'transaction');
    expect(event.observedAt, observedAt);
    expect(event.occurredAt, occurredAt);
  });

  test('collects internal transfers and multiple endpoints', () {
    final movement = FinanceAssetMovement(
      id: 'allocation',
      fundId: 'vacanze',
      kind: FinanceAssetMovementKind.fundAllocation,
      description: 'Versamento',
      occurredAt: DateTime(2026, 8, 18),
      legs: const [
        FinanceAssetLeg(
          type: FinanceAssetLegType.balance,
          referenceId: 'account-1',
          delta: -70,
        ),
        FinanceAssetLeg(
          type: FinanceAssetLegType.balance,
          referenceId: 'account-2',
          delta: -30,
        ),
        FinanceAssetLeg(
          type: FinanceAssetLegType.fund,
          referenceId: 'vacanze',
          delta: 100,
        ),
      ],
    );

    final event = collector
        .collect(
          transactions: const [],
          assetMovements: [movement],
          realExpenses: const [],
          observedAt: observedAt,
        )
        .single;

    expect(event.nature, EconomicNature.internalTransfer);
    expect(event.origins, hasLength(2));
    expect(event.destinations, hasLength(1));
  });

  test('keeps both fund-to-fund legs for future correlation', () {
    final occurredAt = DateTime(2026, 8, 18);
    const legs = [
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: 'vacanze',
        delta: -200,
      ),
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: 'auto',
        delta: 200,
      ),
    ];
    final events = collector.collect(
      transactions: const [],
      assetMovements: [
        FinanceAssetMovement(
          id: 'transfer-out',
          fundId: 'vacanze',
          kind: FinanceAssetMovementKind.fundTransferOut,
          description: 'Cambio obiettivo',
          occurredAt: occurredAt,
          legs: legs,
        ),
        FinanceAssetMovement(
          id: 'transfer-in',
          fundId: 'auto',
          kind: FinanceAssetMovementKind.fundTransferIn,
          description: 'Cambio obiettivo',
          occurredAt: occurredAt,
          legs: legs,
        ),
      ],
      realExpenses: const [],
      observedAt: observedAt,
    );

    expect(events, hasLength(2));
    expect(events.map((event) => event.id), [
      'finance_asset_movement:transfer-out',
      'finance_asset_movement:transfer-in',
    ]);
    expect(
      events.every((event) => event.nature == EconomicNature.internalTransfer),
      isTrue,
    );
  });

  test('collects fund expense as outflow', () {
    final event = collector
        .collect(
          transactions: const [],
          assetMovements: [_fundExpense('hotel')],
          realExpenses: const [],
          observedAt: observedAt,
        )
        .single;

    expect(event.nature, EconomicNature.outflow);
    expect(event.origins.single.kind, EconomicEndpointKind.fund);
    expect(event.destinations.single.kind, EconomicEndpointKind.external);
  });

  test('keeps potentially equivalent records without deduplication', () {
    final occurredAt = DateTime(2026, 8, 18);
    final events = collector.collect(
      transactions: [_transaction(id: 'expense', date: occurredAt)],
      assetMovements: const [],
      realExpenses: [_realExpense('expense', date: occurredAt)],
      observedAt: observedAt,
    );

    expect(events, hasLength(2));
    expect(events.map((event) => event.id), [
      'finance_transaction:expense',
      'real_expense:expense',
    ]);
    expect(events.expand((event) => event.sourceLinks), hasLength(2));
  });

  test('returns immutable results without mutating source collections', () {
    final transactions = [_transaction(id: 'transaction')];
    final movements = [_fundExpense('movement')];
    final expenses = [_realExpense('expense')];
    final originalTransaction = transactions.single;
    final originalMovement = movements.single;
    final originalExpense = expenses.single;

    final events = collector.collect(
      transactions: transactions,
      assetMovements: movements,
      realExpenses: expenses,
      observedAt: observedAt,
    );

    expect(transactions.single, same(originalTransaction));
    expect(movements.single, same(originalMovement));
    expect(expenses.single, same(originalExpense));
    expect(() => events.clear(), throwsUnsupportedError);
  });

  test(
    'collector has no UI, store, persistence or side-effect dependencies',
    () {
      final source = File(
        'lib/logic/ledger/economic_event_collector.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('package:flutter')));
      expect(source, isNot(contains('Widget')));
      expect(source, isNot(contains('Store')));
      expect(source, isNot(contains('PersistenceStore')));
      expect(source, isNot(contains('save(')));
      expect(source, isNot(contains('DateTime.now')));
      expect(source, isNot(contains('.sort(')));
      expect(source, isNot(contains('.where(')));
    },
  );
}

FinanceTransaction _transaction({
  required String id,
  FinanceTransactionType type = FinanceTransactionType.expense,
  bool isIncome = false,
  DateTime? date,
}) => FinanceTransaction(
  id: id,
  balanceId: 'account',
  amount: 20,
  date: date ?? DateTime(2026, 8, 18),
  isIncome: isIncome,
  subject: FinanceSubject.matteo,
  description: id,
  type: type,
  origin: FinanceTransactionOrigin.manual,
);

FinanceAssetMovement _fundExpense(String id) => FinanceAssetMovement(
  id: id,
  fundId: 'vacanze',
  kind: FinanceAssetMovementKind.fundExpense,
  description: id,
  occurredAt: DateTime(2026, 8, 18),
  legs: const [
    FinanceAssetLeg(
      type: FinanceAssetLegType.fund,
      referenceId: 'vacanze',
      delta: -20,
    ),
    FinanceAssetLeg(type: FinanceAssetLegType.expense, delta: 20),
  ],
);

RealExpense _realExpense(String id, {DateTime? date}) => RealExpense(
  id: id,
  balanceId: 'account',
  balanceName: 'Conto Matteo',
  amount: 20,
  description: id,
  category: 'Alimentazione',
  date: date ?? DateTime(2026, 8, 18),
  subject: FinanceSubject.matteo,
);
