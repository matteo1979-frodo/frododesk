import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/ledger_snapshot_builder.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/ledger_event_view_model.dart';
import 'package:frododesk/models/ledger_snapshot.dart';

void main() {
  const builder = LedgerSnapshotBuilder();
  final observedAt = DateTime(2026, 8, 24, 12);

  test('builds empty and unfiltered snapshots with explicit observedAt', () {
    final empty = builder.build(observedAt: observedAt, timeline: const []);
    final input = [_event(id: 'a'), _event(id: 'b')];
    final complete = builder.build(observedAt: observedAt, timeline: input);

    expect(empty.observedAt, observedAt);
    expect(empty.totalEventCount, 0);
    expect(empty.filteredEventCount, 0);
    expect(empty.isArchiveEmpty, isTrue);
    expect(empty.hasNoResults, isFalse);
    expect(complete.timeline.map((event) => event.eventId), ['a', 'b']);
    expect(complete.totalEventCount, 2);
    expect(complete.filteredEventCount, 2);
    expect(complete.isArchiveEmpty, isFalse);
    expect(complete.hasNoResults, isFalse);
  });

  test('normalizes query and searches visible semantic fields', () {
    final timeline = [
      _event(
        id: 'event',
        title: 'Spesa Casa',
        subtitle: 'Banca → Fornitore',
        counterparties: [
          _party(
            kind: EconomicEndpointKind.account,
            id: 'account',
            label: 'Conto Famiglia',
          ),
        ],
        badges: const [
          LedgerEventBadge(label: 'Urgente', tone: LedgerBadgeTone.warning),
        ],
        category: const EconomicCategoryRef(id: 'utenze', label: 'Utenze'),
        sourceKind: EconomicSourceKind.financeTransaction,
        notes: const ['Pagamento tramite addebito automatico'],
      ),
    ];

    for (final query in [
      'spesa casa',
      'banca',
      'conto famiglia',
      'urgente',
      'utenze',
      'movimenti dei conti',
      'addebito automatico',
    ]) {
      expect(
        builder
            .build(observedAt: observedAt, timeline: timeline, query: query)
            .timeline,
        hasLength(1),
      );
    }
    final normalized = builder.build(
      observedAt: observedAt,
      timeline: timeline,
      query: '  SPESA   CASA  ',
    );
    expect(normalized.query, 'spesa casa');
  });

  test('query no results sets state and preserves complete filters', () {
    final timeline = [_event(id: 'event')];
    final baseline = builder.build(observedAt: observedAt, timeline: timeline);
    final filtered = builder.build(
      observedAt: observedAt,
      timeline: timeline,
      query: 'inesistente',
    );

    expect(filtered.timeline, isEmpty);
    expect(filtered.totalEventCount, 1);
    expect(filtered.filteredEventCount, 0);
    expect(filtered.isArchiveEmpty, isFalse);
    expect(filtered.hasNoResults, isTrue);
    expect(
      filtered.availableFilters.map((option) => option.id),
      baseline.availableFilters.map((option) => option.id),
    );
  });

  test('filters nature, period, account, fund, category and source', () {
    final income = _event(
      id: 'income',
      nature: EconomicNature.income,
      date: DateTime(2026, 8, 10),
      counterparties: [
        _party(
          kind: EconomicEndpointKind.account,
          id: 'account',
          label: 'Conto',
        ),
      ],
      category: const EconomicCategoryRef(id: 'salary', label: 'Stipendio'),
      sourceKind: EconomicSourceKind.financeTransaction,
    );
    final transfer = _event(
      id: 'transfer',
      nature: EconomicNature.internalTransfer,
      date: DateTime(2026, 7, 10),
      counterparties: [
        _party(kind: EconomicEndpointKind.fund, id: 'fund', label: 'Vacanze'),
      ],
      sourceKind: EconomicSourceKind.financeAssetMovement,
    );
    final timeline = [income, transfer];
    final cases = <String, String>{
      'nature:income': 'income',
      'period:2026-07': 'transfer',
      'account:account': 'income',
      'fund:fund': 'transfer',
      'category:salary': 'income',
      'source:financeAssetMovement': 'transfer',
    };

    for (final entry in cases.entries) {
      final snapshot = builder.build(
        observedAt: observedAt,
        timeline: timeline,
        selectedFilterIds: {entry.key},
      );
      expect(snapshot.timeline.single.eventId, entry.value, reason: entry.key);
      expect(snapshot.filteredEventCount, 1);
    }
  });

  test('filters person through global identity and counterparties', () {
    final timeline = [
      _event(id: 'global', personId: 'matteo', personLabel: 'Matteo'),
      _event(
        id: 'counterparty',
        counterparties: [
          _party(
            kind: EconomicEndpointKind.account,
            id: 'chiara-account',
            label: 'Conto Chiara',
            personId: 'chiara',
            personLabel: 'Chiara',
          ),
        ],
      ),
    ];

    expect(
      builder
          .build(
            observedAt: observedAt,
            timeline: timeline,
            selectedFilterIds: const {'person:matteo'},
          )
          .timeline
          .single
          .eventId,
      'global',
    );
    expect(
      builder
          .build(
            observedAt: observedAt,
            timeline: timeline,
            selectedFilterIds: const {'person:chiara'},
          )
          .timeline
          .single
          .eventId,
      'counterparty',
    );
  });

  test('combines same kind with OR and different kinds and query with AND', () {
    final timeline = [
      _event(
        id: 'income-matteo',
        title: 'Bonus',
        nature: EconomicNature.income,
        personId: 'matteo',
        personLabel: 'Matteo',
      ),
      _event(
        id: 'outflow-matteo',
        title: 'Casa',
        nature: EconomicNature.outflow,
        personId: 'matteo',
        personLabel: 'Matteo',
      ),
      _event(
        id: 'income-chiara',
        title: 'Bonus',
        nature: EconomicNature.income,
        personId: 'chiara',
        personLabel: 'Chiara',
      ),
    ];

    final sameKind = builder.build(
      observedAt: observedAt,
      timeline: timeline,
      selectedFilterIds: const {'nature:income', 'nature:outflow'},
    );
    final differentKinds = builder.build(
      observedAt: observedAt,
      timeline: timeline,
      selectedFilterIds: const {'nature:income', 'person:matteo'},
    );
    final queryAndFilter = builder.build(
      observedAt: observedAt,
      timeline: timeline,
      query: 'bonus',
      selectedFilterIds: const {'person:matteo'},
    );

    expect(sameKind.timeline, hasLength(3));
    expect(differentKinds.timeline.single.eventId, 'income-matteo');
    expect(queryAndFilter.timeline.single.eventId, 'income-matteo');
  });

  test('ignores malformed, unknown and unavailable filter ids', () {
    final snapshot = builder.build(
      observedAt: observedAt,
      timeline: [_event(id: 'event')],
      selectedFilterIds: const {
        'malformed',
        'unknown:value',
        'nature:income',
        'nature:outflow',
      },
    );

    expect(snapshot.selectedFilterIds, {'nature:outflow'});
    expect(snapshot.timeline, hasLength(1));
  });

  test('builds namespaced encoded ids and deterministic filter order', () {
    final timeline = [
      _event(
        id: 'new',
        nature: EconomicNature.internalTransfer,
        date: DateTime(2026, 8, 1),
        personId: 'z-person',
        personLabel: 'Zeno',
        counterparties: [
          _party(
            kind: EconomicEndpointKind.account,
            id: 'account:shared',
            label: 'Conto A',
          ),
        ],
      ),
      _event(
        id: 'old',
        nature: EconomicNature.income,
        date: DateTime(2026, 7, 1),
        personId: 'a-person',
        personLabel: 'Anna',
      ),
      _event(id: 'outflow', nature: EconomicNature.outflow),
    ];
    final filters = builder
        .build(observedAt: observedAt, timeline: timeline)
        .availableFilters;

    expect(filters.map((option) => option.kind).toSet().toList(), [
      LedgerFilterKind.nature,
      LedgerFilterKind.period,
      LedgerFilterKind.person,
      LedgerFilterKind.account,
      LedgerFilterKind.source,
    ]);
    expect(
      filters
          .where((option) => option.kind == LedgerFilterKind.nature)
          .map((option) => option.label),
      ['Entrate', 'Uscite', 'Trasferimenti'],
    );
    expect(
      filters
          .where((option) => option.kind == LedgerFilterKind.period)
          .map((option) => option.label),
      ['Agosto 2026', 'Luglio 2026'],
    );
    expect(
      filters
          .where((option) => option.kind == LedgerFilterKind.person)
          .map((option) => option.label),
      ['Anna', 'Zeno'],
    );
    expect(
      filters.map((option) => option.id),
      contains('account:account%3Ashared'),
    );
    expect(
      filters.map((option) => option.id).toSet(),
      hasLength(filters.length),
    );
  });

  test('never exposes an unresolved person id as its label', () {
    final filters = builder
        .build(
          observedAt: observedAt,
          timeline: [_event(id: 'event', personId: 'technical-id')],
        )
        .availableFilters;

    expect(
      filters.where((option) => option.kind == LedgerFilterKind.person),
      isEmpty,
    );
    expect(
      filters.map((option) => option.label),
      isNot(contains('technical-id')),
    );
  });

  test(
    'preserves timeline order and all exposed collections are immutable',
    () {
      final input = [_event(id: 'second'), _event(id: 'first')];
      final snapshot = builder.build(
        observedAt: observedAt,
        timeline: input,
        selectedFilterIds: const {'nature:outflow'},
      );
      input
        ..clear()
        ..add(_event(id: 'changed'));

      expect(snapshot.timeline.map((event) => event.eventId), [
        'second',
        'first',
      ]);
      expect(() => snapshot.timeline.clear(), throwsUnsupportedError);
      expect(
        () => snapshot.selectedFilterIds.add('nature:income'),
        throwsUnsupportedError,
      );
      expect(() => snapshot.availableFilters.clear(), throwsUnsupportedError);
    },
  );

  test(
    'same input and observedAt produces equivalent deterministic output',
    () {
      final timeline = [_event(id: 'event')];
      final first = builder.build(observedAt: observedAt, timeline: timeline);
      final second = builder.build(observedAt: observedAt, timeline: timeline);

      expect(second.observedAt, first.observedAt);
      expect(second.query, first.query);
      expect(
        second.timeline.map((event) => event.eventId),
        first.timeline.map((event) => event.eventId),
      );
      expect(second.selectedFilterIds, first.selectedFilterIds);
      expect(
        second.availableFilters.map((option) => option.id),
        first.availableFilters.map((option) => option.id),
      );
    },
  );

  test('has no Flutter, store, persistence or current-time dependency', () {
    final source = File(
      'lib/logic/ledger/ledger_snapshot_builder.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('PersistenceStore')));
    expect(source, isNot(contains('DateTime.now')));
    expect(source, isNot(contains('EconomicEventCollector')));
    expect(source, isNot(contains('EconomicEventCorrelator')));
  });
}

LedgerEventViewModel _event({
  required String id,
  String title = 'Descrizione',
  String subtitle = 'Conto → Spesa',
  EconomicNature nature = EconomicNature.outflow,
  DateTime? date,
  String? personId,
  String? personLabel,
  List<LedgerEventCounterparty> counterparties = const [],
  List<LedgerEventBadge> badges = const [],
  EconomicCategoryRef? category,
  EconomicSourceKind sourceKind = EconomicSourceKind.other,
  List<String> notes = const [],
}) => LedgerEventViewModel(
  eventId: id,
  title: title,
  subtitle: subtitle,
  amount: 20,
  currencyCode: 'EUR',
  economicSign: switch (nature) {
    EconomicNature.income => LedgerEconomicSign.positive,
    EconomicNature.outflow => LedgerEconomicSign.negative,
    EconomicNature.internalTransfer => LedgerEconomicSign.neutral,
  },
  nature: nature,
  personId: personId,
  personLabel: personLabel,
  category: category,
  observedAt: DateTime(2026, 8, 24),
  occurredAt: date ?? DateTime(2026, 8, 20),
  logicalIcon: LedgerLogicalIcon.other,
  logicalColor: LedgerLogicalColor.neutral,
  counterparties: counterparties,
  badges: badges,
  sourceLinks: [EconomicSourceLink(kind: sourceKind, recordId: id)],
  notes: notes,
);

LedgerEventCounterparty _party({
  required EconomicEndpointKind kind,
  required String id,
  required String label,
  String? personId,
  String? personLabel,
}) => LedgerEventCounterparty(
  role: LedgerCounterpartyRole.origin,
  kind: kind,
  referenceId: id,
  label: label,
  personId: personId,
  personLabel: personLabel,
  amount: 20,
);
