import '../../models/composite_correction_metadata.dart';
import '../../models/expense_replacement_metadata.dart';
import '../../models/finance_transaction.dart';

enum FinanceTransactionEconomicRole { income, outflow, transfer, compensation }

extension FinanceTransactionSemantics on FinanceTransaction {
  FinanceTransactionEconomicRole get economicRole {
    if (type == FinanceTransactionType.transfer) {
      return FinanceTransactionEconomicRole.transfer;
    }
    if (expenseReplacementMetadata?.role ==
            ExpenseReplacementRole.compensation ||
        compositeCorrectionMetadata?.role ==
            CompositeCorrectionFactRole.compensation ||
        semanticRole == FinanceTransactionSemanticRole.balanceCompensation ||
        _isDeterministicLegacyExpenseReplacementCompensation) {
      return FinanceTransactionEconomicRole.compensation;
    }
    return type == FinanceTransactionType.income
        ? FinanceTransactionEconomicRole.income
        : FinanceTransactionEconomicRole.outflow;
  }

  bool get _isDeterministicLegacyExpenseReplacementCompensation {
    const prefix = 'expense_replacement_';
    const transactionSuffix = '_compensation_transaction';
    if (!id.startsWith(prefix) || !id.endsWith(transactionSuffix)) return false;
    final namespace = id.substring(0, id.length - transactionSuffix.length);
    if (namespace.length == prefix.length) return false;
    final token = namespace.substring(prefix.length);
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(token)) return false;
    return economicFactId == '${namespace}_compensation_fact';
  }
}
