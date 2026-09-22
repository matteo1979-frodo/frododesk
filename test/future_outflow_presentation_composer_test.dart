import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_reader.dart';
import 'package:frododesk/logic/finance/future_expense_reader.dart';
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
}

FiniteFinancialPlan _plan({int completed = 3}) => FiniteFinancialPlan(
  id: 'plan_inps',
  name: 'INPS',
  subject: FinanceSubject.matteo,
  debitBalanceId: 'balance_banca',
  totalInstallments: 12,
  expectedInstallmentAmount: 386,
  firstInstallmentDate: DateTime(2026, 7, 15),
  scheduledDayOfMonth: 15,
  completedInstallments: completed,
);

List<FutureExpenseProjection> _expected({
  required DateTime reference,
  double amount = 59.63,
  String service = 'Acqua',
  int? cycleSequence,
}) {
  final relationship = ExpenseRelationship(
    relationshipId: 'relationship_hera',
    service: service,
    provider: 'Hera',
    subject: FinanceSubject.matteo,
    status: ExpenseRelationshipStatus.active,
    periodicity: ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.custom,
      customInterval: 2,
      customIntervalUnit: 'months',
    ),
    paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
    ),
  );
  final occurrence = ExpectedExpenseOccurrence(
    occurrenceId: 'occurrence_hera',
    relationshipId: relationship.relationshipId,
    cycleSequence: cycleSequence,
    cycleAnchor: cycleSequence == null ? null : reference,
    status: ExpectedExpenseOccurrenceStatus.pending,
    expectedAmount: amount,
    estimationMethod: ExpenseEstimationMethod.manualEstimate,
    confidence: ExpenseEstimateConfidence.high,
    provisional: true,
    expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
    ),
    expectedSubject: FinanceSubject.matteo,
    expectedDueDate: reference.add(const Duration(days: 4)),
    expectedDueDateSource: ExpectedExpenseDateSource.explicit,
    expectedDueDateCertainty: ExpectedExpenseDateCertainty.known,
    plannedEconomicImpact: PlannedEconomicImpact(
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

ProjectedExpenseCycle _projected({required int sequence}) =>
    ProjectedExpenseCycle(
      identity: ExpenseCycleIdentity(
        relationshipId: 'relationship_hera',
        cycleSequence: sequence,
      ),
      cycleAnchor: DateTime(2026, 10 + sequence),
      sourceOccurrenceId: 'occurrence_hera',
      service: 'Acqua',
      provider: 'Hera',
      expectedAmount: 59.63,
      expectedSubject: FinanceSubject.matteo,
      expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.manual,
      ),
      paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
      provisional: true,
    );
