import 'dart:collection';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/ledger/ledger_coordinator.dart';
import 'package:frododesk/logic/ledger/ledger_endpoint_resolver.dart';
import 'package:frododesk/logic/ledger/ledger_snapshot_builder.dart';
import 'package:frododesk/logic/ledger/ledger_timeline_builder.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/finance_asset_movement.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/ledger_event_view_model.dart';
import 'package:frododesk/models/ledger_resolved_endpoint.dart';
import 'package:frododesk/models/ledger_snapshot.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  final observedAt = DateTime(2026, 8, 25, 12);
  late LedgerCoordinator coordinator;

  setUp(() {
    coordinator = LedgerCoordinator(
      timelineBuilder: LedgerTimelineBuilder(
        endpointResolver: LedgerEndpointResolver(
          registry: LedgerEndpointRegistry(
            accounts: const {
              'account': LedgerEndpointRecord(
                id: 'account',
                label: 'Conto Famiglia',
                personId: 'matteo',
              ),
            },
            funds: const {
              'fund': LedgerEndpointRecord(id: 'fund', label: 'Fondo Vacanze'),
            },
            cashWallets: const {
              'cash': LedgerEndpointRecord(
                id: 'cash',
                label: 'Portafoglio Matteo',
                personId: 'matteo',
              ),
            },
            people: const {
              'matteo': LedgerPersonRecord(id: 'matteo', label: 'Matteo'),
            },
          ),
        ),
      ),
    );
  });

  test('empty sources produce an empty deterministic snapshot', () {
    final snapshot = coordinator.build(
      transactions: const [],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );

    expect(snapshot.observedAt, observedAt);
    expect(snapshot.timeline, isEmpty);
    expect(snapshot.totalEventCount, 0);
    expect(snapshot.filteredEventCount, 0);
    expect(snapshot.isArchiveEmpty, isTrue);
    expect(snapshot.hasNoResults, isFalse);
  });

  test('accepts each individual source and preserves economic semantics', () {
    final transaction = coordinator.build(
      transactions: [_transaction('income', income: true)],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );
    final movement = coordinator.build(
      transactions: const [],
      assetMovements: [_fundTransfer('transfer')],
      realExpenses: const [],
      observedAt: observedAt,
    );
    final expense = coordinator.build(
      transactions: const [],
      assetMovements: const [],
      realExpenses: [_expense('expense')],
      observedAt: observedAt,
    );

    expect(transaction.timeline.single.nature, EconomicNature.income);
    expect(movement.timeline.single.nature, EconomicNature.internalTransfer);
    expect(expense.timeline.single.nature, EconomicNature.outflow);
  });

  test('mixed sources complete the pipeline and resolve endpoints', () {
    final snapshot = coordinator.build(
      transactions: [_transaction('transaction')],
      assetMovements: [_fundExpense('movement')],
      realExpenses: [_expense('expense')],
      observedAt: observedAt,
    );

    expect(snapshot.timeline, hasLength(3));
    expect(snapshot.totalEventCount, 3);
    expect(
      snapshot.timeline
          .expand((event) => event.counterparties)
          .map((party) => party.label),
      containsAll(['Conto Famiglia', 'Fondo Vacanze']),
    );
    expect(snapshot.availableFilters, isNotEmpty);
  });

  test(
    'shared fact merges once while distinct and legacy facts stay separate',
    () {
      final merged = coordinator.build(
        transactions: [_transaction('transaction', factId: 'shared')],
        assetMovements: const [],
        realExpenses: [_expense('expense', factId: 'shared')],
        observedAt: observedAt,
      );
      final distinct = coordinator.build(
        transactions: [_transaction('a', factId: 'fact-a')],
        assetMovements: const [],
        realExpenses: [_expense('b', factId: 'fact-b')],
        observedAt: observedAt,
      );
      final legacy = coordinator.build(
        transactions: [_transaction('legacy-a')],
        assetMovements: const [],
        realExpenses: [_expense('legacy-b')],
        observedAt: observedAt,
      );

      expect(merged.timeline, hasLength(1));
      expect(merged.timeline.single.eventId, 'economic_fact:shared');
      expect(distinct.timeline, hasLength(2));
      expect(legacy.timeline, hasLength(2));
    },
  );

  test('preserves H8.3G order independently from source input order', () {
    final older = _transaction('older', date: DateTime(2026, 8, 20));
    final newer = _transaction('newer', date: DateTime(2026, 8, 22));
    final forward = coordinator.build(
      transactions: [older, newer],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );
    final reverse = coordinator.build(
      transactions: [newer, older],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );

    expect(forward.timeline.map((event) => event.eventId), [
      'finance_transaction:newer',
      'finance_transaction:older',
    ]);
    expect(
      reverse.timeline.map((event) => event.eventId),
      forward.timeline.map((event) => event.eventId),
    );
  });

  test('forwards query and filters to snapshot semantics', () {
    final snapshot = coordinator.build(
      transactions: [
        _transaction('income', income: true, description: 'Bonus'),
        _transaction('expense', description: 'Spesa'),
      ],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
      query: '  BONUS ',
      selectedFilterIds: const {'nature:income'},
    );

    expect(snapshot.query, 'bonus');
    expect(snapshot.selectedFilterIds, {'nature:income'});
    expect(snapshot.totalEventCount, 2);
    expect(snapshot.filteredEventCount, 1);
    expect(snapshot.timeline.single.title, 'Bonus');
    expect(snapshot.isArchiveEmpty, isFalse);
    expect(snapshot.hasNoResults, isFalse);

    final noResults = coordinator.build(
      transactions: [_transaction('expense', description: 'Spesa')],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
      query: 'inesistente',
    );
    expect(noResults.totalEventCount, 1);
    expect(noResults.filteredEventCount, 0);
    expect(noResults.isArchiveEmpty, isFalse);
    expect(noResults.hasNoResults, isTrue);
  });

  test('resolves historical fallbacks without store access', () {
    final snapshot = coordinator.build(
      transactions: [_transaction('historical', balanceId: 'deleted')],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );

    expect(snapshot.timeline.single.subtitle, contains('Conto non'));
    expect(
      snapshot.timeline.single.badges.map((badge) => badge.label),
      contains('Riferimento storico'),
    );
  });

  test('does not mutate inputs and snapshot collections stay immutable', () {
    final transactions = [_transaction('transaction')];
    final movements = [_fundExpense('movement')];
    final expenses = [_expense('expense')];
    final selected = <String>{'nature:outflow'};
    final snapshot = coordinator.build(
      transactions: transactions,
      assetMovements: movements,
      realExpenses: expenses,
      observedAt: observedAt,
      selectedFilterIds: selected,
    );
    transactions.clear();
    movements.clear();
    expenses.clear();
    selected.clear();

    expect(snapshot.totalEventCount, 3);
    expect(snapshot.timeline, hasLength(3));
    expect(() => snapshot.timeline.clear(), throwsUnsupportedError);
    expect(
      () => snapshot.selectedFilterIds.add('nature:income'),
      throwsUnsupportedError,
    );
    expect(() => snapshot.availableFilters.clear(), throwsUnsupportedError);
  });

  test('propagates EconomicEventMergeConflict unchanged', () {
    expect(
      () => coordinator.build(
        transactions: [
          _transaction('a', factId: 'conflict', amount: 10),
          _transaction('b', factId: 'conflict', amount: 20),
        ],
        assetMovements: const [],
        realExpenses: const [],
        observedAt: observedAt,
      ),
      throwsA(
        isA<EconomicEventMergeConflict>()
            .having((error) => error.economicFactId, 'fact', 'conflict')
            .having((error) => error.field, 'field', 'amount'),
      ),
    );
  });

  test('delegates stages in order without adding transformations', () {
    final calls = <String>[];
    final raw = [_economicEvent('raw')];
    final canonical = [_economicEvent('canonical')];
    final timeline = [_viewModel('timeline')];
    final expected = LedgerSnapshot(
      observedAt: observedAt,
      timeline: timeline,
      query: 'expected',
      selectedFilterIds: const {},
      availableFilters: const [],
      totalEventCount: 1,
      filteredEventCount: 1,
    );
    final spyCoordinator = LedgerCoordinator(
      collector: _CollectorSpy(calls, raw),
      correlator: _CorrelatorSpy(calls, raw, canonical),
      timelineBuilder: _TimelineSpy(calls, canonical, timeline),
      snapshotBuilder: _SnapshotSpy(calls, timeline, expected),
    );

    final result = spyCoordinator.build(
      transactions: const [],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
      query: ' Query ',
      selectedFilterIds: const {'nature:income'},
    );

    expect(result, same(expected));
    expect(calls, ['collector', 'correlator', 'timeline', 'snapshot']);
  });

  test('same inputs and observedAt produce equivalent snapshots', () {
    final transaction = _transaction('transaction');
    final first = coordinator.build(
      transactions: [transaction],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );
    final second = coordinator.build(
      transactions: [transaction],
      assetMovements: const [],
      realExpenses: const [],
      observedAt: observedAt,
    );

    expect(second.observedAt, first.observedAt);
    expect(
      second.timeline.map((event) => event.eventId),
      first.timeline.map((event) => event.eventId),
    );
    expect(
      second.availableFilters.map((item) => item.id),
      first.availableFilters.map((item) => item.id),
    );
  });

  test(
    'has no UI, store, persistence, mutation or current-time dependency',
    () {
      final source = File(
        'lib/logic/ledger/ledger_coordinator.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('package:flutter')));
      expect(source, isNot(contains('Widget')));
      expect(source, isNot(contains('BuildContext')));
      expect(source, isNot(contains('Store')));
      expect(source, isNot(contains('PersistenceStore')));
      expect(source, isNot(contains('DateTime.now')));
      expect(source, isNot(contains('catch')));
    },
  );
}

FinanceTransaction _transaction(
  String id, {
  bool income = false,
  String? factId,
  String balanceId = 'account',
  String? description,
  double amount = 20,
  DateTime? date,
}) => FinanceTransaction(
  id: id,
  economicFactId: factId,
  balanceId: balanceId,
  amount: amount,
  date: date ?? DateTime(2026, 8, 20),
  isIncome: income,
  subject: FinanceSubject.matteo,
  description: description ?? id,
  type: income ? FinanceTransactionType.income : FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
);

RealExpense _expense(String id, {String? factId}) => RealExpense(
  id: id,
  economicFactId: factId,
  balanceId: 'account',
  balanceName: 'Conto Famiglia',
  amount: 20,
  description: id,
  category: 'Casa',
  date: DateTime(2026, 8, 20),
  subject: FinanceSubject.matteo,
);

FinanceAssetMovement _fundExpense(String id) => FinanceAssetMovement(
  id: id,
  fundId: 'fund',
  kind: FinanceAssetMovementKind.fundExpense,
  description: id,
  occurredAt: DateTime(2026, 8, 21),
  legs: const [
    FinanceAssetLeg(
      type: FinanceAssetLegType.fund,
      referenceId: 'fund',
      delta: -20,
    ),
    FinanceAssetLeg(type: FinanceAssetLegType.expense, delta: 20),
  ],
);

FinanceAssetMovement _fundTransfer(String id) => FinanceAssetMovement(
  id: id,
  fundId: 'fund',
  kind: FinanceAssetMovementKind.fundAllocation,
  description: id,
  occurredAt: DateTime(2026, 8, 21),
  legs: const [
    FinanceAssetLeg(
      type: FinanceAssetLegType.balance,
      referenceId: 'account',
      delta: -20,
    ),
    FinanceAssetLeg(
      type: FinanceAssetLegType.fund,
      referenceId: 'fund',
      delta: 20,
    ),
  ],
);

EconomicEvent _economicEvent(String id) => EconomicEvent(
  id: id,
  observedAt: DateTime(2026, 8, 25),
  occurredAt: DateTime(2026, 8, 20),
  origins: const [],
  destinations: const [],
  description: id,
  amount: 20,
  nature: EconomicNature.outflow,
);

LedgerEventViewModel _viewModel(String id) => LedgerEventViewModel(
  eventId: id,
  title: id,
  subtitle: '',
  amount: 20,
  currencyCode: 'EUR',
  economicSign: LedgerEconomicSign.negative,
  nature: EconomicNature.outflow,
  observedAt: DateTime(2026, 8, 25),
  occurredAt: DateTime(2026, 8, 20),
  logicalIcon: LedgerLogicalIcon.expense,
  logicalColor: LedgerLogicalColor.negative,
  counterparties: const [],
  badges: const [],
);

class _CollectorSpy extends EconomicEventCollector {
  final List<String> calls;
  final List<EconomicEvent> output;

  const _CollectorSpy(this.calls, this.output);

  @override
  UnmodifiableListView<EconomicEvent> collect({
    required Iterable<FinanceTransaction> transactions,
    required Iterable<FinanceAssetMovement> assetMovements,
    required Iterable<RealExpense> realExpenses,
    required DateTime observedAt,
  }) {
    calls.add('collector');
    return UnmodifiableListView(output);
  }
}

class _CorrelatorSpy extends EconomicEventCorrelator {
  final List<String> calls;
  final List<EconomicEvent> expectedInput;
  final List<EconomicEvent> output;

  const _CorrelatorSpy(this.calls, this.expectedInput, this.output);

  @override
  UnmodifiableListView<EconomicEvent> correlate(List<EconomicEvent> events) {
    expect(events, orderedEquals(expectedInput));
    calls.add('correlator');
    return UnmodifiableListView(output);
  }
}

class _TimelineSpy extends LedgerTimelineBuilder {
  final List<String> calls;
  final List<EconomicEvent> expectedInput;
  final List<LedgerEventViewModel> output;

  _TimelineSpy(this.calls, this.expectedInput, this.output)
    : super(
        endpointResolver: LedgerEndpointResolver(
          registry: LedgerEndpointRegistry(),
        ),
      );

  @override
  UnmodifiableListView<LedgerEventViewModel> build(
    List<EconomicEvent> canonicalEvents,
  ) {
    expect(canonicalEvents, orderedEquals(expectedInput));
    calls.add('timeline');
    return UnmodifiableListView(output);
  }
}

class _SnapshotSpy extends LedgerSnapshotBuilder {
  final List<String> calls;
  final List<LedgerEventViewModel> expectedInput;
  final LedgerSnapshot output;

  const _SnapshotSpy(this.calls, this.expectedInput, this.output);

  @override
  LedgerSnapshot build({
    required DateTime observedAt,
    required List<LedgerEventViewModel> timeline,
    String query = '',
    Set<String> selectedFilterIds = const <String>{},
  }) {
    expect(timeline, orderedEquals(expectedInput));
    expect(query, ' Query ');
    expect(selectedFilterIds, {'nature:income'});
    calls.add('snapshot');
    return output;
  }
}
