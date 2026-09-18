import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/finance_lifecycle_loader.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lifecycle loads an absent key as an empty aggregate', () async {
    SharedPreferences.setMockInitialValues(_emptyPortfolioV3());
    final store = FinanceStore();

    await FinanceLifecycleLoader(financeStore: store, refresh: () {}).load();

    expect(store.expectedExpenseAggregate.relationships, isEmpty);
    expect(store.expectedExpenseAggregate.occurrences, isEmpty);
  });

  test('lifecycle publishes a valid aggregate before final refresh', () async {
    final aggregate = _aggregate(resolved: true);
    await ExpectedExpensePersistence().write(aggregate);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('frododesk_finance_expected_expenses_v1');
    SharedPreferences.setMockInitialValues({
      ..._emptyPortfolioV3(),
      'frododesk_finance_expected_expenses_v1': raw!,
    });
    final store = FinanceStore();
    var refreshed = false;

    await FinanceLifecycleLoader(
      financeStore: store,
      refresh: () {
        expect(store.expectedExpenseAggregate.relationships, hasLength(1));
        expect(store.expectedExpenseAggregate.occurrences, hasLength(1));
        refreshed = true;
      },
    ).load();

    expect(refreshed, isTrue);
    expect(
      store.expectedExpenseAggregate.relationships.single.toJson(),
      aggregate.relationships.single.toJson(),
    );
    expect(
      store.expectedExpenseAggregate.occurrences.single.toJson(),
      aggregate.occurrences.single.toJson(),
    );
    expect(
      store.expectedExpenseAggregate.occurrences.single.resolvedEconomicFactId,
      'economic_fact_resolved',
    );
  });

  test('corrupt lifecycle load fails without replacing prior memory', () async {
    SharedPreferences.setMockInitialValues({
      ..._emptyPortfolioV3(),
      'frododesk_finance_expected_expenses_v1': '{broken',
    });
    final initial = _aggregate();
    final store = FinanceStore(initialExpectedExpenseAggregate: initial);
    var notifications = 0;
    store.addListener(() => notifications++);

    await expectLater(
      FinanceLifecycleLoader(financeStore: store, refresh: () {}).load(),
      throwsFormatException,
    );

    expect(store.expectedExpenseAggregate, same(initial));
    expect(notifications, 0);
  });

  test('valid save persists before publishing and notifies once', () async {
    late FinanceStore store;
    final initial = ExpectedExpenseAggregate.empty();
    final candidate = _aggregate();
    var writeObservedOldMemory = false;
    final persistence = ExpectedExpensePersistence(
      saveVerified: (_, value) async {
        writeObservedOldMemory = identical(
          store.expectedExpenseAggregate,
          initial,
        );
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    );
    store = FinanceStore(
      initialExpectedExpenseAggregate: initial,
      expectedExpensePersistence: persistence,
    );
    var notifications = 0;
    store.addListener(() => notifications++);

    expect(await store.saveExpectedExpenseAggregate(candidate), isTrue);

    expect(writeObservedOldMemory, isTrue);
    expect(store.expectedExpenseAggregate, same(candidate));
    expect(notifications, 1);
  });

  test('write and read-back failures leave memory unchanged', () async {
    for (final verification in const [
      PersistenceWriteVerification(backendAccepted: false, readBack: null),
      PersistenceWriteVerification(backendAccepted: true, readBack: null),
      PersistenceWriteVerification(
        backendAccepted: true,
        readBack: 'different',
      ),
    ]) {
      final initial = _aggregate();
      final store = FinanceStore(
        initialExpectedExpenseAggregate: initial,
        expectedExpensePersistence: ExpectedExpensePersistence(
          saveVerified: (_, _) async => verification,
        ),
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(
        store.saveExpectedExpenseAggregate(
          ExpectedExpenseAggregate(relationships: [_relationship('other')]),
        ),
        throwsStateError,
      );

      expect(store.expectedExpenseAggregate, same(initial));
      expect(notifications, 0);
    }
  });

  test(
    'retrying an identical candidate does not duplicate or renotify',
    () async {
      final candidate = _aggregate();
      final store = FinanceStore();
      var notifications = 0;
      store.addListener(() => notifications++);

      expect(await store.saveExpectedExpenseAggregate(candidate), isTrue);
      expect(await store.saveExpectedExpenseAggregate(candidate), isFalse);

      expect(store.expectedExpenseAggregate.relationships, hasLength(1));
      expect(store.expectedExpenseAggregate.occurrences, hasLength(1));
      expect(notifications, 1);
    },
  );

  test('runtime state cannot be mutated through its public collections', () {
    final store = FinanceStore(initialExpectedExpenseAggregate: _aggregate());

    expect(
      () => store.expectedExpenseAggregate.relationships.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => store.expectedExpenseAggregate.occurrences.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'aggregate save has no economic or recurring forecast effects',
    () async {
      final store = FinanceStore();

      await store.saveExpectedExpenseAggregate(_aggregate());

      expect(store.balances, isEmpty);
      expect(store.transactions, isEmpty);
      expect(store.funds, isEmpty);
      expect(store.assetMovements, isEmpty);
      expect(store.recurringItems, isEmpty);
      expect(store.itemsForProjectionMonth(DateTime(2026, 10)), isEmpty);
    },
  );
}

Map<String, Object> _emptyPortfolioV3() => {
  'frododesk_finance_portfolio_v3': jsonEncode({
    'version': 3,
    'balances': const [],
    'funds': const [],
    'assetMovements': const [],
    'transactions': const [],
    'fundTransactions': const [],
    'linkedItems': const [],
  }),
};

ExpectedExpenseAggregate _aggregate({bool resolved = false}) =>
    ExpectedExpenseAggregate(
      relationships: [_relationship('relationship_1')],
      occurrences: [
        _occurrence(
          status: resolved
              ? ExpectedExpenseOccurrenceStatus.resolved
              : ExpectedExpenseOccurrenceStatus.pending,
          resolvedEconomicFactId: resolved ? 'economic_fact_resolved' : null,
        ),
      ],
    );

ExpenseRelationship _relationship(String id) => ExpenseRelationship(
  relationshipId: id,
  service: 'Acqua',
  provider: 'Hera',
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.custom,
    customInterval: 2,
    customIntervalUnit: 'months',
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance_matteo',
  ),
);

ExpectedExpenseOccurrence _occurrence({
  ExpectedExpenseOccurrenceStatus status =
      ExpectedExpenseOccurrenceStatus.pending,
  String? resolvedEconomicFactId,
}) => ExpectedExpenseOccurrence(
  occurrenceId: 'occurrence_1',
  relationshipId: 'relationship_1',
  status: status,
  expectedIssueDate: DateTime(2026, 10, 23),
  expectedIssueDateSource: ExpectedExpenseDateSource.explicit,
  expectedAmount: 59.63,
  estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
  evidenceEconomicFactIds: const ['economic_fact_1'],
  confidence: ExpenseEstimateConfidence.low,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance_matteo',
  ),
  expectedSubject: FinanceSubject.matteo,
  resolvedEconomicFactId: resolvedEconomicFactId,
);
