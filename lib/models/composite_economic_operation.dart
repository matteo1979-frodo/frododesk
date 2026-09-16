import 'dart:collection';

import 'economic_operation_metadata.dart';

typedef CompositeEconomicAccessoryInput = ({
  String economicFactId,
  double amount,
  AccessoryCostType accessoryCostType,
});

class CompositeEconomicFact {
  final String economicFactId;
  final double amount;
  final EconomicOperationMetadata operationMetadata;

  const CompositeEconomicFact._({
    required this.economicFactId,
    required this.amount,
    required this.operationMetadata,
  });
}

/// Pure, immutable contract for one main economic fact and its accessory
/// costs. It creates no economic records and performs no persistence.
class CompositeEconomicOperation {
  final String operationId;
  final OperationContext context;
  final CompositeEconomicFact main;
  final UnmodifiableListView<CompositeEconomicFact> accessories;

  CompositeEconomicOperation({
    required String operationId,
    required this.context,
    required String mainEconomicFactId,
    required double mainAmount,
    List<CompositeEconomicAccessoryInput> accessories = const [],
  }) : operationId = _validatedId(operationId, 'operationId'),
       main = CompositeEconomicFact._(
         economicFactId: _validatedId(mainEconomicFactId, 'mainEconomicFactId'),
         amount: _validatedAmount(mainAmount, 'mainAmount'),
         operationMetadata: EconomicOperationMetadata(
           operationId: operationId,
           role: OperationRole.main,
           context: context,
         ),
       ),
       accessories = UnmodifiableListView(
         accessories
             .map(
               (input) => CompositeEconomicFact._(
                 economicFactId: _validatedId(
                   input.economicFactId,
                   'accessoryEconomicFactId',
                 ),
                 amount: _validatedAmount(input.amount, 'accessoryAmount'),
                 operationMetadata: EconomicOperationMetadata(
                   operationId: operationId,
                   role: OperationRole.accessory,
                   context: context,
                   accessoryCostType: input.accessoryCostType,
                 ),
               ),
             )
             .toList(),
       ) {
    final economicFactIds = <String>{main.economicFactId};
    for (final accessory in this.accessories) {
      if (!economicFactIds.add(accessory.economicFactId)) {
        throw ArgumentError.value(
          accessory.economicFactId,
          'economicFactId',
          'Must be unique within the operation',
        );
      }
    }
  }

  double get totalAmount => accessories.fold(
    main.amount,
    (total, accessory) => total + accessory.amount,
  );

  static String _validatedId(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be empty');
    }
    return normalized;
  }

  static double _validatedAmount(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        'Must be finite and greater than zero',
      );
    }
    return value;
  }
}
