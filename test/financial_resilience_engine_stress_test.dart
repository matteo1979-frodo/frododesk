import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/financial_resilience_engine.dart';
import 'package:frododesk/models/financial_resilience.dart';

void main() {
  test('case 1: ample liquidity and unknown income does not suffer', () {
    final a = _assess(
      resources: [_balance('main', 10000)],
      events: [_out(390.99)],
    );
    expect(a.status, ResilienceStatus.breathes);
    expect(a.coverage.partial, isTrue);
  });

  test('case 2: expense before salary exposes temporary deficit', () {
    final a = _assess(
      resources: [_balance('main', 300)],
      events: [_out(500, day: 2), _income(2000, day: 4)],
    );
    expect(a.minimumProjectedLiquidity, -200);
    expect(a.status, ResilienceStatus.suffers);
  });

  test('case 3: structural loss across horizon exposes deterioration', () {
    final events = List.generate(
      8,
      (i) => _out(1500, month: i + 10, structural: true),
    );
    final a = _year(resources: [_balance('main', 10000)], events: events)[9];
    expect(a.status, isNot(ResilienceStatus.breathes));
    expect(a.explanations.join(' '), contains('traiettoria'));
  });

  test('case 4: irregular income is not projected by the engine', () {
    final year = _year(
      resources: [_balance('main', 100)],
      events: [_income(500, month: 10)],
    );
    expect(year[9].inflow, 500);
    expect(year[10].inflow, 0);
  });

  test('case 5: annual fact remains in its actual month', () {
    final facts = [_fact(300, DateTime(2025, 4, 7), structural: false)];
    final april = _year(year: 2025, facts: facts)[3];
    expect(april.outflow, 300);
    expect(_year(year: 2025, facts: facts)[4].outflow, 0);
  });

  test('case 6: extraordinary income component does not define baseline', () {
    final facts = [
      _fact(1000, DateTime(2025, 10, 27), income: true, structural: true),
      _fact(4000, DateTime(2025, 10, 27), income: true, extraordinary: true),
    ];
    expect(_assess(facts: facts).structuralNeed.monthlyOrdinaryNeed, isNull);
  });

  test(
    'case 7: additional salary components are event-driven, not hardcoded',
    () {
      final year = _year(
        events: [_income(1000, month: 11), _income(500, month: 11)],
      );
      expect(year[10].inflow, 1500);
      expect(year[11].inflow, 0);
    },
  );

  test('case 8: extraordinary expense does not enter ordinary need', () {
    final a = _assess(
      facts: [_fact(900, DateTime(2025, 10, 1), extraordinary: true)],
    );
    expect(a.structuralNeed.monthlyOrdinaryNeed, isNull);
  });

  test('case 9: designated fund reports coverage and gap context', () {
    final a = _assess(
      resources: [_fund('auto', 200, purpose: 'auto')],
      events: [_out(220, purpose: 'auto')],
    );
    expect(a.fundCoverage, 200);
    expect(
      a.alternatives.any((item) => item.kind == MitigationKind.designatedFund),
      isTrue,
    );
  });

  test('case 10: committed account is not proposed as free capacity', () {
    final a = _assess(
      resources: [
        _balance('pay', 0, owner: 'm'),
        _balance('main', 100, owner: 'm'),
      ],
      events: [
        _out(20, balance: 'pay', owner: 'm'),
        _out(100, day: 20, balance: 'main', owner: 'm'),
      ],
    );
    expect(a.status, ResilienceStatus.suffers);
    expect(
      a.alternatives.any((x) => x.kind == MitigationKind.sameOwnerBalance),
      isFalse,
    );
  });

  test('case 11: another account of same owner is a mitigation', () {
    final a = _assess(
      resources: [
        _balance('pay', 0, owner: 'm'),
        _balance('other', 50, owner: 'm'),
      ],
      events: [_out(20, balance: 'pay', owner: 'm')],
    );
    expect(
      a.alternatives.any((x) => x.kind == MitigationKind.sameOwnerBalance),
      isTrue,
    );
    expect(a.status, ResilienceStatus.attention);
  });

  test('case 12: other owner money always requires approval', () {
    final a = _assess(
      resources: [
        _balance('pay', 0, owner: 'm'),
        _balance('partner', 50, owner: 'c'),
      ],
      events: [_out(20, balance: 'pay', owner: 'm')],
    );
    final option = a.alternatives.firstWhere(
      (x) => x.kind == MitigationKind.otherOwnerRequiresApproval,
    );
    expect(option.requiresApproval, isTrue);
  });

  test('case 13: only explicitly flexible commitment may be deferred', () {
    final a = _assess(
      events: [_out(20, flexibility: FinancialFlexibility.flexible)],
    );
    expect(
      a.alternatives.any(
        (x) => x.kind == MitigationKind.deferKnownFlexibleCommitment,
      ),
      isTrue,
    );
  });

  test('case 14: unknown flexibility is never treated as deferrable', () {
    final a = _assess(events: [_out(20)]);
    expect(a.status, ResilienceStatus.suffers);
    expect(
      a.alternatives.any(
        (x) => x.kind == MitigationKind.deferKnownFlexibleCommitment,
      ),
      isFalse,
    );
  });

  test('case 15: unresolved deficit is stated explicitly', () {
    final a = _assess(events: [_out(20)]);
    expect(a.unresolvedDeficit, 20);
    expect(a.explanations.join(' '), contains('non risultano coperti'));
  });

  test('case 16: negative flow and ample liquidity coexist', () {
    final a = _assess(
      resources: [_balance('main', 10000)],
      events: [_out(390.99)],
    );
    expect(a.flow, -390.99);
    expect(a.status, ResilienceStatus.breathes);
  });

  test('case 17: positive flow does not hide pre-income tension', () {
    final a = _assess(
      resources: [_balance('main', 300)],
      events: [_out(500, day: 2), _income(1000, day: 3)],
    );
    expect(a.flow, 500);
    expect(a.minimumProjectedLiquidity, -200);
  });

  test('case 18: cold start reports limited coverage without false status', () {
    final a = _assess(resources: [_balance('main', 100)]);
    expect(a.coverage.partial, isTrue);
    expect(a.status, ResilienceStatus.breathes);
  });

  test('case 19: two years produce seasonal evidence', () {
    final facts = [
      _fact(100, DateTime(2024, 10, 1), structural: true),
      _fact(200, DateTime(2025, 10, 1), structural: true),
    ];
    final a = _assess(facts: facts);
    expect(a.structuralNeed.seasonalNeed, 150);
    expect(a.structuralNeed.sameMonthYears, 2);
  });

  test('case 20: unlocated documentary knowledge is not pressure', () {
    final a = _assess(
      events: [_out(200, precision: FinancialTemporalPrecision.unlocated)],
    );
    expect(a.outflow, 0);
    expect(a.coverage.unlocatedEvents, 1);
  });

  test('case 21: own-account transfer is not income or expense', () {
    final a = _assess(
      events: [_out(100, transfer: true), _income(100, transfer: true)],
    );
    expect(a.inflow, 0);
    expect(a.outflow, 0);
  });

  test('case 22: fund reallocation never creates money', () {
    final resources = [
      _fund('a', 200, purpose: 'a'),
      _fund('b', 20, purpose: 'b'),
    ];
    final first = _assess(resources: resources);
    final second = _assess(resources: resources);
    expect(first.openingLiquidity, 220);
    expect(second.openingLiquidity, 220);
  });

  test('case 23: corrected fact identity is counted once', () {
    final facts = [
      _fact(45, DateTime(2025, 4, 7), id: 'fact'),
      _fact(46, DateTime(2025, 4, 7), id: 'fact'),
    ];
    expect(_year(year: 2025, facts: facts)[3].outflow, 46);
  });

  test('case 24: repeated forecasting is pure and idempotent', () {
    final resources = [_balance('main', 1000)];
    final events = [_out(100)];
    expect(
      _assess(resources: resources, events: events).projectedClosingLiquidity,
      _assess(resources: resources, events: events).projectedClosingLiquidity,
    );
    expect(resources.single.amount, 1000);
  });
}

List<ResilienceAssessment> _year({
  int year = 2026,
  List<FinancialResource> resources = const [],
  List<FinancialTimelineEvent> events = const [],
  List<HistoricalFinancialFact> facts = const [],
}) => const FinancialResilienceEngine().assessYear(
  year: year,
  referenceTime: DateTime(2026, 10, 1),
  resources: resources,
  futureEvents: events,
  historicalFacts: facts,
  futureIncomeKnown: false,
);

ResilienceAssessment _assess({
  List<FinancialResource> resources = const [],
  List<FinancialTimelineEvent> events = const [],
  List<HistoricalFinancialFact> facts = const [],
}) => _year(resources: resources, events: events, facts: facts)[9];

FinancialResource _balance(String id, double amount, {String? owner}) =>
    FinancialResource(
      id: id,
      label: id,
      ownerId: owner,
      amount: amount,
      kind: FinancialResourceKind.balance,
    );
FinancialResource _fund(String id, double amount, {String? purpose}) =>
    FinancialResource(
      id: id,
      label: id,
      ownerId: null,
      amount: amount,
      kind: FinancialResourceKind.fund,
      purposeKey: purpose,
    );

FinancialTimelineEvent _out(
  double amount, {
  int month = 10,
  int day = 10,
  String? balance,
  String? owner,
  String? purpose,
  bool structural = false,
  bool transfer = false,
  FinancialFlexibility flexibility = FinancialFlexibility.unknown,
  FinancialTemporalPrecision precision = FinancialTemporalPrecision.exactDate,
}) => FinancialTimelineEvent(
  identity: 'out:$amount:$month:$day:$balance',
  label: 'Uscita',
  amount: amount,
  direction: FinancialEventDirection.outflow,
  temporalPrecision: precision,
  start: precision == FinancialTemporalPrecision.unlocated
      ? null
      : DateTime(2026, month, day),
  balanceId: balance,
  ownerId: owner,
  purposeKey: purpose,
  structural: structural,
  transfer: transfer,
  flexibility: flexibility,
);
FinancialTimelineEvent _income(
  double amount, {
  int month = 10,
  int day = 10,
  bool transfer = false,
}) => FinancialTimelineEvent(
  identity: 'in:$amount:$month:$day',
  label: 'Entrata',
  amount: amount,
  direction: FinancialEventDirection.income,
  temporalPrecision: FinancialTemporalPrecision.exactDate,
  start: DateTime(2026, month, day),
  transfer: transfer,
  structural: true,
);
HistoricalFinancialFact _fact(
  double amount,
  DateTime date, {
  String? id,
  bool income = false,
  bool structural = false,
  bool extraordinary = false,
}) => HistoricalFinancialFact(
  identity: id ?? 'fact:$amount:$date',
  date: date,
  amount: amount,
  direction: income
      ? FinancialEventDirection.income
      : FinancialEventDirection.outflow,
  structural: structural,
  extraordinary: extraordinary,
);
