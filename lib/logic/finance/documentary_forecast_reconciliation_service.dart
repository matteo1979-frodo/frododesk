import 'dart:convert';

import '../../models/documentary_obligation.dart';
import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../models/finance_recurring_item.dart';
import '../../stores/finance_store.dart';
import 'documentary_obligation_persistence.dart';
import 'expected_expense_persistence.dart';

enum DocumentaryForecastReconciliationClassification {
  safeCreate,
  noOp,
  conflict,
}

enum DocumentaryForecastReconciliationApplyStatus {
  applied,
  noOp,
  conflict,
  writerFailed,
}

class DocumentaryForecastReconciliationPreview {
  final String relationshipId;
  final int cycleSequence;
  final ExpectedDocumentCycle? target;
  final DocumentaryObligation? source;
  final ExpenseRelationship? relationship;
  final ExpectedExpenseOccurrence? candidate;
  final bool targetOccurrenceExists;
  final DocumentaryForecastReconciliationClassification classification;
  final List<String> reasons;

  DocumentaryForecastReconciliationPreview({
    required this.relationshipId,
    required this.cycleSequence,
    required this.target,
    required this.source,
    required this.relationship,
    required this.candidate,
    required this.targetOccurrenceExists,
    required this.classification,
    required Iterable<String> reasons,
  }) : reasons = List.unmodifiable(reasons);

  String get cycleIdentity => '$relationshipId#$cycleSequence';
}

class DocumentaryForecastReconciliationApplyResult {
  final DocumentaryForecastReconciliationApplyStatus status;
  final DocumentaryForecastReconciliationPreview preview;
  final List<String> errors;

  DocumentaryForecastReconciliationApplyResult({
    required this.status,
    required this.preview,
    Iterable<String> errors = const [],
  }) : errors = List.unmodifiable(errors);
}

class DocumentaryForecastReconciliationService {
  final FinanceStore financeStore;

  const DocumentaryForecastReconciliationService({
    required this.financeStore,
  });

  DocumentaryForecastReconciliationPreview preview({
    required String relationshipId,
    required int cycleSequence,
  }) => previewAggregates(
    relationshipId: relationshipId,
    cycleSequence: cycleSequence,
    documentary: financeStore.documentaryObligationAggregate,
    expected: financeStore.expectedExpenseAggregate,
  );

  DocumentaryForecastReconciliationPreview previewAggregates({
    required String relationshipId,
    required int cycleSequence,
    required DocumentaryObligationAggregate documentary,
    required ExpectedExpenseAggregate expected,
  }) {
    final reasons = <String>[];
    if (relationshipId.trim().isEmpty) {
      reasons.add('relationshipId non valido');
    }
    if (cycleSequence <= 0) {
      reasons.add('cycleSequence target non valida');
    }
    final identity = '$relationshipId#$cycleSequence';
    final targets = documentary.expectedDocuments
        .where((item) => item.identity == identity)
        .toList();
    if (targets.length != 1) {
      reasons.add(
        targets.isEmpty
            ? 'ExpectedDocumentCycle target assente'
            : 'ExpectedDocumentCycle target duplicato',
      );
    }
    final target = targets.length == 1 ? targets.single : null;
    if (target != null && target.status != ExpectedDocumentCycleStatus.expected) {
      reasons.add('ExpectedDocumentCycle target non è expected');
    }

    final relationships = expected.relationships
        .where((item) => item.relationshipId == relationshipId)
        .toList();
    if (relationships.length != 1) {
      reasons.add(
        relationships.isEmpty
            ? 'ExpenseRelationship assente'
            : 'ExpenseRelationship duplicata',
      );
    }
    final relationship = relationships.length == 1 ? relationships.single : null;

    final duplicateDocumentaryCycles = <String>{};
    final seenDocumentaryCycles = <String>{};
    for (final obligation in documentary.obligations) {
      final obligationRelationshipId = obligation.relationshipId;
      final obligationCycleSequence = obligation.cycleSequence;
      if (obligationRelationshipId == null || obligationCycleSequence == null) {
        continue;
      }
      final obligationIdentity =
          '$obligationRelationshipId#$obligationCycleSequence';
      if (!seenDocumentaryCycles.add(obligationIdentity)) {
        duplicateDocumentaryCycles.add(obligationIdentity);
      }
    }
    if (duplicateDocumentaryCycles.isNotEmpty) {
      reasons.add(
        'Cycle identity documentale duplicata: '
        '${(duplicateDocumentaryCycles.toList()..sort()).join(', ')}',
      );
    }

    final sources = documentary.obligations
        .where(
          (item) =>
              item.relationshipId == relationshipId &&
              item.cycleSequence == cycleSequence - 1,
        )
        .toList();
    if (sources.length != 1) {
      reasons.add(
        sources.isEmpty
            ? 'DocumentaryObligation sorgente del ciclo precedente assente'
            : 'Più DocumentaryObligation sorgente per il ciclo precedente',
      );
    }
    final source = sources.length == 1 ? sources.single : null;
    if (source != null &&
        (!source.totalAmount.isFinite || source.totalAmount <= 0)) {
      reasons.add('Importo sorgente non valido');
    }

    ExpectedExpenseOccurrence? candidate;
    if (target != null &&
        target.status == ExpectedDocumentCycleStatus.expected &&
        relationship != null &&
        source != null &&
        source.totalAmount.isFinite &&
        source.totalAmount > 0 &&
        reasons.isEmpty) {
      candidate = _candidate(
        relationship: relationship,
        target: target,
        source: source,
      );
    }

    final targetOccurrences = expected.occurrences
        .where(
          (item) =>
              item.relationshipId == relationshipId &&
              item.cycleSequence == cycleSequence,
        )
        .toList();
    if (targetOccurrences.length > 1) {
      reasons.add('Più ExpectedExpenseOccurrence per la target cycle identity');
    }
    final deterministicOccurrenceId =
        'documentary_${relationshipId}_$cycleSequence';
    final idCollisions = expected.occurrences
        .where(
          (item) =>
              item.occurrenceId == deterministicOccurrenceId &&
              (item.relationshipId != relationshipId ||
                  item.cycleSequence != cycleSequence),
        )
        .toList();
    if (idCollisions.isNotEmpty) {
      reasons.add('occurrenceId deterministico già usato da un altro ciclo');
    }

    if (reasons.isNotEmpty || candidate == null) {
      return DocumentaryForecastReconciliationPreview(
        relationshipId: relationshipId,
        cycleSequence: cycleSequence,
        target: target,
        source: source,
        relationship: relationship,
        candidate: candidate,
        targetOccurrenceExists: targetOccurrences.isNotEmpty,
        classification:
            DocumentaryForecastReconciliationClassification.conflict,
        reasons: reasons.isEmpty
            ? const ['Precondizioni insufficienti']
            : reasons,
      );
    }

    if (targetOccurrences.length == 1) {
      final existing = targetOccurrences.single;
      final equivalent = _same(existing.toJson(), candidate.toJson());
      return DocumentaryForecastReconciliationPreview(
        relationshipId: relationshipId,
        cycleSequence: cycleSequence,
        target: target,
        source: source,
        relationship: relationship,
        candidate: candidate,
        targetOccurrenceExists: true,
        classification: equivalent
            ? DocumentaryForecastReconciliationClassification.noOp
            : DocumentaryForecastReconciliationClassification.conflict,
        reasons: [
          equivalent
              ? 'Seed semanticamente equivalente già presente'
              : 'Occurrence della target cycle identity incompatibile',
        ],
      );
    }

    return DocumentaryForecastReconciliationPreview(
      relationshipId: relationshipId,
      cycleSequence: cycleSequence,
      target: target,
      source: source,
      relationship: relationship,
      candidate: candidate,
      targetOccurrenceExists: false,
      classification:
          DocumentaryForecastReconciliationClassification.safeCreate,
      reasons: const ['Tutte le precondizioni strutturali sono verificate'],
    );
  }

  Future<DocumentaryForecastReconciliationApplyResult> apply({
    required String relationshipId,
    required int cycleSequence,
  }) async {
    final currentPreview = preview(
      relationshipId: relationshipId,
      cycleSequence: cycleSequence,
    );
    if (currentPreview.classification ==
        DocumentaryForecastReconciliationClassification.noOp) {
      return DocumentaryForecastReconciliationApplyResult(
        status: DocumentaryForecastReconciliationApplyStatus.noOp,
        preview: currentPreview,
      );
    }
    if (currentPreview.classification !=
        DocumentaryForecastReconciliationClassification.safeCreate) {
      return DocumentaryForecastReconciliationApplyResult(
        status: DocumentaryForecastReconciliationApplyStatus.conflict,
        preview: currentPreview,
        errors: currentPreview.reasons,
      );
    }
    final candidateOccurrence = currentPreview.candidate!;
    final current = financeStore.expectedExpenseAggregate;
    try {
      await financeStore.saveExpectedExpenseAggregate(
        ExpectedExpenseAggregate(
          relationships: current.relationships,
          occurrences: [...current.occurrences, candidateOccurrence],
        ),
      );
    } catch (error) {
      return DocumentaryForecastReconciliationApplyResult(
        status: DocumentaryForecastReconciliationApplyStatus.writerFailed,
        preview: currentPreview,
        errors: ['Verified write fallita: $error'],
      );
    }
    final after = preview(
      relationshipId: relationshipId,
      cycleSequence: cycleSequence,
    );
    if (after.classification !=
            DocumentaryForecastReconciliationClassification.noOp ||
        after.candidate == null ||
        !_same(after.candidate!.toJson(), candidateOccurrence.toJson())) {
      return DocumentaryForecastReconciliationApplyResult(
        status: DocumentaryForecastReconciliationApplyStatus.writerFailed,
        preview: after,
        errors: const ['Read-back pubblicato non equivalente al candidate'],
      );
    }
    return DocumentaryForecastReconciliationApplyResult(
      status: DocumentaryForecastReconciliationApplyStatus.applied,
      preview: after,
    );
  }

  ExpectedExpenseOccurrence _candidate({
    required ExpenseRelationship relationship,
    required ExpectedDocumentCycle target,
    required DocumentaryObligation source,
  }) => ExpectedExpenseOccurrence(
    occurrenceId:
        'documentary_${relationship.relationshipId}_${target.cycleSequence}',
    relationshipId: relationship.relationshipId,
    cycleSequence: target.cycleSequence,
    expectedPeriod: target.expectedPeriod,
    status: ExpectedExpenseOccurrenceStatus.pending,
    expectedAmount: source.totalAmount,
    estimationMethod: ExpenseEstimationMethod.documentaryObligation,
    sourceDocumentaryObligationId: source.obligationId,
    confidence: ExpenseEstimateConfidence.medium,
    provisional: true,
    expectedPaymentConfiguration: relationship.paymentConfiguration,
    paymentExecutionMode: PaymentExecutionMode.unknown,
    expectedSubject: relationship.subject,
  );

  bool _same(Map<String, dynamic> left, Map<String, dynamic> right) =>
      jsonEncode(left) == jsonEncode(right);
}
