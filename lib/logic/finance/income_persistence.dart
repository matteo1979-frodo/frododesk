import 'dart:convert';

import '../../models/income.dart';
import '../persistence_store.dart';

enum IncomeWriteFailure {
  invalidPayload,
  backendRejected,
  missingReadBack,
  mismatchedReadBack,
  persistenceError,
}

class IncomeWriteResult {
  final IncomeWriteFailure? failure;
  final List<String> errors;

  const IncomeWriteResult._(this.failure, this.errors);
  const IncomeWriteResult.success() : this._(null, const []);
  IncomeWriteResult.failed(IncomeWriteFailure failure, Iterable<String> errors)
    : this._(failure, List.unmodifiable(errors));

  bool get isSuccess => failure == null;
}

typedef IncomeLoad = Future<String?> Function(String key);
typedef IncomeSave =
    Future<PersistenceWriteVerification> Function(String key, String value);

class IncomePersistence {
  static const storageKey = 'finance_incomes_v1';
  static const version = 1;

  final IncomeLoad _load;
  final IncomeSave _save;

  IncomePersistence({IncomeLoad? load, IncomeSave? save})
    : _load = load ?? PersistenceStore.loadString,
      _save = save ?? PersistenceStore.saveStringVerified;

  Future<IncomeAggregate> load() async {
    final raw = await _load(storageKey);
    if (raw == null || raw.isEmpty) return IncomeAggregate.empty();
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['version'] != version) {
      throw const FormatException('Unsupported income payload');
    }
    return IncomeAggregate(
      relationships: _list(
        decoded,
        'relationships',
        IncomeRelationship.fromJson,
      ),
      occurrences: _list(
        decoded,
        'occurrences',
        ExpectedIncomeOccurrence.fromJson,
      ),
      reconciliations: _list(
        decoded,
        'reconciliations',
        IncomeReconciliation.fromJson,
      ),
      customCategories: _list(
        decoded,
        'customCategories',
        IncomeCustomCategory.fromJson,
      ),
    );
  }

  Future<IncomeWriteResult> write(IncomeAggregate aggregate) async {
    late final String serialized;
    try {
      serialized = jsonEncode({
        'version': version,
        'relationships': aggregate.relationships
            .map((item) => item.toJson())
            .toList(),
        'occurrences': aggregate.occurrences
            .map((item) => item.toJson())
            .toList(),
        'reconciliations': aggregate.reconciliations
            .map((item) => item.toJson())
            .toList(),
        'customCategories': aggregate.customCategories
            .map((item) => item.toJson())
            .toList(),
      });
    } catch (error) {
      return IncomeWriteResult.failed(IncomeWriteFailure.invalidPayload, [
        '$error',
      ]);
    }
    late final PersistenceWriteVerification verification;
    try {
      verification = await _save(storageKey, serialized);
    } catch (error) {
      return IncomeWriteResult.failed(IncomeWriteFailure.persistenceError, [
        '$error',
      ]);
    }
    if (!verification.backendAccepted) {
      return IncomeWriteResult.failed(
        IncomeWriteFailure.backendRejected,
        const ['Income write was rejected'],
      );
    }
    if (verification.readBack == null) {
      return IncomeWriteResult.failed(
        IncomeWriteFailure.missingReadBack,
        const ['Income read-back is missing'],
      );
    }
    if (!verification.matches(serialized)) {
      return IncomeWriteResult.failed(
        IncomeWriteFailure.mismatchedReadBack,
        const ['Income read-back differs'],
      );
    }
    return const IncomeWriteResult.success();
  }

  List<T> _list<T>(
    Map<dynamic, dynamic> json,
    String field,
    T Function(Map<String, dynamic>) decode,
  ) {
    final raw = json[field] ?? const [];
    if (raw is! List) throw FormatException('$field must be a list');
    return raw.map((item) {
      if (item is! Map) throw FormatException('$field item must be an object');
      return decode(Map<String, dynamic>.from(item));
    }).toList();
  }
}
