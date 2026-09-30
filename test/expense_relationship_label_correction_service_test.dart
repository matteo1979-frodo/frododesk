import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/documentary_obligation_persistence.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/expense_relationship_label_correction_service.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/documentary_obligation.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/manual_payment_preference.dart';
import 'package:frododesk/models/planned_economic_impact.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('previews a safe update without mutating the aggregate', () {
    final original = _relationship();
    final aggregate = ExpectedExpenseAggregate(
      relationships: [original],
      occurrences: [_occurrence()],
    );
    final service = ExpenseRelationshipLabelCorrectionService(
      financeStore: FinanceStore(initialExpectedExpenseAggregate: aggregate),
    );

    final preview = service.preview(_intent(original));

    expect(
      preview.classification,
      ExpenseRelationshipLabelCorrectionClassification.safeUpdate,
    );
    expect(preview.candidate?.service, 'TARI');
    expect(aggregate.relationships.single.service, 'TARI 2026');
    expect(aggregate.occurrences.single.toJson(), _occurrence().toJson());
  });

  test('conflicts when the expected relationship snapshot is stale', () {
    final original = _relationship();
    final current = original.copyWith(provider: 'Provider aggiornato');
    final service = ExpenseRelationshipLabelCorrectionService(
      financeStore: FinanceStore(
        initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
          relationships: [current],
        ),
      ),
    );

    final preview = service.preview(_intent(original));

    expect(
      preview.classification,
      ExpenseRelationshipLabelCorrectionClassification.conflict,
    );
  });

  test('missing and duplicate relationship identities are conflicts', () {
    final original = _relationship();
    final missing = ExpenseRelationshipLabelCorrectionService(
      financeStore: FinanceStore(),
    ).preview(_intent(original));
    final duplicate = ExpenseRelationshipLabelCorrectionService(
      financeStore: FinanceStore(
        initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
          relationships: [original, original],
        ),
      ),
    ).preview(_intent(original));

    expect(
      missing.classification,
      ExpenseRelationshipLabelCorrectionClassification.conflict,
    );
    expect(
      duplicate.classification,
      ExpenseRelationshipLabelCorrectionClassification.conflict,
    );
  });

  test(
    'applies through verified persistence and preserves occurrences',
    () async {
      final original = _relationship();
      final otherRelationship = _otherRelationship();
      final occurrences = [
        _occurrence(),
        _occurrence(
          id: 'occurrence_other_1',
          relationshipId: otherRelationship.relationshipId,
          sequence: 1,
          period: ExpectedDocumentPeriod(year: 2026, month: 11),
          amount: 81.25,
          sourceDocumentaryObligationId: 'document_other_2026',
          evidenceEconomicFactIds: const ['fact_other'],
        ),
      ];
      final documentary = DocumentaryObligationAggregate(
        obligations: [
          DocumentaryObligation(
            obligationId: 'document_tari_2026',
            title: 'Titolo storico 2026',
            totalAmount: 173,
            relationshipId: original.relationshipId,
            cycleSequence: 1,
          ),
        ],
      );
      final documentaryBefore = _documentaryFingerprint(documentary);
      final occurrencesBefore = _occurrencesFingerprint(occurrences);
      final otherRelationshipBefore = jsonEncode(otherRelationship.toJson());
      String? stored;
      final store = FinanceStore(
        initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
          relationships: [original, otherRelationship],
          occurrences: occurrences,
        ),
        initialDocumentaryObligationAggregate: documentary,
        expectedExpensePersistence: ExpectedExpensePersistence(
          load: (_) async => stored,
          saveVerified: (_, value) async {
            stored = value;
            return PersistenceWriteVerification(
              backendAccepted: true,
              readBack: value,
            );
          },
        ),
      );
      final service = ExpenseRelationshipLabelCorrectionService(
        financeStore: store,
      );

      final result = await service.apply(_intent(original));

      expect(
        result.status,
        ExpenseRelationshipLabelCorrectionApplyStatus.applied,
      );
      expect(
        store.expectedExpenseAggregate.relationships.first.toJson(),
        original
            .copyWith(
              service: 'TARI',
              cycleLabelPolicy:
                  ExpenseRelationshipCycleLabelPolicy
                      .stableNameWithTargetYear,
            )
            .toJson(),
      );
      expect(
        jsonEncode(
          store.expectedExpenseAggregate.relationships[1].toJson(),
        ),
        otherRelationshipBefore,
      );
      expect(
        _occurrencesFingerprint(store.expectedExpenseAggregate.occurrences),
        occurrencesBefore,
      );
      expect(
        _documentaryFingerprint(store.documentaryObligationAggregate),
        documentaryBefore,
      );
      expect(stored, isNotNull);
    },
  );

  test('retry after success is an idempotent no-op', () async {
    final original = _relationship();
    final corrected = original.copyWith(
      service: 'TARI',
      cycleLabelPolicy:
          ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear,
    );
    final service = ExpenseRelationshipLabelCorrectionService(
      financeStore: FinanceStore(
        initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
          relationships: [corrected],
        ),
      ),
    );

    final result = await service.apply(_intent(original));

    expect(result.status, ExpenseRelationshipLabelCorrectionApplyStatus.noOp);
  });

  test('writer failure leaves the in-memory relationship unchanged', () async {
    final original = _relationship();
    final store = FinanceStore(
      initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
        relationships: [original],
      ),
      expectedExpensePersistence: ExpectedExpensePersistence(
        saveVerified: (_, value) async => PersistenceWriteVerification(
          backendAccepted: false,
          readBack: null,
        ),
      ),
    );
    final service = ExpenseRelationshipLabelCorrectionService(
      financeStore: store,
    );

    final result = await service.apply(_intent(original));

    expect(result.status, ExpenseRelationshipLabelCorrectionApplyStatus.failed);
    expect(
      store.expectedExpenseAggregate.relationships.single.toJson(),
      original.toJson(),
    );
  });

  test(
    'read-back mismatch leaves the in-memory relationship unchanged',
    () async {
      final original = _relationship();
      final store = FinanceStore(
        initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
          relationships: [original],
        ),
        expectedExpensePersistence: ExpectedExpensePersistence(
          saveVerified: (_, value) async => PersistenceWriteVerification(
            backendAccepted: true,
            readBack: '{}',
          ),
        ),
      );

      final result = await ExpenseRelationshipLabelCorrectionService(
        financeStore: store,
      ).apply(_intent(original));

      expect(
        result.status,
        ExpenseRelationshipLabelCorrectionApplyStatus.failed,
      );
      expect(
        store.expectedExpenseAggregate.relationships.single.toJson(),
        original.toJson(),
      );
    },
  );

  test(
    'reload after an accepted but unpublished write is an idempotent no-op',
    () async {
      final original = _relationship();
      String? stored;
      var writes = 0;
      final persistence = ExpectedExpensePersistence(
        load: (_) async => stored,
        saveVerified: (_, value) async {
          writes++;
          stored = value;
          return const PersistenceWriteVerification(
            backendAccepted: true,
            readBack: '{}',
          );
        },
      );
      final firstStore = FinanceStore(
        initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
          relationships: [original],
        ),
        expectedExpensePersistence: persistence,
      );

      final firstResult = await ExpenseRelationshipLabelCorrectionService(
        financeStore: firstStore,
      ).apply(_intent(original));
      expect(
        firstResult.status,
        ExpenseRelationshipLabelCorrectionApplyStatus.failed,
      );
      expect(
        firstStore.expectedExpenseAggregate.relationships.single.toJson(),
        original.toJson(),
      );
      expect(writes, 1);

      final loaded = await ExpectedExpensePersistence(
        load: (_) async => stored,
      ).load();
      final reloadedStore = FinanceStore(
        initialExpectedExpenseAggregate: loaded,
      );
      final retry = await ExpenseRelationshipLabelCorrectionService(
        financeStore: reloadedStore,
      ).apply(_intent(original));

      expect(retry.status, ExpenseRelationshipLabelCorrectionApplyStatus.noOp);
      expect(writes, 1);
      expect(
        reloadedStore.expectedExpenseAggregate.relationships.single.service,
        'TARI',
      );
    },
  );
}

ExpenseRelationshipLabelCorrectionIntent _intent(
  ExpenseRelationship original,
) => ExpenseRelationshipLabelCorrectionIntent(
  relationshipId: original.relationshipId,
  expectedCurrent: original,
  targetService: 'TARI',
  targetPolicy: ExpenseRelationshipCycleLabelPolicy.stableNameWithTargetYear,
);

ExpenseRelationship _relationship() => ExpenseRelationship(
  relationshipId: 'relationship_tari',
  service: 'TARI 2026',
  provider: 'Comune',
  subject: FinanceSubject.matteo,
  status: ExpenseRelationshipStatus.active,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.yearly,
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.manual,
    expectedBalanceId: 'balance_tari',
  ),
  paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
  manualPaymentPreference: ManualPaymentPreference(
    preferredStartDayOfMonth: 12,
  ),
);

ExpenseRelationship _otherRelationship() => ExpenseRelationship(
  relationshipId: 'relationship_other',
  service: 'Servizio distinto',
  provider: 'Altro provider',
  subject: FinanceSubject.chiara,
  status: ExpenseRelationshipStatus.terminated,
  periodicity: ExpenseRelationshipPeriodicity(
    type: FinanceRecurringType.custom,
    customInterval: 2,
    customIntervalUnit: 'months',
  ),
  paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
    method: FinancePaymentMethod.rid,
    expectedBalanceId: 'balance_other',
  ),
  paymentExecutionMode: PaymentExecutionMode.automatic,
);

ExpectedExpenseOccurrence _occurrence({
  String id = 'occurrence_tari_2',
  String relationshipId = 'relationship_tari',
  int sequence = 2,
  ExpectedDocumentPeriod? period,
  double amount = 173,
  String sourceDocumentaryObligationId = 'document_tari_2026',
  List<String> evidenceEconomicFactIds = const ['fact_tari_2026'],
}) {
  final effectivePeriod =
      period ?? ExpectedDocumentPeriod(year: 2027, month: 3);
  return ExpectedExpenseOccurrence(
    occurrenceId: id,
    relationshipId: relationshipId,
    cycleSequence: sequence,
    expectedPeriod: effectivePeriod,
    status: ExpectedExpenseOccurrenceStatus.pending,
    expectedAmount: amount,
    estimationMethod: ExpenseEstimationMethod.documentaryObligation,
    sourceDocumentaryObligationId: sourceDocumentaryObligationId,
    evidenceEconomicFactIds: evidenceEconomicFactIds,
    confidence: ExpenseEstimateConfidence.high,
    provisional: true,
    expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
      expectedBalanceId: 'balance_expected',
    ),
    paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
    expectedSubject: FinanceSubject.matteo,
    plannedEconomicImpact: PlannedEconomicImpact(
      start: DateTime(effectivePeriod.year, effectivePeriod.month, 10),
      end: DateTime(effectivePeriod.year, effectivePeriod.month, 12),
      origin: PlannedEconomicImpactOrigin.userDecision,
    ),
  );
}

String _occurrencesFingerprint(Iterable<ExpectedExpenseOccurrence> values) =>
    jsonEncode(values.map((item) => item.toJson()).toList());

String _documentaryFingerprint(DocumentaryObligationAggregate aggregate) =>
    jsonEncode({
      'obligations': aggregate.obligations.map((item) => item.toJson()).toList(),
      'expectedDocuments': aggregate.expectedDocuments
          .map((item) => item.toJson())
          .toList(),
    });
