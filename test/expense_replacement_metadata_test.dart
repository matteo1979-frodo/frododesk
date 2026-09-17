import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/expense_replacement_metadata.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';

void main() {
  group('ExpenseReplacementMetadata contract', () {
    test('constructs valid compensation and replacement metadata', () {
      final compensation = _metadata(ExpenseReplacementRole.compensation);
      final replacement = _metadata(ExpenseReplacementRole.replacement);

      expect(compensation.originalEconomicFactId, 'fact-a');
      expect(compensation.replacementEconomicFactId, 'fact-b');
      expect(replacement.role, ExpenseReplacementRole.replacement);
    });

    test('rejects empty and equal economic fact identities', () {
      expect(
        () => ExpenseReplacementMetadata(
          originalEconomicFactId: '',
          replacementEconomicFactId: 'fact-b',
          role: ExpenseReplacementRole.compensation,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseReplacementMetadata(
          originalEconomicFactId: 'fact-a',
          replacementEconomicFactId: ' ',
          role: ExpenseReplacementRole.compensation,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseReplacementMetadata(
          originalEconomicFactId: 'fact-a',
          replacementEconomicFactId: 'fact-a',
          role: ExpenseReplacementRole.replacement,
        ),
        throwsArgumentError,
      );
    });

    for (final role in ExpenseReplacementRole.values) {
      test('round-trips ${role.name} JSON', () {
        final metadata = _metadata(role);
        final restored = ExpenseReplacementMetadata.fromJson(metadata.toJson());

        expect(restored.originalEconomicFactId, 'fact-a');
        expect(restored.replacementEconomicFactId, 'fact-b');
        expect(restored.role, role);
      });
    }

    test('rejects missing, wrong-type and unknown JSON fields', () {
      expect(
        () => ExpenseReplacementMetadata.fromJson({
          'replacementEconomicFactId': 'fact-b',
          'role': 'compensation',
        }),
        throwsFormatException,
      );
      expect(
        () => ExpenseReplacementMetadata.fromJson({
          'originalEconomicFactId': 1,
          'replacementEconomicFactId': 'fact-b',
          'role': 'compensation',
        }),
        throwsFormatException,
      );
      expect(
        () => ExpenseReplacementMetadata.fromJson({
          'originalEconomicFactId': 'fact-a',
          'replacementEconomicFactId': 'fact-b',
          'role': 'unknown',
        }),
        throwsFormatException,
      );
    });

    test('represents a replacement chain without skipping a fact', () {
      final aToB = ExpenseReplacementMetadata(
        originalEconomicFactId: 'fact-a',
        replacementEconomicFactId: 'fact-b',
        role: ExpenseReplacementRole.replacement,
      );
      final bToC = ExpenseReplacementMetadata(
        originalEconomicFactId: 'fact-b',
        replacementEconomicFactId: 'fact-c',
        role: ExpenseReplacementRole.replacement,
      );

      expect(aToB.replacementEconomicFactId, bToC.originalEconomicFactId);
      expect(bToC.originalEconomicFactId, isNot('fact-a'));
    });
  });

  group('FinanceTransaction persistence', () {
    test('legacy JSON without replacement metadata remains valid', () {
      final json = _transaction().toJson()
        ..remove('expenseReplacementMetadata');

      expect(
        FinanceTransaction.fromJson(json).expenseReplacementMetadata,
        isNull,
      );
    });

    test('round-trips replacement metadata beside operation metadata', () {
      final operationMetadata = EconomicOperationMetadata(
        operationId: 'utility-operation',
        role: OperationRole.main,
        context: OperationContext.utilityBill,
      );
      final restored = FinanceTransaction.fromJson(
        _transaction(
          replacementMetadata: _metadata(ExpenseReplacementRole.replacement),
          operationMetadata: operationMetadata,
        ).toJson(),
      );

      expect(restored.operationMetadata?.operationId, 'utility-operation');
      expect(
        restored.expenseReplacementMetadata?.role,
        ExpenseReplacementRole.replacement,
      );
    });

    test('present null or invalid replacement metadata fails explicitly', () {
      final nullMetadata = _transaction().toJson()
        ..['expenseReplacementMetadata'] = null;
      expect(
        () => FinanceTransaction.fromJson(nullMetadata),
        throwsFormatException,
      );
      final invalidMetadata = _transaction().toJson()
        ..['expenseReplacementMetadata'] = {'role': 'replacement'};
      expect(
        () => FinanceTransaction.fromJson(invalidMetadata),
        throwsFormatException,
      );
    });
  });
}

ExpenseReplacementMetadata _metadata(ExpenseReplacementRole role) =>
    ExpenseReplacementMetadata(
      originalEconomicFactId: 'fact-a',
      replacementEconomicFactId: 'fact-b',
      role: role,
    );

FinanceTransaction _transaction({
  ExpenseReplacementMetadata? replacementMetadata,
  EconomicOperationMetadata? operationMetadata,
}) => FinanceTransaction(
  id: 'transaction',
  balanceId: 'account',
  amount: 10,
  date: DateTime(2026, 9, 17),
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: 'Expense',
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: 'fact-b',
  operationMetadata: operationMetadata,
  expenseReplacementMetadata: replacementMetadata,
);
