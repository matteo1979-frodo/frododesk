import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_transaction_semantics.dart';
import 'package:frododesk/models/composite_correction_metadata.dart';
import 'package:frododesk/models/expense_replacement_metadata.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';

void main() {
  test('true income, expense and transfer retain economic semantics', () {
    expect(
      _transaction('income', income: true).economicRole,
      FinanceTransactionEconomicRole.income,
    );
    expect(
      _transaction('expense').economicRole,
      FinanceTransactionEconomicRole.outflow,
    );
    expect(
      _transaction(
        'transfer',
        type: FinanceTransactionType.transfer,
      ).economicRole,
      FinanceTransactionEconomicRole.transfer,
    );
  });

  test('replacement metadata distinguishes compensation from replacement', () {
    final link = ExpenseReplacementMetadata(
      originalEconomicFactId: 'original',
      replacementEconomicFactId: 'replacement',
      role: ExpenseReplacementRole.compensation,
    );
    expect(
      _transaction(
        'compensation',
        income: true,
        replacement: link,
      ).economicRole,
      FinanceTransactionEconomicRole.compensation,
    );
  });

  test('persisted semantic role marks a general balance compensation', () {
    final transaction = _transaction(
      'restore',
      income: true,
      semanticRole: FinanceTransactionSemanticRole.balanceCompensation,
    );
    final restored = FinanceTransaction.fromJson(transaction.toJson());
    expect(restored.economicRole, FinanceTransactionEconomicRole.compensation);
    expect(
      restored.semanticRole,
      FinanceTransactionSemanticRole.balanceCompensation,
    );
  });

  test('composite correction compensation is not economic income', () {
    final metadata = CompositeCorrectionMetadata(
      correctionId: 'correction',
      operationId: 'operation',
      role: CompositeCorrectionFactRole.compensation,
      revision: 1,
    );
    expect(
      _transaction(
        'compensation',
        income: true,
        composite: metadata,
      ).economicRole,
      FinanceTransactionEconomicRole.compensation,
    );
  });

  test(
    'legacy compensation requires the exact deterministic identity pair',
    () {
      const namespace = 'expense_replacement_dG9rZW4';
      final valid = _transaction(
        '${namespace}_compensation_transaction',
        income: true,
        fact: '${namespace}_compensation_fact',
      );
      final wrongFact = _transaction(
        '${namespace}_compensation_transaction',
        income: true,
        fact: 'unrelated',
      );
      final similarText = _transaction(
        'ordinary',
        income: true,
        description: 'Annullamento Farmacia',
      );
      expect(valid.economicRole, FinanceTransactionEconomicRole.compensation);
      expect(wrongFact.economicRole, FinanceTransactionEconomicRole.income);
      expect(similarText.economicRole, FinanceTransactionEconomicRole.income);
    },
  );
}

FinanceTransaction _transaction(
  String id, {
  bool income = false,
  String? fact,
  String description = 'Voce',
  FinanceTransactionType? type,
  ExpenseReplacementMetadata? replacement,
  CompositeCorrectionMetadata? composite,
  FinanceTransactionSemanticRole semanticRole =
      FinanceTransactionSemanticRole.economicEvent,
}) => FinanceTransaction(
  id: id,
  balanceId: 'balance',
  amount: 10,
  date: DateTime(2026, 9, 1),
  isIncome: income,
  subject: FinanceSubject.shared,
  description: description,
  type:
      type ??
      (income ? FinanceTransactionType.income : FinanceTransactionType.expense),
  origin: FinanceTransactionOrigin.manual,
  economicFactId: fact ?? 'fact:$id',
  expenseReplacementMetadata: replacement,
  compositeCorrectionMetadata: composite,
  semanticRole: semanticRole,
);
