import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:frododesk/logic/finance/documentary_obligation_persistence.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/finance_forecast_reader.dart';
import 'package:frododesk/models/documentary_obligation.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_forecast_presentation.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finite_financial_plan.dart';
import 'package:frododesk/models/planned_economic_impact.dart';
import 'package:frododesk/models/projected_expense_cycle.dart';
import 'package:frododesk/screens/finance_screen.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  const reader = FinanceForecastReader();
  final horizon = ExpenseProjectionHorizon(
    start: DateTime(2026, 10),
    end: DateTime(2027, 12, 31),
  );

  FinanceForecastOverview read({
    ExpectedExpenseAggregate? expected,
    DocumentaryObligationAggregate? documentary,
    Iterable<FiniteFinancialPlan>? plans,
  }) => reader.read(
    expectedExpenses: expected ?? _realExpectedExpenses(),
    documentaryObligations:
        documentary ?? DocumentaryObligationAggregate.empty(),
    finitePlans: plans ?? [_inps()],
    referenceTime: DateTime(2026, 10, 2),
    projectionHorizon: horizon,
  );

  test('maps economic dates, document periods and unlocated knowledge', () {
    final unlocatedRelationship = _relationship(
      id: 'unknown',
      service: 'Unknown',
    );
    final aggregate = _realExpectedExpenses(
      extraRelationships: [unlocatedRelationship],
      extraOccurrences: [
        _occurrence(
          id: 'unknown-occurrence',
          relationship: unlocatedRelationship,
          amount: 12,
          issue: DateTime(2026, 10, 1),
        ),
      ],
    );

    final overview = read(expected: aggregate);
    final tim = overview.items.singleWhere(
      (item) => item.occurrenceId == 'tim-occurrence',
    );
    final tari = overview.items.singleWhere(
      (item) => item.occurrenceId == 'tari-occurrence',
    );
    final unknown = overview.items.singleWhere(
      (item) => item.occurrenceId == 'unknown-occurrence',
    );

    expect(
      tim.temporalKnowledge,
      FinanceForecastTemporalKnowledge.economicDateKnown,
    );
    expect(tim.countsInEconomicMonth(DateTime(2026, 10)), isTrue);
    expect(
      tari.temporalKnowledge,
      FinanceForecastTemporalKnowledge.documentPeriodOnly,
    );
    expect(tari.countsInEconomicMonth(DateTime(2027, 3)), isFalse);
    expect(tari.documentKnowledgeFallsIn(DateTime(2027, 3)), isTrue);
    expect(
      unknown.temporalKnowledge,
      FinanceForecastTemporalKnowledge.unlocated,
    );
    expect(unknown.countsInEconomicMonth(DateTime(2026, 10)), isFalse);
  });

  test('same-month windows count but cross-month windows stay unlocated', () {
    final same = _relationship(id: 'same', service: 'Same');
    final cross = _relationship(id: 'cross', service: 'Cross');
    final overview = read(
      expected: ExpectedExpenseAggregate(
        relationships: [same, cross],
        occurrences: [
          _occurrence(
            id: 'same-occurrence',
            relationship: same,
            amount: 10,
            issue: DateTime(2026, 10, 1),
            impact: PlannedEconomicImpact(
              start: DateTime(2026, 10, 10),
              end: DateTime(2026, 10, 12),
              origin: PlannedEconomicImpactOrigin.userDecision,
            ),
          ),
          _occurrence(
            id: 'cross-occurrence',
            relationship: cross,
            amount: 20,
            issue: DateTime(2026, 10, 1),
            impact: PlannedEconomicImpact(
              start: DateTime(2026, 10, 31),
              end: DateTime(2026, 11, 1),
              origin: PlannedEconomicImpactOrigin.userDecision,
            ),
          ),
        ],
      ),
      plans: const [],
    );

    final sameItem = overview.items.singleWhere(
      (item) => item.occurrenceId == 'same-occurrence',
    );
    final crossItem = overview.items.singleWhere(
      (item) => item.occurrenceId == 'cross-occurrence',
    );
    expect(
      sameItem.temporalKnowledge,
      FinanceForecastTemporalKnowledge.economicWindowKnown,
    );
    expect(sameItem.countsInEconomicMonth(DateTime(2026, 10)), isTrue);
    expect(
      crossItem.temporalKnowledge,
      FinanceForecastTemporalKnowledge.unlocated,
    );
  });

  test(
    'uses structural identities and occurrence precedence over projection',
    () {
      final overview = read();
      final timOctober = overview.items.singleWhere(
        (item) => item.occurrenceId == 'tim-occurrence',
      );
      final timMarch = overview.items.singleWhere(
        (item) =>
            item.relationshipId == 'tim-relationship' &&
            item.economicStart == DateTime(2027, 3, 12),
      );
      final inpsOctober = overview.items.singleWhere(
        (item) => item.planId == 'inps-plan' && item.installmentNumber == 4,
      );

      expect(timOctober.identity, 'expense-cycle:tim-relationship#1');
      expect(
        overview.items.where((item) => item.identity == timOctober.identity),
        hasLength(1),
      );
      expect(timMarch.identity, 'expense-cycle:tim-relationship#6');
      expect(inpsOctober.identity, 'finite-plan:inps-plan#4');
      expect(timOctober.identity, isNot(inpsOctober.identity));
    },
  );

  test(
    'documentary installments replace their lineage and remain distinct',
    () {
      final relationship = _relationship(
        id: 'tax',
        service: 'Tax',
        periodicity: FinanceRecurringType.yearly,
      );
      final expected = ExpectedExpenseAggregate(
        relationships: [relationship],
        occurrences: [
          _occurrence(
            id: 'tax-occurrence',
            relationship: relationship,
            amount: 100,
            sequence: 1,
            period: ExpectedDocumentPeriod(year: 2027, month: 3),
          ),
        ],
      );
      final obligation = DocumentaryObligation(
        obligationId: 'tax-obligation',
        title: 'Tax',
        totalAmount: 100,
        relationshipId: relationship.relationshipId,
        cycleSequence: 1,
        options: [
          DocumentaryFulfillmentOption(
            optionId: 'two',
            label: 'Due rate',
            installments: [
              DocumentaryInstallment(
                installmentId: 'a',
                amount: 40,
                dueDate: DateTime(2027, 3, 10),
              ),
              DocumentaryInstallment(
                installmentId: 'b',
                amount: 60,
                dueDate: DateTime(2027, 4, 10),
              ),
            ],
          ),
        ],
        selectedOptionId: 'two',
      );
      final overview = read(
        expected: expected,
        documentary: DocumentaryObligationAggregate(obligations: [obligation]),
        plans: const [],
      );

      expect(overview.items, hasLength(2));
      expect(overview.items.map((item) => item.identity), {
        'documentary-installment:tax-obligation#a',
        'documentary-installment:tax-obligation#b',
      });
      expect(overview.items.every((item) => item.occurrenceId == null), isTrue);
      expect(
        overview.items.map((item) => item.temporalKnowledge),
        everyElement(FinanceForecastTemporalKnowledge.unlocated),
      );
      expect(
        overview.items.every((item) => item.economicStart == null),
        isTrue,
      );
      expect(overview.economicOutflowForMonth(DateTime(2027, 3)), 0);
    },
  );

  test(
    'certified October and March totals keep document-only amounts apart',
    () {
      final overview = read();

      expect(
        overview.economicOutflowForMonth(DateTime(2026, 10)),
        closeTo(390.99, 0.001),
      );
      expect(overview.documentaryOnlyOutflowForMonth(DateTime(2026, 10)), 0);
      expect(
        overview.economicOutflowForMonth(DateTime(2027, 3)),
        closeTo(390.99, 0.001),
      );
      expect(
        overview.documentaryOnlyOutflowForMonth(DateTime(2027, 3)),
        closeTo(219.32, 0.001),
      );
    },
  );

  testWidgets('only Uscite previste consumes the convergent forecast', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = FinanceStore(
      initialExpectedExpenseAggregate: _realExpectedExpenses(),
      initialFiniteFinancialPlans: [_inps()],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FinanceScreen(
          financeStore: store,
          expenseStore: ExpenseStore(),
          cashWalletStore: CashWalletStore(),
          forecastReferenceTime: DateTime(2026, 10, 2),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Uscite previste'), findsOneWidget);
    expect(find.text('2 voci • €390,99'), findsOneWidget);
    expect(find.text('Entrate previste'), findsOneWidget);
    expect(find.text('0 voci • €0,00'), findsOneWidget);
    expect(store.recurringItems, isEmpty);
  });
}

ExpectedExpenseAggregate _realExpectedExpenses({
  Iterable<ExpenseRelationship> extraRelationships = const [],
  Iterable<ExpectedExpenseOccurrence> extraOccurrences = const [],
}) {
  final tim = _relationship(
    id: 'tim-relationship',
    service: 'Telefonia',
    provider: 'TIM',
    paymentMode: PaymentExecutionMode.automatic,
  );
  final tari = _relationship(
    id: 'tari-relationship',
    service: 'TARI',
    provider: 'Comune',
    periodicity: FinanceRecurringType.yearly,
  );
  final sorit = _relationship(
    id: 'sorit-relationship',
    service: 'SORIT',
    provider: 'SORIT',
    periodicity: FinanceRecurringType.yearly,
  );
  return ExpectedExpenseAggregate(
    relationships: [tim, tari, sorit, ...extraRelationships],
    occurrences: [
      _occurrence(
        id: 'tim-occurrence',
        relationship: tim,
        amount: 4.99,
        sequence: 1,
        anchor: DateTime(2026, 10, 12),
        due: DateTime(2026, 10, 12),
        dueCertainty: ExpectedExpenseDateCertainty.known,
      ),
      _occurrence(
        id: 'tari-occurrence',
        relationship: tari,
        amount: 173,
        sequence: 2,
        period: ExpectedDocumentPeriod(year: 2027, month: 3),
      ),
      _occurrence(
        id: 'sorit-occurrence',
        relationship: sorit,
        amount: 46.32,
        sequence: 2,
        period: ExpectedDocumentPeriod(year: 2027, month: 3),
      ),
      ...extraOccurrences,
    ],
  );
}

ExpenseRelationship _relationship({
  required String id,
  required String service,
  String provider = 'Provider',
  FinanceRecurringType periodicity = FinanceRecurringType.monthly,
  PaymentExecutionMode paymentMode = PaymentExecutionMode.requiresUserAction,
}) => ExpenseRelationship(
  relationshipId: id,
  service: service,
  provider: provider,
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(type: periodicity),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: paymentMode == PaymentExecutionMode.automatic
        ? FinancePaymentMethod.rid
        : FinancePaymentMethod.manual,
  ),
  paymentExecutionMode: paymentMode,
);

ExpectedExpenseOccurrence _occurrence({
  required String id,
  required ExpenseRelationship relationship,
  required double amount,
  int? sequence,
  DateTime? anchor,
  ExpectedDocumentPeriod? period,
  DateTime? issue,
  DateTime? due,
  ExpectedExpenseDateCertainty? dueCertainty,
  PlannedEconomicImpact? impact,
}) => ExpectedExpenseOccurrence(
  occurrenceId: id,
  relationshipId: relationship.relationshipId,
  cycleSequence: sequence,
  cycleAnchor: anchor,
  expectedPeriod: period,
  status: ExpectedExpenseOccurrenceStatus.pending,
  expectedAmount: amount,
  estimationMethod: ExpenseEstimationMethod.manualEstimate,
  confidence: ExpenseEstimateConfidence.high,
  provisional: period != null,
  expectedPaymentConfiguration: relationship.paymentConfiguration,
  paymentExecutionMode: relationship.paymentExecutionMode,
  expectedSubject: relationship.subject,
  expectedDueDate: due,
  expectedIssueDate: issue,
  expectedIssueDateSource: issue == null
      ? null
      : ExpectedExpenseDateSource.explicit,
  expectedDueDateSource: due == null
      ? null
      : ExpectedExpenseDateSource.explicit,
  expectedDueDateCertainty: dueCertainty,
  plannedEconomicImpact: impact,
);

FiniteFinancialPlan _inps() => FiniteFinancialPlan(
  id: 'inps-plan',
  name: 'INPS',
  subject: FinanceSubject.matteo,
  totalInstallments: 12,
  expectedInstallmentAmount: 386,
  firstInstallmentDate: DateTime(2026, 7, 15),
  scheduledDayOfMonth: 15,
  completedInstallments: 3,
);
