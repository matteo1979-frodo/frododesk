import 'dart:collection';

import 'expense_relationship.dart';
import 'documentary_obligation.dart';
import 'finance_recurring_item.dart';
import 'planned_economic_impact.dart';

enum ExpectedExpenseOccurrenceStatus { pending, resolved, cancelled }

enum ExpectedExpenseKnowledgeState { forecast, knownUnpaid }

enum ExpectedExpenseKnowledgeSource { userConfirmed, legacyUnspecified }

enum ExpenseEstimationMethod {
  firstAvailableFact,
  previousComparablePeriod,
  personalHistory,
  externalEvidence,
  manualEstimate,
  documentaryObligation,
}

enum ExpenseEstimateConfidence { low, medium, high }

enum ExpectedExpenseDateSource {
  explicit,
  calculatedFromPeriodicity,

  /// Backward-compatible representation for JSON written before temporal
  /// provenance existed. It deliberately makes no claim about date origin.
  legacyUnspecified,
}

enum ExpectedExpenseDateCertainty { estimated, known, legacyUnspecified }

enum ExpectedPaymentWindowSemantic {
  userPreferred,
  expectedDebit,
  legacyUnspecified,
}

enum ExpectedPaymentWindowOrigin {
  relationshipDefault,
  occurrenceOverride,
  legacyUnspecified,
}

enum ExpectedTemporalConfidence { low, medium, high, legacyUnspecified }

class ExpectedPaymentWindow {
  final DateTime start;
  final DateTime end;
  final ExpectedPaymentWindowSemantic semantic;
  final ExpectedExpenseDateSource source;
  final ExpectedTemporalConfidence confidence;
  final ExpectedPaymentWindowOrigin origin;

  ExpectedPaymentWindow({
    required this.start,
    required this.end,
    this.semantic = ExpectedPaymentWindowSemantic.legacyUnspecified,
    this.source = ExpectedExpenseDateSource.legacyUnspecified,
    this.confidence = ExpectedTemporalConfidence.legacyUnspecified,
    this.origin = ExpectedPaymentWindowOrigin.legacyUnspecified,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'Must not be before start');
    }
  }

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'semantic': semantic.name,
    'source': source.name,
    'confidence': confidence.name,
    'origin': origin.name,
  };

  factory ExpectedPaymentWindow.fromJson(Map<String, dynamic> json) =>
      ExpectedPaymentWindow(
        start: _requiredDate(json, 'start'),
        end: _requiredDate(json, 'end'),
        semantic: _optionalEnumValue(
          json,
          'semantic',
          ExpectedPaymentWindowSemantic.values,
          (value) => value.name,
          ExpectedPaymentWindowSemantic.legacyUnspecified,
        ),
        source: _optionalEnumValue(
          json,
          'source',
          ExpectedExpenseDateSource.values,
          (value) => value.name,
          ExpectedExpenseDateSource.legacyUnspecified,
        ),
        confidence: _optionalEnumValue(
          json,
          'confidence',
          ExpectedTemporalConfidence.values,
          (value) => value.name,
          ExpectedTemporalConfidence.legacyUnspecified,
        ),
        origin: _optionalEnumValue(
          json,
          'origin',
          ExpectedPaymentWindowOrigin.values,
          (value) => value.name,
          ExpectedPaymentWindowOrigin.legacyUnspecified,
        ),
      );
}

/// A future expense expected from a continuing [ExpenseRelationship].
///
/// This is a forecast contract only. It is not an economic fact, transaction,
/// expense or balance mutation. Evidence refers to real economic facts by ID
/// without copying their payload.
class ExpectedExpenseOccurrence {
  final String occurrenceId;
  final String relationshipId;
  final int? cycleSequence;
  final DateTime? cycleAnchor;
  final ExpectedDocumentPeriod? expectedPeriod;
  final ExpectedExpenseOccurrenceStatus status;
  final ExpectedExpenseKnowledgeState knowledgeState;
  final ExpectedExpenseKnowledgeSource knowledgeSource;
  final DateTime? expectedIssueDate;
  final ExpectedExpenseDateSource? expectedIssueDateSource;
  final DateTime? expectedDueDate;
  final ExpectedExpenseDateSource? expectedDueDateSource;
  final ExpectedExpenseDateCertainty? expectedDueDateCertainty;
  final ExpectedPaymentWindow? expectedPaymentWindow;
  final PlannedEconomicImpact? plannedEconomicImpact;
  final double expectedAmount;
  final ExpenseEstimationMethod estimationMethod;
  final String? sourceDocumentaryObligationId;
  final UnmodifiableListView<String> evidenceEconomicFactIds;
  final ExpenseEstimateConfidence confidence;
  final bool provisional;
  final ExpenseRelationshipPaymentConfiguration expectedPaymentConfiguration;
  final PaymentExecutionMode paymentExecutionMode;
  final FinanceSubject expectedSubject;
  final String? resolvedEconomicFactId;
  final bool participatesInCycleProjection;

  ExpectedExpenseOccurrence({
    required String occurrenceId,
    required String relationshipId,
    this.cycleSequence,
    this.cycleAnchor,
    this.expectedPeriod,
    required this.status,
    this.knowledgeState = ExpectedExpenseKnowledgeState.forecast,
    this.knowledgeSource = ExpectedExpenseKnowledgeSource.legacyUnspecified,
    this.expectedIssueDate,
    this.expectedIssueDateSource,
    this.expectedDueDate,
    this.expectedDueDateSource,
    ExpectedExpenseDateCertainty? expectedDueDateCertainty,
    this.expectedPaymentWindow,
    this.plannedEconomicImpact,
    required this.expectedAmount,
    required this.estimationMethod,
    String? sourceDocumentaryObligationId,
    List<String> evidenceEconomicFactIds = const [],
    required this.confidence,
    required this.provisional,
    required this.expectedPaymentConfiguration,
    this.paymentExecutionMode = PaymentExecutionMode.unknown,
    required this.expectedSubject,
    String? resolvedEconomicFactId,
    this.participatesInCycleProjection = true,
  }) : occurrenceId = _requiredText(occurrenceId, 'occurrenceId'),
       relationshipId = _requiredText(relationshipId, 'relationshipId'),
       expectedDueDateCertainty = expectedDueDate == null
           ? null
           : expectedDueDateCertainty ??
                 ExpectedExpenseDateCertainty.legacyUnspecified,
       evidenceEconomicFactIds = UnmodifiableListView(
         _validatedEvidence(evidenceEconomicFactIds),
       ),
       sourceDocumentaryObligationId = _optionalText(
         sourceDocumentaryObligationId,
         'sourceDocumentaryObligationId',
       ),
       resolvedEconomicFactId = _optionalText(
         resolvedEconomicFactId,
         'resolvedEconomicFactId',
       ) {
    if ((cycleSequence == null) !=
        (cycleAnchor == null && expectedPeriod == null)) {
      throw ArgumentError(
        'cycleSequence and a cycleAnchor or expectedPeriod must either both be present or both be absent',
      );
    }
    if (cycleAnchor != null && expectedPeriod != null) {
      throw ArgumentError(
        'cycleAnchor and expectedPeriod are alternative temporal precisions',
      );
    }
    if (cycleSequence != null && cycleSequence! <= 0) {
      throw ArgumentError.value(
        cycleSequence,
        'cycleSequence',
        'Must be greater than zero',
      );
    }
    if (expectedDueDate == null && expectedDueDateCertainty != null) {
      throw ArgumentError(
        'expectedDueDateCertainty must be null when expectedDueDate is absent',
      );
    }
    if (knowledgeState == ExpectedExpenseKnowledgeState.knownUnpaid &&
        knowledgeSource == ExpectedExpenseKnowledgeSource.legacyUnspecified) {
      throw ArgumentError.value(
        knowledgeSource,
        'knowledgeSource',
        'Known unpaid occurrences require explicit informational provenance',
      );
    }
    if (knowledgeState == ExpectedExpenseKnowledgeState.forecast &&
        knowledgeSource != ExpectedExpenseKnowledgeSource.legacyUnspecified) {
      throw ArgumentError.value(
        knowledgeSource,
        'knowledgeSource',
        'Forecast occurrences cannot claim known informational provenance',
      );
    }
    if (!expectedAmount.isFinite || expectedAmount <= 0) {
      throw ArgumentError.value(
        expectedAmount,
        'expectedAmount',
        'Must be finite and greater than zero',
      );
    }
    if (expectedIssueDate == null &&
        expectedDueDate == null &&
        expectedPaymentWindow == null &&
        expectedPeriod == null) {
      throw ArgumentError(
        'At least one expected issue, due, payment-window date or expected period is required',
      );
    }
    _validateDateSource(
      date: expectedIssueDate,
      source: expectedIssueDateSource,
      dateField: 'expectedIssueDate',
      sourceField: 'expectedIssueDateSource',
    );
    _validateDateSource(
      date: expectedDueDate,
      source: expectedDueDateSource,
      dateField: 'expectedDueDate',
      sourceField: 'expectedDueDateSource',
    );
    _validateDueDateCertainty(
      date: expectedDueDate,
      certainty: this.expectedDueDateCertainty,
    );
    if (expectedIssueDate != null &&
        expectedDueDate != null &&
        expectedDueDate!.isBefore(expectedIssueDate!)) {
      throw ArgumentError.value(
        expectedDueDate,
        'expectedDueDate',
        'Must not be before expectedIssueDate',
      );
    }
    if (expectedIssueDate != null &&
        expectedPaymentWindow != null &&
        expectedPaymentWindow!.end.isBefore(expectedIssueDate!)) {
      throw ArgumentError.value(
        expectedPaymentWindow,
        'expectedPaymentWindow',
        'Must not end before expectedIssueDate',
      );
    }
    if (status == ExpectedExpenseOccurrenceStatus.resolved) {
      if (this.resolvedEconomicFactId == null) {
        throw ArgumentError.value(
          resolvedEconomicFactId,
          'resolvedEconomicFactId',
          'Must be present for a resolved occurrence',
        );
      }
    } else if (this.resolvedEconomicFactId != null) {
      throw ArgumentError.value(
        resolvedEconomicFactId,
        'resolvedEconomicFactId',
        'Must be null unless the occurrence is resolved',
      );
    }
    if (_requiresPersonalEconomicEvidence(estimationMethod) &&
        this.evidenceEconomicFactIds.isEmpty) {
      throw ArgumentError.value(
        evidenceEconomicFactIds,
        'evidenceEconomicFactIds',
        'The estimation method requires economic-fact evidence',
      );
    }
    if (estimationMethod == ExpenseEstimationMethod.documentaryObligation &&
        this.sourceDocumentaryObligationId == null) {
      throw ArgumentError.value(
        sourceDocumentaryObligationId,
        'sourceDocumentaryObligationId',
        'Documentary estimates require their source obligation',
      );
    }
  }

  ExpectedExpenseOccurrence copyWith({
    Object? cycleSequence = _preserveValue,
    Object? cycleAnchor = _preserveValue,
    Object? expectedPeriod = _preserveValue,
    ExpectedExpenseOccurrenceStatus? status,
    ExpectedExpenseKnowledgeState? knowledgeState,
    ExpectedExpenseKnowledgeSource? knowledgeSource,
    Object? expectedIssueDate = _preserveValue,
    Object? expectedIssueDateSource = _preserveValue,
    Object? expectedDueDate = _preserveValue,
    Object? expectedDueDateSource = _preserveValue,
    Object? expectedDueDateCertainty = _preserveValue,
    Object? expectedPaymentWindow = _preserveValue,
    Object? plannedEconomicImpact = _preserveValue,
    double? expectedAmount,
    ExpenseEstimationMethod? estimationMethod,
    Object? sourceDocumentaryObligationId = _preserveValue,
    List<String>? evidenceEconomicFactIds,
    ExpenseEstimateConfidence? confidence,
    bool? provisional,
    ExpenseRelationshipPaymentConfiguration? expectedPaymentConfiguration,
    PaymentExecutionMode? paymentExecutionMode,
    FinanceSubject? expectedSubject,
    Object? resolvedEconomicFactId = _preserveValue,
    bool? participatesInCycleProjection,
  }) => ExpectedExpenseOccurrence(
    occurrenceId: occurrenceId,
    relationshipId: relationshipId,
    cycleSequence: identical(cycleSequence, _preserveValue)
        ? this.cycleSequence
        : cycleSequence as int?,
    cycleAnchor: identical(cycleAnchor, _preserveValue)
        ? this.cycleAnchor
        : cycleAnchor as DateTime?,
    expectedPeriod: identical(expectedPeriod, _preserveValue)
        ? this.expectedPeriod
        : expectedPeriod as ExpectedDocumentPeriod?,
    status: status ?? this.status,
    knowledgeState: knowledgeState ?? this.knowledgeState,
    knowledgeSource: knowledgeSource ?? this.knowledgeSource,
    expectedIssueDate: identical(expectedIssueDate, _preserveValue)
        ? this.expectedIssueDate
        : expectedIssueDate as DateTime?,
    expectedIssueDateSource: identical(expectedIssueDateSource, _preserveValue)
        ? this.expectedIssueDateSource
        : expectedIssueDateSource as ExpectedExpenseDateSource?,
    expectedDueDate: identical(expectedDueDate, _preserveValue)
        ? this.expectedDueDate
        : expectedDueDate as DateTime?,
    expectedDueDateSource: identical(expectedDueDateSource, _preserveValue)
        ? this.expectedDueDateSource
        : expectedDueDateSource as ExpectedExpenseDateSource?,
    expectedDueDateCertainty:
        !identical(expectedDueDate, _preserveValue) && expectedDueDate == null
        ? null
        : identical(expectedDueDateCertainty, _preserveValue)
        ? this.expectedDueDateCertainty
        : expectedDueDateCertainty as ExpectedExpenseDateCertainty?,
    expectedPaymentWindow: identical(expectedPaymentWindow, _preserveValue)
        ? this.expectedPaymentWindow
        : expectedPaymentWindow as ExpectedPaymentWindow?,
    plannedEconomicImpact: identical(plannedEconomicImpact, _preserveValue)
        ? this.plannedEconomicImpact
        : plannedEconomicImpact as PlannedEconomicImpact?,
    expectedAmount: expectedAmount ?? this.expectedAmount,
    estimationMethod: estimationMethod ?? this.estimationMethod,
    sourceDocumentaryObligationId:
        identical(sourceDocumentaryObligationId, _preserveValue)
        ? this.sourceDocumentaryObligationId
        : sourceDocumentaryObligationId as String?,
    evidenceEconomicFactIds:
        evidenceEconomicFactIds ?? this.evidenceEconomicFactIds,
    confidence: confidence ?? this.confidence,
    provisional: provisional ?? this.provisional,
    expectedPaymentConfiguration:
        expectedPaymentConfiguration ?? this.expectedPaymentConfiguration,
    paymentExecutionMode: paymentExecutionMode ?? this.paymentExecutionMode,
    expectedSubject: expectedSubject ?? this.expectedSubject,
    resolvedEconomicFactId: identical(resolvedEconomicFactId, _preserveValue)
        ? this.resolvedEconomicFactId
        : resolvedEconomicFactId as String?,
    participatesInCycleProjection:
        participatesInCycleProjection ?? this.participatesInCycleProjection,
  );

  Map<String, dynamic> toJson() => {
    'occurrenceId': occurrenceId,
    'relationshipId': relationshipId,
    'cycleSequence': cycleSequence,
    'cycleAnchor': cycleAnchor?.toIso8601String(),
    'expectedPeriod': expectedPeriod?.toJson(),
    'status': status.name,
    'knowledgeState': knowledgeState.name,
    'knowledgeSource': knowledgeSource.name,
    'expectedIssueDate': expectedIssueDate?.toIso8601String(),
    'expectedIssueDateSource': expectedIssueDateSource?.name,
    'expectedDueDate': expectedDueDate?.toIso8601String(),
    'expectedDueDateSource': expectedDueDateSource?.name,
    'expectedDueDateCertainty': expectedDueDateCertainty?.name,
    'expectedPaymentWindow': expectedPaymentWindow?.toJson(),
    'plannedEconomicImpact': plannedEconomicImpact?.toJson(),
    'expectedAmount': expectedAmount,
    'estimationMethod': estimationMethod.name,
    'sourceDocumentaryObligationId': sourceDocumentaryObligationId,
    'evidenceEconomicFactIds': evidenceEconomicFactIds.toList(),
    'confidence': confidence.name,
    'provisional': provisional,
    'expectedPaymentConfiguration': expectedPaymentConfiguration.toJson(),
    'paymentExecutionMode': paymentExecutionMode.name,
    'expectedSubject': expectedSubject.name,
    'resolvedEconomicFactId': resolvedEconomicFactId,
    if (!participatesInCycleProjection)
      'participatesInCycleProjection': false,
  };

  factory ExpectedExpenseOccurrence.fromJson(Map<String, dynamic> json) {
    final issueDate = _optionalDate(json, 'expectedIssueDate');
    final dueDate = _optionalDate(json, 'expectedDueDate');
    final issueSource = _dateSourceFromJson(
      json,
      'expectedIssueDateSource',
      datePresent: issueDate != null,
    );
    final dueSource = _dateSourceFromJson(
      json,
      'expectedDueDateSource',
      datePresent: dueDate != null,
    );
    final dueCertainty = _dueDateCertaintyFromJson(
      json,
      datePresent: dueDate != null,
    );
    final rawWindow = json['expectedPaymentWindow'];
    if (rawWindow != null && rawWindow is! Map) {
      throw const FormatException('expectedPaymentWindow must be an object');
    }
    final rawPlannedImpact = json['plannedEconomicImpact'];
    if (rawPlannedImpact != null && rawPlannedImpact is! Map) {
      throw const FormatException('plannedEconomicImpact must be an object');
    }
    final rawExpectedPeriod = json['expectedPeriod'];
    if (rawExpectedPeriod != null && rawExpectedPeriod is! Map) {
      throw const FormatException('expectedPeriod must be an object');
    }
    final rawEvidence = json['evidenceEconomicFactIds'];
    if (rawEvidence is! List || rawEvidence.any((item) => item is! String)) {
      throw const FormatException(
        'evidenceEconomicFactIds must be a string list',
      );
    }
    final rawPayment = json['expectedPaymentConfiguration'];
    if (rawPayment is! Map) {
      throw const FormatException(
        'expectedPaymentConfiguration must be an object',
      );
    }
    final expectedAmount = json['expectedAmount'];
    if (expectedAmount is! num) {
      throw const FormatException('expectedAmount must be a number');
    }
    final provisional = json['provisional'];
    if (provisional is! bool) {
      throw const FormatException('provisional must be a boolean');
    }
    final resolvedFact = json['resolvedEconomicFactId'];
    if (resolvedFact != null && resolvedFact is! String) {
      throw const FormatException(
        'resolvedEconomicFactId must be a string or null',
      );
    }
    final participates = json['participatesInCycleProjection'] ?? true;
    if (participates is! bool) {
      throw const FormatException(
        'participatesInCycleProjection must be a boolean',
      );
    }
    return ExpectedExpenseOccurrence(
      occurrenceId: _jsonString(json, 'occurrenceId'),
      relationshipId: _jsonString(json, 'relationshipId'),
      cycleSequence: _optionalPositiveInt(json, 'cycleSequence'),
      cycleAnchor: _optionalDate(json, 'cycleAnchor'),
      expectedPeriod: rawExpectedPeriod == null
          ? null
          : ExpectedDocumentPeriod.fromJson(
              Map<String, dynamic>.from(rawExpectedPeriod),
            ),
      status: _enumValue(
        json,
        'status',
        ExpectedExpenseOccurrenceStatus.values,
        (value) => value.name,
      ),
      knowledgeState: _optionalEnumValue(
        json,
        'knowledgeState',
        ExpectedExpenseKnowledgeState.values,
        (value) => value.name,
        ExpectedExpenseKnowledgeState.forecast,
      ),
      knowledgeSource: _optionalEnumValue(
        json,
        'knowledgeSource',
        ExpectedExpenseKnowledgeSource.values,
        (value) => value.name,
        ExpectedExpenseKnowledgeSource.legacyUnspecified,
      ),
      expectedIssueDate: issueDate,
      expectedIssueDateSource: issueSource,
      expectedDueDate: dueDate,
      expectedDueDateSource: dueSource,
      expectedDueDateCertainty: dueCertainty,
      expectedPaymentWindow: rawWindow == null
          ? null
          : ExpectedPaymentWindow.fromJson(
              Map<String, dynamic>.from(rawWindow),
            ),
      plannedEconomicImpact: rawPlannedImpact == null
          ? null
          : PlannedEconomicImpact.fromJson(
              Map<String, dynamic>.from(rawPlannedImpact),
            ),
      expectedAmount: expectedAmount.toDouble(),
      estimationMethod: _enumValue(
        json,
        'estimationMethod',
        ExpenseEstimationMethod.values,
        (value) => value.name,
      ),
      sourceDocumentaryObligationId:
          json['sourceDocumentaryObligationId'] as String?,
      evidenceEconomicFactIds: List<String>.from(rawEvidence),
      confidence: _enumValue(
        json,
        'confidence',
        ExpenseEstimateConfidence.values,
        (value) => value.name,
      ),
      provisional: provisional,
      expectedPaymentConfiguration:
          ExpenseRelationshipPaymentConfiguration.fromJson(
            Map<String, dynamic>.from(rawPayment),
          ),
      paymentExecutionMode: _optionalEnumValue(
        json,
        'paymentExecutionMode',
        PaymentExecutionMode.values,
        (value) => value.name,
        PaymentExecutionMode.unknown,
      ),
      expectedSubject: _enumValue(
        json,
        'expectedSubject',
        FinanceSubject.values,
        (value) => value.name,
      ),
      resolvedEconomicFactId: resolvedFact as String?,
      participatesInCycleProjection: participates,
    );
  }
}

void _validateDueDateCertainty({
  required DateTime? date,
  required ExpectedExpenseDateCertainty? certainty,
}) {
  if (date != null && certainty == null) {
    throw ArgumentError(
      'expectedDueDateCertainty is required when expectedDueDate is present',
    );
  }
  if (date == null && certainty != null) {
    throw ArgumentError(
      'expectedDueDateCertainty must be null when expectedDueDate is absent',
    );
  }
}

ExpectedExpenseDateCertainty? _dueDateCertaintyFromJson(
  Map<String, dynamic> json, {
  required bool datePresent,
}) {
  final raw = json['expectedDueDateCertainty'];
  if (raw == null) {
    return datePresent ? ExpectedExpenseDateCertainty.legacyUnspecified : null;
  }
  if (raw is! String) {
    throw const FormatException(
      'expectedDueDateCertainty must be a string or null',
    );
  }
  for (final value in ExpectedExpenseDateCertainty.values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unknown expectedDueDateCertainty: $raw');
}

const Object _preserveValue = Object();

void _validateDateSource({
  required DateTime? date,
  required ExpectedExpenseDateSource? source,
  required String dateField,
  required String sourceField,
}) {
  if (date != null && source == null) {
    throw ArgumentError('$sourceField is required when $dateField is present');
  }
  if (date == null && source != null) {
    throw ArgumentError('$sourceField must be null when $dateField is absent');
  }
}

ExpectedExpenseDateSource? _dateSourceFromJson(
  Map<String, dynamic> json,
  String key, {
  required bool datePresent,
}) {
  final raw = json[key];
  if (raw == null) {
    return datePresent ? ExpectedExpenseDateSource.legacyUnspecified : null;
  }
  if (raw is! String) throw FormatException('$key must be a string or null');
  for (final value in ExpectedExpenseDateSource.values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unknown $key: $raw');
}

bool _requiresPersonalEconomicEvidence(ExpenseEstimationMethod method) =>
    method == ExpenseEstimationMethod.firstAvailableFact ||
    method == ExpenseEstimationMethod.previousComparablePeriod ||
    method == ExpenseEstimationMethod.personalHistory;

List<String> _validatedEvidence(List<String> values) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final normalized = _requiredText(value, 'evidenceEconomicFactIds');
    if (!seen.add(normalized)) {
      throw ArgumentError.value(
        values,
        'evidenceEconomicFactIds',
        'Must not contain duplicates',
      );
    }
    result.add(normalized);
  }
  return result;
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty');
  }
  return normalized;
}

String? _optionalText(String? value, String field) {
  if (value == null) return null;
  return _requiredText(value, field);
}

String _jsonString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string');
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('$key must be an ISO date');
  return parsed;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('$key must be a string or null');
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('$key must be an ISO date');
  return parsed;
}

int? _optionalPositiveInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int || value <= 0) {
    throw FormatException('$key must be a positive integer or null');
  }
  return value;
}

T _enumValue<T>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
  String Function(T value) nameOf,
) {
  final raw = json[key];
  if (raw is! String) throw FormatException('$key must be a string');
  for (final value in values) {
    if (nameOf(value) == raw) return value;
  }
  throw FormatException('Unknown $key: $raw');
}

T _optionalEnumValue<T>(
  Map<String, dynamic> json,
  String key,
  List<T> values,
  String Function(T value) nameOf,
  T fallback,
) {
  final raw = json[key];
  if (raw == null) return fallback;
  if (raw is! String) throw FormatException('$key must be a string or null');
  for (final value in values) {
    if (nameOf(value) == raw) return value;
  }
  throw FormatException('Unknown $key: $raw');
}
