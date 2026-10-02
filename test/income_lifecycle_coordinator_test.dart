import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_portfolio_v3_writer.dart';
import 'package:frododesk/logic/finance/income_lifecycle_coordinator.dart';
import 'package:frododesk/logic/finance/income_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/balance_posting_mode.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/income.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('real composite credit posts once and retry is idempotent', () async {
    final harness = _Harness();
    final request = harness.request(
      operationId: 'salary-composite',
      amount: 5100,
      allocations: [
        harness.part('ordinary', IncomeComponentKind.ordinary, 1000),
        harness.part('730', IncomeComponentKind.taxRefund730, 4000),
        harness.part('other', IncomeComponentKind.other, 100),
      ],
    );
    final first = await harness.coordinator.recordCredit(request);
    final retry = await harness.coordinator.recordCredit(request);
    expect(first.economicFactId, retry.economicFactId);
    expect(harness.store.transactions, hasLength(1));
    expect(harness.store.balances.single.currentAmount, 6100);
    expect(harness.store.incomeAggregate.reconciliations, hasLength(1));
    expect(
      first.allocations
          .where((item) => item.contributesToOrdinaryBaseline)
          .single
          .amount,
      1000,
    );
  });

  test(
    'historical credit and correction never alter current balance',
    () async {
      final harness = _Harness();
      final recorded = await harness.coordinator.recordCredit(
        harness.request(
          operationId: 'historical',
          amount: 1000,
          postingMode: BalancePostingMode.alreadyIncludedInCurrentBalance,
        ),
      );
      expect(harness.store.balances.single.currentAmount, 1000);
      final corrected = await harness.coordinator.correctCredit(
        reconciliationId: recorded.reconciliationId,
        occurredAt: DateTime(2026, 2, 2),
        totalAmount: 1200,
        subject: FinanceSubject.chiara,
        destinationBalanceId: 'bank',
        payer: 'Datore corretto',
        allocations: [
          harness.part('corrected', IncomeComponentKind.productionBonus, 1200),
        ],
      );
      expect(
        corrected.postingMode,
        BalancePostingMode.alreadyIncludedInCurrentBalance,
      );
      expect(harness.store.balances.single.currentAmount, 1000);
      expect(harness.store.transactions, hasLength(1));
      expect(harness.store.transactions.single.amount, 1200);
      expect(harness.store.transactions.single.subject, FinanceSubject.chiara);
    },
  );

  test(
    'multiple credits partially then fully resolve one salary occurrence',
    () async {
      final harness = _Harness(withOccurrence: true);
      await harness.coordinator.recordCredit(
        harness.request(
          operationId: 'advance',
          amount: 400,
          occurrenceId: 'occurrence:1',
        ),
      );
      expect(
        harness.store.incomeAggregate.occurrences.single.status,
        ExpectedIncomeStatus.partiallyReconciled,
      );
      await harness.coordinator.recordCredit(
        harness.request(
          operationId: 'balance',
          amount: 600,
          occurrenceId: 'occurrence:1',
          kind: IncomeComponentKind.thirteenth,
        ),
      );
      expect(
        harness.store.incomeAggregate.occurrences.single.status,
        ExpectedIncomeStatus.resolved,
      );
      expect(harness.store.transactions, hasLength(2));
      expect(harness.store.balances.single.currentAmount, 2000);
    },
  );

  test(
    'real correction adjusts amount and account without duplicate facts',
    () async {
      final harness = _Harness(twoBalances: true);
      final recorded = await harness.coordinator.recordCredit(
        harness.request(operationId: 'correct-real', amount: 500),
      );
      await harness.coordinator.correctCredit(
        reconciliationId: recorded.reconciliationId,
        occurredAt: DateTime(2026, 12, 31),
        totalAmount: 700,
        subject: FinanceSubject.matteo,
        destinationBalanceId: 'second',
        allocations: [
          harness.part('fourteenth', IncomeComponentKind.fourteenth, 700),
        ],
      );
      expect(harness.store.transactions, hasLength(1));
      expect(harness.store.balances.first.currentAmount, 1000);
      expect(harness.store.balances.last.currentAmount, 1700);
      expect(harness.store.transactions.single.date, DateTime(2026, 12, 31));
    },
  );
}

class _Harness {
  late final FinanceStore store;
  late final IncomeLifecycleCoordinator coordinator;
  String? incomeRaw;
  String? portfolioRaw;

  _Harness({bool withOccurrence = false, bool twoBalances = false}) {
    final relationship = IncomeRelationship(
      relationshipId: 'relationship:salary',
      label: 'Stipendio',
      category: IncomeCategoryKind.salary,
      subject: FinanceSubject.matteo,
      destinationBalanceId: 'bank',
      expectedOrdinaryAmount: 1000,
      periodicity: IncomePeriodicity.monthly,
      firstExpectedDate: DateTime(2026, 12, 1),
    );
    store = FinanceStore(
      initialBalances: [_balance('bank'), if (twoBalances) _balance('second')],
      initialIncomeAggregate: IncomeAggregate(
        relationships: [relationship],
        occurrences: [
          if (withOccurrence)
            ExpectedIncomeOccurrence(
              occurrenceId: 'occurrence:1',
              relationshipId: relationship.relationshipId,
              cycleSequence: 1,
              expectedDate: DateTime(2026, 12, 1),
              expectedAmount: 1000,
              provenance: IncomeProvenance.userEntered,
              knowledge: IncomeKnowledge.known,
            ),
        ],
      ),
      incomePersistence: IncomePersistence(
        load: (_) async => incomeRaw,
        save: (_, value) async {
          incomeRaw = value;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      ),
      portfolioV3Writer: FinancePortfolioV3Writer(
        saveVerified: (_, value) async {
          portfolioRaw = value;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      ),
    );
    coordinator = IncomeLifecycleCoordinator(financeStore: store);
  }

  IncomeCreditRequest request({
    required String operationId,
    required double amount,
    String? occurrenceId,
    IncomeComponentKind kind = IncomeComponentKind.ordinary,
    BalancePostingMode postingMode = BalancePostingMode.affectsCurrentBalance,
    List<IncomeReconciliationAllocation>? allocations,
  }) => IncomeCreditRequest(
    operationId: operationId,
    relationshipId: 'relationship:salary',
    occurredAt: DateTime(2026, 12, 1),
    totalAmount: amount,
    subject: FinanceSubject.matteo,
    payer: 'Datore',
    destinationBalanceId: 'bank',
    postingMode: postingMode,
    allocations:
        allocations ??
        [part(operationId, kind, amount, occurrenceId: occurrenceId)],
  );

  IncomeReconciliationAllocation part(
    String id,
    IncomeComponentKind kind,
    double amount, {
    String? occurrenceId,
  }) => IncomeReconciliationAllocation(
    componentId: 'component:$id',
    kind: kind,
    label: kind.name,
    amount: amount,
    occurrenceId: occurrenceId,
  );
}

FinanceBalance _balance(String id) => FinanceBalance(
  personId: 'matteo',
  balanceId: id,
  name: id,
  initialAmount: 1000,
  currentAmount: 1000,
  updatedAt: DateTime(2026, 1, 1),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);
