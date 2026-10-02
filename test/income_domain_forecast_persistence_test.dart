import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/income_forecast_reader.dart';
import 'package:frododesk/logic/finance/income_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/balance_posting_mode.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/income.dart';
import 'package:frododesk/models/projected_expense_cycle.dart';

void main() {
  test(
    'domain validates stable structural identities and nullable balance',
    () {
      final relationship = _relationship(destinationBalanceId: null);
      final occurrence = _occurrence();
      final aggregate = IncomeAggregate(
        relationships: [relationship],
        occurrences: [occurrence],
        customCategories: [
          IncomeCustomCategory(id: 'custom:1', label: 'Collaborazione'),
        ],
      );
      expect(relationship.destinationBalanceId, isNull);
      expect(
        occurrence.structuralIdentity,
        'income-cycle:relationship:salary#1',
      );
      expect(aggregate.customCategories.single.label, 'Collaborazione');
      expect(
        () => IncomeAggregate(relationships: [relationship, relationship]),
        throwsArgumentError,
      );
    },
  );

  test(
    'persistence round-trip, missing, corrupt and unsupported payload',
    () async {
      String? stored;
      final persistence = IncomePersistence(
        load: (_) async => stored,
        save: (_, value) async {
          stored = value;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: stored,
          );
        },
      );
      expect((await persistence.load()).relationships, isEmpty);
      final aggregate = IncomeAggregate(
        relationships: [_relationship()],
        occurrences: [_occurrence()],
      );
      expect((await persistence.write(aggregate)).isSuccess, isTrue);
      final loaded = await persistence.load();
      expect(loaded.relationships.single.relationshipId, 'relationship:salary');
      stored = '{broken';
      expect(persistence.load(), throwsFormatException);
      stored = jsonEncode({'version': 99});
      expect(persistence.load(), throwsFormatException);
    },
  );

  test(
    'verified persistence rejects missing and mismatched read-back',
    () async {
      final missing = IncomePersistence(
      save: (_, _) async => const PersistenceWriteVerification(
          backendAccepted: true,
          readBack: null,
        ),
      );
      expect(
        (await missing.write(IncomeAggregate.empty())).failure,
        IncomeWriteFailure.missingReadBack,
      );
      final mismatch = IncomePersistence(
      save: (_, _) async => const PersistenceWriteVerification(
          backendAccepted: true,
          readBack: '{}',
        ),
      );
      expect(
        (await mismatch.write(IncomeAggregate.empty())).failure,
        IncomeWriteFailure.mismatchedReadBack,
      );
    },
  );

  test(
    'forecast is idempotent, history-aware and excludes resolved cycles',
    () {
      final historical = IncomeReconciliation(
        reconciliationId: 'reconciliation:history',
        economicFactId: 'fact:history',
        transactionId: 'transaction:history',
        relationshipId: 'relationship:salary',
        occurredAt: DateTime(2026, 1, 27),
        totalAmount: 5000,
        subject: FinanceSubject.matteo,
        destinationBalanceId: 'bank',
        postingMode: _historicalPosting,
        allocations: [
          IncomeReconciliationAllocation(
            componentId: 'ordinary',
            kind: IncomeComponentKind.ordinary,
            label: 'Stipendio ordinario',
            amount: 1000,
          ),
          IncomeReconciliationAllocation(
            componentId: '730',
            kind: IncomeComponentKind.taxRefund730,
            label: 'Rimborso 730',
            amount: 4000,
          ),
        ],
      );
      final aggregate = IncomeAggregate(
        relationships: [_relationship(useHistory: true)],
        occurrences: [
          ExpectedIncomeOccurrence(
            occurrenceId: 'resolved',
            relationshipId: 'relationship:salary',
            cycleSequence: 1,
            expectedDate: DateTime(2026, 1, 27),
            expectedAmount: 1000,
            status: ExpectedIncomeStatus.resolved,
            provenance: IncomeProvenance.userEntered,
            knowledge: IncomeKnowledge.known,
            reconciliationIds: const ['reconciliation:history'],
          ),
        ],
        reconciliations: [historical],
      );
      final horizon = ExpenseProjectionHorizon(
        start: DateTime(2027, 1),
        end: DateTime(2027, 1, 31),
      );
      final first = const IncomeForecastReader().read(
        aggregate: aggregate,
        horizon: horizon,
      );
      final second = const IncomeForecastReader().read(
        aggregate: aggregate,
        horizon: horizon,
      );
      expect(first.items, hasLength(1));
      expect(first.items.single.amount, 1000);
      expect(
        first.items.single.provenance,
        IncomeProvenance.previousYearPeriod,
      );
      expect(first.items.single.evidenceEconomicFactIds, ['fact:history']);
      expect(second.items.single.identity, first.items.single.identity);
    },
  );
}

const _historicalPosting =
    // Kept explicit: past facts must never mutate the current balance.
    BalancePostingMode.alreadyIncludedInCurrentBalance;

IncomeRelationship _relationship({
  String? destinationBalanceId = 'bank',
  bool useHistory = false,
}) => IncomeRelationship(
  relationshipId: 'relationship:salary',
  label: 'Stipendio',
  category: IncomeCategoryKind.salary,
  subject: FinanceSubject.matteo,
  destinationBalanceId: destinationBalanceId,
  expectedOrdinaryAmount: 1000,
  periodicity: IncomePeriodicity.monthly,
  firstExpectedDate: DateTime(2026, 1, 27),
  historyBasedForecastEnabled: useHistory,
);

ExpectedIncomeOccurrence _occurrence() => ExpectedIncomeOccurrence(
  occurrenceId: 'occurrence:salary:1',
  relationshipId: 'relationship:salary',
  cycleSequence: 1,
  expectedDate: DateTime(2026, 1, 27),
  expectedAmount: 1000,
  provenance: IncomeProvenance.userEntered,
  knowledge: IncomeKnowledge.known,
);
