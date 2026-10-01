import 'dart:convert';

import '../persistence_store.dart';
import 'finance_portfolio_v3_contract.dart';

enum FinancePortfolioV3WriteFailure {
  invalidPayload,
  backendRejected,
  missingReadBack,
  mismatchedReadBack,
  persistenceError,
}

class FinancePortfolioV3WriteResult {
  final FinancePortfolioV3WriteFailure? failure;
  final List<String> errors;

  FinancePortfolioV3WriteResult._({
    required this.failure,
    required Iterable<String> errors,
  }) : errors = List.unmodifiable(errors);

  factory FinancePortfolioV3WriteResult.success() {
    return FinancePortfolioV3WriteResult._(failure: null, errors: const []);
  }

  factory FinancePortfolioV3WriteResult.failed(
    FinancePortfolioV3WriteFailure failure,
    Iterable<String> errors,
  ) {
    return FinancePortfolioV3WriteResult._(failure: failure, errors: errors);
  }

  bool get isSuccess => failure == null;
}

typedef FinancePortfolioV3VerifiedSave =
    Future<PersistenceWriteVerification> Function(String key, String value);
typedef FinancePortfolioV3Load = Future<String?> Function(String key);

class FinancePortfolioV3Writer {
  static const String storageKey = 'finance_portfolio_v3';

  final FinancePortfolioV3VerifiedSave _saveVerified;
  final FinancePortfolioV3Load _load;

  FinancePortfolioV3Writer({
    FinancePortfolioV3VerifiedSave? saveVerified,
    FinancePortfolioV3Load? load,
  }) : _saveVerified = saveVerified ?? PersistenceStore.saveStringVerified,
       _load = load ?? PersistenceStore.loadString;

  Future<FinancePortfolioV3WriteResult> write(
    FinancePortfolioV3 portfolio,
  ) async {
    final validation = FinancePortfolioV3Validator.validate(portfolio);
    if (!validation.isValid) {
      return FinancePortfolioV3WriteResult.failed(
        FinancePortfolioV3WriteFailure.invalidPayload,
        validation.errors,
      );
    }

    final serialized = jsonEncode(FinancePortfolioV3Contract.build(portfolio));
    late final PersistenceWriteVerification verification;
    try {
      verification = await _saveVerified(storageKey, serialized);
    } catch (error) {
      return FinancePortfolioV3WriteResult.failed(
        FinancePortfolioV3WriteFailure.persistenceError,
        ['Portfolio V3 persistence failed: $error'],
      );
    }

    if (!verification.backendAccepted) {
      return FinancePortfolioV3WriteResult.failed(
        FinancePortfolioV3WriteFailure.backendRejected,
        const ['Portfolio V3 backend rejected the write'],
      );
    }
    if (verification.readBack == null) {
      return FinancePortfolioV3WriteResult.failed(
        FinancePortfolioV3WriteFailure.missingReadBack,
        const ['Portfolio V3 read-back is missing'],
      );
    }
    if (!verification.matches(serialized)) {
      return FinancePortfolioV3WriteResult.failed(
        FinancePortfolioV3WriteFailure.mismatchedReadBack,
        const ['Portfolio V3 read-back differs from the written payload'],
      );
    }

    return FinancePortfolioV3WriteResult.success();
  }

  Future<FinancePortfolioV3WriteResult> writeIfCurrent({
    required Map<String, dynamic> expectedCurrent,
    required FinancePortfolioV3 candidate,
  }) async {
    try {
      final persisted = await _load(storageKey);
      if (persisted == null || persisted != jsonEncode(expectedCurrent)) {
        return FinancePortfolioV3WriteResult.failed(
          FinancePortfolioV3WriteFailure.invalidPayload,
          const ['Portfolio V3 persisted snapshot changed'],
        );
      }
    } catch (error) {
      return FinancePortfolioV3WriteResult.failed(
        FinancePortfolioV3WriteFailure.persistenceError,
        ['Portfolio V3 snapshot read failed: $error'],
      );
    }
    return write(candidate);
  }
}
