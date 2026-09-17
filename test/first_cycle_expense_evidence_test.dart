import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/first_cycle_expense_evidence.dart';

void main() {
  group('FirstCycleExpenseEvidence', () {
    test('accepts explicit issue-date evidence', () {
      final evidence = _evidence(semantic: ExpenseEvidenceDateSemantic.issue);

      expect(evidence.economicFactId, 'economic_fact_1');
      expect(evidence.amount, 59.63);
      expect(evidence.referenceDate, DateTime(2026, 8, 24));
      expect(evidence.referenceDateSemantic, ExpenseEvidenceDateSemantic.issue);
    });

    test('accepts explicit due-date evidence', () {
      final evidence = _evidence(semantic: ExpenseEvidenceDateSemantic.due);

      expect(evidence.referenceDateSemantic, ExpenseEvidenceDateSemantic.due);
    });

    test('rejects invalid amounts and economic fact identifiers', () {
      for (final amount in [0.0, -1.0, double.infinity, double.nan]) {
        expect(() => _evidence(amount: amount), throwsArgumentError);
      }
      expect(() => _evidence(economicFactId: '  '), throwsArgumentError);
    });

    test('accepts structurally identified main operation metadata', () {
      final metadata = EconomicOperationMetadata(
        operationId: 'utility_operation_1',
        role: OperationRole.main,
        context: OperationContext.utilityBill,
      );

      final evidence = _evidence(metadata: metadata);

      expect(evidence.operationMetadata, same(metadata));
    });

    test('rejects structurally identified accessory operation metadata', () {
      final metadata = EconomicOperationMetadata(
        operationId: 'utility_operation_1',
        role: OperationRole.accessory,
        context: OperationContext.utilityBill,
        accessoryCostType: AccessoryCostType.bankCommission,
      );

      expect(() => _evidence(metadata: metadata), throwsArgumentError);
    });

    test('accepts explicitly supplied legacy evidence without metadata', () {
      final evidence = _evidence();

      expect(evidence.operationMetadata, isNull);
    });

    test('contains no description or category heuristic inputs', () {
      final evidence = _evidence();

      expect(evidence.economicFactId, isNotEmpty);
      expect(evidence.operationMetadata?.role, isNot(OperationRole.accessory));
    });
  });
}

FirstCycleExpenseEvidence _evidence({
  String economicFactId = 'economic_fact_1',
  double amount = 59.63,
  ExpenseEvidenceDateSemantic semantic = ExpenseEvidenceDateSemantic.issue,
  EconomicOperationMetadata? metadata,
}) => FirstCycleExpenseEvidence(
  economicFactId: economicFactId,
  amount: amount,
  referenceDate: DateTime(2026, 8, 24),
  referenceDateSemantic: semantic,
  operationMetadata: metadata,
);
