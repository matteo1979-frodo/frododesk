import 'package:flutter_test/flutter_test.dart';

import 'package:frododesk/models/economic_operation_metadata.dart';

void main() {
  group('EconomicOperationMetadata', () {
    test('accepts main cash withdrawal metadata', () {
      final metadata = EconomicOperationMetadata(
        operationId: 'withdrawal_1',
        role: OperationRole.main,
        context: OperationContext.cashWithdrawal,
      );

      expect(metadata.operationId, 'withdrawal_1');
      expect(metadata.role, OperationRole.main);
      expect(metadata.context, OperationContext.cashWithdrawal);
      expect(metadata.accessoryCostType, isNull);
    });

    test('accepts main financial plan installment metadata', () {
      final metadata = EconomicOperationMetadata(
        operationId: 'installment_3',
        role: OperationRole.main,
        context: OperationContext.financialPlanInstallment,
      );

      expect(metadata.context, OperationContext.financialPlanInstallment);
    });

    test('accepts bank commission accessory for a cash withdrawal', () {
      final metadata = EconomicOperationMetadata(
        operationId: 'withdrawal_1',
        role: OperationRole.accessory,
        context: OperationContext.cashWithdrawal,
        accessoryCostType: AccessoryCostType.bankCommission,
      );

      expect(metadata.accessoryCostType, AccessoryCostType.bankCommission);
    });

    test('accepts bank commission accessory for an installment', () {
      final metadata = EconomicOperationMetadata(
        operationId: 'installment_3',
        role: OperationRole.accessory,
        context: OperationContext.financialPlanInstallment,
        accessoryCostType: AccessoryCostType.bankCommission,
      );

      expect(metadata.accessoryCostType, AccessoryCostType.bankCommission);
    });

    test('rejects an accessory cost type on a main fact', () {
      expect(
        () => EconomicOperationMetadata(
          operationId: 'withdrawal_1',
          role: OperationRole.main,
          context: OperationContext.cashWithdrawal,
          accessoryCostType: AccessoryCostType.bankCommission,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an accessory fact without its cost type', () {
      expect(
        () => EconomicOperationMetadata(
          operationId: 'withdrawal_1',
          role: OperationRole.accessory,
          context: OperationContext.cashWithdrawal,
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty and whitespace-only operation identifiers', () {
      for (final operationId in ['', '   ']) {
        expect(
          () => EconomicOperationMetadata(
            operationId: operationId,
            role: OperationRole.main,
            context: OperationContext.cashWithdrawal,
          ),
          throwsArgumentError,
        );
      }
    });

    test('trims a valid operation identifier', () {
      final metadata = EconomicOperationMetadata(
        operationId: '  withdrawal_1  ',
        role: OperationRole.main,
        context: OperationContext.cashWithdrawal,
      );

      expect(metadata.operationId, 'withdrawal_1');
    });

    test('round-trips main metadata through stable JSON names', () {
      final source = EconomicOperationMetadata(
        operationId: 'withdrawal_1',
        role: OperationRole.main,
        context: OperationContext.cashWithdrawal,
      );

      final json = source.toJson();
      final restored = EconomicOperationMetadata.fromJson(json);

      expect(json, {
        'operationId': 'withdrawal_1',
        'role': 'main',
        'context': 'cashWithdrawal',
        'accessoryCostType': null,
      });
      expect(restored.operationId, source.operationId);
      expect(restored.role, source.role);
      expect(restored.context, source.context);
      expect(restored.accessoryCostType, isNull);
    });

    test('round-trips accessory metadata through stable JSON names', () {
      final source = EconomicOperationMetadata(
        operationId: 'installment_3',
        role: OperationRole.accessory,
        context: OperationContext.financialPlanInstallment,
        accessoryCostType: AccessoryCostType.bankCommission,
      );

      final json = source.toJson();
      final restored = EconomicOperationMetadata.fromJson(json);

      expect(json, {
        'operationId': 'installment_3',
        'role': 'accessory',
        'context': 'financialPlanInstallment',
        'accessoryCostType': 'bankCommission',
      });
      expect(restored.operationId, source.operationId);
      expect(restored.role, source.role);
      expect(restored.context, source.context);
      expect(restored.accessoryCostType, source.accessoryCostType);
    });

    test('rejects unknown enum values without a fallback', () {
      final validMain = {
        'operationId': 'operation_1',
        'role': 'main',
        'context': 'cashWithdrawal',
        'accessoryCostType': null,
      };

      for (final invalidJson in [
        {...validMain, 'role': 'other'},
        {...validMain, 'context': 'utilityBill'},
        {
          ...validMain,
          'role': 'accessory',
          'accessoryCostType': 'serviceCharge',
        },
      ]) {
        expect(
          () => EconomicOperationMetadata.fromJson(invalidJson),
          throwsFormatException,
        );
      }
    });

    test('rejects incomplete and malformed JSON', () {
      for (final invalidJson in <Map<String, dynamic>>[
        {},
        {'operationId': 'operation_1'},
        {'operationId': 1, 'role': 'main', 'context': 'cashWithdrawal'},
        {'operationId': 'operation_1', 'role': 1, 'context': 'cashWithdrawal'},
        {'operationId': 'operation_1', 'role': 'main', 'context': null},
      ]) {
        expect(
          () => EconomicOperationMetadata.fromJson(invalidJson),
          throwsFormatException,
        );
      }
    });

    test('contains no descriptive or categorical heuristic fields', () {
      final json = EconomicOperationMetadata(
        operationId: 'operation_1',
        role: OperationRole.main,
        context: OperationContext.cashWithdrawal,
      ).toJson();

      expect(json, isNot(contains('description')));
      expect(json, isNot(contains('category')));
      expect(json, isNot(contains('name')));
      expect(json, isNot(contains('economicFactId')));
    });

    test('allows multiple accessories to share one operation identifier', () {
      final first = EconomicOperationMetadata(
        operationId: 'operation_1',
        role: OperationRole.accessory,
        context: OperationContext.cashWithdrawal,
        accessoryCostType: AccessoryCostType.bankCommission,
      );
      final second = EconomicOperationMetadata(
        operationId: 'operation_1',
        role: OperationRole.accessory,
        context: OperationContext.cashWithdrawal,
        accessoryCostType: AccessoryCostType.bankCommission,
      );

      expect(first.operationId, second.operationId);
    });
  });
}
