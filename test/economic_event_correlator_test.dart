import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';

void main() {
  const correlator = EconomicEventCorrelator();

  test('merges expense representations and complementary metadata', () {
    final result = correlator.correlate([
      _event(
        id: 'transaction',
        factId: 'expense-1',
        origins: [_account('account-1')],
        destinations: [_external('Destinazione esterna')],
        sourceKind: EconomicSourceKind.financeTransaction,
        personId: 'matteo',
      ),
      _event(
        id: 'expense',
        factId: 'expense-1',
        origins: [_account('account-1')],
        destinations: [_external('Spesa sostenuta')],
        sourceKind: EconomicSourceKind.realExpense,
        category: const EconomicCategoryRef(id: 'casa', label: 'Casa'),
        personId: 'matteo',
        description: 'Spesa supermercato settimanale',
      ),
    ]);

    final event = result.single;
    expect(event.id, 'economic_fact:expense-1');
    expect(event.economicFactId, 'expense-1');
    expect(event.sourceLinks, hasLength(2));
    expect(event.category?.id, 'casa');
    expect(event.personId, 'matteo');
    expect(event.description, 'Spesa supermercato settimanale');
    expect(event.origins.single.referenceId, 'account-1');
  });

  test('merges cash withdrawal as one account to cash transfer', () {
    final result = correlator.correlate([
      _event(
        id: 'transaction',
        factId: 'cash-1',
        origins: [_account('account-1')],
        destinations: [_external('Destinazione esterna')],
        sourceKind: EconomicSourceKind.financeTransaction,
        nature: EconomicNature.outflow,
      ),
      _event(
        id: 'expense',
        factId: 'cash-1',
        origins: [_account('account-1')],
        destinations: [_cash('wallet-1')],
        sourceKind: EconomicSourceKind.realExpense,
        nature: EconomicNature.internalTransfer,
      ),
    ]).single;

    expect(result.nature, EconomicNature.internalTransfer);
    expect(result.origins.single.kind, EconomicEndpointKind.account);
    expect(result.destinations.single.kind, EconomicEndpointKind.cash);
  });

  group('concrete endpoint identity', () {
    test('merges null and equal person metadata symmetrically', () {
      final withoutPerson = _event(
        id: 'without-person',
        factId: 'person-enrichment',
        origins: [_account('account-1')],
      );
      final withPerson = _event(
        id: 'with-person',
        factId: 'person-enrichment',
        origins: [_account('account-1', personId: 'matteo')],
      );

      final forward = correlator.correlate([withoutPerson, withPerson]).single;
      final reverse = correlator.correlate([withPerson, withoutPerson]).single;

      expect(forward.origins, hasLength(1));
      expect(forward.origins.single.personId, 'matteo');
      expect(reverse.origins, hasLength(1));
      expect(reverse.origins.single.personId, 'matteo');
    });

    test('merges null/null and equal/equal person metadata once', () {
      final nullResult = correlator.correlate([
        _event(id: 'a', factId: 'null-person'),
        _event(id: 'b', factId: 'null-person'),
      ]).single;
      final equalResult = correlator.correlate([
        _event(
          id: 'c',
          factId: 'equal-person',
          origins: [_account('account', personId: 'matteo')],
        ),
        _event(
          id: 'd',
          factId: 'equal-person',
          origins: [_account('account', personId: 'matteo')],
        ),
      ]).single;

      expect(nullResult.origins, hasLength(1));
      expect(nullResult.origins.single.personId, isNull);
      expect(equalResult.origins, hasLength(1));
      expect(equalResult.origins.single.personId, 'matteo');
    });

    test('rejects conflicting person metadata deterministically', () {
      EconomicEvent event(String id, String personId) => _event(
        id: id,
        factId: 'person-conflict',
        origins: [_account('account', personId: personId)],
      );

      for (final input in [
        [event('a', 'matteo'), event('b', 'chiara')],
        [event('b', 'chiara'), event('a', 'matteo')],
      ]) {
        expect(
          () => correlator.correlate(input),
          throwsA(
            isA<EconomicEventMergeConflict>()
                .having((error) => error.field, 'field', 'origins.personId')
                .having((error) => error.values, 'values', [
                  'chiara',
                  'matteo',
                ]),
          ),
        );
      }
    });

    test('rejects conflicting endpoint amounts without partial result', () {
      expect(
        () => correlator.correlate([
          _event(
            id: 'a',
            factId: 'endpoint-amount-conflict',
            origins: [_account('account', amount: 10)],
          ),
          _event(
            id: 'b',
            factId: 'endpoint-amount-conflict',
            origins: [_account('account', amount: 20)],
          ),
        ]),
        throwsA(
          isA<EconomicEventMergeConflict>().having(
            (error) => error.field,
            'field',
            'origins.amount',
          ),
        ),
      );
    });

    test('keeps distinct references, kinds and economic roles', () {
      final result = correlator.correlate([
        _event(
          id: 'a',
          factId: 'distinct-endpoints',
          origins: [_account('one'), _account('two'), _fund('shared')],
          destinations: [_account('shared')],
        ),
        _event(
          id: 'b',
          factId: 'distinct-endpoints',
          origins: [_fund('shared'), _account('two'), _account('one')],
          destinations: [_account('shared')],
        ),
      ]).single;

      expect(result.origins, hasLength(3));
      expect(result.destinations, hasLength(1));
      expect(result.destinations.single.referenceId, 'shared');
    });

    test('result is independent from endpoint order', () {
      EconomicEvent event(List<EconomicEndpoint> origins) =>
          _event(id: 'event', factId: 'endpoint-order', origins: origins);
      final forward = correlator.correlate([
        event([_account('one'), _account('two')]),
      ]).single;
      final reverse = correlator.correlate([
        event([_account('two'), _account('one')]),
      ]).single;

      expect(
        reverse.origins.map((endpoint) => endpoint.referenceId),
        forward.origins.map((endpoint) => endpoint.referenceId),
      );
    });

    test('generic endpoints preserve person-based identity behavior', () {
      EconomicEndpoint generic(String? personId) => EconomicEndpoint(
        kind: EconomicEndpointKind.other,
        label: 'Contropartita',
        personId: personId,
        amount: 20,
      );
      final result = correlator.correlate([
        _event(
          id: 'a',
          factId: 'generic',
          origins: [generic('matteo'), generic('chiara')],
        ),
        _event(id: 'b', factId: 'generic', origins: [generic('matteo')]),
      ]).single;

      expect(result.origins, hasLength(2));
      expect(result.origins.map((endpoint) => endpoint.personId), {
        'matteo',
        'chiara',
      });
    });
  });

  test('merges extra income and preserves related source references', () {
    final result = correlator.correlate([
      _event(
        id: 'transaction-income',
        factId: 'income-1',
        origins: [_external('Provenienza esterna')],
        destinations: [_account('account-1')],
        sourceKind: EconomicSourceKind.financeTransaction,
        nature: EconomicNature.income,
        relatedEventIds: const ['recurring_item:salary'],
      ),
      _event(
        id: 'real-income',
        factId: 'income-1',
        origins: [_external('Entrata extra')],
        destinations: [_account('account-1')],
        sourceKind: EconomicSourceKind.realExpense,
        nature: EconomicNature.income,
        category: const EconomicCategoryRef(
          id: 'entrata_extra',
          label: 'Entrata extra',
        ),
        personId: 'matteo',
        relatedEventIds: const ['source:expense'],
      ),
    ]).single;

    expect(result.nature, EconomicNature.income);
    expect(result.category?.id, 'entrata_extra');
    expect(result.destinations.single.referenceId, 'account-1');
    expect(result.relatedEventIds, ['recurring_item:salary', 'source:expense']);
  });

  test('merges fund to fund legs into one transfer', () {
    final result = correlator.correlate([
      _fundTransfer('out', 'fund-transfer'),
      _fundTransfer('in', 'fund-transfer'),
    ]).single;

    expect(result.nature, EconomicNature.internalTransfer);
    expect(result.origins.single.referenceId, 'vacanze');
    expect(result.destinations.single.referenceId, 'auto');
    expect(result.sourceLinks, hasLength(2));
  });

  test('merges fund movement and transaction into one fund expense', () {
    final result = correlator.correlate([
      _event(
        id: 'movement',
        factId: 'fund-expense',
        origins: [_fund('vacanze')],
        destinations: [_external('Spesa sostenuta')],
        sourceKind: EconomicSourceKind.financeAssetMovement,
      ),
      _event(
        id: 'transaction',
        factId: 'fund-expense',
        origins: [_fund('vacanze')],
        destinations: [_external('Destinazione esterna')],
        sourceKind: EconomicSourceKind.financeTransaction,
      ),
    ]).single;

    expect(result.nature, EconomicNature.outflow);
    expect(result.origins.single.kind, EconomicEndpointKind.fund);
    expect(result.sourceLinks, hasLength(2));
  });

  test('merges account transfer legs and removes generic counterparts', () {
    final result = correlator.correlate([
      _event(
        id: 'out',
        factId: 'account-transfer',
        origins: [_account('source')],
        destinations: [_other()],
        sourceKind: EconomicSourceKind.financeTransaction,
        nature: EconomicNature.internalTransfer,
      ),
      _event(
        id: 'in',
        factId: 'account-transfer',
        origins: [_other()],
        destinations: [_account('destination')],
        sourceKind: EconomicSourceKind.financeTransaction,
        nature: EconomicNature.internalTransfer,
      ),
    ]).single;

    expect(result.origins.single.referenceId, 'source');
    expect(result.destinations.single.referenceId, 'destination');
  });

  test('different facts, null facts and identical content remain separate', () {
    final first = _event(id: 'a', factId: 'fact-a');
    final second = _event(id: 'b', factId: 'fact-b');
    final legacyA = _event(id: 'legacy-a');
    final legacyB = _event(id: 'legacy-b');

    final result = correlator.correlate([first, second, legacyA, legacyB]);

    expect(result, hasLength(4));
    expect(result.where((event) => event.economicFactId == null), hasLength(2));
  });

  group('operation metadata', () {
    test('merges null/null as null and enriches metadata/null', () {
      final nullResult = correlator.correlate([
        _event(id: 'a', factId: 'null-metadata'),
        _event(id: 'b', factId: 'null-metadata'),
      ]).single;
      final metadata = _metadata();
      final enriched = correlator.correlate([
        _event(
          id: 'transaction',
          factId: 'enriched-metadata',
          operationMetadata: metadata,
        ),
        _event(id: 'expense', factId: 'enriched-metadata'),
      ]).single;

      expect(nullResult.operationMetadata, isNull);
      expect(enriched.operationMetadata, same(metadata));
    });

    test('preserves semantically identical metadata', () {
      final result = correlator.correlate([
        _event(
          id: 'transaction',
          factId: 'same-metadata',
          operationMetadata: _metadata(),
        ),
        _event(
          id: 'expense',
          factId: 'same-metadata',
          operationMetadata: _metadata(),
        ),
      ]).single;

      expect(result.operationMetadata?.operationId, 'utility-operation');
      expect(result.operationMetadata?.role, OperationRole.main);
      expect(result.operationMetadata?.context, OperationContext.utilityBill);
    });

    test('rejects incompatible metadata explicitly', () {
      expect(
        () => correlator.correlate([
          _event(
            id: 'main',
            factId: 'metadata-conflict',
            operationMetadata: _metadata(),
          ),
          _event(
            id: 'accessory',
            factId: 'metadata-conflict',
            operationMetadata: _metadata(
              role: OperationRole.accessory,
              accessoryCostType: AccessoryCostType.bankCommission,
            ),
          ),
        ]),
        throwsA(
          isA<EconomicEventMergeConflict>().having(
            (error) => error.field,
            'field',
            'operationMetadata',
          ),
        ),
      );
    });

    test('same operationId keeps two distinct economic facts separate', () {
      final result = correlator.correlate([
        _event(
          id: 'main',
          factId: 'fact-main',
          operationMetadata: _metadata(),
        ),
        _event(
          id: 'commission',
          factId: 'fact-commission',
          operationMetadata: _metadata(
            role: OperationRole.accessory,
            accessoryCostType: AccessoryCostType.bankCommission,
          ),
        ),
      ]);

      expect(result, hasLength(2));
      expect(result.map((event) => event.economicFactId), {
        'fact-main',
        'fact-commission',
      });
    });

    test('operationId never correlates distinct economic facts', () {
      final result = correlator.correlate([
        _event(
          id: 'main',
          factId: 'fact-main',
          amount: 59.63,
          operationMetadata: _metadata(),
        ),
        _event(
          id: 'commission',
          factId: 'fact-commission',
          amount: 2,
          operationMetadata: _metadata(
            role: OperationRole.accessory,
            accessoryCostType: AccessoryCostType.bankCommission,
          ),
        ),
        _event(
          id: 'postal',
          factId: 'fact-postal',
          amount: 1,
          operationMetadata: _metadata(
            role: OperationRole.accessory,
            accessoryCostType: AccessoryCostType.postalAcceptanceCharge,
          ),
        ),
      ]);

      expect(result, hasLength(3));
      expect(result.map((event) => event.economicFactId), {
        'fact-main',
        'fact-commission',
        'fact-postal',
      });
      expect(
        result.map((event) => event.operationMetadata?.operationId).toSet(),
        {'utility-operation'},
      );
    });
  });

  test(
    'recurring occurrences with one rule and different facts stay separate',
    () {
      final result = correlator.correlate([
        _event(
          id: 'occurrence-1',
          factId: 'fact-1',
          relatedEventIds: const ['recurring_item:salary'],
        ),
        _event(
          id: 'occurrence-2',
          factId: 'fact-2',
          relatedEventIds: const ['recurring_item:salary'],
        ),
      ]);

      expect(result, hasLength(2));
      expect(result.map((event) => event.economicFactId), {'fact-1', 'fact-2'});
    },
  );

  test('merge and canonical id are independent from input order', () {
    final a = _event(
      id: 'a',
      factId: 'fact',
      sourceKind: EconomicSourceKind.financeTransaction,
    );
    final b = _event(
      id: 'b',
      factId: 'fact',
      sourceKind: EconomicSourceKind.realExpense,
      description: 'Descrizione più informativa',
    );

    final forward = correlator.correlate([a, b]).single;
    final reverse = correlator.correlate([b, a]).single;

    expect(forward.id, 'economic_fact:fact');
    expect(reverse.id, forward.id);
    expect(reverse.description, forward.description);
    expect(
      reverse.sourceLinks.map((link) => '${link.kind.name}:${link.recordId}'),
      forward.sourceLinks.map((link) => '${link.kind.name}:${link.recordId}'),
    );
  });

  test('does not mutate inputs and returns an immutable result', () {
    final events = [_event(id: 'a'), _event(id: 'b', factId: 'fact')];
    final first = events.first;

    final result = correlator.correlate(events);

    expect(events.first, same(first));
    expect(events, hasLength(2));
    expect(() => result.clear(), throwsUnsupportedError);
  });

  test('preserves mixed concrete and external endpoints from one source', () {
    final event = _event(
      id: 'mixed',
      factId: 'mixed-fact',
      origins: [_account('account'), _external('Contributo esterno')],
    );

    final result = correlator.correlate([event]).single;

    expect(result.origins, hasLength(2));
  });

  test(
    'merges semantic fields conservatively without inventing duplicates',
    () {
      final result = correlator.correlate([
        _event(
          id: 'out',
          factId: 'transfer',
          notes: const ['Verso destinazione'],
          transactionOrigins: const [EconomicTransactionOrigin.manual],
        ),
        _event(
          id: 'in',
          factId: 'transfer',
          notes: const ['Da origine', 'Verso destinazione'],
          transactionOrigins: const [EconomicTransactionOrigin.manual],
          recurringItemIds: const ['rule'],
        ),
      ]).single;

      expect(result.notes, ['Da origine', 'Verso destinazione']);
      expect(result.transactionOrigins, [EconomicTransactionOrigin.manual]);
      expect(result.recurringItemIds, ['rule']);
    },
  );

  test('fails explicitly for structurally correlated incompatible amounts', () {
    expect(
      () => correlator.correlate([
        _event(id: 'a', factId: 'fact', amount: 20),
        _event(id: 'b', factId: 'fact', amount: 30),
      ]),
      throwsA(
        isA<EconomicEventMergeConflict>()
            .having((error) => error.field, 'field', 'amount')
            .having((error) => error.economicFactId, 'economicFactId', 'fact'),
      ),
    );
  });

  test('has no heuristic, UI, store or persistence dependencies', () {
    final source = File(
      'lib/logic/ledger/economic_event_correlator.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('package:flutter')));
    expect(source, isNot(contains('Store')));
    expect(source, isNot(contains('PersistenceStore')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('DateTime.now')));
    expect(source, isNot(contains('similar')));
  });
}

EconomicEvent _event({
  required String id,
  String? factId,
  double amount = 20,
  EconomicNature nature = EconomicNature.outflow,
  List<EconomicEndpoint>? origins,
  List<EconomicEndpoint>? destinations,
  EconomicSourceKind sourceKind = EconomicSourceKind.other,
  EconomicCategoryRef? category,
  String? personId,
  String description = 'Descrizione',
  List<String> relatedEventIds = const [],
  List<String> notes = const [],
  List<EconomicTransactionOrigin> transactionOrigins = const [],
  List<String> recurringItemIds = const [],
  EconomicOperationMetadata? operationMetadata,
}) => EconomicEvent(
  id: id,
  economicFactId: factId,
  observedAt: DateTime(2026, 8, 20),
  occurredAt: DateTime(2026, 8, 18),
  origins: origins ?? [_account('account')],
  destinations: destinations ?? [_external('Spesa')],
  category: category,
  personId: personId,
  description: description,
  amount: amount,
  nature: nature,
  sourceLinks: [EconomicSourceLink(kind: sourceKind, recordId: id)],
  relatedEventIds: relatedEventIds,
  notes: notes,
  transactionOrigins: transactionOrigins,
  recurringItemIds: recurringItemIds,
  operationMetadata: operationMetadata,
);

EconomicOperationMetadata _metadata({
  OperationRole role = OperationRole.main,
  AccessoryCostType? accessoryCostType,
}) => EconomicOperationMetadata(
  operationId: 'utility-operation',
  role: role,
  context: OperationContext.utilityBill,
  accessoryCostType: accessoryCostType,
);

EconomicEvent _fundTransfer(String id, String factId) => _event(
  id: id,
  factId: factId,
  origins: [_fund('vacanze')],
  destinations: [_fund('auto')],
  sourceKind: EconomicSourceKind.financeAssetMovement,
  nature: EconomicNature.internalTransfer,
);

EconomicEndpoint _account(String id, {String? personId, double amount = 20}) =>
    EconomicEndpoint(
      kind: EconomicEndpointKind.account,
      referenceId: id,
      label: 'Conto $id',
      personId: personId,
      amount: amount,
    );

EconomicEndpoint _fund(String id) => EconomicEndpoint(
  kind: EconomicEndpointKind.fund,
  referenceId: id,
  label: 'Fondo $id',
  amount: 20,
);

EconomicEndpoint _cash(String id) => EconomicEndpoint(
  kind: EconomicEndpointKind.cash,
  referenceId: id,
  label: 'Contanti',
  amount: 20,
);

EconomicEndpoint _external(String label) => EconomicEndpoint(
  kind: EconomicEndpointKind.external,
  label: label,
  amount: 20,
);

EconomicEndpoint _other() => const EconomicEndpoint(
  kind: EconomicEndpointKind.other,
  label: 'Contropartita',
  amount: 20,
);
