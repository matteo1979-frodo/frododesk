import 'finance_portfolio_v3_contract.dart';
import 'finance_portfolio_v3_writer.dart';

enum FinancePortfolioV3CommitFailure {
  snapshotConflict,
  transformationFailed,
  validationFailed,
  writerFailed,
}

class FinancePortfolioV3CommitResult {
  final FinancePortfolioV3CommitFailure? failure;
  final FinancePortfolioV3WriteResult? writeResult;
  final List<String> errors;

  FinancePortfolioV3CommitResult._({
    required this.failure,
    required this.writeResult,
    required Iterable<String> errors,
  }) : errors = List.unmodifiable(errors);

  factory FinancePortfolioV3CommitResult.success(
    FinancePortfolioV3WriteResult writeResult,
  ) {
    return FinancePortfolioV3CommitResult._(
      failure: null,
      writeResult: writeResult,
      errors: const [],
    );
  }

  factory FinancePortfolioV3CommitResult.failed({
    required FinancePortfolioV3CommitFailure failure,
    required Iterable<String> errors,
    FinancePortfolioV3WriteResult? writeResult,
  }) {
    return FinancePortfolioV3CommitResult._(
      failure: failure,
      writeResult: writeResult,
      errors: errors,
    );
  }

  bool get isSuccess => failure == null;
}

typedef FinancePortfolioV3Transformation =
    FinancePortfolioV3 Function(FinancePortfolioV3 current);
