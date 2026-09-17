import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/ledger/expense_replacement_ledger_projector.dart';
import 'package:frododesk/models/economic_event.dart';
import 'package:frododesk/models/expense_replacement_metadata.dart';

void main() {
  const projector = ExpenseReplacementLedgerProjector();

  test('ordinary event remains independent with empty history', () {
    final ordinary = _event('ordinary', 'ordinary-fact');

    final result = projector.project([ordinary]);

    expect(result, hasLength(1));
    expect(result.single.currentEvent, same(ordinary));
    expect(result.single.replacementHistory, isEmpty);
  });

  test('complete A to B projects B with one structural edge', () {
    final relation = _relation('A', 'B');

    final result = projector.project(relation.events);

    expect(result, hasLength(1));
    expect(result.single.currentEvent, same(relation.replacement));
    final edge = result.single.replacementHistory.single;
    expect(edge.originalEvent, same(relation.original));
    expect(edge.compensationEvent, same(relation.compensation));
    expect(edge.replacementEvent, same(relation.replacement));
    expect(edge.originalEconomicFactId, 'A');
    expect(edge.replacementEconomicFactId, 'B');
  });

  test('already correlated replacement stays one current event', () {
    final relation = _relation(
      'A',
      'B',
      replacementLinks: const [
        EconomicSourceLink(
          kind: EconomicSourceKind.financeTransaction,
          recordId: 'transaction-B',
        ),
        EconomicSourceLink(
          kind: EconomicSourceKind.realExpense,
          recordId: 'expense-B',
        ),
      ],
    );

    final result = projector.project(relation.events);

    expect(result, hasLength(1));
    expect(result.single.currentEvent, same(relation.replacement));
    expect(result.single.currentEvent.sourceLinks, hasLength(2));
  });

  test('A to B to C preserves two ordered edges without inventing A to C', () {
    final first = _relation('A', 'B');
    final second = _relation(
      'B',
      'C',
      original: first.replacement,
      compensationId: 'compensation-B-C',
    );
    final input = [
      first.original,
      first.compensation,
      first.replacement,
      second.compensation,
      second.replacement,
    ];

    final result = projector.project(input);

    expect(result, hasLength(1));
    expect(result.single.currentEvent, same(second.replacement));
    expect(
      result.single.replacementHistory.map(
        (edge) =>
            '${edge.originalEconomicFactId}->${edge.replacementEconomicFactId}',
      ),
      ['A->B', 'B->C'],
    );
  });

  test('missing compensation fails safe', () {
    final relation = _relation('A', 'B');
    _expectIndependent(
      projector.project([relation.original, relation.replacement]),
      [relation.original, relation.replacement],
    );
  });

  test('missing replacement marker fails safe', () {
    final relation = _relation('A', 'B');
    final unmarkedTarget = _event('target-B', 'B');
    _expectIndependent(
      projector.project([
        relation.original,
        relation.compensation,
        unmarkedTarget,
      ]),
      [relation.original, relation.compensation, unmarkedTarget],
    );
  });

  test('missing original fails safe', () {
    final relation = _relation('A', 'B');
    _expectIndependent(
      projector.project([relation.compensation, relation.replacement]),
      [relation.compensation, relation.replacement],
    );
  });

  test('duplicated compensation fails safe', () {
    final relation = _relation('A', 'B');
    final duplicate = _marked(
      'other-compensation',
      'other-compensation-fact',
      'A',
      'B',
      ExpenseReplacementRole.compensation,
    );
    final input = [...relation.events, duplicate];
    _expectIndependent(projector.project(input), input);
  });

  test('duplicated replacement fact is ambiguous and fails safe', () {
    final relation = _relation('A', 'B');
    final duplicate = _marked(
      'other-replacement',
      'B',
      'A',
      'B',
      ExpenseReplacementRole.replacement,
    );
    final input = [...relation.events, duplicate];
    _expectIndependent(projector.project(input), input);
  });

  test('branching replacement component fails safe in full', () {
    final first = _relation('A', 'B');
    final second = _relation(
      'A',
      'C',
      original: first.original,
      compensationId: 'compensation-A-C',
    );
    final input = [
      first.original,
      first.compensation,
      first.replacement,
      second.compensation,
      second.replacement,
    ];
    _expectIndependent(projector.project(input), input);
  });

  test('cycle fails safe in full', () {
    final eventA = _marked(
      'replacement-A',
      'A',
      'B',
      'A',
      ExpenseReplacementRole.replacement,
    );
    final eventB = _marked(
      'replacement-B',
      'B',
      'A',
      'B',
      ExpenseReplacementRole.replacement,
    );
    final compensationAB = _marked(
      'compensation-A-B',
      'compensation-A-B-fact',
      'A',
      'B',
      ExpenseReplacementRole.compensation,
    );
    final compensationBA = _marked(
      'compensation-B-A',
      'compensation-B-A-fact',
      'B',
      'A',
      ExpenseReplacementRole.compensation,
    );
    final input = [eventA, compensationAB, eventB, compensationBA];
    _expectIndependent(projector.project(input), input);
  });

  test('legacy events are never inferred as replacements', () {
    final old = _event('Farmacia originale', 'legacy-A');
    final compensation = _event('Storno farmacia', 'legacy-K');
    final replacement = _event('Farmacia corretta', 'legacy-B');
    final input = [old, compensation, replacement];

    _expectIndependent(projector.project(input), input);
  });

  test('independent event is retained beside a complete replacement', () {
    final relation = _relation('A', 'B');
    final independent = _event('independent', 'independent-fact');

    final result = projector.project([...relation.events, independent]);

    expect(result, hasLength(2));
    expect(result.first.currentEvent, same(relation.replacement));
    expect(result.first.replacementHistory, hasLength(1));
    expect(result.last.currentEvent, same(independent));
    expect(result.last.replacementHistory, isEmpty);
  });

  test('projection leaves input events and input list unchanged', () {
    final relation = _relation('A', 'B');
    final input = List<EconomicEvent>.of(relation.events);
    final originalSnapshot = List<EconomicEvent>.of(input);

    projector.project(input);

    expect(input, orderedEquals(originalSnapshot));
    expect(input[0], same(relation.original));
    expect(input[1], same(relation.compensation));
    expect(input[2], same(relation.replacement));
  });

  test('incompatible metadata and broken chain fail safe in full', () {
    final first = _relation('A', 'B');
    final incompatibleReplacement = _marked(
      'replacement-C',
      'C',
      'X',
      'C',
      ExpenseReplacementRole.replacement,
    );
    final compensationBC = _marked(
      'compensation-B-C',
      'compensation-B-C-fact',
      'B',
      'C',
      ExpenseReplacementRole.compensation,
    );
    final input = [...first.events, compensationBC, incompatibleReplacement];
    _expectIndependent(projector.project(input), input);
  });

  test('role and economic fact mismatch fails safe', () {
    final original = _event('original-A', 'A');
    final compensation = _marked(
      'compensation-A-B',
      'compensation-A-B-fact',
      'A',
      'B',
      ExpenseReplacementRole.compensation,
    );
    final wrongReplacement = _marked(
      'replacement-with-wrong-fact',
      'C',
      'A',
      'B',
      ExpenseReplacementRole.replacement,
    );
    final input = [original, compensation, wrongReplacement];
    _expectIndependent(projector.project(input), input);
  });

  test('null or ambiguous necessary fact identity fails safe', () {
    final relation = _relation('A', 'B');
    final nullFactCompensation = _marked(
      'null-fact-compensation',
      null,
      'A',
      'B',
      ExpenseReplacementRole.compensation,
    );
    final input = [
      relation.original,
      nullFactCompensation,
      relation.replacement,
    ];
    _expectIndependent(projector.project(input), input);
  });
}

class _TestRelation {
  final EconomicEvent original;
  final EconomicEvent compensation;
  final EconomicEvent replacement;

  const _TestRelation(this.original, this.compensation, this.replacement);

  List<EconomicEvent> get events => [original, compensation, replacement];
}

_TestRelation _relation(
  String originalFactId,
  String replacementFactId, {
  EconomicEvent? original,
  String? compensationId,
  List<EconomicSourceLink> replacementLinks = const [],
}) {
  return _TestRelation(
    original ?? _event('original-$originalFactId', originalFactId),
    _marked(
      compensationId ?? 'compensation-$originalFactId-$replacementFactId',
      '${compensationId ?? 'compensation-$originalFactId-$replacementFactId'}-fact',
      originalFactId,
      replacementFactId,
      ExpenseReplacementRole.compensation,
    ),
    _marked(
      'replacement-$replacementFactId',
      replacementFactId,
      originalFactId,
      replacementFactId,
      ExpenseReplacementRole.replacement,
      sourceLinks: replacementLinks,
    ),
  );
}

EconomicEvent _marked(
  String id,
  String? factId,
  String originalFactId,
  String replacementFactId,
  ExpenseReplacementRole role, {
  List<EconomicSourceLink> sourceLinks = const [],
}) {
  return _event(
    id,
    factId,
    metadata: ExpenseReplacementMetadata(
      originalEconomicFactId: originalFactId,
      replacementEconomicFactId: replacementFactId,
      role: role,
    ),
    sourceLinks: sourceLinks,
  );
}

EconomicEvent _event(
  String id,
  String? factId, {
  ExpenseReplacementMetadata? metadata,
  List<EconomicSourceLink> sourceLinks = const [],
}) {
  return EconomicEvent(
    id: id,
    observedAt: DateTime.utc(2026, 9, 17),
    occurredAt: DateTime.utc(2026, 9, 17),
    origins: const [],
    destinations: const [],
    description: id,
    amount: 10,
    nature: EconomicNature.outflow,
    economicFactId: factId,
    expenseReplacementMetadata: metadata,
    sourceLinks: sourceLinks,
  );
}

void _expectIndependent(
  List<dynamic> projected,
  List<EconomicEvent> expectedEvents,
) {
  expect(projected, hasLength(expectedEvents.length));
  for (var index = 0; index < expectedEvents.length; index++) {
    expect(projected[index].currentEvent, same(expectedEvents[index]));
    expect(projected[index].replacementHistory, isEmpty);
  }
}
