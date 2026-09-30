import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_reader.dart';
import 'package:frododesk/logic/finance/future_expense_reader.dart';
import 'package:frododesk/logic/finance/expense_relationship_projection_adapter.dart';
import 'package:frododesk/logic/finance/future_outflow_presentation_composer.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finite_financial_plan.dart';
import 'package:frododesk/models/future_expense_projection.dart';
import 'package:frododesk/models/future_outflow_presentation.dart';
import 'package:frododesk/models/planned_economic_impact.dart';
import 'package:frododesk/models/projected_expense_cycle.dart';

void main() {
  const composer = FutureOutflowPresentationComposer();
  final reference = DateTime(2026, 9, 20);

  test('preserves an Expected Expense and its structural identities', () {
    final overview = composer.compose(
      expectedExpenses: _expected(reference: DateTime(2026, 11, 10)),
      finitePlans: const [],
      referenceTime: reference,
    );
    final item = overview.futureMonths.single.items.single;

    expect(item.authority, FutureOutflowAuthority.expectedExpense);
    expect(item.identity, 'occurrence_hera');
    expect(item.expectedExpense!.relationshipId, 'relationship_hera');
  });

  test('projects only installments 4 through 12 with stable identities', () {
    final overview = composer.compose(
      expectedExpenses: const [],
      finitePlans: [_plan()],
      referenceTime: reference,
    );
    final items = overview.futureMonths.expand((month) => month.items).toList();

    expect(items, hasLength(9));
    expect(
      items.map((item) => item.installmentNumber),
      orderedEquals([4, 5, 6, 7, 8, 9, 10, 11, 12]),
    );
    expect(items.first.identity, 'plan_inps#4');
    expect(items.last.identity, 'plan_inps#12');
    expect(items.where((item) => item.installmentNumber == 13), isEmpty);
  });

  test('groups October, mixed November, and December with combined counts', () {
    final overview = composer.compose(
      expectedExpenses: _expected(reference: DateTime(2026, 11, 10)),
      finitePlans: [_plan()],
      referenceTime: reference,
    );

    expect(overview.futureMonths.take(3).map((group) => group.month), [
      DateTime(2026, 10),
      DateTime(2026, 11),
      DateTime(2026, 12),
    ]);
    expect(overview.futureMonths[0].items.single.installmentNumber, 4);
    expect(overview.futureMonths[1].items, hasLength(2));
    expect(overview.futureMonths[2].items.single.installmentNumber, 6);
    expect(overview.futureCount, 10);
  });

  test(
    'advancing the plan removes installment 4 and retains installment 5',
    () {
      final overview = composer.compose(
        expectedExpenses: const [],
        finitePlans: [_plan(completed: 4)],
        referenceTime: reference,
      );
      final items = overview.futureMonths
          .expand((month) => month.items)
          .toList();

      expect(items.where((item) => item.installmentNumber == 4), isEmpty);
      expect(items.where((item) => item.installmentNumber == 5), hasLength(1));
    },
  );

  test(
    'plan forecast is placed and receives no Expected Expense semantics',
    () {
      final item = composer
          .compose(
            expectedExpenses: const [],
            finitePlans: [_plan()],
            referenceTime: reference,
          )
          .futureMonths
          .first
          .items
          .single;

      expect(
        item.datePresentation,
        FutureOutflowDatePresentation.finitePlanForecast,
      );
      expect(item.requiresPlanning, isFalse);
      expect(item.requiresUserAction, isFalse);
      expect(item.expectedExpense, isNull);
      expect(item.placementStart, DateTime(2026, 10, 15));
    },
  );

  test('does not heuristically deduplicate similar cross-authority items', () {
    final overview = composer.compose(
      expectedExpenses: _expected(
        reference: DateTime(2026, 10, 15),
        amount: 386,
        service: 'INPS',
      ),
      finitePlans: [_plan()],
      referenceTime: reference,
    );

    expect(overview.futureMonths.first.items, hasLength(2));
  });

  test('adds projected relationship cycles as non-interactive forecasts', () {
    final overview = composer.compose(
      expectedExpenses: const [],
      projectedCycles: [_projected(sequence: 2)],
      finitePlans: const [],
      referenceTime: reference,
    );
    final item = overview.futureMonths.single.items.single;

    expect(item.authority, FutureOutflowAuthority.projectedExpenseRelationship);
    expect(item.identity, 'relationship_hera#2');
    expect(item.datePresentation, FutureOutflowDatePresentation.projectedCycle);
    expect(item.expectedExpense, isNull);
    expect(item.projectedExpenseCycle, isNotNull);
    expect(item.isInteractive, isFalse);
    expect(item.provisional, isTrue);
  });

  test('uses the structured target year only when the policy requests it', () {
    final stable = composer.compose(
      expectedExpenses: _expected(
        reference: DateTime(2027, 3, 1),
        service: 'TARI',
      ),
      finitePlans: const [],
      referenceTime: reference,
    );
    final withYear = composer.compose(
      expectedExpenses: _expected(
        reference: DateTime(2027, 3, 1),
        service: 'TARI',
        yearlyLabel: true,
      ),
      projectedCycles: [
        _projected(
          sequence: 2,
          anchor: DateTime(2027, 3, 1),
          yearlyLabel: true,
        ),
        _projected(
          sequence: 3,
          anchor: DateTime(2028, 3, 1),
          yearlyLabel: true,
        ),
      ],
      finitePlans: const [],
      referenceTime: reference,
    );

    expect(stable.futureMonths.single.items.single.title, 'TARI · Hera');
    final yearlyTitles = withYear.futureMonths
        .expand((group) => group.items)
        .map((item) => item.title)
        .toList();
    expect(yearlyTitles.where((item) => item == 'TARI 2027 · Hera'), hasLength(2));
    expect(yearlyTitles, contains('TARI 2028 · Hera'));
  });

  test('annual relationship projects structured 2027 and 2028 labels', () {
    final relationship = ExpenseRelationship(
      relationshipId: 'annual_tax',
      service: 'Tributo comunale',
      provider: 'Comune',
      subject: FinanceSubject.matteo,
      status: ExpenseRelationshipStatus.active,
      periodicity: ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.yearly,
      ),
      cycleLabelPolicy:
          ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear,
      paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.manual,
      ),
    );
    final seed = ExpectedExpenseOccurrence(
      occurrenceId: 'annual_tax_2026',
      relationshipId: relationship.relationshipId,
      cycleSequence: 1,
      expectedPeriod: ExpectedDocumentPeriod(year: 2026, month: 3),
      status: ExpectedExpenseOccurrenceStatus.pending,
      expectedAmount: 173,
      estimationMethod: ExpenseEstimationMethod.documentaryObligation,
      confidence: ExpenseEstimateConfidence.medium,
      provisional: true,
      expectedPaymentConfiguration: relationship.paymentConfiguration,
      expectedSubject: relationship.subject,
    );
    final projected = const ExpenseRelationshipProjectionAdapter().project(
      aggregate: ExpectedExpenseAggregate(
        relationships: [relationship],
        occurrences: [seed],
      ),
      horizon: ExpenseProjectionHorizon(
        start: DateTime(2027),
        end: DateTime(2028, 12, 31),
      ),
    );

    final overview = composer.compose(
      expectedExpenses: const [],
      projectedCycles: projected,
      finitePlans: const [],
      referenceTime: reference,
    );
    final items = overview.futureMonths.expand((group) => group.items).toList();

    expect(projected.map((item) => item.expectedPeriod?.year), [2027, 2028]);
    expect(items.map((item) => item.title), [
      'Tributo comunale 2027 · Comune',
      'Tributo comunale 2028 · Comune',
    ]);
  });

  test('target-year policy falls back without inventing an absent year', () {
    final overview = composer.compose(
      expectedExpenses: _expected(
        reference: DateTime(2027, 3, 1),
        service: 'Tributo comunale',
        yearlyLabel: true,
        structuredYear: false,
      ),
      finitePlans: const [],
      referenceTime: reference,
    );

    expect(
      overview.futureMonths.single.items.single.title,
      'Tributo comunale · Hera',
    );
  });

  test(
    'materialized occurrence wins over projected cycle with same identity',
    () {
      final expected = _expected(
        reference: DateTime(2026, 11, 10),
        cycleSequence: 2,
      );
      final overview = composer.compose(
        expectedExpenses: expected,
        projectedCycles: [_projected(sequence: 2), _projected(sequence: 3)],
        finitePlans: const [],
        referenceTime: reference,
      );
      final items = overview.futureMonths
          .expand((group) => group.items)
          .toList();

      expect(
        items.where((item) => item.identity == 'relationship_hera#2'),
        isEmpty,
      );
      expect(
        items.where((item) => item.identity == 'occurrence_hera'),
        hasLength(1),
      );
      expect(
        items.where((item) => item.identity == 'relationship_hera#3'),
        hasLength(1),
      );
    },
  );

  group('composeInRange', () {
    test('selects a near inclusive range and omits empty month groups', () {
      final overview = composer.composeInRange(
        expectedExpenses: _expected(reference: DateTime(2026, 11, 10)),
        projectedCycles: [
          _projected(sequence: 2, anchor: DateTime(2026, 12, 31)),
          _projected(sequence: 3, anchor: DateTime(2027, 1, 1)),
        ],
        finitePlans: [_plan()],
        start: DateTime(2026, 11, 10),
        end: DateTime(2026, 12, 31),
        referenceTime: reference,
      );
      final items = _items(overview);

      expect(items.map((item) => item.placementStart), containsAll([
        DateTime(2026, 11, 10),
        DateTime(2026, 11, 15),
        DateTime(2026, 12, 15),
        DateTime(2026, 12, 31),
      ]));
      expect(items.any((item) => item.placementStart == DateTime(2027)), isFalse);
      expect(overview.futureMonths.every((group) => group.items.isNotEmpty), isTrue);
      expect(overview.futureCount, 4);
    });

    test('reads a distant 2056 finite-plan range without earlier output', () {
      final overview = composer.composeInRange(
        expectedExpenses: const [],
        finitePlans: [
          _plan(
            total: 372,
            completed: 0,
            firstDate: DateTime(2026, 1, 15),
          ),
        ],
        start: DateTime(2056, 1, 1),
        end: DateTime(2056, 12, 31, 23, 59, 59),
        referenceTime: reference,
      );
      final items = _items(overview);

      expect(items, hasLength(12));
      expect(items.first.installmentNumber, 361);
      expect(items.last.installmentNumber, 372);
      expect(items.every((item) => item.placementStart!.year == 2056), isTrue);
    });

    test('returns empty for a range with no selected authority', () {
      final overview = composer.composeInRange(
        expectedExpenses: _expected(reference: DateTime(2026, 11, 10)),
        projectedCycles: [_projected(sequence: 2)],
        finitePlans: [_plan()],
        start: DateTime(2056),
        end: DateTime(2056, 12, 31),
        referenceTime: reference,
      );

      expect(_items(overview), isEmpty);
      expect(overview.futureMonths, isEmpty);
      expect(overview.futureCount, 0);
    });

    test('combines all three authorities and preserves classification', () {
      final overview = composer.composeInRange(
        expectedExpenses: _expected(reference: DateTime(2026, 8, 10)),
        projectedCycles: [
          _projected(sequence: 4, anchor: DateTime(2026, 9, 20)),
        ],
        finitePlans: [_plan()],
        start: DateTime(2026, 8),
        end: DateTime(2026, 10, 31),
        referenceTime: reference,
      );

      expect(overview.pastMonths, hasLength(1));
      expect(overview.currentMonth, hasLength(1));
      expect(overview.futureMonths.single.items, hasLength(1));
      expect(
        _items(overview).map((item) => item.authority).toSet(),
        {
          FutureOutflowAuthority.expectedExpense,
          FutureOutflowAuthority.projectedExpenseRelationship,
          FutureOutflowAuthority.finiteFinancialPlan,
        },
      );
    });

    test('excludes unplaced expected expenses from the range result', () {
      final overview = composer.composeInRange(
        expectedExpenses: _expected(
          reference: DateTime(2026, 11, 10),
          unplaced: true,
        ),
        finitePlans: const [],
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
        referenceTime: reference,
      );

      expect(_items(overview), isEmpty);
      expect(overview.unplaced, isEmpty);
    });

    test('keeps in-range materialized item and suppresses its projection', () {
      final overview = composer.composeInRange(
        expectedExpenses: _expected(
          reference: DateTime(2056, 6, 10),
          cycleSequence: 2,
        ),
        projectedCycles: [
          _projected(sequence: 2, anchor: DateTime(2056, 6, 10)),
        ],
        finitePlans: const [],
        start: DateTime(2056),
        end: DateTime(2056, 12, 31),
        referenceTime: reference,
      );
      final items = _items(overview);

      expect(items, hasLength(1));
      expect(items.single.identity, 'occurrence_hera');
      expect(items.single.authority, FutureOutflowAuthority.expectedExpense);
    });

    test('materialized identity suppresses projection before range filtering', () {
      final overview = composer.composeInRange(
        expectedExpenses: _expected(
          reference: DateTime(2025, 11, 10),
          cycleSequence: 2,
        ),
        projectedCycles: [
          _projected(sequence: 2, anchor: DateTime(2056, 6, 10)),
        ],
        finitePlans: const [],
        start: DateTime(2056),
        end: DateTime(2056, 12, 31),
        referenceTime: reference,
      );

      expect(_items(overview), isEmpty);
    });

    test('filters projected cycles defensively by cycle anchor', () {
      final overview = composer.composeInRange(
        expectedExpenses: const [],
        projectedCycles: [
          _projected(sequence: 2, anchor: DateTime(2055, 12, 31)),
          _projected(sequence: 3, anchor: DateTime(2056, 1, 1)),
          _projected(sequence: 4, anchor: DateTime(2056, 12, 31)),
          _projected(sequence: 5, anchor: DateTime(2057, 1, 1)),
        ],
        finitePlans: const [],
        start: DateTime(2056),
        end: DateTime(2056, 12, 31),
        referenceTime: reference,
      );

      expect(
        _items(overview).map((item) => item.identity),
        orderedEquals(['relationship_hera#3', 'relationship_hera#4']),
      );
    });

    test('completed finite plan contributes no items', () {
      final overview = composer.composeInRange(
        expectedExpenses: const [],
        finitePlans: [_plan(completed: 12)],
        start: DateTime(2026),
        end: DateTime(2027, 12, 31),
        referenceTime: reference,
      );

      expect(_items(overview), isEmpty);
    });

    test('returns immutable collections', () {
      final overview = composer.composeInRange(
        expectedExpenses: const [],
        projectedCycles: [_projected(sequence: 2)],
        finitePlans: const [],
        start: DateTime(2026),
        end: DateTime(2027, 12, 31),
        referenceTime: reference,
      );

      expect(
        () => overview.futureMonths.add(
          FutureOutflowMonthGroup(month: DateTime(2056), items: const []),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => overview.futureMonths.single.items.clear(),
        throwsUnsupportedError,
      );
    });

    test('rejects an inverted range', () {
      expect(
        () => composer.composeInRange(
          expectedExpenses: const [],
          finitePlans: const [],
          start: DateTime(2027),
          end: DateTime(2026),
          referenceTime: reference,
        ),
        throwsArgumentError,
      );
    });

    test('is equivalent to compose then filter after precedence', () {
      final expected = [
        ..._expected(reference: DateTime(2026, 8, 10)),
        ..._expected(
          reference: DateTime(2025, 11, 10),
          cycleSequence: 2,
        ),
        ..._expected(
          reference: DateTime(2026, 10, 10),
          unplaced: true,
          occurrenceId: 'occurrence_unplaced',
        ),
      ];
      final projected = [
        _projected(sequence: 2, anchor: DateTime(2026, 9, 10)),
        _projected(sequence: 3, anchor: DateTime(2026, 10, 10)),
      ];
      final start = DateTime(2026, 8);
      final end = DateTime(2026, 10, 31);
      final full = composer.compose(
        expectedExpenses: expected,
        projectedCycles: projected,
        finitePlans: [_plan()],
        referenceTime: reference,
      );
      final ranged = composer.composeInRange(
        expectedExpenses: expected,
        projectedCycles: projected,
        finitePlans: [_plan()],
        start: start,
        end: end,
        referenceTime: reference,
      );

      expect(
        _signature(ranged),
        _signature(full, start: start, end: end),
      );
    });
  });
}

FiniteFinancialPlan _plan({
  int completed = 3,
  int total = 12,
  DateTime? firstDate,
}) => FiniteFinancialPlan(
  id: 'plan_inps',
  name: 'INPS',
  subject: FinanceSubject.matteo,
  debitBalanceId: 'balance_banca',
  totalInstallments: total,
  expectedInstallmentAmount: 386,
  firstInstallmentDate: firstDate ?? DateTime(2026, 7, 15),
  scheduledDayOfMonth: 15,
  completedInstallments: completed,
);

List<FutureExpenseProjection> _expected({
  required DateTime reference,
  double amount = 59.63,
  String service = 'Acqua',
  int? cycleSequence,
  bool unplaced = false,
  String occurrenceId = 'occurrence_hera',
  bool yearlyLabel = false,
  bool structuredYear = true,
}) {
  final relationship = ExpenseRelationship(
    relationshipId: 'relationship_hera',
    service: service,
    provider: 'Hera',
    subject: FinanceSubject.matteo,
    status: ExpenseRelationshipStatus.active,
    periodicity: ExpenseRelationshipPeriodicity(
      type: yearlyLabel
          ? FinanceRecurringType.yearly
          : FinanceRecurringType.custom,
      customInterval: yearlyLabel ? null : 2,
      customIntervalUnit: yearlyLabel ? null : 'months',
    ),
    cycleLabelPolicy: yearlyLabel
        ? ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear
        : ExpenseRelationshipCycleLabelPolicy.stableNameOnly,
    paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
    ),
  );
  final occurrence = ExpectedExpenseOccurrence(
    occurrenceId: occurrenceId,
    relationshipId: relationship.relationshipId,
    cycleSequence: yearlyLabel && structuredYear ? 1 : cycleSequence,
    cycleAnchor:
        yearlyLabel && structuredYear || cycleSequence == null
        ? null
        : reference,
    expectedPeriod: yearlyLabel && structuredYear
        ? ExpectedDocumentPeriod(year: reference.year, month: reference.month)
        : null,
    status: ExpectedExpenseOccurrenceStatus.pending,
    expectedAmount: amount,
    estimationMethod: ExpenseEstimationMethod.manualEstimate,
    confidence: ExpenseEstimateConfidence.high,
    provisional: true,
    expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
    ),
    expectedSubject: FinanceSubject.matteo,
    expectedDueDate: unplaced ? null : reference.add(const Duration(days: 4)),
    expectedDueDateSource: unplaced
        ? null
        : ExpectedExpenseDateSource.explicit,
    expectedDueDateCertainty: unplaced
        ? null
        : ExpectedExpenseDateCertainty.known,
    plannedEconomicImpact: unplaced
        ? null
        : PlannedEconomicImpact(
            start: reference,
            end: reference,
            origin: PlannedEconomicImpactOrigin.userDecision,
          ),
  );
  final projections = const ExpectedExpenseReader().read(
    ExpectedExpenseAggregate(
      relationships: [relationship],
      occurrences: [occurrence],
    ),
  );
  return const FutureExpenseReader().read(
    projections: projections,
    referenceTime: DateTime(2026, 9, 20),
  );
}

ProjectedExpenseCycle _projected({
  required int sequence,
  DateTime? anchor,
  bool yearlyLabel = false,
}) =>
    ProjectedExpenseCycle(
      identity: ExpenseCycleIdentity(
        relationshipId: 'relationship_hera',
        cycleSequence: sequence,
      ),
      cycleAnchor: anchor ?? DateTime(2026, 10 + sequence),
      sourceOccurrenceId: 'occurrence_hera',
      service: yearlyLabel ? 'TARI' : 'Acqua',
      provider: 'Hera',
      cycleLabelPolicy: yearlyLabel
          ? ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear
          : ExpenseRelationshipCycleLabelPolicy.stableNameOnly,
      expectedAmount: 59.63,
      expectedSubject: FinanceSubject.matteo,
      expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.manual,
      ),
      paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
      provisional: true,
    );

List<FutureOutflowPresentation> _items(FutureOutflowOverview overview) => [
  ...overview.pastMonths,
  ...overview.currentMonth,
  ...overview.futureMonths.expand((group) => group.items),
  ...overview.unplaced,
];

List<String> _signature(
  FutureOutflowOverview overview, {
  DateTime? start,
  DateTime? end,
}) {
  bool selected(FutureOutflowPresentation item) {
    final date = item.placementStart;
    if (date == null) return start == null && end == null;
    return (start == null || !date.isBefore(start)) &&
        (end == null || !date.isAfter(end));
  }

  String entry(String group, FutureOutflowPresentation item) =>
      '$group|${item.identity}|${item.authority.name}|'
      '${item.placementStart?.toIso8601String()}|'
      '${item.placementEnd?.toIso8601String()}|${item.amount}';

  return [
    for (final item in overview.pastMonths.where(selected))
      entry('past', item),
    for (final item in overview.currentMonth.where(selected))
      entry('current', item),
    for (final group in overview.futureMonths)
      for (final item in group.items.where(selected))
        entry('future:${group.month.toIso8601String()}', item),
    if (start == null && end == null)
      for (final item in overview.unplaced) entry('unplaced', item),
  ];
}
