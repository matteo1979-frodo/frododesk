import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/documentary_forecast_reconciliation_service.dart';
import 'package:frododesk/logic/finance/documentary_obligation_persistence.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/documentary_obligation.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  group('DocumentaryForecastReconciliationService', () {
    test('SAFE CREATE derives the native documentary seed contract', () {
      final harness = _Harness();

      final preview = harness.service.preview(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );

      expect(
        preview.classification,
        DocumentaryForecastReconciliationClassification.safeCreate,
      );
      expect(preview.source!.obligationId, 'document-1');
      expect(preview.target!.expectedPeriod.year, 2027);
      expect(preview.target!.expectedPeriod.month, 3);
      expect(preview.targetOccurrenceExists, isFalse);
      expect(preview.candidate!.toJson(), {
        'occurrenceId': 'documentary_annual-tax_2',
        'relationshipId': 'annual-tax',
        'cycleSequence': 2,
        'cycleAnchor': null,
        'expectedPeriod': {'year': 2027, 'month': 3},
        'status': 'pending',
        'knowledgeState': 'forecast',
        'knowledgeSource': 'legacyUnspecified',
        'expectedIssueDate': null,
        'expectedIssueDateSource': null,
        'expectedDueDate': null,
        'expectedDueDateSource': null,
        'expectedDueDateCertainty': null,
        'expectedPaymentWindow': null,
        'plannedEconomicImpact': null,
        'expectedAmount': 173.0,
        'estimationMethod': 'documentaryObligation',
        'sourceDocumentaryObligationId': 'document-1',
        'evidenceEconomicFactIds': <String>[],
        'confidence': 'medium',
        'provisional': true,
        'expectedPaymentConfiguration': {
          'method': 'manual',
          'expectedBalanceId': null,
        },
        'paymentExecutionMode': 'unknown',
        'expectedSubject': 'matteo',
        'resolvedEconomicFactId': null,
      });
    });

    test('equivalent seed is NO-OP', () {
      final source = _Harness();
      final candidate = source.service
          .preview(relationshipId: 'annual-tax', cycleSequence: 2)
          .candidate!;
      final harness = _Harness(occurrences: [candidate]);

      final preview = harness.service.preview(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );

      expect(
        preview.classification,
        DocumentaryForecastReconciliationClassification.noOp,
      );
    });

    test('incompatible target occurrence is CONFLICT', () {
      final harness = _Harness(
        occurrences: [_occurrence(amount: 181)],
      );
      expect(
        harness.service
            .preview(relationshipId: 'annual-tax', cycleSequence: 2)
            .classification,
        DocumentaryForecastReconciliationClassification.conflict,
      );
    });

    test('deterministic occurrenceId collision is CONFLICT', () {
      final collision = _occurrence(
        relationshipId: 'other-tax',
        cycleSequence: 7,
        occurrenceId: 'documentary_annual-tax_2',
      );
      final harness = _Harness(
        relationships: [_relationship(), _relationship(id: 'other-tax')],
        occurrences: [collision],
      );
      final preview = harness.service.preview(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );
      expect(
        preview.classification,
        DocumentaryForecastReconciliationClassification.conflict,
      );
      expect(preview.reasons.join(' '), contains('occurrenceId deterministico'));
    });

    test('missing source is CONFLICT', () {
      final harness = _Harness(obligations: const []);
      expect(
        harness.service
            .preview(relationshipId: 'annual-tax', cycleSequence: 2)
            .classification,
        DocumentaryForecastReconciliationClassification.conflict,
      );
    });

    test('multiple immediately preceding sources are CONFLICT', () {
      final harness = _Harness(
        obligations: [
          _obligation(),
          _obligation(id: 'document-1-duplicate'),
        ],
      );
      expect(
        harness.service
            .preview(relationshipId: 'annual-tax', cycleSequence: 2)
            .reasons
            .join(' '),
        contains('Più DocumentaryObligation sorgente'),
      );
    });

    test('non-immediately preceding source is not selected', () {
      final harness = _Harness(
        obligations: [_obligation(cycleSequence: 1)],
        targets: [_target(cycleSequence: 3)],
      );
      final preview = harness.service.preview(
        relationshipId: 'annual-tax',
        cycleSequence: 3,
      );
      expect(
        preview.classification,
        DocumentaryForecastReconciliationClassification.conflict,
      );
      expect(preview.source, isNull);
    });

    test('invalid amount is rejected by the domain before preview', () {
      expect(() => _obligation(amount: 0), throwsArgumentError);
      expect(() => _obligation(amount: double.nan), throwsArgumentError);
    });

    test('materialized or duplicate target is CONFLICT', () {
      final materialized = _target().materialize('document-2');
      expect(
        _Harness(targets: [materialized])
            .service
            .preview(relationshipId: 'annual-tax', cycleSequence: 2)
            .classification,
        DocumentaryForecastReconciliationClassification.conflict,
      );
      expect(
        _Harness(targets: [_target(), _target()])
            .service
            .preview(relationshipId: 'annual-tax', cycleSequence: 2)
            .classification,
        DocumentaryForecastReconciliationClassification.conflict,
      );
    });

    test('duplicate documentary cycle identity is CONFLICT', () {
      final harness = _Harness(
        obligations: [
          _obligation(),
          _obligation(id: 'document-1-duplicate'),
        ],
      );
      final preview = harness.service.preview(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );
      expect(preview.reasons.join(' '), contains('documentale duplicata'));
    });

    test('preview is read-only and emits no notification', () {
      final harness = _Harness();
      final expectedBefore = harness.store.expectedExpenseAggregate;
      final documentaryBefore = harness.store.documentaryObligationAggregate;
      var notifications = 0;
      harness.store.addListener(() => notifications++);

      harness.service.preview(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );

      expect(harness.store.expectedExpenseAggregate, same(expectedBefore));
      expect(
        harness.store.documentaryObligationAggregate,
        same(documentaryBefore),
      );
      expect(notifications, 0);
      expect(harness.writes, 0);
    });

    test('apply performs verified write and retry is idempotent', () async {
      final harness = _Harness();
      final balanceBefore = harness.store.balances.single.toJson();
      final transactionBefore = harness.store.transactions.single.toJson();

      final first = await harness.service.apply(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );
      final retry = await harness.service.apply(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );

      expect(first.status, DocumentaryForecastReconciliationApplyStatus.applied);
      expect(retry.status, DocumentaryForecastReconciliationApplyStatus.noOp);
      expect(harness.store.expectedExpenseAggregate.occurrences, hasLength(1));
      expect(harness.writes, 1);
      expect(harness.lastReadBackMatched, isTrue);
      expect(harness.store.balances.single.toJson(), balanceBefore);
      expect(harness.store.transactions.single.toJson(), transactionBefore);
    });

    test('apply rechecks changed preconditions and returns conflict', () async {
      final harness = _Harness();
      expect(
        harness.service
            .preview(relationshipId: 'annual-tax', cycleSequence: 2)
            .classification,
        DocumentaryForecastReconciliationClassification.safeCreate,
      );
      await harness.store.saveExpectedExpenseAggregate(
        ExpectedExpenseAggregate(
          relationships: [_relationship()],
          occurrences: [_occurrence(amount: 181)],
        ),
      );

      final result = await harness.service.apply(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );

      expect(result.status,
          DocumentaryForecastReconciliationApplyStatus.conflict);
      expect(harness.store.expectedExpenseAggregate.occurrences.single.expectedAmount,
          181);
    });

    test('failed verified read-back leaves memory unchanged', () async {
      final initial = ExpectedExpenseAggregate(
        relationships: [_relationship()],
      );
      final store = FinanceStore(
        initialExpectedExpenseAggregate: initial,
        initialDocumentaryObligationAggregate: _documentary(),
        expectedExpensePersistence: ExpectedExpensePersistence(
          saveVerified: (_, _) async => const PersistenceWriteVerification(
            backendAccepted: true,
            readBack: 'different',
          ),
        ),
      );
      final result = await DocumentaryForecastReconciliationService(
        financeStore: store,
      ).apply(relationshipId: 'annual-tax', cycleSequence: 2);

      expect(result.status,
          DocumentaryForecastReconciliationApplyStatus.writerFailed);
      expect(store.expectedExpenseAggregate, same(initial));
      expect(store.expectedExpenseAggregate.occurrences, isEmpty);
    });

    test('candidate identity is compatible with D2.2 precedence', () {
      final preview = _Harness().service.preview(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
      );
      expect(preview.cycleIdentity, 'annual-tax#2');
      expect(preview.candidate!.relationshipId, 'annual-tax');
      expect(preview.candidate!.cycleSequence, 2);
    });
  });
}

class _Harness {
  late final FinanceStore store;
  late final DocumentaryForecastReconciliationService service;
  int writes = 0;
  bool lastReadBackMatched = false;

  _Harness({
    List<ExpenseRelationship>? relationships,
    List<ExpectedExpenseOccurrence> occurrences = const [],
    List<DocumentaryObligation>? obligations,
    List<ExpectedDocumentCycle>? targets,
  }) {
    final expected = ExpectedExpenseAggregate(
      relationships: relationships ?? [_relationship()],
      occurrences: occurrences,
    );
    store = FinanceStore(
      initialBalances: [_balance()],
      initialTransactions: [_transaction()],
      initialExpectedExpenseAggregate: expected,
      initialDocumentaryObligationAggregate: DocumentaryObligationAggregate(
        obligations: obligations ?? [_obligation()],
        expectedDocuments: targets ?? [_target()],
      ),
      expectedExpensePersistence: ExpectedExpensePersistence(
        saveVerified: (_, value) async {
          writes++;
          lastReadBackMatched = true;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      ),
    );
    service = DocumentaryForecastReconciliationService(financeStore: store);
  }
}

ExpenseRelationship _relationship({String id = 'annual-tax'}) =>
    ExpenseRelationship(
      relationshipId: id,
      service: 'Tributo',
      provider: 'Ente',
      subject: FinanceSubject.matteo,
      status: ExpenseRelationshipStatus.active,
      periodicity: ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.yearly,
      ),
      paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.manual,
      ),
    );

DocumentaryObligation _obligation({
  String id = 'document-1',
  int cycleSequence = 1,
  double amount = 173,
}) => DocumentaryObligation(
  obligationId: id,
  title: 'Documento precedente',
  totalAmount: amount,
  relationshipId: 'annual-tax',
  cycleSequence: cycleSequence,
);

ExpectedDocumentCycle _target({int cycleSequence = 2}) => ExpectedDocumentCycle(
  relationshipId: 'annual-tax',
  cycleSequence: cycleSequence,
  expectedPeriod: ExpectedDocumentPeriod(year: 2027, month: 3),
);

DocumentaryObligationAggregate _documentary() =>
    DocumentaryObligationAggregate(
      obligations: [_obligation()],
      expectedDocuments: [_target()],
    );

ExpectedExpenseOccurrence _occurrence({
  String relationshipId = 'annual-tax',
  int cycleSequence = 2,
  String occurrenceId = 'documentary_annual-tax_2',
  double amount = 173,
}) => ExpectedExpenseOccurrence(
  occurrenceId: occurrenceId,
  relationshipId: relationshipId,
  cycleSequence: cycleSequence,
  expectedPeriod: ExpectedDocumentPeriod(year: 2027, month: 3),
  status: ExpectedExpenseOccurrenceStatus.pending,
  expectedAmount: amount,
  estimationMethod: ExpenseEstimationMethod.documentaryObligation,
  sourceDocumentaryObligationId: 'document-1',
  confidence: ExpenseEstimateConfidence.medium,
  provisional: true,
  expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.manual,
  ),
  paymentExecutionMode: PaymentExecutionMode.unknown,
  expectedSubject: FinanceSubject.matteo,
);

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'bank',
  name: 'Conto',
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

FinanceTransaction _transaction() => FinanceTransaction(
  id: 'transaction-existing',
  balanceId: 'bank',
  amount: 10,
  date: DateTime(2026, 1, 1),
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: 'Esistente',
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: 'fact-existing',
);
