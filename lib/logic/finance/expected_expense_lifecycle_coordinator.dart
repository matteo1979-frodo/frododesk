import 'dart:convert';

import '../../models/composite_economic_operation.dart';
import '../../models/economic_operation_metadata.dart';
import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../models/finance_recurring_item.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';
import 'composite_economic_operation_coordinator.dart';
import 'expected_expense_persistence.dart';
import 'expected_expense_update_coordinator.dart';

enum ExpectedExpenseLifecycleStatus {
  completed,
  unchanged,
  missingRelationship,
  missingOccurrence,
  identityMismatch,
  invalidState,
  conflict,
  failed,
}

class ExpectedExpenseLifecycleResult {
  final ExpectedExpenseLifecycleStatus status;
  final String? mainEconomicFactId;
  final String? nextOccurrenceId;
  final List<String> errors;

  const ExpectedExpenseLifecycleResult._(
    this.status, {
    this.mainEconomicFactId,
    this.nextOccurrenceId,
    this.errors = const [],
  });

  bool get isSuccess =>
      status == ExpectedExpenseLifecycleStatus.completed ||
      status == ExpectedExpenseLifecycleStatus.unchanged;
}

class KnownExpectedExpenseData {
  final double amount;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final List<String> evidenceEconomicFactIds;

  KnownExpectedExpenseData({
    required this.amount,
    this.issueDate,
    this.dueDate,
    Iterable<String> evidenceEconomicFactIds = const [],
  }) : evidenceEconomicFactIds = List.unmodifiable(
         evidenceEconomicFactIds
             .map((item) => item.trim())
             .where((item) => item.isNotEmpty),
       ) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }
  }
}

typedef ExpectedExpenseAccessoryPayment = ({
  double amount,
  AccessoryCostType type,
});

class ExpectedExpensePayment {
  final DateTime paidAt;
  final String balanceId;
  final FinanceSubject subject;
  final String category;
  final String description;
  final double amount;
  final List<ExpectedExpenseAccessoryPayment> accessories;

  ExpectedExpensePayment({
    required this.paidAt,
    required String balanceId,
    required this.subject,
    required String category,
    required String description,
    required this.amount,
    Iterable<ExpectedExpenseAccessoryPayment> accessories = const [],
  }) : balanceId = _requiredText(balanceId, 'balanceId'),
       category = _requiredText(category, 'category'),
       description = _requiredText(description, 'description'),
       accessories = List.unmodifiable(accessories) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }
    if (this.accessories.any(
      (item) => !item.amount.isFinite || item.amount <= 0,
    )) {
      throw ArgumentError.value(accessories, 'accessories');
    }
  }

  static String _requiredText(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, name);
    return normalized;
  }
}

/// Coordinates the informational and economic lifecycle of one expected
/// expense. All identities derive from the occurrence, making interrupted
/// cross-store writes safely retryable without name or amount matching.
class ExpectedExpenseLifecycleCoordinator {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;

  const ExpectedExpenseLifecycleCoordinator({
    required this.financeStore,
    required this.expenseStore,
  });

  Future<ExpectedExpenseLifecycleResult> recordKnownExpenseData({
    required String relationshipId,
    required String occurrenceId,
    required KnownExpectedExpenseData data,
  }) async {
    final lookup = _lookup(relationshipId, occurrenceId);
    if (lookup.failure case final failure?) return failure;
    final occurrence = lookup.occurrence!;
    if (occurrence.status != ExpectedExpenseOccurrenceStatus.pending) {
      return const ExpectedExpenseLifecycleResult._(
        ExpectedExpenseLifecycleStatus.invalidState,
        errors: ['Only pending occurrences can receive known expense data'],
      );
    }
    final evidence = <String>{
      ...occurrence.evidenceEconomicFactIds,
      ...data.evidenceEconomicFactIds,
    }.toList();
    final candidate = occurrence.copyWith(
      knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
      knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
      expectedAmount: data.amount,
      expectedIssueDate: data.issueDate ?? occurrence.expectedIssueDate,
      expectedIssueDateSource: data.issueDate == null
          ? occurrence.expectedIssueDateSource
          : ExpectedExpenseDateSource.explicit,
      expectedDueDate: data.dueDate ?? occurrence.expectedDueDate,
      expectedDueDateSource: data.dueDate == null
          ? occurrence.expectedDueDateSource
          : ExpectedExpenseDateSource.explicit,
      expectedDueDateCertainty: data.dueDate == null
          ? occurrence.expectedDueDateCertainty
          : ExpectedExpenseDateCertainty.known,
      estimationMethod: ExpenseEstimationMethod.manualEstimate,
      evidenceEconomicFactIds: evidence,
      confidence: ExpenseEstimateConfidence.high,
      provisional: false,
    );
    final outcome = await ExpectedExpenseUpdateCoordinator(
      financeStore: financeStore,
    ).updateOccurrence(occurrenceId: occurrenceId, candidate: candidate);
    return ExpectedExpenseLifecycleResult._(switch (outcome) {
      ExpectedExpenseUpdateOutcome.applied =>
        ExpectedExpenseLifecycleStatus.completed,
      ExpectedExpenseUpdateOutcome.unchanged =>
        ExpectedExpenseLifecycleStatus.unchanged,
      ExpectedExpenseUpdateOutcome.missingRelationship =>
        ExpectedExpenseLifecycleStatus.missingRelationship,
      ExpectedExpenseUpdateOutcome.missingOccurrence =>
        ExpectedExpenseLifecycleStatus.missingOccurrence,
      ExpectedExpenseUpdateOutcome.identityMismatch =>
        ExpectedExpenseLifecycleStatus.identityMismatch,
    });
  }

  Future<ExpectedExpenseLifecycleResult> recordExpectedExpensePayment({
    required String relationshipId,
    required String occurrenceId,
    required ExpectedExpensePayment payment,
  }) async {
    final lookup = _lookup(relationshipId, occurrenceId);
    if (lookup.failure case final failure?) return failure;
    final relationship = lookup.relationship!;
    final occurrence = lookup.occurrence!;
    final identities = _PaymentIdentities(occurrenceId);

    if (occurrence.status == ExpectedExpenseOccurrenceStatus.cancelled) {
      return const ExpectedExpenseLifecycleResult._(
        ExpectedExpenseLifecycleStatus.invalidState,
        errors: ['Cancelled occurrences cannot be paid'],
      );
    }
    if (occurrence.status == ExpectedExpenseOccurrenceStatus.resolved) {
      if (occurrence.resolvedEconomicFactId != identities.mainFactId) {
        return const ExpectedExpenseLifecycleResult._(
          ExpectedExpenseLifecycleStatus.conflict,
          errors: ['Occurrence is resolved to a different economic fact'],
        );
      }
      return ExpectedExpenseLifecycleResult._(
        ExpectedExpenseLifecycleStatus.unchanged,
        mainEconomicFactId: identities.mainFactId,
        nextOccurrenceId: _existingNextId(identities.nextOccurrenceId),
      );
    }

    final operation = CompositeEconomicOperation(
      operationId: identities.operationId,
      context: OperationContext.utilityBill,
      mainEconomicFactId: identities.mainFactId,
      mainAmount: payment.amount,
      accessories: [
        for (var index = 0; index < payment.accessories.length; index++)
          (
            economicFactId: identities.accessoryFactId(index),
            amount: payment.accessories[index].amount,
            accessoryCostType: payment.accessories[index].type,
          ),
      ],
    );
    final economic =
        await CompositeEconomicOperationCoordinator(
          financeStore: financeStore,
          expenseStore: expenseStore,
        ).record(
          CompositeEconomicOperationPosting(
            operation: operation,
            debitBalanceId: payment.balanceId,
            subject: payment.subject,
            economicDate: payment.paidAt,
            description: payment.description,
            category: payment.category,
          ),
        );
    if (economic.status == CompositeEconomicOperationStatus.inconsistent) {
      return ExpectedExpenseLifecycleResult._(
        ExpectedExpenseLifecycleStatus.conflict,
        mainEconomicFactId: identities.mainFactId,
        errors: economic.errors,
      );
    }
    if (economic.status == CompositeEconomicOperationStatus.failed) {
      return ExpectedExpenseLifecycleResult._(
        ExpectedExpenseLifecycleStatus.failed,
        mainEconomicFactId: identities.mainFactId,
        errors: economic.errors,
      );
    }

    final current = financeStore.expectedExpenseAggregate;
    final currentIndex = current.occurrences.indexWhere(
      (item) => item.occurrenceId == occurrenceId,
    );
    if (currentIndex < 0) {
      return const ExpectedExpenseLifecycleResult._(
        ExpectedExpenseLifecycleStatus.missingOccurrence,
      );
    }
    final occurrences = current.occurrences.toList();
    occurrences[currentIndex] = occurrence.copyWith(
      status: ExpectedExpenseOccurrenceStatus.resolved,
      resolvedEconomicFactId: identities.mainFactId,
    );
    String? nextOccurrenceId;
    if (_isRecurringActive(relationship) &&
        occurrence.cycleSequence != null &&
        occurrence.cycleAnchor != null) {
      nextOccurrenceId = identities.nextOccurrenceId;
      final existing = occurrences.where(
        (item) => item.occurrenceId == nextOccurrenceId,
      );
      if (existing.isEmpty) {
        occurrences.add(
          _nextOccurrence(
            relationship: relationship,
            current: occurrence,
            occurrenceId: nextOccurrenceId,
            evidenceEconomicFactId: identities.mainFactId,
            actualAmount: payment.amount,
          ),
        );
      } else if (existing.length != 1 ||
          existing.single.relationshipId != relationshipId) {
        return const ExpectedExpenseLifecycleResult._(
          ExpectedExpenseLifecycleStatus.conflict,
          errors: ['Next occurrence identity is conflicting'],
        );
      }
    }
    try {
      await financeStore.saveExpectedExpenseAggregate(
        ExpectedExpenseAggregate(
          relationships: current.relationships,
          occurrences: occurrences,
        ),
      );
    } catch (error) {
      return ExpectedExpenseLifecycleResult._(
        ExpectedExpenseLifecycleStatus.failed,
        mainEconomicFactId: identities.mainFactId,
        errors: ['$error'],
      );
    }
    return ExpectedExpenseLifecycleResult._(
      ExpectedExpenseLifecycleStatus.completed,
      mainEconomicFactId: identities.mainFactId,
      nextOccurrenceId: nextOccurrenceId,
    );
  }

  _Lookup _lookup(String relationshipId, String occurrenceId) {
    final aggregate = financeStore.expectedExpenseAggregate;
    final relationships = aggregate.relationships
        .where((item) => item.relationshipId == relationshipId)
        .toList();
    if (relationships.isEmpty) {
      return _Lookup.failed(ExpectedExpenseLifecycleStatus.missingRelationship);
    }
    final occurrences = aggregate.occurrences
        .where((item) => item.occurrenceId == occurrenceId)
        .toList();
    if (occurrences.isEmpty) {
      return _Lookup.failed(ExpectedExpenseLifecycleStatus.missingOccurrence);
    }
    if (relationships.length != 1 ||
        occurrences.length != 1 ||
        occurrences.single.relationshipId != relationshipId) {
      return _Lookup.failed(ExpectedExpenseLifecycleStatus.identityMismatch);
    }
    return _Lookup(relationships.single, occurrences.single, null);
  }

  bool _isRecurringActive(ExpenseRelationship relationship) =>
      relationship.status == ExpenseRelationshipStatus.active &&
      relationship.periodicity.type != FinanceRecurringType.oneShot;

  String? _existingNextId(String id) =>
      financeStore.expectedExpenseAggregate.occurrences.any(
        (item) => item.occurrenceId == id,
      )
      ? id
      : null;

  ExpectedExpenseOccurrence _nextOccurrence({
    required ExpenseRelationship relationship,
    required ExpectedExpenseOccurrence current,
    required String occurrenceId,
    required String evidenceEconomicFactId,
    required double actualAmount,
  }) {
    final nextDate = _advance(current.cycleAnchor!, relationship.periodicity);
    final usesIssueDate =
        current.expectedIssueDate != null && current.expectedDueDate == null;
    return ExpectedExpenseOccurrence(
      occurrenceId: occurrenceId,
      relationshipId: relationship.relationshipId,
      cycleSequence: current.cycleSequence! + 1,
      cycleAnchor: nextDate,
      status: ExpectedExpenseOccurrenceStatus.pending,
      expectedIssueDate: usesIssueDate ? nextDate : null,
      expectedIssueDateSource: usesIssueDate
          ? ExpectedExpenseDateSource.calculatedFromPeriodicity
          : null,
      expectedDueDate: usesIssueDate ? null : nextDate,
      expectedDueDateSource: usesIssueDate
          ? null
          : ExpectedExpenseDateSource.calculatedFromPeriodicity,
      expectedDueDateCertainty: usesIssueDate
          ? null
          : ExpectedExpenseDateCertainty.estimated,
      expectedAmount: actualAmount,
      estimationMethod: ExpenseEstimationMethod.firstAvailableFact,
      evidenceEconomicFactIds: [evidenceEconomicFactId],
      confidence: ExpenseEstimateConfidence.low,
      provisional: true,
      expectedPaymentConfiguration: relationship.paymentConfiguration,
      paymentExecutionMode: relationship.paymentExecutionMode,
      expectedSubject: relationship.subject,
    );
  }

  DateTime _advance(
    DateTime source,
    ExpenseRelationshipPeriodicity periodicity,
  ) {
    final months = switch (periodicity.type) {
      FinanceRecurringType.monthly => 1,
      FinanceRecurringType.yearly => 12,
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'months' =>
        periodicity.customInterval!,
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'years' =>
        periodicity.customInterval! * 12,
      FinanceRecurringType.custom
          when periodicity.customIntervalUnit == 'days' =>
        null,
      FinanceRecurringType.custom => throw UnsupportedError(
        'Unsupported custom periodicity unit',
      ),
      FinanceRecurringType.oneShot => throw StateError(
        'One-shot relationships have no next cycle',
      ),
    };
    if (months == null) {
      return source.add(Duration(days: periodicity.customInterval!));
    }
    final monthStart = source.isUtc
        ? DateTime.utc(source.year, source.month + months)
        : DateTime(source.year, source.month + months);
    final following = source.isUtc
        ? DateTime.utc(monthStart.year, monthStart.month + 1)
        : DateTime(monthStart.year, monthStart.month + 1);
    final lastDay = following.subtract(const Duration(days: 1)).day;
    final day = source.day <= lastDay ? source.day : lastDay;
    return source.isUtc
        ? DateTime.utc(monthStart.year, monthStart.month, day)
        : DateTime(monthStart.year, monthStart.month, day);
  }
}

class _PaymentIdentities {
  final String encodedOccurrenceId;

  _PaymentIdentities(String occurrenceId)
    : encodedOccurrenceId = base64Url.encode(utf8.encode(occurrenceId));

  String get operationId => 'expected_expense:$encodedOccurrenceId';
  String get mainFactId => 'economic_fact:$operationId:main';
  String accessoryFactId(int index) =>
      'economic_fact:$operationId:accessory:${index + 1}';
  String get nextOccurrenceId =>
      'expected_expense_occurrence:after:$encodedOccurrenceId';
}

class _Lookup {
  final ExpenseRelationship? relationship;
  final ExpectedExpenseOccurrence? occurrence;
  final ExpectedExpenseLifecycleResult? failure;

  const _Lookup(this.relationship, this.occurrence, this.failure);

  factory _Lookup.failed(ExpectedExpenseLifecycleStatus status) =>
      _Lookup(null, null, ExpectedExpenseLifecycleResult._(status));
}
