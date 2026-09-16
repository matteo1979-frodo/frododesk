import 'package:flutter_test/flutter_test.dart';

import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/real_expense.dart';

void main() {
  group('FinanceTransaction operation metadata persistence', () {
    test('legacy JSON without metadata remains compatible', () {
      final transaction = FinanceTransaction.fromJson(
        _transactionJson()..remove('operationMetadata'),
      );

      expect(transaction.operationMetadata, isNull);
      expect(transaction.toJson()['operationMetadata'], isNull);
    });

    test('round-trips main utility bill metadata', () {
      final metadata = _mainMetadata();
      final restored = FinanceTransaction.fromJson(
        _transaction(operationMetadata: metadata).toJson(),
      );

      _expectMetadata(restored.operationMetadata, metadata);
    });

    test('round-trips bank commission accessory metadata', () {
      final metadata = _accessoryMetadata(AccessoryCostType.bankCommission);
      final restored = FinanceTransaction.fromJson(
        _transaction(operationMetadata: metadata).toJson(),
      );

      _expectMetadata(restored.operationMetadata, metadata);
    });

    test('round-trips postal acceptance accessory metadata', () {
      final metadata = _accessoryMetadata(
        AccessoryCostType.postalAcceptanceCharge,
      );
      final restored = FinanceTransaction.fromJson(
        _transaction(operationMetadata: metadata).toJson(),
      );

      _expectMetadata(restored.operationMetadata, metadata);
    });

    test('invalid metadata fails explicitly', () {
      final json = _transactionJson();
      json['operationMetadata'] = {
        'operationId': 'utility_bill_1',
        'role': 'accessory',
        'context': 'utilityBill',
        'accessoryCostType': 'unknown',
      };

      expect(() => FinanceTransaction.fromJson(json), throwsFormatException);
    });
  });

  group('RealExpense operation metadata persistence', () {
    test('legacy JSON without metadata remains compatible', () {
      final expense = RealExpense.fromJson(
        _expenseJson()..remove('operationMetadata'),
      );

      expect(expense.operationMetadata, isNull);
      expect(expense.toJson()['operationMetadata'], isNull);
    });

    test('round-trips main utility bill metadata', () {
      final metadata = _mainMetadata();
      final restored = RealExpense.fromJson(
        _expense(operationMetadata: metadata).toJson(),
      );

      _expectMetadata(restored.operationMetadata, metadata);
    });

    test('round-trips bank commission accessory metadata', () {
      final metadata = _accessoryMetadata(AccessoryCostType.bankCommission);
      final restored = RealExpense.fromJson(
        _expense(operationMetadata: metadata).toJson(),
      );

      _expectMetadata(restored.operationMetadata, metadata);
    });

    test('round-trips postal acceptance accessory metadata', () {
      final metadata = _accessoryMetadata(
        AccessoryCostType.postalAcceptanceCharge,
      );
      final restored = RealExpense.fromJson(
        _expense(operationMetadata: metadata).toJson(),
      );

      _expectMetadata(restored.operationMetadata, metadata);
    });

    test('invalid metadata fails explicitly', () {
      final json = _expenseJson();
      json['operationMetadata'] = {
        'operationId': 'utility_bill_1',
        'role': 'main',
        'context': 'utilityBill',
        'accessoryCostType': 'bankCommission',
      };

      expect(() => RealExpense.fromJson(json), throwsArgumentError);
    });
  });
}

EconomicOperationMetadata _mainMetadata() => EconomicOperationMetadata(
  operationId: 'utility_bill_1',
  role: OperationRole.main,
  context: OperationContext.utilityBill,
);

EconomicOperationMetadata _accessoryMetadata(AccessoryCostType type) =>
    EconomicOperationMetadata(
      operationId: 'utility_bill_1',
      role: OperationRole.accessory,
      context: OperationContext.utilityBill,
      accessoryCostType: type,
    );

FinanceTransaction _transaction({
  EconomicOperationMetadata? operationMetadata,
}) => FinanceTransaction(
  id: 'transaction_1',
  balanceId: 'balance_1',
  amount: 59.63,
  date: DateTime(2026, 9, 16),
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: 'Pagamento bolletta',
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: 'economic_fact_1',
  operationMetadata: operationMetadata,
);

Map<String, dynamic> _transactionJson() => _transaction().toJson();

RealExpense _expense({EconomicOperationMetadata? operationMetadata}) =>
    RealExpense(
      id: 'expense_1',
      balanceId: 'balance_1',
      balanceName: 'Conto',
      amount: 59.63,
      description: 'Pagamento bolletta',
      category: 'Utenze',
      date: DateTime(2026, 9, 16),
      subject: FinanceSubject.matteo,
      economicFactId: 'economic_fact_1',
      operationMetadata: operationMetadata,
    );

Map<String, dynamic> _expenseJson() => _expense().toJson();

void _expectMetadata(
  EconomicOperationMetadata? actual,
  EconomicOperationMetadata expected,
) {
  expect(actual, isNotNull);
  expect(actual!.operationId, expected.operationId);
  expect(actual.role, expected.role);
  expect(actual.context, expected.context);
  expect(actual.accessoryCostType, expected.accessoryCostType);
}
