import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/ledger_coordinator.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/logic/ledger/ledger_presentation_builder.dart';
import 'package:frododesk/logic/ledger/ledger_timeline_builder.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/ledger_presentation_data.dart';
import 'package:frododesk/models/ledger_resolved_endpoint.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  const presentationBuilder = LedgerPresentationBuilder();
  final coordinator = _coordinator();
  final observedAt = DateTime(2026, 9, 14, 12);

  test('correlated expense and income become one lossless entry each', () {
    final expense = _present(
      coordinator,
      observedAt,
      transactions: [
        _transaction('expense-tx', factId: 'expense', notes: 'Nota spesa'),
      ],
      expenses: [_expense('expense-record', factId: 'expense')],
    ).entries.single;
    final income = _present(
      coordinator,
      observedAt,
      transactions: [_transaction('income-tx', factId: 'income', income: true)],
      expenses: [_expense('income-record', factId: 'income', income: true)],
    ).entries.single;

    expect(expense.title, 'expense-record');
    expect(expense.amount, 20);
    expect(expense.nature, EconomicNature.outflow);
    expect(expense.category?.label, 'Casa');
    expect(expense.personLabel, 'Matteo');
    expect(expense.notes, ['Nota spesa']);
    expect(expense.sourceLinks, hasLength(2));
    expect(income.nature, EconomicNature.income);
    expect(income.economicSign.name, 'positive');
    expect(income.sourceLinks, hasLength(2));
  });

  test('account transfers remain one entry with structural endpoints', () {
    final account = _transfer(
      coordinator,
      observedAt,
      factId: 'account-transfer',
      from: 'bank-a',
      to: 'bank-b',
    );
    final prepaid = _transfer(
      coordinator,
      observedAt,
      factId: 'prepaid-transfer',
      from: 'bank-a',
      to: 'prepaid',
    );

    expect(account.entries, hasLength(1));
    expect(account.entries.single.subtitle, 'Conto A → Conto B');
    expect(account.entries.single.nature, EconomicNature.internalTransfer);
    expect(prepaid.entries, hasLength(1));
    expect(prepaid.entries.single.subtitle, 'Conto A → Prepagata');
    expect(
      prepaid.entries.single.counterparties.first.balanceType,
      FinanceBalanceType.bankAccount,
    );
    expect(
      prepaid.entries.single.counterparties.last.balanceType,
      FinanceBalanceType.prepaidCard,
    );
  });

  test('account to fund and correlated fund transfer remain one entry', () {
    final allocation = _present(
      coordinator,
      observedAt,
      movements: [
        _movement(
          'allocation',
          'allocation-fact',
          FinanceAssetMovementKind.fundAllocation,
          const [
            FinanceAssetLeg(
              type: FinanceAssetLegType.balance,
              referenceId: 'bank-a',
              delta: -20,
            ),
            FinanceAssetLeg(
              type: FinanceAssetLegType.fund,
              referenceId: 'fund-a',
              delta: 20,
            ),
          ],
        ),
      ],
    );
    const fundLegs = [
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: 'fund-a',
        delta: -20,
      ),
      FinanceAssetLeg(
        type: FinanceAssetLegType.fund,
        referenceId: 'fund-b',
        delta: 20,
      ),
    ];
    final fundTransfer = _present(
      coordinator,
      observedAt,
      movements: [
        _movement(
          'fund-out',
          'fund-transfer',
          FinanceAssetMovementKind.fundTransferOut,
          fundLegs,
        ),
        _movement(
          'fund-in',
          'fund-transfer',
          FinanceAssetMovementKind.fundTransferIn,
          fundLegs,
          fundId: 'fund-b',
        ),
      ],
    );

    expect(allocation.entries.single.subtitle, 'Conto A → Vacanze');
    expect(fundTransfer.entries, hasLength(1));
    expect(fundTransfer.entries.single.subtitle, 'Vacanze → Auto');
    expect(fundTransfer.entries.single.sourceLinks, hasLength(2));
  });

  test(
    'recurring semantics and multiple notes stay structured and lossless',
    () {
      final data = _present(
        coordinator,
        observedAt,
        transactions: [
          _transaction(
            'recurring-out',
            factId: 'recurring-fact',
            origin: FinanceTransactionOrigin.recurringItem,
            recurringItemId: 'rule',
            notes: 'Nota B',
          ),
          _transaction(
            'recurring-copy',
            factId: 'recurring-fact',
            origin: FinanceTransactionOrigin.recurringItem,
            recurringItemId: 'rule',
            notes: 'Nota A',
          ),
        ],
      );

      final entry = data.entries.single;
      expect(entry.transactionOrigins, [
        EconomicTransactionOrigin.recurringItem,
      ]);
      expect(entry.recurringItemIds, ['rule']);
      expect(entry.notes, ['Nota A', 'Nota B']);
      expect(entry.title, 'recurring-copy');
    },
  );

  test('legacy records without fact identity remain two entries', () {
    final data = _present(
      coordinator,
      observedAt,
      transactions: [_transaction('legacy-tx')],
      expenses: [_expense('legacy-expense')],
    );

    expect(data.entries, hasLength(2));
    expect(data.entries.map((entry) => entry.eventId).toSet(), hasLength(2));
  });

  test('exposes archive empty, no results and results states', () {
    final empty = _present(coordinator, observedAt);
    final noResults = presentationBuilder.build(
      coordinator.build(
        transactions: [_transaction('transaction')],
        assetMovements: const [],
        realExpenses: const [],
        observedAt: observedAt,
        query: 'non presente',
      ),
    );
    final results = _present(
      coordinator,
      observedAt,
      transactions: [_transaction('transaction')],
    );

    expect(empty.state, LedgerPresentationState.archiveEmpty);
    expect(noResults.state, LedgerPresentationState.noResults);
    expect(noResults.totalEventCount, 1);
    expect(noResults.entries, isEmpty);
    expect(results.state, LedgerPresentationState.results);
  });

  test('is deterministic, immutable and independent from forbidden layers', () {
    final snapshot = coordinator.build(
      transactions: [_transaction('transaction')],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );
    final first = presentationBuilder.build(snapshot);
    final second = presentationBuilder.build(snapshot);

    expect(
      second.entries.map((entry) => entry.eventId),
      first.entries.map((entry) => entry.eventId),
    );
    expect(second.state, first.state);
    expect(() => first.entries.clear(), throwsUnsupportedError);
    expect(() => first.selectedFilterIds.add('x'), throwsUnsupportedError);

    final source = File(
      'lib/logic/ledger/ledger_presentation_builder.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('FinanceTransaction')));
    expect(source, isNot(contains('FinanceAssetMovement')));
    expect(source, isNot(contains('RealExpense')));
  });
}

LedgerPresentationData _present(
  LedgerCoordinator coordinator,
  DateTime observedAt, {
  List<FinanceTransaction> transactions = const [],
  List<FinanceAssetMovement> movements = const [],
  List<RealExpense> expenses = const [],
}) => const LedgerPresentationBuilder().build(
  coordinator.build(
    transactions: transactions,
    assetMovements: movements,
    realExpenses: expenses,
    observedAt: observedAt,
  ),
);

LedgerPresentationData _transfer(
  LedgerCoordinator coordinator,
  DateTime observedAt, {
  required String factId,
  required String from,
  required String to,
}) => _present(
  coordinator,
  observedAt,
  transactions: [
    _transaction(
      '$factId-out',
      factId: factId,
      balanceId: from,
      type: FinanceTransactionType.transfer,
      description: 'Trasferimento',
    ),
    _transaction(
      '$factId-in',
      factId: factId,
      balanceId: to,
      type: FinanceTransactionType.transfer,
      income: true,
      description: 'Trasferimento',
    ),
  ],
);

LedgerCoordinator _coordinator() => LedgerCoordinator(
  timelineBuilder: LedgerTimelineBuilder(
    endpointResolver: LedgerEndpointResolver(
      registry: LedgerEndpointRegistry(
        accounts: const {
          'bank-a': LedgerEndpointRecord(
            id: 'bank-a',
            label: 'Conto A',
            personId: 'matteo',
            balanceType: FinanceBalanceType.bankAccount,
          ),
          'bank-b': LedgerEndpointRecord(
            id: 'bank-b',
            label: 'Conto B',
            personId: 'chiara',
            balanceType: FinanceBalanceType.bankAccount,
          ),
          'prepaid': LedgerEndpointRecord(
            id: 'prepaid',
            label: 'Prepagata',
            personId: 'matteo',
            balanceType: FinanceBalanceType.prepaidCard,
          ),
        },
        funds: const {
          'fund-a': LedgerEndpointRecord(id: 'fund-a', label: 'Vacanze'),
          'fund-b': LedgerEndpointRecord(id: 'fund-b', label: 'Auto'),
        },
        people: const {
          'matteo': LedgerPersonRecord(id: 'matteo', label: 'Matteo'),
          'chiara': LedgerPersonRecord(id: 'chiara', label: 'Chiara'),
        },
      ),
    ),
  ),
);

FinanceTransaction _transaction(
  String id, {
  String? factId,
  String balanceId = 'bank-a',
  bool income = false,
  FinanceTransactionType? type,
  FinanceTransactionOrigin origin = FinanceTransactionOrigin.manual,
  String? recurringItemId,
  String? notes,
  String? description,
}) => FinanceTransaction(
  id: id,
  economicFactId: factId,
  balanceId: balanceId,
  amount: 20,
  date: DateTime(2026, 9, 14),
  isIncome: income,
  subject: FinanceSubject.matteo,
  description: description ?? id,
  type:
      type ??
      (income ? FinanceTransactionType.income : FinanceTransactionType.expense),
  origin: origin,
  recurringItemId: recurringItemId,
  notes: notes,
);

RealExpense _expense(String id, {String? factId, bool income = false}) =>
    RealExpense(
      id: id,
      economicFactId: factId,
      balanceId: 'bank-a',
      balanceName: 'Conto A',
      amount: 20,
      description: id,
      category: 'Casa',
      date: DateTime(2026, 9, 14),
      isIncome: income,
      subject: FinanceSubject.matteo,
    );

FinanceAssetMovement _movement(
  String id,
  String factId,
  FinanceAssetMovementKind kind,
  List<FinanceAssetLeg> legs, {
  String fundId = 'fund-a',
}) => FinanceAssetMovement(
  id: id,
  economicFactId: factId,
  fundId: fundId,
  kind: kind,
  description: id,
  occurredAt: DateTime(2026, 9, 14),
  legs: legs,
);
