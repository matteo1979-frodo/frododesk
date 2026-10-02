import 'dart:collection';

import 'balance_posting_mode.dart';
import 'finance_recurring_item.dart';

enum IncomeCategoryKind {
  salary,
  professionalWork,
  occasionalWork,
  pension,
  singleAllowance,
  otherBenefit,
  rent,
  taxRefund730,
  otherTaxRefund,
  genericRefund,
  financialIncome,
  saleGain,
  gift,
  moneyReturn,
  other,
  custom,
}

enum IncomePeriodicity { oneTime, monthly, yearly, customMonths }

enum IncomeProvenance {
  userEntered,
  recurringRelationship,
  historicalEvidence,
  previousYearPeriod,
}

enum IncomeKnowledge { known, predicted, estimated, incomplete }

enum ExpectedIncomeStatus { pending, partiallyReconciled, resolved, cancelled }

enum IncomeComponentKind {
  ordinary,
  taxRefund730,
  productionBonus,
  thirteenth,
  fourteenth,
  other,
}

class IncomeCustomCategory {
  final String id;
  final String label;

  IncomeCustomCategory({required String id, required String label})
    : id = _required(id, 'id'),
      label = _required(label, 'label');

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  factory IncomeCustomCategory.fromJson(Map<String, dynamic> json) =>
      IncomeCustomCategory(
        id: _string(json, 'id'),
        label: _string(json, 'label'),
      );
}

class IncomeRelationship {
  final String relationshipId;
  final String label;
  final IncomeCategoryKind category;
  final String? customCategoryId;
  final FinanceSubject subject;
  final String? payer;
  final String? destinationBalanceId;
  final double expectedOrdinaryAmount;
  final IncomePeriodicity periodicity;
  final int? customIntervalMonths;
  final DateTime firstExpectedDate;
  final bool historyBasedForecastEnabled;
  final bool active;

  IncomeRelationship({
    required String relationshipId,
    required String label,
    required this.category,
    String? customCategoryId,
    required this.subject,
    String? payer,
    String? destinationBalanceId,
    required this.expectedOrdinaryAmount,
    required this.periodicity,
    this.customIntervalMonths,
    required DateTime firstExpectedDate,
    this.historyBasedForecastEnabled = false,
    this.active = true,
  }) : relationshipId = _required(relationshipId, 'relationshipId'),
       label = _required(label, 'label'),
       customCategoryId = _optional(customCategoryId, 'customCategoryId'),
       payer = _optional(payer, 'payer'),
       destinationBalanceId = _optional(
         destinationBalanceId,
         'destinationBalanceId',
       ),
       firstExpectedDate = _dateOnly(firstExpectedDate) {
    if (!expectedOrdinaryAmount.isFinite || expectedOrdinaryAmount <= 0) {
      throw ArgumentError.value(
        expectedOrdinaryAmount,
        'expectedOrdinaryAmount',
      );
    }
    if ((category == IncomeCategoryKind.custom) !=
        (this.customCategoryId != null)) {
      throw ArgumentError('Custom category and customCategoryId must agree');
    }
    if (periodicity == IncomePeriodicity.customMonths &&
        (customIntervalMonths == null || customIntervalMonths! <= 0)) {
      throw ArgumentError.value(customIntervalMonths, 'customIntervalMonths');
    }
  }

  bool get isSalary => category == IncomeCategoryKind.salary;

  Map<String, dynamic> toJson() => {
    'relationshipId': relationshipId,
    'label': label,
    'category': category.name,
    'customCategoryId': customCategoryId,
    'subject': subject.name,
    'payer': payer,
    'destinationBalanceId': destinationBalanceId,
    'expectedOrdinaryAmount': expectedOrdinaryAmount,
    'periodicity': periodicity.name,
    'customIntervalMonths': customIntervalMonths,
    'firstExpectedDate': firstExpectedDate.toIso8601String(),
    'historyBasedForecastEnabled': historyBasedForecastEnabled,
    'active': active,
  };

  factory IncomeRelationship.fromJson(Map<String, dynamic> json) =>
      IncomeRelationship(
        relationshipId: _string(json, 'relationshipId'),
        label: _string(json, 'label'),
        category: _enum(json, 'category', IncomeCategoryKind.values),
        customCategoryId: json['customCategoryId'] as String?,
        subject: _enum(json, 'subject', FinanceSubject.values),
        payer: json['payer'] as String?,
        destinationBalanceId: json['destinationBalanceId'] as String?,
        expectedOrdinaryAmount: _number(json, 'expectedOrdinaryAmount'),
        periodicity: _enum(json, 'periodicity', IncomePeriodicity.values),
        customIntervalMonths: json['customIntervalMonths'] as int?,
        firstExpectedDate: _date(json, 'firstExpectedDate'),
        historyBasedForecastEnabled:
            json['historyBasedForecastEnabled'] as bool? ?? false,
        active: json['active'] as bool? ?? true,
      );
}

class IncomeReconciliationAllocation {
  final String componentId;
  final IncomeComponentKind kind;
  final String label;
  final double amount;
  final String? occurrenceId;
  final bool contributesToOrdinaryBaseline;

  IncomeReconciliationAllocation({
    required String componentId,
    required this.kind,
    required String label,
    required this.amount,
    String? occurrenceId,
    bool? contributesToOrdinaryBaseline,
  }) : componentId = _required(componentId, 'componentId'),
       label = _required(label, 'label'),
       occurrenceId = _optional(occurrenceId, 'occurrenceId'),
       contributesToOrdinaryBaseline =
           contributesToOrdinaryBaseline ??
           kind == IncomeComponentKind.ordinary {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }
  }

  Map<String, dynamic> toJson() => {
    'componentId': componentId,
    'kind': kind.name,
    'label': label,
    'amount': amount,
    'occurrenceId': occurrenceId,
    'contributesToOrdinaryBaseline': contributesToOrdinaryBaseline,
  };

  factory IncomeReconciliationAllocation.fromJson(Map<String, dynamic> json) =>
      IncomeReconciliationAllocation(
        componentId: _string(json, 'componentId'),
        kind: _enum(json, 'kind', IncomeComponentKind.values),
        label: _string(json, 'label'),
        amount: _number(json, 'amount'),
        occurrenceId: json['occurrenceId'] as String?,
        contributesToOrdinaryBaseline:
            json['contributesToOrdinaryBaseline'] as bool?,
      );
}

class IncomeReconciliation {
  final String reconciliationId;
  final String economicFactId;
  final String transactionId;
  final String? relationshipId;
  final DateTime occurredAt;
  final double totalAmount;
  final FinanceSubject subject;
  final String? payer;
  final String destinationBalanceId;
  final BalancePostingMode postingMode;
  final UnmodifiableListView<IncomeReconciliationAllocation> allocations;

  IncomeReconciliation({
    required String reconciliationId,
    required String economicFactId,
    required String transactionId,
    String? relationshipId,
    required DateTime occurredAt,
    required this.totalAmount,
    required this.subject,
    String? payer,
    required String destinationBalanceId,
    required this.postingMode,
    required Iterable<IncomeReconciliationAllocation> allocations,
  }) : reconciliationId = _required(reconciliationId, 'reconciliationId'),
       economicFactId = _required(economicFactId, 'economicFactId'),
       transactionId = _required(transactionId, 'transactionId'),
       relationshipId = _optional(relationshipId, 'relationshipId'),
       occurredAt = _dateOnly(occurredAt),
       payer = _optional(payer, 'payer'),
       destinationBalanceId = _required(
         destinationBalanceId,
         'destinationBalanceId',
       ),
       allocations = UnmodifiableListView(List.of(allocations)) {
    if (!totalAmount.isFinite || totalAmount <= 0) {
      throw ArgumentError.value(totalAmount, 'totalAmount');
    }
    if (this.allocations.isEmpty) throw ArgumentError('allocations is empty');
    _unique(this.allocations.map((item) => item.componentId), 'componentId');
    final allocated = this.allocations.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    if ((allocated - totalAmount).abs() > 0.005) {
      throw ArgumentError('Component total must equal real credit total');
    }
  }

  Map<String, dynamic> toJson() => {
    'reconciliationId': reconciliationId,
    'economicFactId': economicFactId,
    'transactionId': transactionId,
    'relationshipId': relationshipId,
    'occurredAt': occurredAt.toIso8601String(),
    'totalAmount': totalAmount,
    'subject': subject.name,
    'payer': payer,
    'destinationBalanceId': destinationBalanceId,
    'postingMode': postingMode.name,
    'allocations': allocations.map((item) => item.toJson()).toList(),
  };

  factory IncomeReconciliation.fromJson(Map<String, dynamic> json) =>
      IncomeReconciliation(
        reconciliationId: _string(json, 'reconciliationId'),
        economicFactId: _string(json, 'economicFactId'),
        transactionId: _string(json, 'transactionId'),
        relationshipId: json['relationshipId'] as String?,
        occurredAt: _date(json, 'occurredAt'),
        totalAmount: _number(json, 'totalAmount'),
        subject: _enum(json, 'subject', FinanceSubject.values),
        payer: json['payer'] as String?,
        destinationBalanceId: _string(json, 'destinationBalanceId'),
        postingMode: balancePostingModeFromJson(json['postingMode']),
        allocations: _mapList(
          json,
          'allocations',
          IncomeReconciliationAllocation.fromJson,
        ),
      );
}

class ExpectedIncomeOccurrence {
  final String occurrenceId;
  final String relationshipId;
  final int? cycleSequence;
  final DateTime expectedDate;
  final double expectedAmount;
  final ExpectedIncomeStatus status;
  final IncomeProvenance provenance;
  final IncomeKnowledge knowledge;
  final UnmodifiableListView<String> evidenceEconomicFactIds;
  final UnmodifiableListView<String> reconciliationIds;

  ExpectedIncomeOccurrence({
    required String occurrenceId,
    required String relationshipId,
    this.cycleSequence,
    required DateTime expectedDate,
    required this.expectedAmount,
    this.status = ExpectedIncomeStatus.pending,
    required this.provenance,
    required this.knowledge,
    Iterable<String> evidenceEconomicFactIds = const [],
    Iterable<String> reconciliationIds = const [],
  }) : occurrenceId = _required(occurrenceId, 'occurrenceId'),
       relationshipId = _required(relationshipId, 'relationshipId'),
       expectedDate = _dateOnly(expectedDate),
       evidenceEconomicFactIds = UnmodifiableListView(
         List.of(evidenceEconomicFactIds),
       ),
       reconciliationIds = UnmodifiableListView(List.of(reconciliationIds)) {
    if (!expectedAmount.isFinite || expectedAmount <= 0) {
      throw ArgumentError.value(expectedAmount, 'expectedAmount');
    }
    if (cycleSequence != null && cycleSequence! <= 0) {
      throw ArgumentError.value(cycleSequence, 'cycleSequence');
    }
    _unique(this.reconciliationIds, 'reconciliationIds');
  }

  ExpectedIncomeOccurrence withReconciliation({
    required String reconciliationId,
    required double reconciledTotal,
  }) => withReconciliationState(
    reconciliationIds: {...reconciliationIds, reconciliationId},
    reconciledTotal: reconciledTotal,
  );

  ExpectedIncomeOccurrence withReconciliationState({
    required Iterable<String> reconciliationIds,
    required double reconciledTotal,
  }) => ExpectedIncomeOccurrence(
    occurrenceId: occurrenceId,
    relationshipId: relationshipId,
    cycleSequence: cycleSequence,
    expectedDate: expectedDate,
    expectedAmount: expectedAmount,
    status: reconciledTotal <= 0.005
        ? ExpectedIncomeStatus.pending
        : reconciledTotal + 0.005 >= expectedAmount
        ? ExpectedIncomeStatus.resolved
        : ExpectedIncomeStatus.partiallyReconciled,
    provenance: provenance,
    knowledge: knowledge,
    evidenceEconomicFactIds: evidenceEconomicFactIds,
    reconciliationIds: reconciliationIds,
  );

  String get structuralIdentity => cycleSequence == null
      ? 'income-occurrence:$occurrenceId'
      : 'income-cycle:$relationshipId#$cycleSequence';

  Map<String, dynamic> toJson() => {
    'occurrenceId': occurrenceId,
    'relationshipId': relationshipId,
    'cycleSequence': cycleSequence,
    'expectedDate': expectedDate.toIso8601String(),
    'expectedAmount': expectedAmount,
    'status': status.name,
    'provenance': provenance.name,
    'knowledge': knowledge.name,
    'evidenceEconomicFactIds': evidenceEconomicFactIds.toList(),
    'reconciliationIds': reconciliationIds.toList(),
  };

  factory ExpectedIncomeOccurrence.fromJson(Map<String, dynamic> json) =>
      ExpectedIncomeOccurrence(
        occurrenceId: _string(json, 'occurrenceId'),
        relationshipId: _string(json, 'relationshipId'),
        cycleSequence: json['cycleSequence'] as int?,
        expectedDate: _date(json, 'expectedDate'),
        expectedAmount: _number(json, 'expectedAmount'),
        status: _enum(json, 'status', ExpectedIncomeStatus.values),
        provenance: _enum(json, 'provenance', IncomeProvenance.values),
        knowledge: _enum(json, 'knowledge', IncomeKnowledge.values),
        evidenceEconomicFactIds: _strings(json, 'evidenceEconomicFactIds'),
        reconciliationIds: _strings(json, 'reconciliationIds'),
      );
}

class IncomeAggregate {
  final UnmodifiableListView<IncomeRelationship> relationships;
  final UnmodifiableListView<ExpectedIncomeOccurrence> occurrences;
  final UnmodifiableListView<IncomeReconciliation> reconciliations;
  final UnmodifiableListView<IncomeCustomCategory> customCategories;

  IncomeAggregate({
    Iterable<IncomeRelationship> relationships = const [],
    Iterable<ExpectedIncomeOccurrence> occurrences = const [],
    Iterable<IncomeReconciliation> reconciliations = const [],
    Iterable<IncomeCustomCategory> customCategories = const [],
  }) : relationships = UnmodifiableListView(List.of(relationships)),
       occurrences = UnmodifiableListView(List.of(occurrences)),
       reconciliations = UnmodifiableListView(List.of(reconciliations)),
       customCategories = UnmodifiableListView(List.of(customCategories)) {
    _unique(
      this.relationships.map((item) => item.relationshipId),
      'relationshipId',
    );
    _unique(this.occurrences.map((item) => item.occurrenceId), 'occurrenceId');
    _unique(
      this.reconciliations.map((item) => item.reconciliationId),
      'reconciliationId',
    );
    _unique(
      this.reconciliations.map((item) => item.economicFactId),
      'economicFactId',
    );
    _unique(this.customCategories.map((item) => item.id), 'customCategoryId');
    final relationshipIds = this.relationships
        .map((item) => item.relationshipId)
        .toSet();
    final customCategoryIds = this.customCategories
        .map((item) => item.id)
        .toSet();
    final occurrenceById = {
      for (final item in this.occurrences) item.occurrenceId: item,
    };
    final reconciliationIds = this.reconciliations
        .map((item) => item.reconciliationId)
        .toSet();
    for (final relationship in this.relationships) {
      if (relationship.customCategoryId != null &&
          !customCategoryIds.contains(relationship.customCategoryId)) {
        throw ArgumentError('Missing referenced custom income category');
      }
    }
    for (final occurrence in this.occurrences) {
      if (!relationshipIds.contains(occurrence.relationshipId)) {
        throw ArgumentError('Missing referenced income relationship');
      }
      if (occurrence.reconciliationIds.any(
        (id) => !reconciliationIds.contains(id),
      )) {
        throw ArgumentError('Missing referenced income reconciliation');
      }
    }
    for (final reconciliation in this.reconciliations) {
      if (reconciliation.relationshipId != null &&
          !relationshipIds.contains(reconciliation.relationshipId)) {
        throw ArgumentError('Missing reconciliation relationship');
      }
      for (final allocation in reconciliation.allocations) {
        final occurrence = allocation.occurrenceId == null
            ? null
            : occurrenceById[allocation.occurrenceId];
        if (allocation.occurrenceId != null && occurrence == null) {
          throw ArgumentError('Missing reconciliation occurrence');
        }
        if (occurrence != null &&
            occurrence.relationshipId != reconciliation.relationshipId) {
          throw ArgumentError('Reconciliation occurrence mismatch');
        }
      }
    }
  }

  factory IncomeAggregate.empty() => IncomeAggregate();
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
String _required(String value, String field) {
  final result = value.trim();
  if (result.isEmpty) throw ArgumentError.value(value, field);
  return result;
}

String? _optional(String? value, String field) =>
    value == null || value.trim().isEmpty ? null : _required(value, field);
String _string(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a string');
  return value;
}

double _number(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! num) throw FormatException('$field must be a number');
  return value.toDouble();
}

DateTime _date(Map<String, dynamic> json, String field) =>
    DateTime.parse(_string(json, field));
T _enum<T extends Enum>(
  Map<String, dynamic> json,
  String field,
  List<T> values,
) {
  final name = _string(json, field);
  return values.firstWhere(
    (item) => item.name == name,
    orElse: () => throw FormatException('Unknown $field: $name'),
  );
}

List<String> _strings(Map<String, dynamic> json, String field) {
  final value = json[field] ?? const [];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$field must be a string list');
  }
  return value.cast<String>();
}

List<T> _mapList<T>(
  Map<String, dynamic> json,
  String field,
  T Function(Map<String, dynamic>) decode,
) {
  final value = json[field];
  if (value is! List) throw FormatException('$field must be a list');
  return value.map((item) {
    if (item is! Map) throw FormatException('$field item must be an object');
    return decode(Map<String, dynamic>.from(item));
  }).toList();
}

void _unique(Iterable<String> values, String field) {
  final list = values.toList();
  if (list.toSet().length != list.length) {
    throw ArgumentError.value(list, field, 'Must be unique');
  }
}
