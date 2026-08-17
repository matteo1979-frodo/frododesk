import '../../../models/economic_event.dart';
import '../../../models/finance_asset_movement.dart';
import '../economic_event_adapter.dart';

class FinanceAssetMovementEventAdapter
    implements EconomicEventAdapter<FinanceAssetMovement> {
  final EconomicCategoryRef? category;
  final String? personId;

  const FinanceAssetMovementEventAdapter({this.category, this.personId});

  @override
  EconomicEvent adapt(
    FinanceAssetMovement source, {
    required DateTime observedAt,
    String? eventId,
  }) {
    final origins = source.legs
        .where((leg) => leg.delta < 0)
        .map(_endpoint)
        .toList();
    final destinations = source.legs
        .where((leg) => leg.delta > 0)
        .map(_endpoint)
        .toList();
    final amount = source.legs
        .where((leg) => leg.delta > 0)
        .fold<double>(0, (sum, leg) => sum + leg.delta.abs());

    return EconomicEvent(
      id: eventId ?? 'finance_asset_movement:${source.id}',
      economicFactId: source.economicFactId,
      observedAt: observedAt,
      occurredAt: source.occurredAt,
      origins: origins,
      destinations: destinations,
      category: category,
      personId: personId,
      description: source.description,
      amount: amount,
      nature: source.kind == FinanceAssetMovementKind.fundExpense
          ? EconomicNature.outflow
          : EconomicNature.internalTransfer,
      sourceLinks: [
        EconomicSourceLink(
          kind: EconomicSourceKind.financeAssetMovement,
          recordId: source.id,
        ),
      ],
    );
  }

  EconomicEndpoint _endpoint(FinanceAssetLeg leg) => EconomicEndpoint(
    kind: switch (leg.type) {
      FinanceAssetLegType.balance => EconomicEndpointKind.account,
      FinanceAssetLegType.fund => EconomicEndpointKind.fund,
      FinanceAssetLegType.openingBalance => EconomicEndpointKind.openingBalance,
      FinanceAssetLegType.expense => EconomicEndpointKind.external,
      FinanceAssetLegType.legacyCounterpart => EconomicEndpointKind.other,
    },
    referenceId: leg.referenceId,
    label: switch (leg.type) {
      FinanceAssetLegType.balance => 'Conto',
      FinanceAssetLegType.fund => 'Fondo',
      FinanceAssetLegType.openingBalance => 'Saldo già esistente',
      FinanceAssetLegType.expense => 'Spesa sostenuta',
      FinanceAssetLegType.legacyCounterpart => 'Contropartita precedente',
    },
    amount: leg.delta.abs(),
  );
}
