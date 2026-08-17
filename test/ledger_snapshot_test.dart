import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/ledger_event_view_model.dart';
import 'package:frododesk/models/ledger_snapshot.dart';

void main() {
  final observedAt = DateTime(2026, 8, 19, 12);

  test('snapshot owns immutable copies of timeline and filters', () {
    final timeline = [_event('event-1', observedAt)];
    final selectedFilters = <String>{'nature:outflow'};
    final availableFilters = <LedgerFilterOption>[
      const LedgerFilterOption(
        id: 'nature:outflow',
        kind: LedgerFilterKind.nature,
        label: 'Spese',
      ),
    ];

    final snapshot = LedgerSnapshot(
      observedAt: observedAt,
      timeline: timeline,
      query: ' supermercato ',
      selectedFilterIds: selectedFilters,
      availableFilters: availableFilters,
      totalEventCount: 2,
      filteredEventCount: 1,
    );

    timeline.clear();
    selectedFilters.clear();
    availableFilters.clear();

    expect(snapshot.timeline.single.eventId, 'event-1');
    expect(snapshot.selectedFilterIds, {'nature:outflow'});
    expect(snapshot.availableFilters.single.label, 'Spese');
    expect(() => snapshot.timeline.clear(), throwsUnsupportedError);
    expect(
      () => snapshot.selectedFilterIds.add('period:month'),
      throwsUnsupportedError,
    );
    expect(() => snapshot.availableFilters.clear(), throwsUnsupportedError);
  });

  test('distinguishes an empty archive from a filtered empty result', () {
    final emptyArchive = LedgerSnapshot(
      observedAt: observedAt,
      timeline: const [],
      query: '',
      selectedFilterIds: const {},
      availableFilters: const [],
      totalEventCount: 0,
      filteredEventCount: 0,
    );
    final noResults = LedgerSnapshot(
      observedAt: observedAt,
      timeline: const [],
      query: 'inesistente',
      selectedFilterIds: const {'nature:income'},
      availableFilters: const [
        LedgerFilterOption(
          id: 'nature:income',
          kind: LedgerFilterKind.nature,
          label: 'Entrate',
        ),
      ],
      totalEventCount: 3,
      filteredEventCount: 0,
    );

    expect(emptyArchive.isArchiveEmpty, isTrue);
    expect(emptyArchive.hasNoResults, isFalse);
    expect(noResults.isArchiveEmpty, isFalse);
    expect(noResults.hasNoResults, isTrue);
  });

  test('enforces timeline and count invariants on view models', () {
    expect(
      () => LedgerSnapshot(
        observedAt: observedAt,
        timeline: [_event('event-1', observedAt)],
        query: '',
        selectedFilterIds: const {},
        availableFilters: const [],
        totalEventCount: 1,
        filteredEventCount: 0,
      ),
      throwsAssertionError,
    );
    expect(
      () => LedgerSnapshot(
        observedAt: observedAt,
        timeline: const [],
        query: '',
        selectedFilterIds: const {},
        availableFilters: const [],
        totalEventCount: 0,
        filteredEventCount: 1,
      ),
      throwsAssertionError,
    );
  });

  test('contract has no UI, store, persistence or legacy dependencies', () {
    final source = File('lib/models/ledger_snapshot.dart').readAsStringSync();

    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('PersistenceStore')));
    expect(source, isNot(contains('FinanceTransaction')));
    expect(source, isNot(contains('FinanceAssetMovement')));
    expect(source, contains('UnmodifiableListView<LedgerEventViewModel>'));
    expect(source, isNot(contains('UnmodifiableListView<EconomicEvent>')));
  });
}

LedgerEventViewModel _event(String id, DateTime occurredAt) =>
    LedgerEventViewModel(
      eventId: id,
      title: 'Supermercato',
      subtitle: 'Conto → Spesa',
      amount: 20,
      currencyCode: 'EUR',
      economicSign: LedgerEconomicSign.negative,
      nature: EconomicNature.outflow,
      observedAt: occurredAt,
      occurredAt: occurredAt,
      logicalIcon: LedgerLogicalIcon.expense,
      logicalColor: LedgerLogicalColor.negative,
      counterparties: const [],
      badges: const [],
    );
