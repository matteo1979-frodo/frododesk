import 'dart:collection';

import 'expense_relationship.dart';
import 'finance_recurring_item.dart';

enum ExpectedExpenseOccurrenceStatus { pending, resolved, cancelled }

enum ExpenseEstimationMethod {
  firstAvailableFact,
  previousComparablePeriod,
  personalHistory,
  externalEvidence,
  manualEstimate,
}

enum ExpenseEstimateConfidence { low, medium, high }

class ExpectedPaymentWindow {
  final DateTime start;
  final DateTime end;

  ExpectedPaymentWindow({required this.start, required this.end}) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'Must not be before start');
    }
  }

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  factory ExpectedPaymentWindow.fromJson(Map<String, dynamic> json) =>
      ExpectedPaymentWindow(
        start: _requiredDate(json, 'start'),
        end: _requiredDate(json, 'end'),
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
  final ExpectedExpenseOccurrenceStatus status;
  final DateTime? expectedIssueDate;
  final DateTime? expectedDueDate;
  final ExpectedPaymentWindow? expectedPaymentWindow;
  final double expectedAmount;
  final ExpenseEstimationMethod estimationMethod;
  final UnmodifiableListView<String> evidenceEconomicFactIds;
  final ExpenseEstimateConfidence confidence;
  final bool provisional;
  final ExpenseRelationshipPaymentConfiguration expectedPaymentConfiguration;
  final FinanceSubject expectedSubject;
  final String? resolvedEconomicFactId;

  ExpectedExpenseOccurrence({
    required String occurrenceId,
    required String relationshipId,
    required this.status,
    this.expectedIssueDate,
    this.expectedDueDate,
    this.expectedPaymentWindow,
    required this.expectedAmount,
    required this.estimationMethod,
    List<String> evidenceEconomicFactIds = const [],
    required this.confidence,
    required this.provisional,
    required this.expectedPaymentConfiguration,
    required this.expectedSubject,
    String? resolvedEconomicFactId,
  }) : occurrenceId = _requiredText(occurrenceId, 'occurrenceId'),
       relationshipId = _requiredText(relationshipId, 'relationshipId'),
       evidenceEconomicFactIds = UnmodifiableListView(
         _validatedEvidence(evidenceEconomicFactIds),
       ),
       resolvedEconomicFactId = _optionalText(
         resolvedEconomicFactId,
         'resolvedEconomicFactId',
       ) {
    if (!expectedAmount.isFinite || expectedAmount <= 0) {
      throw ArgumentError.value(
        expectedAmount,
        'expectedAmount',
        'Must be finite and greater than zero',
      );
    }
    if (expectedIssueDate == null &&
        expectedDueDate == null &&
        expectedPaymentWindow == null) {
      throw ArgumentError(
        'At least one expected issue, due or payment-window date is required',
      );
    }
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
  }

  Map<String, dynamic> toJson() => {
    'occurrenceId': occurrenceId,
    'relationshipId': relationshipId,
    'status': status.name,
    'expectedIssueDate': expectedIssueDate?.toIso8601String(),
    'expectedDueDate': expectedDueDate?.toIso8601String(),
    'expectedPaymentWindow': expectedPaymentWindow?.toJson(),
    'expectedAmount': expectedAmount,
    'estimationMethod': estimationMethod.name,
    'evidenceEconomicFactIds': evidenceEconomicFactIds.toList(),
    'confidence': confidence.name,
    'provisional': provisional,
    'expectedPaymentConfiguration': expectedPaymentConfiguration.toJson(),
    'expectedSubject': expectedSubject.name,
    'resolvedEconomicFactId': resolvedEconomicFactId,
  };

  factory ExpectedExpenseOccurrence.fromJson(Map<String, dynamic> json) {
    final issueDate = _optionalDate(json, 'expectedIssueDate');
    final dueDate = _optionalDate(json, 'expectedDueDate');
    final rawWindow = json['expectedPaymentWindow'];
    if (rawWindow != null && rawWindow is! Map) {
      throw const FormatException('expectedPaymentWindow must be an object');
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
    return ExpectedExpenseOccurrence(
      occurrenceId: _jsonString(json, 'occurrenceId'),
      relationshipId: _jsonString(json, 'relationshipId'),
      status: _enumValue(
        json,
        'status',
        ExpectedExpenseOccurrenceStatus.values,
        (value) => value.name,
      ),
      expectedIssueDate: issueDate,
      expectedDueDate: dueDate,
      expectedPaymentWindow: rawWindow == null
          ? null
          : ExpectedPaymentWindow.fromJson(
              Map<String, dynamic>.from(rawWindow),
            ),
      expectedAmount: expectedAmount.toDouble(),
      estimationMethod: _enumValue(
        json,
        'estimationMethod',
        ExpenseEstimationMethod.values,
        (value) => value.name,
      ),
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
      expectedSubject: _enumValue(
        json,
        'expectedSubject',
        FinanceSubject.values,
        (value) => value.name,
      ),
      resolvedEconomicFactId: resolvedFact as String?,
    );
  }
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
