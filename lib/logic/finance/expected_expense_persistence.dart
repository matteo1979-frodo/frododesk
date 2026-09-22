import 'dart:collection';
import 'dart:convert';

import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../persistence_store.dart';

class ExpectedExpenseAggregate {
  final UnmodifiableListView<ExpenseRelationship> relationships;
  final UnmodifiableListView<ExpectedExpenseOccurrence> occurrences;

  ExpectedExpenseAggregate({
    Iterable<ExpenseRelationship> relationships = const [],
    Iterable<ExpectedExpenseOccurrence> occurrences = const [],
  }) : relationships = UnmodifiableListView(List.of(relationships)),
       occurrences = UnmodifiableListView(List.of(occurrences));

  factory ExpectedExpenseAggregate.empty() => ExpectedExpenseAggregate();
}

enum ExpectedExpenseWriteFailure {
  invalidPayload,
  backendRejected,
  missingReadBack,
  mismatchedReadBack,
  persistenceError,
}

class ExpectedExpenseWriteResult {
  final ExpectedExpenseWriteFailure? failure;
  final List<String> errors;

  ExpectedExpenseWriteResult._({
    required this.failure,
    required Iterable<String> errors,
  }) : errors = List.unmodifiable(errors);

  factory ExpectedExpenseWriteResult.success() =>
      ExpectedExpenseWriteResult._(failure: null, errors: const []);

  factory ExpectedExpenseWriteResult.failed(
    ExpectedExpenseWriteFailure failure,
    Iterable<String> errors,
  ) => ExpectedExpenseWriteResult._(failure: failure, errors: errors);

  bool get isSuccess => failure == null;
}

typedef ExpectedExpenseLoad = Future<String?> Function(String key);
typedef ExpectedExpenseVerifiedSave =
    Future<PersistenceWriteVerification> Function(String key, String value);

class ExpectedExpensePersistence {
  static const String storageKey = 'finance_expected_expenses_v1';
  static const int version = 1;

  final ExpectedExpenseLoad _load;
  final ExpectedExpenseVerifiedSave _saveVerified;

  ExpectedExpensePersistence({
    ExpectedExpenseLoad? load,
    ExpectedExpenseVerifiedSave? saveVerified,
  }) : _load = load ?? PersistenceStore.loadString,
       _saveVerified = saveVerified ?? PersistenceStore.saveStringVerified;

  Future<ExpectedExpenseAggregate> load() async {
    final raw = await _load(storageKey);
    if (raw == null || raw.isEmpty) return ExpectedExpenseAggregate.empty();

    late final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw FormatException('Invalid expected expenses JSON: ${error.message}');
    }
    if (decoded is! Map) {
      throw const FormatException(
        'Invalid expected expenses payload: root must be an object',
      );
    }

    final envelope = Map<String, dynamic>.from(decoded);
    if (envelope['version'] != version) {
      throw FormatException(
        'Unsupported expected expenses version: ${envelope['version']}',
      );
    }

    final relationships = _parseList(
      envelope: envelope,
      field: 'relationships',
      decode: ExpenseRelationship.fromJson,
    );
    final occurrences = _parseList(
      envelope: envelope,
      field: 'occurrences',
      decode: ExpectedExpenseOccurrence.fromJson,
    );
    final aggregate = ExpectedExpenseAggregate(
      relationships: relationships,
      occurrences: occurrences,
    );
    final errors = _validate(aggregate);
    if (errors.isNotEmpty) {
      throw FormatException(
        'Invalid expected expenses aggregate: ${errors.join('; ')}',
      );
    }
    return aggregate;
  }

  Future<ExpectedExpenseWriteResult> write(
    ExpectedExpenseAggregate candidate,
  ) async {
    final errors = _validate(candidate);
    if (errors.isNotEmpty) {
      return ExpectedExpenseWriteResult.failed(
        ExpectedExpenseWriteFailure.invalidPayload,
        errors,
      );
    }

    final serialized = jsonEncode(_buildEnvelope(candidate));
    late final PersistenceWriteVerification verification;
    try {
      verification = await _saveVerified(storageKey, serialized);
    } catch (error) {
      return ExpectedExpenseWriteResult.failed(
        ExpectedExpenseWriteFailure.persistenceError,
        ['Expected expenses persistence failed: $error'],
      );
    }
    if (!verification.backendAccepted) {
      return ExpectedExpenseWriteResult.failed(
        ExpectedExpenseWriteFailure.backendRejected,
        const ['Expected expenses backend rejected the write'],
      );
    }
    if (verification.readBack == null) {
      return ExpectedExpenseWriteResult.failed(
        ExpectedExpenseWriteFailure.missingReadBack,
        const ['Expected expenses read-back is missing'],
      );
    }
    if (!verification.matches(serialized)) {
      return ExpectedExpenseWriteResult.failed(
        ExpectedExpenseWriteFailure.mismatchedReadBack,
        const ['Expected expenses read-back differs from written payload'],
      );
    }
    return ExpectedExpenseWriteResult.success();
  }

  static Map<String, dynamic> _buildEnvelope(
    ExpectedExpenseAggregate aggregate,
  ) => {
    'version': version,
    'relationships': aggregate.relationships
        .map((relationship) => relationship.toJson())
        .toList(),
    'occurrences': aggregate.occurrences
        .map((occurrence) => occurrence.toJson())
        .toList(),
  };

  static List<T> _parseList<T>({
    required Map<String, dynamic> envelope,
    required String field,
    required T Function(Map<String, dynamic>) decode,
  }) {
    final rawValues = envelope[field];
    if (rawValues is! List) {
      throw FormatException(
        'Invalid expected expenses payload: $field must be a list',
      );
    }
    final values = <T>[];
    for (var index = 0; index < rawValues.length; index++) {
      final rawValue = rawValues[index];
      if (rawValue is! Map) {
        throw FormatException('Invalid $field element at index $index');
      }
      try {
        values.add(decode(Map<String, dynamic>.from(rawValue)));
      } catch (error) {
        throw FormatException('Invalid $field element at index $index: $error');
      }
    }
    return values;
  }

  static List<String> _validate(ExpectedExpenseAggregate aggregate) {
    final errors = <String>[];
    final relationshipIds = <String>{};
    final duplicateRelationshipIds = <String>{};
    for (final relationship in aggregate.relationships) {
      if (!relationshipIds.add(relationship.relationshipId)) {
        duplicateRelationshipIds.add(relationship.relationshipId);
      }
    }
    for (final id in duplicateRelationshipIds.toList()..sort()) {
      errors.add('Duplicate relationshipId: $id');
    }

    final occurrenceIds = <String>{};
    final duplicateOccurrenceIds = <String>{};
    final cycleSequences = <String>{};
    final cycleAnchors = <String>{};
    for (final occurrence in aggregate.occurrences) {
      if (!occurrenceIds.add(occurrence.occurrenceId)) {
        duplicateOccurrenceIds.add(occurrence.occurrenceId);
      }
      if (!relationshipIds.contains(occurrence.relationshipId)) {
        errors.add(
          'Occurrence ${occurrence.occurrenceId} references missing '
          'relationship: ${occurrence.relationshipId}',
        );
      }
      final sequence = occurrence.cycleSequence;
      final anchor = occurrence.cycleAnchor;
      if (sequence != null && anchor != null) {
        final sequenceKey = '${occurrence.relationshipId}#$sequence';
        if (!cycleSequences.add(sequenceKey)) {
          errors.add('Duplicate cycle identity: $sequenceKey');
        }
        final anchorKey =
            '${occurrence.relationshipId}#${anchor.toIso8601String()}';
        if (!cycleAnchors.add(anchorKey)) {
          errors.add('Duplicate cycle anchor: $anchorKey');
        }
      }
    }
    for (final id in duplicateOccurrenceIds.toList()..sort()) {
      errors.add('Duplicate occurrenceId: $id');
    }
    return errors;
  }
}
