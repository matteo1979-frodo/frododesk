import 'dart:convert';

import '../../models/finite_financial_plan.dart';
import '../persistence_store.dart';

enum FiniteFinancialPlanWriteFailure {
  invalidPayload,
  backendRejected,
  missingReadBack,
  mismatchedReadBack,
  persistenceError,
}

class FiniteFinancialPlanWriteResult {
  final FiniteFinancialPlanWriteFailure? failure;
  final List<String> errors;

  FiniteFinancialPlanWriteResult._({
    required this.failure,
    required Iterable<String> errors,
  }) : errors = List.unmodifiable(errors);

  factory FiniteFinancialPlanWriteResult.success() =>
      FiniteFinancialPlanWriteResult._(failure: null, errors: const []);

  factory FiniteFinancialPlanWriteResult.failed(
    FiniteFinancialPlanWriteFailure failure,
    Iterable<String> errors,
  ) => FiniteFinancialPlanWriteResult._(failure: failure, errors: errors);

  bool get isSuccess => failure == null;
}

typedef FiniteFinancialPlanLoad = Future<String?> Function(String key);
typedef FiniteFinancialPlanVerifiedSave =
    Future<PersistenceWriteVerification> Function(String key, String value);

class FiniteFinancialPlanPersistence {
  static const String storageKey = 'finance_finite_financial_plans';
  static const int version = 1;

  final FiniteFinancialPlanLoad _load;
  final FiniteFinancialPlanVerifiedSave _saveVerified;

  FiniteFinancialPlanPersistence({
    FiniteFinancialPlanLoad? load,
    FiniteFinancialPlanVerifiedSave? saveVerified,
  }) : _load = load ?? PersistenceStore.loadString,
       _saveVerified = saveVerified ?? PersistenceStore.saveStringVerified;

  Future<List<FiniteFinancialPlan>> load() async {
    final raw = await _load(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    late final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw FormatException(
        'Invalid finite financial plans JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const FormatException(
        'Invalid finite financial plans payload: root must be an object',
      );
    }

    final envelope = Map<String, dynamic>.from(decoded);
    if (envelope['version'] != version) {
      throw FormatException(
        'Unsupported finite financial plans version: ${envelope['version']}',
      );
    }
    final rawPlans = envelope['plans'];
    if (rawPlans is! List) {
      throw const FormatException(
        'Invalid finite financial plans payload: plans must be a list',
      );
    }

    final plans = <FiniteFinancialPlan>[];
    for (var index = 0; index < rawPlans.length; index++) {
      final rawPlan = rawPlans[index];
      if (rawPlan is! Map) {
        throw FormatException('Invalid finite financial plan at index $index');
      }
      try {
        plans.add(
          FiniteFinancialPlan.fromJson(Map<String, dynamic>.from(rawPlan)),
        );
      } catch (error) {
        throw FormatException(
          'Invalid finite financial plan at index $index: $error',
        );
      }
    }
    final errors = _validate(plans);
    if (errors.isNotEmpty) {
      throw FormatException(
        'Invalid finite financial plans: ${errors.join('; ')}',
      );
    }
    return List.unmodifiable(plans);
  }

  Future<FiniteFinancialPlanWriteResult> write(
    Iterable<FiniteFinancialPlan> plans,
  ) async {
    final candidate = List<FiniteFinancialPlan>.of(plans);
    final errors = _validate(candidate);
    if (errors.isNotEmpty) {
      return FiniteFinancialPlanWriteResult.failed(
        FiniteFinancialPlanWriteFailure.invalidPayload,
        errors,
      );
    }

    final serialized = jsonEncode({
      'version': version,
      'plans': candidate.map((plan) => plan.toJson()).toList(),
    });
    late final PersistenceWriteVerification verification;
    try {
      verification = await _saveVerified(storageKey, serialized);
    } catch (error) {
      return FiniteFinancialPlanWriteResult.failed(
        FiniteFinancialPlanWriteFailure.persistenceError,
        ['Finite financial plans persistence failed: $error'],
      );
    }
    if (!verification.backendAccepted) {
      return FiniteFinancialPlanWriteResult.failed(
        FiniteFinancialPlanWriteFailure.backendRejected,
        const ['Finite financial plans backend rejected the write'],
      );
    }
    if (verification.readBack == null) {
      return FiniteFinancialPlanWriteResult.failed(
        FiniteFinancialPlanWriteFailure.missingReadBack,
        const ['Finite financial plans read-back is missing'],
      );
    }
    if (!verification.matches(serialized)) {
      return FiniteFinancialPlanWriteResult.failed(
        FiniteFinancialPlanWriteFailure.mismatchedReadBack,
        const ['Finite financial plans read-back differs from written payload'],
      );
    }
    return FiniteFinancialPlanWriteResult.success();
  }

  static List<String> _validate(Iterable<FiniteFinancialPlan> plans) {
    final ids = <String>{};
    final duplicates = <String>{};
    for (final plan in plans) {
      if (!ids.add(plan.id)) duplicates.add(plan.id);
    }
    return [
      for (final id in duplicates.toList()..sort())
        'Duplicate finite financial plan id: $id',
    ];
  }
}
