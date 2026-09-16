import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/composite_economic_operation.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';

void main() {
  group('CompositeEconomicOperation', () {
    test('accepts one main fact without accessories', () {
      final operation = _operation();

      expect(operation.main.economicFactId, 'fact-main');
      expect(operation.accessories, isEmpty);
      expect(operation.totalAmount, 59.63);
    });

    test('accepts a bank commission accessory', () {
      final operation = _operation(accessories: [_accessory('fact-fee', 2)]);

      expect(operation.accessories, hasLength(1));
      expect(
        operation.accessories.single.operationMetadata.accessoryCostType,
        AccessoryCostType.bankCommission,
      );
      expect(operation.totalAmount, closeTo(61.63, 0.000001));
    });

    test('represents the synthetic utility bill fixture', () {
      final operation = _operation(
        accessories: [
          _accessory('fact-bank-fee', 2),
          _accessory(
            'fact-postal-fee',
            1,
            type: AccessoryCostType.postalAcceptanceCharge,
          ),
        ],
      );

      expect(operation.totalAmount, closeTo(62.63, 0.000001));
      expect(operation.accessories, hasLength(2));
    });

    test('generates coherent metadata for every fact', () {
      final operation = _operation(
        accessories: [
          _accessory('fact-bank-fee', 2),
          _accessory(
            'fact-postal-fee',
            1,
            type: AccessoryCostType.postalAcceptanceCharge,
          ),
        ],
      );
      final facts = [operation.main, ...operation.accessories];

      expect(operation.main.operationMetadata.role, OperationRole.main);
      expect(operation.main.operationMetadata.accessoryCostType, isNull);
      expect(
        operation.accessories.first.operationMetadata.role,
        OperationRole.accessory,
      );
      expect(
        operation.accessories.first.operationMetadata.accessoryCostType,
        AccessoryCostType.bankCommission,
      );
      expect(
        operation.accessories.last.operationMetadata.accessoryCostType,
        AccessoryCostType.postalAcceptanceCharge,
      );
      expect(facts.map((fact) => fact.operationMetadata.operationId).toSet(), {
        'operation-utility',
      });
      expect(facts.map((fact) => fact.operationMetadata.context).toSet(), {
        OperationContext.utilityBill,
      });
      expect(facts.map((fact) => fact.economicFactId).toSet(), hasLength(3));
    });

    test('normalizes operation and fact identities', () {
      final operation = CompositeEconomicOperation(
        operationId: '  operation  ',
        context: OperationContext.cashWithdrawal,
        mainEconomicFactId: '  main  ',
        mainAmount: 40,
        accessories: [_accessory('  fee  ', 1)],
      );

      expect(operation.operationId, 'operation');
      expect(operation.main.economicFactId, 'main');
      expect(operation.accessories.single.economicFactId, 'fee');
      expect(operation.main.operationMetadata.operationId, 'operation');
    });

    test('rejects empty operation and economic fact identities', () {
      expect(() => _operation(operationId: '   '), throwsArgumentError);
      expect(() => _operation(mainEconomicFactId: ''), throwsArgumentError);
      expect(
        () => _operation(accessories: [_accessory('   ', 1)]),
        throwsArgumentError,
      );
    });

    test('rejects duplicate main/accessory fact identity', () {
      expect(
        () => _operation(accessories: [_accessory('fact-main', 1)]),
        throwsArgumentError,
      );
    });

    test('rejects duplicate accessory fact identities', () {
      expect(
        () => _operation(
          accessories: [_accessory('fact-fee', 1), _accessory('fact-fee', 2)],
        ),
        throwsArgumentError,
      );
    });

    test('rejects zero, negative and non-finite amounts', () {
      for (final amount in [0.0, -1.0, double.infinity, double.nan]) {
        expect(() => _operation(mainAmount: amount), throwsArgumentError);
        expect(
          () => _operation(accessories: [_accessory('fact-fee', amount)]),
          throwsArgumentError,
        );
      }
    });

    test('allows more than two accessories', () {
      final operation = _operation(
        context: OperationContext.financialPlanInstallment,
        accessories: [
          _accessory('fee-1', 1),
          _accessory('fee-2', 2),
          _accessory('fee-3', 3),
        ],
      );

      expect(operation.accessories, hasLength(3));
      expect(operation.totalAmount, closeTo(65.63, 0.000001));
    });

    test('owns an immutable copy of accessory input', () {
      final input = [_accessory('fact-fee', 2)];
      final operation = _operation(accessories: input);

      input.clear();

      expect(operation.accessories, hasLength(1));
      expect(() => operation.accessories.clear(), throwsUnsupportedError);
    });

    test('contains no Hera-specific or infrastructure semantics', () {
      final operation = _operation(context: OperationContext.cashWithdrawal);

      expect(operation.context, OperationContext.cashWithdrawal);
      expect(operation.main.operationMetadata.context, operation.context);
    });
  });
}

CompositeEconomicOperation _operation({
  String operationId = 'operation-utility',
  OperationContext context = OperationContext.utilityBill,
  String mainEconomicFactId = 'fact-main',
  double mainAmount = 59.63,
  List<CompositeEconomicAccessoryInput> accessories = const [],
}) => CompositeEconomicOperation(
  operationId: operationId,
  context: context,
  mainEconomicFactId: mainEconomicFactId,
  mainAmount: mainAmount,
  accessories: accessories,
);

CompositeEconomicAccessoryInput _accessory(
  String economicFactId,
  double amount, {
  AccessoryCostType type = AccessoryCostType.bankCommission,
}) => (economicFactId: economicFactId, amount: amount, accessoryCostType: type);
