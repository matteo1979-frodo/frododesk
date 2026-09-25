import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frododesk/logic/composite_creation_intent_store.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/telefonia/add_sim_creation_coordinator.dart';
import 'package:frododesk/models/composite_creation_intent.dart';
import 'package:frododesk/models/continuing_service_relationship.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/sim_service_details.dart';
import 'package:frododesk/stores/continuing_service_relationship_store.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:frododesk/stores/sim_service_details_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('buildIntent invariants', () {
    test('requires a supported person and never falls back to shared', () {
      final harness = _Harness();
      final withoutPerson = ContinuingServiceRelationship(
        relationshipId: harness.serviceRelationship.relationshipId,
        provider: harness.serviceRelationship.provider,
        label: harness.serviceRelationship.label,
      );
      final unsupportedPerson = harness.serviceRelationship.copyWith(
        personId: 'unsupported',
      );

      expect(
        () => harness.coordinator.buildIntent(
          operationId: 'missing_person',
          serviceRelationship: withoutPerson,
          simDetails: harness.simDetails,
          expenseRelationship: harness.expenseRelationship,
          firstOccurrence: harness.firstOccurrence,
          creditBalance: harness.creditBalance,
        ),
        throwsArgumentError,
      );
      expect(
        () => harness.coordinator.buildIntent(
          operationId: 'unsupported_person',
          serviceRelationship: unsupportedPerson,
          simDetails: harness.simDetails,
          expenseRelationship: harness.expenseRelationship,
          firstOccurrence: harness.firstOccurrence,
          creditBalance: harness.creditBalance,
        ),
        throwsArgumentError,
      );
    });

    test('uses one coherent person identity in all three domains', () {
      final harness = _Harness();
      final intent = harness.intent();
      final service = ContinuingServiceRelationship.fromJson(
        Map<String, dynamic>.from(
          intent.payload['serviceRelationship'] as Map,
        ),
      );
      final balance = FinanceBalance.fromJson(
        Map<String, dynamic>.from(intent.payload['creditBalance'] as Map),
      );
      final expense = ExpenseRelationship.fromJson(
        Map<String, dynamic>.from(
          intent.payload['expenseRelationship'] as Map,
        ),
      );

      expect(service.personId, 'matteo');
      expect(balance.personId, service.personId);
      expect(expense.subject, FinanceSubject.matteo);
      expect(expense.subject, isNot(FinanceSubject.shared));
    });

    test('rejects non-first cycle and non-pending initial state', () {
      final harness = _Harness();
      expect(
        () => harness.intent(
          occurrence: harness.firstOccurrence.copyWith(cycleSequence: 2),
        ),
        throwsArgumentError,
      );
      expect(
        () => harness.intent(
          occurrence: harness.firstOccurrence.copyWith(
            status: ExpectedExpenseOccurrenceStatus.cancelled,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects subject, execution and payment configuration mismatches', () {
      final harness = _Harness();
      expect(
        () => harness.intent(
          occurrence: harness.firstOccurrence.copyWith(
            expectedSubject: FinanceSubject.chiara,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => harness.intent(
          occurrence: harness.firstOccurrence.copyWith(
            paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => harness.intent(
          occurrence: harness.firstOccurrence.copyWith(
            expectedPaymentConfiguration:
                ExpenseRelationshipPaymentConfiguration(
                  method: FinancePaymentMethod.manual,
                  expectedBalanceId: 'balance_1',
                ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects balance and canonical date identity mismatches', () {
      final harness = _Harness();
      expect(
        () => harness.intent(
          relationship: harness.expenseRelationship.copyWith(
            paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
              method: FinancePaymentMethod.card,
              expectedBalanceId: 'different_balance',
            ),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => harness.intent(
          occurrence: harness.firstOccurrence.copyWith(
            cycleAnchor: DateTime(2026, 10, 13),
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  test('persists pending intent before creating all SIM components', () async {
    final harness = _Harness();
    final intent = harness.intent();

    final outcome = await harness.coordinator.start(intent);

    expect(outcome, AddSimCreationOutcome.completed);
    expect(harness.relationshipStore.intentWasPersistedBeforeAdd, isTrue);
    expect(harness.relationshipStore.items, hasLength(1));
    expect(harness.financeStore.balances, hasLength(1));
    expect(
      harness.financeStore.expectedExpenseAggregate.relationships,
      hasLength(1),
    );
    expect(
      harness.financeStore.expectedExpenseAggregate.occurrences,
      hasLength(1),
    );
    expect(harness.simStore.items, hasLength(1));
    expect(
      harness.intentStore.find('operation_1')!.status,
      CompositeCreationIntentStatus.completed,
    );
  });

  test('recovers after relationship creation without duplicating it', () async {
    final first = _Harness();
    final intent = first.intent();
    await first.intentStore.save(intent);
    await first.relationshipStore.add(first.serviceRelationship);

    final recovered = _Harness();
    await recovered.intentStore.load();
    final outcome = await recovered.coordinator.recover('operation_1');

    expect(outcome, AddSimCreationOutcome.completed);
    expect(recovered.relationshipStore.items, hasLength(1));
    expect(recovered.financeStore.balances, hasLength(1));
    expect(recovered.simStore.items, hasLength(1));
  });

  test('rolls forward when multiple real components already exist', () async {
    final harness = _Harness();
    await harness.intentStore.save(harness.intent());
    await harness.relationshipStore.add(harness.serviceRelationship);
    await harness.financeStore.addBalance(harness.creditBalance);
    await harness.financeStore.saveExpectedExpenseAggregate(
      ExpectedExpenseAggregate(
        relationships: [harness.expenseRelationship],
        occurrences: [harness.firstOccurrence],
      ),
    );

    final outcome = await harness.coordinator.recover('operation_1');

    expect(outcome, AddSimCreationOutcome.completed);
    expect(harness.financeStore.balances, hasLength(1));
    expect(harness.simStore.items, hasLength(1));
  });

  test('pending marker accepts equivalent reality and updates progress', () async {
    final harness = _Harness();
    await harness.intentStore.save(harness.intent());
    await harness.relationshipStore.add(harness.serviceRelationship);

    await harness.coordinator.recover('operation_1');

    final restored = harness.intentStore.find('operation_1')!;
    expect(
      restored.steps.singleWhere(
        (step) =>
            step.stepId == AddSimCreationCoordinator.serviceStepId,
      ).status,
      CompositeCreationStepStatus.completed,
    );
    expect(harness.relationshipStore.items, hasLength(1));
  });

  test('conflict stops without overwrite, delete, or later steps', () async {
    final harness = _Harness();
    await harness.intentStore.save(harness.intent());
    await harness.relationshipStore.add(
      ContinuingServiceRelationship(
        relationshipId: 'service_1',
        provider: 'Different provider',
        label: 'Different label',
        personId: 'matteo',
      ),
    );

    final outcome = await harness.coordinator.recover('operation_1');

    expect(outcome, AddSimCreationOutcome.conflict);
    expect(
      harness.intentStore.find('operation_1')!.status,
      CompositeCreationIntentStatus.conflict,
    );
    expect(harness.relationshipStore.items.single.provider, 'Different provider');
    expect(harness.financeStore.balances, isEmpty);
    expect(harness.simStore.items, isEmpty);
  });

  test('economically different expected expense becomes conflict', () async {
    final variants = <({
      ExpenseRelationship relationship,
      ExpectedExpenseOccurrence occurrence,
    }) Function(_Harness)>[
      (harness) => (
        relationship: harness.expenseRelationship,
        occurrence: harness.firstOccurrence.copyWith(expectedAmount: 9.99),
      ),
      (harness) => (
        relationship: harness.expenseRelationship.copyWith(
          periodicity: ExpenseRelationshipPeriodicity(
            type: FinanceRecurringType.yearly,
          ),
        ),
        occurrence: harness.firstOccurrence,
      ),
      (harness) => (
        relationship: harness.expenseRelationship,
        occurrence: harness.firstOccurrence.copyWith(
          expectedDueDate: DateTime(2026, 10, 13),
        ),
      ),
      (harness) => (
        relationship: harness.expenseRelationship.copyWith(
          paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
            method: FinancePaymentMethod.card,
            expectedBalanceId: 'other_balance',
          ),
        ),
        occurrence: harness.firstOccurrence.copyWith(
          expectedPaymentConfiguration:
              ExpenseRelationshipPaymentConfiguration(
                method: FinancePaymentMethod.card,
                expectedBalanceId: 'other_balance',
              ),
        ),
      ),
      (harness) => (
        relationship: harness.expenseRelationship.copyWith(
          subject: FinanceSubject.chiara,
        ),
        occurrence: harness.firstOccurrence.copyWith(
          expectedSubject: FinanceSubject.chiara,
        ),
      ),
      (harness) => (
        relationship: harness.expenseRelationship.copyWith(
          paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
        ),
        occurrence: harness.firstOccurrence.copyWith(
          paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
        ),
      ),
      (harness) => (
        relationship: harness.expenseRelationship.copyWith(
          paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
            method: FinancePaymentMethod.manual,
            expectedBalanceId: 'balance_1',
          ),
        ),
        occurrence: harness.firstOccurrence.copyWith(
          expectedPaymentConfiguration:
              ExpenseRelationshipPaymentConfiguration(
                method: FinancePaymentMethod.manual,
                expectedBalanceId: 'balance_1',
              ),
        ),
      ),
    ];

    for (final variant in variants) {
      SharedPreferences.setMockInitialValues({});
      final harness = _Harness();
      await harness.intentStore.save(harness.intent());
      await harness.relationshipStore.add(harness.serviceRelationship);
      await harness.financeStore.addBalance(harness.creditBalance);
      final changed = variant(harness);
      await harness.financeStore.saveExpectedExpenseAggregate(
        ExpectedExpenseAggregate(
          relationships: [changed.relationship],
          occurrences: [changed.occurrence],
        ),
      );

      expect(
        await harness.coordinator.recover('operation_1'),
        AddSimCreationOutcome.conflict,
      );
    }
  });

  test('legitimate later state does not conflict with pending marker', () async {
    final harness = _Harness();
    await harness.intentStore.save(harness.intent());
    await harness.relationshipStore.add(harness.serviceRelationship);
    final changedBalanceJson = harness.creditBalance.toJson()
      ..['currentAmount'] = 14.23
      ..['updatedAt'] = DateTime(2026, 10, 1).toIso8601String();
    await harness.financeStore.addBalance(
      FinanceBalance.fromJson(changedBalanceJson),
    );
    final resolved = harness.firstOccurrence.copyWith(
      status: ExpectedExpenseOccurrenceStatus.resolved,
      resolvedEconomicFactId: 'economic_fact_1',
    );
    final next = ExpectedExpenseOccurrence.fromJson({
      ...harness.firstOccurrence.toJson(),
      'occurrenceId': 'occurrence_2',
      'cycleSequence': 2,
      'cycleAnchor': DateTime(2026, 11, 12).toIso8601String(),
      'expectedDueDate': DateTime(2026, 11, 12).toIso8601String(),
    });
    await harness.financeStore.saveExpectedExpenseAggregate(
      ExpectedExpenseAggregate(
        relationships: [
          harness.expenseRelationship.copyWith(
            status: ExpenseRelationshipStatus.terminated,
          ),
        ],
        occurrences: [resolved, next],
      ),
    );

    expect(
      await harness.coordinator.recover('operation_1'),
      AddSimCreationOutcome.completed,
    );
    expect(harness.financeStore.balances.single.currentAmount, 14.23);
    expect(harness.financeStore.expectedExpenseAggregate.occurrences, hasLength(2));
  });

  test('retrying a completed operation creates no new IDs or records', () async {
    final harness = _Harness();
    final intent = harness.intent();
    await harness.coordinator.start(intent);

    final outcome = await harness.coordinator.start(intent);

    expect(outcome, AddSimCreationOutcome.completed);
    expect(harness.relationshipStore.items.single.relationshipId, 'service_1');
    expect(harness.financeStore.balances.single.balanceId, 'balance_1');
    expect(
      harness.financeStore.expectedExpenseAggregate.occurrences.single.occurrenceId,
      'occurrence_1',
    );
  });

  test('pending recovery entry point resumes matching operations', () async {
    final harness = _Harness();
    await harness.intentStore.save(harness.intent());

    final outcomes = await harness.coordinator.recoverPending();

    expect(outcomes, [AddSimCreationOutcome.completed]);
    expect(harness.intentStore.find('operation_1')!.status,
        CompositeCreationIntentStatus.completed);
  });

  test('onboarding keeps renewal, credit, and economic facts separated', () async {
    final harness = _Harness();
    final expenseStore = ExpenseStore();
    await harness.coordinator.start(harness.intent());
    await expenseStore.load();

    final occurrence =
        harness.financeStore.expectedExpenseAggregate.occurrences.single;
    expect(occurrence.expectedAmount, 4.99);
    expect(occurrence.cycleSequence, 1);
    expect(occurrence.cycleAnchor, DateTime(2026, 10, 12));
    expect(occurrence.status, ExpectedExpenseOccurrenceStatus.pending);
    expect(occurrence.estimationMethod, ExpenseEstimationMethod.manualEstimate);
    expect(
      occurrence.expectedPaymentConfiguration.expectedBalanceId,
      'balance_1',
    );
    expect(
      harness.financeStore.expectedExpenseAggregate.relationships.single
          .periodicity
          .type,
      FinanceRecurringType.monthly,
    );
    expect(occurrence.evidenceEconomicFactIds, isEmpty);
    expect(harness.financeStore.balances.single.currentAmount, 4.23);
    expect(harness.financeStore.transactions, isEmpty);
    expect(expenseStore.all, isEmpty);
  });
}

class _Harness {
  late final CompositeCreationIntentStore intentStore;
  late final _ObservingRelationshipStore relationshipStore;
  late final SimServiceDetailsStore simStore;
  late final FinanceStore financeStore;
  late final AddSimCreationCoordinator coordinator;

  _Harness() {
    intentStore = CompositeCreationIntentStore();
    relationshipStore = _ObservingRelationshipStore(intentStore);
    simStore = SimServiceDetailsStore();
    financeStore = FinanceStore();
    coordinator = AddSimCreationCoordinator(
      intentStore: intentStore,
      relationshipStore: relationshipStore,
      simDetailsStore: simStore,
      financeStore: financeStore,
    );
  }

  final serviceRelationship = ContinuingServiceRelationship(
    relationshipId: 'service_1',
    provider: 'Provider',
    label: 'Personal SIM',
    personId: 'matteo',
  );

  final creditBalance = FinanceBalance(
    personId: 'matteo',
    balanceId: 'balance_1',
    name: 'SIM credit',
    initialAmount: 4.23,
    currentAmount: 4.23,
    updatedAt: DateTime(2026, 9, 24),
    balanceType: FinanceBalanceType.prepaidCard,
    operational: true,
    active: true,
    reservedAmount: 0,
    warningThreshold: 4.99,
    persistentStressDays: 0,
    recoveryDays: 0,
  );

  late final expenseRelationship = ExpenseRelationship(
    relationshipId: 'expense_1',
    service: 'Mobile service',
    provider: 'Provider',
    subject: FinanceSubject.matteo,
    status: ExpenseRelationshipStatus.active,
    periodicity: ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.monthly,
    ),
    paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.card,
      expectedBalanceId: 'balance_1',
    ),
    paymentExecutionMode: PaymentExecutionMode.automatic,
  );

  late final firstOccurrence = ExpectedExpenseOccurrence(
    occurrenceId: 'occurrence_1',
    relationshipId: 'expense_1',
    cycleSequence: 1,
    cycleAnchor: DateTime(2026, 10, 12),
    status: ExpectedExpenseOccurrenceStatus.pending,
    expectedDueDate: DateTime(2026, 10, 12),
    expectedDueDateSource: ExpectedExpenseDateSource.explicit,
    expectedDueDateCertainty: ExpectedExpenseDateCertainty.known,
    expectedAmount: 4.99,
    estimationMethod: ExpenseEstimationMethod.manualEstimate,
    evidenceEconomicFactIds: const [],
    confidence: ExpenseEstimateConfidence.high,
    provisional: false,
    expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.card,
      expectedBalanceId: 'balance_1',
    ),
    paymentExecutionMode: PaymentExecutionMode.automatic,
    expectedSubject: FinanceSubject.matteo,
  );

  late final simDetails = SimServiceDetails(
    relationshipId: 'service_1',
    phoneNumber: '3703042030',
    offerName: 'Offer',
    activationDate: DateTime(2026, 6, 12),
    simExpirationDate: DateTime(2027, 10, 11),
    creditBalanceId: 'balance_1',
    expenseRelationshipId: 'expense_1',
  );

  CompositeCreationIntent intent({
    ExpenseRelationship? relationship,
    ExpectedExpenseOccurrence? occurrence,
  }) => coordinator.buildIntent(
    operationId: 'operation_1',
    serviceRelationship: serviceRelationship,
    simDetails: simDetails,
    expenseRelationship: relationship ?? expenseRelationship,
    firstOccurrence: occurrence ?? firstOccurrence,
    creditBalance: creditBalance,
  );
}

class _ObservingRelationshipStore extends ContinuingServiceRelationshipStore {
  final CompositeCreationIntentStore intentStore;
  bool intentWasPersistedBeforeAdd = false;

  _ObservingRelationshipStore(this.intentStore);

  @override
  Future<void> add(ContinuingServiceRelationship item) async {
    intentWasPersistedBeforeAdd =
        intentStore.find('operation_1')?.status ==
        CompositeCreationIntentStatus.pending;
    await super.add(item);
  }
}
