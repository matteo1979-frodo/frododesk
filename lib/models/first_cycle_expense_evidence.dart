import 'economic_operation_metadata.dart';

enum ExpenseEvidenceDateSemantic { issue, due }

/// Minimal, pure projection of a real economic fact used as first-cycle
/// forecasting evidence.
///
/// It does not duplicate or persist the source fact. The caller explicitly
/// supplies the date semantic because RealExpense and FinanceTransaction do
/// not encode whether their date is an issue or due date.
class FirstCycleExpenseEvidence {
  final String economicFactId;
  final double amount;
  final DateTime referenceDate;
  final ExpenseEvidenceDateSemantic referenceDateSemantic;
  final EconomicOperationMetadata? operationMetadata;

  FirstCycleExpenseEvidence({
    required String economicFactId,
    required this.amount,
    required this.referenceDate,
    required this.referenceDateSemantic,
    this.operationMetadata,
  }) : economicFactId = _requiredText(economicFactId, 'economicFactId') {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Must be finite and greater than zero',
      );
    }
    if (operationMetadata?.role == OperationRole.accessory) {
      throw ArgumentError.value(
        operationMetadata,
        'operationMetadata',
        'An accessory fact cannot be first-cycle main-expense evidence',
      );
    }
  }
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty');
  }
  return normalized;
}
