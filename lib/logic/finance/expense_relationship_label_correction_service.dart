import 'dart:convert';

import '../../models/expense_relationship.dart';
import '../../stores/finance_store.dart';
import 'expected_expense_persistence.dart';

enum ExpenseRelationshipLabelCorrectionClassification {
  safeUpdate,
  noOp,
  conflict,
}

class ExpenseRelationshipLabelCorrectionIntent {
  final String relationshipId;
  final ExpenseRelationship expectedCurrent;
  final String targetService;
  final ExpenseRelationshipCycleLabelPolicy targetPolicy;

  ExpenseRelationshipLabelCorrectionIntent({
    required String relationshipId,
    required this.expectedCurrent,
    required String targetService,
    required this.targetPolicy,
  }) : relationshipId = relationshipId.trim(),
       targetService = targetService.trim() {
    if (this.relationshipId.isEmpty) {
      throw ArgumentError.value(relationshipId, 'relationshipId');
    }
    if (expectedCurrent.relationshipId != this.relationshipId) {
      throw ArgumentError(
        'expectedCurrent must refer to the requested relationshipId',
      );
    }
    if (this.targetService.isEmpty) {
      throw ArgumentError.value(targetService, 'targetService');
    }
  }
}

class ExpenseRelationshipLabelCorrectionPreview {
  final ExpenseRelationshipLabelCorrectionClassification classification;
  final ExpenseRelationship? current;
  final ExpenseRelationship? candidate;
  final String? conflictReason;

  const ExpenseRelationshipLabelCorrectionPreview({
    required this.classification,
    this.current,
    this.candidate,
    this.conflictReason,
  });
}

enum ExpenseRelationshipLabelCorrectionApplyStatus {
  applied,
  noOp,
  conflict,
  failed,
}

class ExpenseRelationshipLabelCorrectionApplyResult {
  final ExpenseRelationshipLabelCorrectionApplyStatus status;
  final String? error;

  const ExpenseRelationshipLabelCorrectionApplyResult({
    required this.status,
    this.error,
  });
}

/// Protected, explicit correction of the stable label metadata of one
/// relationship. It never discovers targets by text and never changes
/// occurrences or documentary data.
class ExpenseRelationshipLabelCorrectionService {
  final FinanceStore financeStore;

  const ExpenseRelationshipLabelCorrectionService({
    required this.financeStore,
  });

  ExpenseRelationshipLabelCorrectionPreview preview(
    ExpenseRelationshipLabelCorrectionIntent intent,
  ) => previewAggregate(
    aggregate: financeStore.expectedExpenseAggregate,
    intent: intent,
  );

  ExpenseRelationshipLabelCorrectionPreview previewAggregate({
    required ExpectedExpenseAggregate aggregate,
    required ExpenseRelationshipLabelCorrectionIntent intent,
  }) {
    final matching = aggregate.relationships
        .where((item) => item.relationshipId == intent.relationshipId)
        .toList();
    if (matching.length != 1) {
      return ExpenseRelationshipLabelCorrectionPreview(
        classification:
            ExpenseRelationshipLabelCorrectionClassification.conflict,
        conflictReason: matching.isEmpty
            ? 'Relationship not found'
            : 'Duplicate relationship identity',
      );
    }
    final current = matching.single;
    ExpenseRelationship candidate;
    try {
      candidate = current.copyWith(
        service: intent.targetService,
        cycleLabelPolicy: intent.targetPolicy,
      );
    } catch (error) {
      return ExpenseRelationshipLabelCorrectionPreview(
        classification:
            ExpenseRelationshipLabelCorrectionClassification.conflict,
        current: current,
        conflictReason: '$error',
      );
    }
    if (_same(current, candidate)) {
      return ExpenseRelationshipLabelCorrectionPreview(
        classification: ExpenseRelationshipLabelCorrectionClassification.noOp,
        current: current,
        candidate: candidate,
      );
    }
    if (!_same(current, intent.expectedCurrent)) {
      return ExpenseRelationshipLabelCorrectionPreview(
        classification:
            ExpenseRelationshipLabelCorrectionClassification.conflict,
        current: current,
        candidate: candidate,
        conflictReason: 'Current relationship differs from expected snapshot',
      );
    }
    return ExpenseRelationshipLabelCorrectionPreview(
      classification:
          ExpenseRelationshipLabelCorrectionClassification.safeUpdate,
      current: current,
      candidate: candidate,
    );
  }

  Future<ExpenseRelationshipLabelCorrectionApplyResult> apply(
    ExpenseRelationshipLabelCorrectionIntent intent,
  ) async {
    final before = financeStore.expectedExpenseAggregate;
    final preview = previewAggregate(aggregate: before, intent: intent);
    if (preview.classification ==
        ExpenseRelationshipLabelCorrectionClassification.noOp) {
      return const ExpenseRelationshipLabelCorrectionApplyResult(
        status: ExpenseRelationshipLabelCorrectionApplyStatus.noOp,
      );
    }
    if (preview.classification !=
        ExpenseRelationshipLabelCorrectionClassification.safeUpdate) {
      return ExpenseRelationshipLabelCorrectionApplyResult(
        status: ExpenseRelationshipLabelCorrectionApplyStatus.conflict,
        error: preview.conflictReason,
      );
    }

    final occurrencesBefore = _occurrencesFingerprint(before);
    final candidate = ExpectedExpenseAggregate(
      relationships: [
        for (final item in before.relationships)
          if (item.relationshipId == intent.relationshipId)
            preview.candidate!
          else
            item,
      ],
      occurrences: before.occurrences,
    );
    try {
      await financeStore.saveExpectedExpenseAggregate(candidate);
    } catch (error) {
      return ExpenseRelationshipLabelCorrectionApplyResult(
        status: ExpenseRelationshipLabelCorrectionApplyStatus.failed,
        error: '$error',
      );
    }

    final after = financeStore.expectedExpenseAggregate;
    final verification = previewAggregate(aggregate: after, intent: intent);
    if (verification.classification !=
            ExpenseRelationshipLabelCorrectionClassification.noOp ||
        occurrencesBefore != _occurrencesFingerprint(after)) {
      return const ExpenseRelationshipLabelCorrectionApplyResult(
        status: ExpenseRelationshipLabelCorrectionApplyStatus.failed,
        error: 'Post-write verification failed',
      );
    }
    return const ExpenseRelationshipLabelCorrectionApplyResult(
      status: ExpenseRelationshipLabelCorrectionApplyStatus.applied,
    );
  }

  static bool _same(
    ExpenseRelationship left,
    ExpenseRelationship right,
  ) => jsonEncode(left.toJson()) == jsonEncode(right.toJson());

  static String _occurrencesFingerprint(ExpectedExpenseAggregate aggregate) =>
      jsonEncode(aggregate.occurrences.map((item) => item.toJson()).toList());
}
