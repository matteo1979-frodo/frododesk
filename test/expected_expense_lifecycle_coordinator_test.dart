import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_lifecycle_coordinator.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_contract.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/ledger/economic_event_collector.dart';
import 'package:frododesk/logic/ledger/economic_event_correlator.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/planned_economic_impact.dart';
import 'package:frododesk/screens/expected_expense_completion_page.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'known data updates the same occurrence without economic effects',
    () async {
      final harness = await _Harness.create();
      final beforeBalance = harness.store.balances.single.currentAmount;

      final result = await harness.coordinator.recordKnownExpenseData(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        data: KnownExpectedExpenseData(
          amount: 82.40,
          issueDate: DateTime(2026, 9, 2),
          dueDate: DateTime(2026, 9, 20),
          evidenceEconomicFactIds: const ['document-hera-september'],
        ),
      );

      expect(result.status, ExpectedExpenseLifecycleStatus.completed);
      final occurrence =
          harness.store.expectedExpenseAggregate.occurrences.single;
      expect(occurrence.occurrenceId, 'occurrence-september');
      expect(occurrence.relationshipId, 'relationship-utility');
      expect(
        occurrence.knowledgeState,
        ExpectedExpenseKnowledgeState.knownUnpaid,
      );
      expect(
        occurrence.knowledgeSource,
        ExpectedExpenseKnowledgeSource.userConfirmed,
      );
      expect(occurrence.expectedAmount, 82.40);
      expect(occurrence.expectedIssueDate, DateTime(2026, 9, 2));
      expect(occurrence.expectedDueDate, DateTime(2026, 9, 20));
      expect(occurrence.plannedEconomicImpact?.start, DateTime(2026, 9, 18));
      expect(
        occurrence.paymentExecutionMode,
        PaymentExecutionMode.requiresUserAction,
      );
      expect(harness.store.balances.single.currentAmount, beforeBalance);
      expect(harness.store.transactions, isEmpty);
      expect(harness.expenses.all, isEmpty);

      final retry = await harness.coordinator.recordKnownExpenseData(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        data: KnownExpectedExpenseData(
          amount: 82.40,
          issueDate: DateTime(2026, 9, 2),
          dueDate: DateTime(2026, 9, 20),
          evidenceEconomicFactIds: const ['document-hera-september'],
        ),
      );
      expect(retry.status, ExpectedExpenseLifecycleStatus.unchanged);
    },
  );

  test('cancelled and resolved occurrences reject known data', () async {
    for (final status in [
      ExpectedExpenseOccurrenceStatus.cancelled,
      ExpectedExpenseOccurrenceStatus.resolved,
    ]) {
      final harness = await _Harness.create(status: status);
      final result = await harness.coordinator.recordKnownExpenseData(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        data: KnownExpectedExpenseData(amount: 80),
      );
      expect(result.status, ExpectedExpenseLifecycleStatus.invalidState);
    }
  });

  test(
    'simple payment resolves occurrence and creates one next cycle',
    () async {
      final harness = await _Harness.create(known: true);
      final result = await harness.coordinator.recordExpectedExpensePayment(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        payment: _payment(),
      );

      expect(result.status, ExpectedExpenseLifecycleStatus.completed);
      expect(harness.store.balances.single.currentAmount, 920);
      expect(harness.store.transactions, hasLength(1));
      expect(harness.expenses.all, hasLength(1));
      final resolved = harness.store.expectedExpenseAggregate.occurrences.first;
      expect(resolved.status, ExpectedExpenseOccurrenceStatus.resolved);
      expect(resolved.resolvedEconomicFactId, result.mainEconomicFactId);
      final next = harness.store.expectedExpenseAggregate.occurrences.last;
      expect(next.status, ExpectedExpenseOccurrenceStatus.pending);
      expect(next.knowledgeState, ExpectedExpenseKnowledgeState.forecast);
      expect(next.relationshipId, resolved.relationshipId);
      expect(next.expectedDueDate, DateTime(2026, 10, 20));
      expect(next.plannedEconomicImpact, isNull);
      expect(next.expectedAmount, 80);

      final retry = await harness.coordinator.recordExpectedExpensePayment(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        payment: _payment(),
      );
      expect(retry.status, ExpectedExpenseLifecycleStatus.unchanged);
      expect(harness.store.balances.single.currentAmount, 920);
      expect(harness.store.transactions, hasLength(1));
      expect(harness.expenses.all, hasLength(1));
      expect(harness.store.expectedExpenseAggregate.occurrences, hasLength(2));
    },
  );

  test(
    'composite payment resolves to main fact and Ledger has no duplicates',
    () async {
      final harness = await _Harness.create(known: true);
      final result = await harness.coordinator.recordExpectedExpensePayment(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        payment: _payment(
          accessories: const [
            (amount: 2, type: AccessoryCostType.bankCommission),
            (amount: 1, type: AccessoryCostType.postalAcceptanceCharge),
          ],
        ),
      );

      expect(result.status, ExpectedExpenseLifecycleStatus.completed);
      expect(harness.store.balances.single.currentAmount, 917);
      expect(harness.store.transactions, hasLength(3));
      expect(harness.expenses.all, hasLength(3));
      final resolved = harness.store.expectedExpenseAggregate.occurrences.first;
      expect(resolved.resolvedEconomicFactId, result.mainEconomicFactId);
      expect(
        harness.store.transactions.skip(1).map((item) => item.economicFactId),
        everyElement(isNot(result.mainEconomicFactId)),
      );
      expect(
        harness.store.transactions
            .map((item) => item.operationMetadata?.operationId)
            .toSet(),
        hasLength(1),
      );
      final ledger = const EconomicEventCorrelator().correlate(
        const EconomicEventCollector().collect(
          transactions: harness.store.transactions,
          assetMovements: const [],
          realExpenses: harness.expenses.all,
          observedAt: DateTime(2026, 9, 22),
        ),
      );
      expect(ledger, hasLength(3));
      expect(ledger.every((item) => item.sourceLinks.length == 2), isTrue);
    },
  );

  test(
    'Expense failure is recovered without a second balance mutation',
    () async {
      var writes = 0;
      final expenses = ExpenseStore(
        saveVerified: (key, value) async {
          writes++;
          if (writes == 1) {
            return const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            );
          }
          return PersistenceStore.saveStringVerified(key, value);
        },
      );
      final harness = await _Harness.create(expenses: expenses, known: true);

      final failed = await harness.coordinator.recordExpectedExpensePayment(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        payment: _payment(),
      );
      expect(failed.status, ExpectedExpenseLifecycleStatus.failed);
      expect(harness.store.balances.single.currentAmount, 920);
      expect(harness.store.transactions, hasLength(1));
      expect(harness.expenses.all, isEmpty);
      expect(
        harness.store.expectedExpenseAggregate.occurrences.single.status,
        ExpectedExpenseOccurrenceStatus.pending,
      );

      final recovered = await harness.coordinator.recordExpectedExpensePayment(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        payment: _payment(),
      );
      expect(recovered.status, ExpectedExpenseLifecycleStatus.completed);
      expect(harness.store.balances.single.currentAmount, 920);
      expect(harness.store.transactions, hasLength(1));
      expect(harness.expenses.all, hasLength(1));
    },
  );

  test(
    'Expected write failure is recovered from complete economic facts',
    () async {
      var expectedWrites = 0;
      final persistence = ExpectedExpensePersistence(
        saveVerified: (key, value) async {
          expectedWrites++;
          if (expectedWrites == 1) {
            return const PersistenceWriteVerification(
              backendAccepted: false,
              readBack: null,
            );
          }
          return PersistenceStore.saveStringVerified(key, value);
        },
      );
      final harness = await _Harness.create(
        known: true,
        expectedPersistence: persistence,
      );
      final failed = await harness.coordinator.recordExpectedExpensePayment(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        payment: _payment(),
      );
      expect(failed.status, ExpectedExpenseLifecycleStatus.failed);
      expect(harness.store.balances.single.currentAmount, 920);
      expect(harness.store.transactions, hasLength(1));
      expect(harness.expenses.all, hasLength(1));
      expect(harness.store.expectedExpenseAggregate.occurrences, hasLength(1));

      final recovered = await harness.coordinator.recordExpectedExpensePayment(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        payment: _payment(),
      );
      expect(recovered.status, ExpectedExpenseLifecycleStatus.completed);
      expect(harness.store.balances.single.currentAmount, 920);
      expect(harness.store.transactions, hasLength(1));
      expect(harness.expenses.all, hasLength(1));
      expect(harness.store.expectedExpenseAggregate.occurrences, hasLength(2));
    },
  );

  test(
    'terminated relationship resolves without generating a next cycle',
    () async {
      final harness = await _Harness.create(
        known: true,
        relationshipStatus: ExpenseRelationshipStatus.terminated,
      );
      final result = await harness.coordinator.recordExpectedExpensePayment(
        relationshipId: 'relationship-utility',
        occurrenceId: 'occurrence-september',
        payment: _payment(),
      );
      expect(result.status, ExpectedExpenseLifecycleStatus.completed);
      expect(result.nextOccurrenceId, isNull);
      expect(harness.store.expectedExpenseAggregate.occurrences, hasLength(1));
    },
  );

  test(
    'monthly short month, annual and custom month cadence are clamped',
    () async {
      final cases = <(ExpenseRelationshipPeriodicity, DateTime, DateTime)>[
        (
          ExpenseRelationshipPeriodicity(type: FinanceRecurringType.monthly),
          DateTime(2027, 1, 31),
          DateTime(2027, 2, 28),
        ),
        (
          ExpenseRelationshipPeriodicity(type: FinanceRecurringType.yearly),
          DateTime(2024, 2, 29),
          DateTime(2025, 2, 28),
        ),
        (
          ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.custom,
            customInterval: 2,
            customIntervalUnit: 'months',
          ),
          DateTime(2026, 12, 31),
          DateTime(2027, 2, 28),
        ),
      ];
      for (final entry in cases) {
        SharedPreferences.setMockInitialValues({});
        final harness = await _Harness.create(
          known: true,
          periodicity: entry.$1,
          dueDate: entry.$2,
        );
        final result = await harness.coordinator.recordExpectedExpensePayment(
          relationshipId: 'relationship-utility',
          occurrenceId: 'occurrence-september',
          payment: _payment(),
        );
        expect(result.status, ExpectedExpenseLifecycleStatus.completed);
        expect(
          harness
              .store
              .expectedExpenseAggregate
              .occurrences
              .last
              .expectedDueDate,
          entry.$3,
        );
      }
    },
  );

  test(
    'cancelled cannot be paid and conflicting resolved fact is explicit',
    () async {
      final cancelled = await _Harness.create(
        status: ExpectedExpenseOccurrenceStatus.cancelled,
      );
      expect(
        (await cancelled.coordinator.recordExpectedExpensePayment(
          relationshipId: 'relationship-utility',
          occurrenceId: 'occurrence-september',
          payment: _payment(),
        )).status,
        ExpectedExpenseLifecycleStatus.invalidState,
      );
      final resolved = await _Harness.create(
        status: ExpectedExpenseOccurrenceStatus.resolved,
        resolvedFactId: 'different-fact',
      );
      expect(
        (await resolved.coordinator.recordExpectedExpensePayment(
          relationshipId: 'relationship-utility',
          occurrenceId: 'occurrence-september',
          payment: _payment(),
        )).status,
        ExpectedExpenseLifecycleStatus.conflict,
      );
    },
  );

  testWidgets('forecast exposes separate arrived and payment actions', (
    tester,
  ) async {
    final harness = await _Harness.create();
    await tester.pumpWidget(_app(harness));
    await tester.scrollUntilVisible(
      find.byKey(const Key('record-known-expense-data')),
      300,
    );
    expect(find.text('La bolletta è arrivata'), findsOneWidget);
    expect(find.text('Registra pagamento'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record-known-expense-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-known-expense-data')));
    await tester.pumpAndSettle();

    final occurrence =
        harness.store.expectedExpenseAggregate.occurrences.single;
    expect(
      occurrence.knowledgeState,
      ExpectedExpenseKnowledgeState.knownUnpaid,
    );
    expect(harness.store.transactions, isEmpty);
    expect(harness.expenses.all, isEmpty);
    expect(harness.store.balances.single.currentAmount, 1000);
  });

  testWidgets('payment action resolves and closes the future expense card', (
    tester,
  ) async {
    final harness = await _Harness.create(known: true);
    await tester.pumpWidget(_app(harness));
    await tester.scrollUntilVisible(
      find.byKey(const Key('record-expected-expense-payment')),
      300,
    );
    expect(find.byKey(const Key('record-known-expense-data')), findsNothing);
    await tester.tap(find.byKey(const Key('record-expected-expense-payment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-expected-payment')));
    await tester.pumpAndSettle();

    expect(
      harness.store.expectedExpenseAggregate.occurrences.first.status,
      ExpectedExpenseOccurrenceStatus.resolved,
    );
    expect(harness.store.transactions, hasLength(1));
    expect(harness.expenses.all, hasLength(1));
    expect(harness.store.expectedExpenseAggregate.occurrences, hasLength(2));
  });
}

Widget _app(_Harness harness) => MaterialApp(
  home: ExpectedExpenseCompletionPage(
    financeStore: harness.store,
    expenseStore: harness.expenses,
    relationshipId: 'relationship-utility',
    occurrenceId: 'occurrence-september',
  ),
);

class _Harness {
  final FinanceStore store;
  final ExpenseStore expenses;
  const _Harness(this.store, this.expenses);

  ExpectedExpenseLifecycleCoordinator get coordinator =>
      ExpectedExpenseLifecycleCoordinator(
        financeStore: store,
        expenseStore: expenses,
      );

  static Future<_Harness> create({
    bool known = false,
    ExpectedExpenseOccurrenceStatus status =
        ExpectedExpenseOccurrenceStatus.pending,
    String? resolvedFactId,
    ExpenseRelationshipStatus relationshipStatus =
        ExpenseRelationshipStatus.active,
    ExpenseRelationshipPeriodicity? periodicity,
    DateTime? dueDate,
    ExpenseStore? expenses,
    ExpectedExpensePersistence? expectedPersistence,
  }) async {
    final seed = FinancePortfolioV3(
      balances: [_balance()],
      funds: const [],
      assetMovements: const [],
      transactions: const [],
      fundTransactions: const [],
      linkedItems: const [],
    );
    expect((await FinancePortfolioV3Writer().write(seed)).isSuccess, isTrue);
    final relationship = _relationship(
      status: relationshipStatus,
      periodicity: periodicity,
    );
    final occurrence = _occurrence(
      status: status,
      known: known,
      resolvedFactId: resolvedFactId,
      dueDate: dueDate,
    );
    final store = FinanceStore(
      expectedExpensePersistence: expectedPersistence,
      initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
        relationships: [relationship],
        occurrences: [occurrence],
      ),
    );
    await store.loadSavedPortfolioV3();
    final expenseStore = expenses ?? ExpenseStore();
    await expenseStore.load();
    return _Harness(store, expenseStore);
  }
}

ExpectedExpensePayment _payment({
  Iterable<ExpectedExpenseAccessoryPayment> accessories = const [],
}) => ExpectedExpensePayment(
  paidAt: DateTime(2026, 9, 18, 11),
  balanceId: 'balance-bank',
  subject: FinanceSubject.matteo,
  category: 'Utenze',
  description: 'Bolletta reale',
  amount: 80,
  accessories: accessories,
);

ExpenseRelationship _relationship({
  ExpenseRelationshipStatus status = ExpenseRelationshipStatus.active,
  ExpenseRelationshipPeriodicity? periodicity,
}) => ExpenseRelationship(
  relationshipId: 'relationship-utility',
  service: 'Acqua',
  provider: 'Fornitore',
  subject: FinanceSubject.matteo,
  status: status,
  periodicity:
      periodicity ??
      ExpenseRelationshipPeriodicity(type: FinanceRecurringType.monthly),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance-bank',
  ),
  paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
);

ExpectedExpenseOccurrence _occurrence({
  ExpectedExpenseOccurrenceStatus status =
      ExpectedExpenseOccurrenceStatus.pending,
  bool known = false,
  String? resolvedFactId,
  DateTime? dueDate,
}) => ExpectedExpenseOccurrence(
  occurrenceId: 'occurrence-september',
  relationshipId: 'relationship-utility',
  status: status,
  knowledgeState: known
      ? ExpectedExpenseKnowledgeState.knownUnpaid
      : ExpectedExpenseKnowledgeState.forecast,
  knowledgeSource: known
      ? ExpectedExpenseKnowledgeSource.userConfirmed
      : ExpectedExpenseKnowledgeSource.legacyUnspecified,
  expectedDueDate: dueDate ?? DateTime(2026, 9, 20),
  expectedDueDateSource: known
      ? ExpectedExpenseDateSource.explicit
      : ExpectedExpenseDateSource.calculatedFromPeriodicity,
  expectedDueDateCertainty: known
      ? ExpectedExpenseDateCertainty.known
      : ExpectedExpenseDateCertainty.estimated,
  plannedEconomicImpact: PlannedEconomicImpact(
    start: DateTime(2026, 9, 18),
    end: DateTime(2026, 9, 18),
    origin: PlannedEconomicImpactOrigin.userDecision,
  ),
  expectedAmount: 75,
  estimationMethod: ExpenseEstimationMethod.manualEstimate,
  confidence: ExpenseEstimateConfidence.medium,
  provisional: !known,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance-bank',
  ),
  paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
  expectedSubject: FinanceSubject.matteo,
  resolvedEconomicFactId: status == ExpectedExpenseOccurrenceStatus.resolved
      ? resolvedFactId ?? 'resolved-fact'
      : null,
);

FinanceBalance _balance() => FinanceBalance(
  balanceId: 'balance-bank',
  personId: 'matteo',
  name: 'Banca',
  initialAmount: 1000,
  currentAmount: 1000,
  updatedAt: DateTime(2026, 9, 1),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);
