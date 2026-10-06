import 'dart:convert';

import '../../models/documentary_obligation.dart';
import '../../models/finance_transaction.dart';
import '../../models/economic_operation_metadata.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../models/expense_relationship.dart';
import '../../stores/finance_store.dart';
import 'documentary_obligation_persistence.dart';
import 'expected_expense_persistence.dart';

enum DocumentaryObligationOutcome {
  applied,
  unchanged,
  missing,
  conflict,
  invalidState,
}

class DocumentaryObligationCoordinator {
  final FinanceStore financeStore;
  const DocumentaryObligationCoordinator({required this.financeStore});

  Future<DocumentaryObligationOutcome> register(
    DocumentaryObligation candidate,
  ) async {
    final identityMatches = financeStore
        .documentaryObligationAggregate
        .obligations
        .where((item) => _sameAuthoritativeIdentity(item, candidate))
        .toList();
    if (identityMatches.isNotEmpty) {
      return identityMatches.length == 1 &&
              _same(identityMatches.single.toJson(), candidate.toJson())
          ? DocumentaryObligationOutcome.unchanged
          : DocumentaryObligationOutcome.conflict;
    }
    final matches = financeStore.documentaryObligationAggregate.obligations
        .where((item) => item.obligationId == candidate.obligationId)
        .toList();
    if (matches.isNotEmpty &&
        !_same(matches.single.toJson(), candidate.toJson())) {
      return DocumentaryObligationOutcome.conflict;
    }
    final current = financeStore.documentaryObligationAggregate;
    final expectedIdentity =
        candidate.relationshipId != null && candidate.cycleSequence != null
        ? '${candidate.relationshipId}#${candidate.cycleSequence}'
        : null;
    final expected = expectedIdentity == null
        ? <ExpectedDocumentCycle>[]
        : current.expectedDocuments
              .where((item) => item.identity == expectedIdentity)
              .toList();
    if (expected.length > 1) return DocumentaryObligationOutcome.conflict;
    if (expected.isNotEmpty &&
        expected.single.materializedObligationId != null &&
        expected.single.materializedObligationId != candidate.obligationId) {
      return DocumentaryObligationOutcome.conflict;
    }
    final markerComplete =
        expected.isEmpty ||
        expected.single.materializedObligationId == candidate.obligationId;
    if (matches.isNotEmpty && markerComplete) {
      return DocumentaryObligationOutcome.unchanged;
    }
    await financeStore.saveDocumentaryObligationAggregate(
      DocumentaryObligationAggregate(
        obligations: [...current.obligations, if (matches.isEmpty) candidate],
        expectedDocuments: current.expectedDocuments
            .map(
              (item) => item.identity == expectedIdentity
                  ? item.materialize(candidate.obligationId)
                  : item,
            )
            .toList(),
      ),
    );
    return DocumentaryObligationOutcome.applied;
  }

  /// Registers one concrete document cycle and, when requested, its recurring
  /// continuity plus the next non-economic expected-document period.
  Future<DocumentaryObligationOutcome> registerRecurringDocument({
    required DocumentaryObligation obligation,
    required ExpenseRelationship relationship,
    ExpectedDocumentCycle? nextExpectedDocument,
  }) async {
    if (obligation.relationshipId != relationship.relationshipId ||
        obligation.cycleSequence == null ||
        (nextExpectedDocument != null &&
            (nextExpectedDocument.relationshipId !=
                    relationship.relationshipId ||
                nextExpectedDocument.cycleSequence <=
                    obligation.cycleSequence!))) {
      return DocumentaryObligationOutcome.invalidState;
    }
    final identityMatches = financeStore
        .documentaryObligationAggregate
        .obligations
        .where((item) => _sameAuthoritativeIdentity(item, obligation))
        .toList();
    if (identityMatches.isNotEmpty) {
      return identityMatches.length == 1 &&
              _same(identityMatches.single.toJson(), obligation.toJson())
          ? DocumentaryObligationOutcome.unchanged
          : DocumentaryObligationOutcome.conflict;
    }
    final economic = financeStore.expectedExpenseAggregate;
    final relationships = economic.relationships
        .where((item) => item.relationshipId == relationship.relationshipId)
        .toList();
    if (relationships.isNotEmpty &&
        !_same(relationships.single.toJson(), relationship.toJson())) {
      return DocumentaryObligationOutcome.conflict;
    }
    final seed = nextExpectedDocument == null
        ? null
        : ExpectedExpenseOccurrence(
            occurrenceId:
                'documentary_${relationship.relationshipId}_${nextExpectedDocument.cycleSequence}',
            relationshipId: relationship.relationshipId,
            cycleSequence: nextExpectedDocument.cycleSequence,
            expectedPeriod: nextExpectedDocument.expectedPeriod,
            status: ExpectedExpenseOccurrenceStatus.pending,
            expectedAmount: obligation.totalAmount,
            estimationMethod: ExpenseEstimationMethod.documentaryObligation,
            sourceDocumentaryObligationId: obligation.obligationId,
            confidence: ExpenseEstimateConfidence.medium,
            provisional: true,
            expectedPaymentConfiguration: relationship.paymentConfiguration,
            paymentExecutionMode: PaymentExecutionMode.unknown,
            expectedSubject: relationship.subject,
          );
    final seedMatches = seed == null
        ? <ExpectedExpenseOccurrence>[]
        : economic.occurrences
              .where(
                (item) =>
                    item.relationshipId == relationship.relationshipId &&
                    item.cycleSequence == seed.cycleSequence,
              )
              .toList();
    if (seedMatches.length > 1 ||
        (seedMatches.isNotEmpty &&
            !_same(seedMatches.single.toJson(), seed!.toJson()))) {
      return DocumentaryObligationOutcome.conflict;
    }
    final current = financeStore.documentaryObligationAggregate;
    final obligationMatches = current.obligations
        .where((item) => item.obligationId == obligation.obligationId)
        .toList();
    if (obligationMatches.isNotEmpty &&
        !_same(obligationMatches.single.toJson(), obligation.toJson())) {
      return DocumentaryObligationOutcome.conflict;
    }
    final expectedMatches = nextExpectedDocument == null
        ? <ExpectedDocumentCycle>[]
        : current.expectedDocuments
              .where((item) => item.identity == nextExpectedDocument.identity)
              .toList();
    if (expectedMatches.isNotEmpty &&
        !_same(
          expectedMatches.single.toJson(),
          nextExpectedDocument!.toJson(),
        )) {
      return DocumentaryObligationOutcome.conflict;
    }
    final currentCycleIdentity =
        '${obligation.relationshipId}#${obligation.cycleSequence}';
    final currentCycle = current.expectedDocuments
        .where((item) => item.identity == currentCycleIdentity)
        .toList();
    if (currentCycle.isNotEmpty &&
        currentCycle.single.materializedObligationId != null &&
        currentCycle.single.materializedObligationId !=
            obligation.obligationId) {
      return DocumentaryObligationOutcome.conflict;
    }
    final currentMarkerComplete =
        currentCycle.isEmpty ||
        currentCycle.single.materializedObligationId == obligation.obligationId;
    if (relationships.isEmpty || (seed != null && seedMatches.isEmpty)) {
      await financeStore.saveExpectedExpenseAggregate(
        ExpectedExpenseAggregate(
          relationships: [
            ...economic.relationships,
            if (relationships.isEmpty) relationship,
          ],
          occurrences: [
            ...economic.occurrences,
            if (seed != null && seedMatches.isEmpty) seed,
          ],
        ),
      );
    }
    if (obligationMatches.isNotEmpty &&
        (nextExpectedDocument == null || expectedMatches.isNotEmpty) &&
        currentMarkerComplete &&
        (seed == null || seedMatches.isNotEmpty)) {
      return DocumentaryObligationOutcome.unchanged;
    }
    await financeStore.saveDocumentaryObligationAggregate(
      DocumentaryObligationAggregate(
        obligations: [
          ...current.obligations,
          if (obligationMatches.isEmpty) obligation,
        ],
        expectedDocuments: [
          ...current.expectedDocuments.map(
            (item) => item.identity == currentCycleIdentity
                ? item.materialize(obligation.obligationId)
                : item,
          ),
          if (nextExpectedDocument != null && expectedMatches.isEmpty)
            nextExpectedDocument,
        ],
      ),
    );
    return DocumentaryObligationOutcome.applied;
  }

  Future<DocumentaryObligationOutcome> selectOption({
    required String obligationId,
    required String optionId,
  }) async {
    final current = _find(obligationId);
    if (current == null) return DocumentaryObligationOutcome.missing;
    if (current.selectedOptionId == optionId ||
        (current.options.length == 1 &&
            current.options.single.optionId == optionId)) {
      return DocumentaryObligationOutcome.unchanged;
    }
    if (current.selectedOptionId != null) {
      return DocumentaryObligationOutcome.conflict;
    }
    DocumentaryObligation candidate;
    try {
      candidate = current.selectOption(optionId);
    } catch (_) {
      return DocumentaryObligationOutcome.invalidState;
    }
    await _replace(candidate);
    return DocumentaryObligationOutcome.applied;
  }

  Future<DocumentaryObligationOutcome> correctDocument(
    DocumentaryObligation candidate,
  ) async {
    final current = _find(candidate.obligationId);
    if (current == null) return DocumentaryObligationOutcome.missing;
    if (current.relationshipId != candidate.relationshipId ||
        current.cycleSequence != candidate.cycleSequence) {
      return DocumentaryObligationOutcome.invalidState;
    }
    if (current.selectedOption?.installments.any((item) => item.isFulfilled) ==
            true &&
        jsonEncode(current.components.map((item) => item.toJson()).toList()) !=
            jsonEncode(
              candidate.components.map((item) => item.toJson()).toList(),
            )) {
      return DocumentaryObligationOutcome.invalidState;
    }
    final conflicts = financeStore.documentaryObligationAggregate.obligations
        .where(
          (item) =>
              item.obligationId != candidate.obligationId &&
              _sameAuthoritativeIdentity(item, candidate),
        )
        .toList();
    if (conflicts.isNotEmpty) return DocumentaryObligationOutcome.conflict;
    if (_same(current.toJson(), candidate.toJson())) {
      return DocumentaryObligationOutcome.unchanged;
    }
    await _replace(candidate);
    return DocumentaryObligationOutcome.applied;
  }

  Future<DocumentaryObligationOutcome> closeContingencyNotDue({
    required String obligationId,
    required String contingencyId,
  }) async {
    final current = _find(obligationId);
    if (current == null) return DocumentaryObligationOutcome.missing;
    final matches = current.contingencies
        .where((item) => item.contingencyId == contingencyId)
        .toList();
    if (matches.length != 1) return DocumentaryObligationOutcome.missing;
    final contingency = matches.single;
    if (contingency.status == DocumentaryContingencyStatus.notDue) {
      return DocumentaryObligationOutcome.unchanged;
    }
    if (contingency.status != DocumentaryContingencyStatus.pending) {
      return DocumentaryObligationOutcome.conflict;
    }
    await _replace(
      current.replaceContingency(
        contingency.copyWith(status: DocumentaryContingencyStatus.notDue),
      ),
    );
    return DocumentaryObligationOutcome.applied;
  }

  Future<DocumentaryObligationOutcome> markInstallmentFulfilled({
    required String obligationId,
    required String installmentId,
    required String economicFactId,
  }) async {
    final current = _find(obligationId);
    if (current == null) return DocumentaryObligationOutcome.missing;
    final option = current.selectedOption;
    if (option == null) return DocumentaryObligationOutcome.invalidState;
    final matches = option.installments
        .where((item) => item.installmentId == installmentId)
        .toList();
    if (matches.length != 1) return DocumentaryObligationOutcome.missing;
    final installment = matches.single;
    if (installment.fulfilledEconomicFactId == economicFactId)
      return DocumentaryObligationOutcome.unchanged;
    if (installment.fulfilledEconomicFactId != null)
      return DocumentaryObligationOutcome.conflict;
    await _replace(
      current.replaceSelectedInstallment(installment.fulfill(economicFactId)),
    );
    return DocumentaryObligationOutcome.applied;
  }

  Future<DocumentaryObligationOutcome> replaceInstallmentFulfillmentVerified({
    required String obligationId,
    required String installmentId,
    required String expectedOldEconomicFactId,
    required FinanceTransaction replacementMain,
    required String operationId,
  }) async {
    final metadata = replacementMain.operationMetadata;
    if (replacementMain.economicFactId == null ||
        metadata == null ||
        metadata.role != OperationRole.main ||
        metadata.context != OperationContext.utilityBill ||
        metadata.operationId != operationId ||
        metadata.documentaryObligationId != obligationId) {
      return DocumentaryObligationOutcome.invalidState;
    }
    final current = _find(obligationId);
    if (current == null) return DocumentaryObligationOutcome.missing;
    final option = current.selectedOption;
    if (option == null) return DocumentaryObligationOutcome.invalidState;
    final matches = option.installments
        .where((item) => item.installmentId == installmentId)
        .toList();
    if (matches.length != 1) return DocumentaryObligationOutcome.missing;
    final installment = matches.single;
    final replacementId = replacementMain.economicFactId!;
    if (installment.fulfilledEconomicFactId == replacementId) {
      return DocumentaryObligationOutcome.unchanged;
    }
    if (installment.fulfilledEconomicFactId != expectedOldEconomicFactId) {
      return DocumentaryObligationOutcome.conflict;
    }
    final replacement = DocumentaryInstallment(
      installmentId: installment.installmentId,
      amount: installment.amount,
      dueDate: installment.dueDate,
      fulfilledEconomicFactId: replacementId,
    );
    await _replace(current.replaceSelectedInstallment(replacement));
    final reloaded = _find(obligationId)?.selectedOption?.installments
        .where((item) => item.installmentId == installmentId)
        .toList();
    return reloaded?.length == 1 &&
            reloaded!.single.fulfilledEconomicFactId == replacementId
        ? DocumentaryObligationOutcome.applied
        : DocumentaryObligationOutcome.conflict;
  }

  /// Materializes a formerly non-economic contingency. Expected Expenses are
  /// persisted first; a retry then completes the documentary marker without
  /// duplicating the occurrence.
  Future<DocumentaryObligationOutcome> materializeContingency({
    required String obligationId,
    required String contingencyId,
    required ExpectedExpenseOccurrence occurrence,
  }) async {
    final current = _find(obligationId);
    if (current == null) return DocumentaryObligationOutcome.missing;
    if (current.relationshipId == null ||
        occurrence.relationshipId != current.relationshipId) {
      return DocumentaryObligationOutcome.invalidState;
    }
    final matches = current.contingencies
        .where((item) => item.contingencyId == contingencyId)
        .toList();
    if (matches.length != 1) return DocumentaryObligationOutcome.missing;
    final contingency = matches.single;
    if (contingency.status == DocumentaryContingencyStatus.notDue) {
      return DocumentaryObligationOutcome.conflict;
    }
    if (contingency.status == DocumentaryContingencyStatus.materialized) {
      return contingency.materializedOccurrenceId == occurrence.occurrenceId
          ? DocumentaryObligationOutcome.unchanged
          : DocumentaryObligationOutcome.conflict;
    }
    final aggregate = financeStore.expectedExpenseAggregate;
    final occurrenceMatches = aggregate.occurrences
        .where((item) => item.occurrenceId == occurrence.occurrenceId)
        .toList();
    if (occurrenceMatches.isNotEmpty &&
        !_same(occurrenceMatches.single.toJson(), occurrence.toJson())) {
      return DocumentaryObligationOutcome.conflict;
    }
    if (occurrenceMatches.isEmpty) {
      final relationshipExists = aggregate.relationships.any(
        (item) => item.relationshipId == occurrence.relationshipId,
      );
      if (!relationshipExists) return DocumentaryObligationOutcome.invalidState;
      await financeStore.saveExpectedExpenseAggregate(
        ExpectedExpenseAggregate(
          relationships: aggregate.relationships,
          occurrences: [...aggregate.occurrences, occurrence],
        ),
      );
    }
    await _replace(
      current.replaceContingency(
        contingency.copyWith(
          status: DocumentaryContingencyStatus.materialized,
          materializedOccurrenceId: occurrence.occurrenceId,
        ),
      ),
    );
    return DocumentaryObligationOutcome.applied;
  }

  DocumentaryObligation? _find(String id) => financeStore
      .documentaryObligationAggregate
      .obligations
      .where((item) => item.obligationId == id)
      .firstOrNull;

  Future<void> _replace(DocumentaryObligation candidate) async {
    final values = financeStore.documentaryObligationAggregate.obligations
        .map(
          (item) =>
              item.obligationId == candidate.obligationId ? candidate : item,
        )
        .toList();
    await _replaceAll(values);
  }

  Future<void> _replaceAll(Iterable<DocumentaryObligation> values) =>
      financeStore.saveDocumentaryObligationAggregate(
        DocumentaryObligationAggregate(
          obligations: values,
          expectedDocuments:
              financeStore.documentaryObligationAggregate.expectedDocuments,
        ),
      );

  bool _same(Map<String, dynamic> left, Map<String, dynamic> right) =>
      jsonEncode(left) == jsonEncode(right);

  bool _sameAuthoritativeIdentity(
    DocumentaryObligation left,
    DocumentaryObligation right,
  ) =>
      left.obligationId != right.obligationId &&
      left.relationshipId != null &&
      left.relationshipId == right.relationshipId &&
      left.documentReferenceType != null &&
      left.documentReferenceType == right.documentReferenceType &&
      left.documentReference != null &&
      left.documentReference == right.documentReference;
}
