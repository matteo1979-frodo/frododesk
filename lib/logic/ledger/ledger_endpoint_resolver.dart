import '../../models/economic_event.dart';
import '../../models/ledger_resolved_endpoint.dart';

class LedgerEndpointResolver {
  final LedgerEndpointRegistry registry;

  const LedgerEndpointResolver({required this.registry});

  LedgerResolvedEndpoint resolve(EconomicEndpoint endpoint) {
    final records = switch (endpoint.kind) {
      EconomicEndpointKind.account => registry.accounts,
      EconomicEndpointKind.fund => registry.funds,
      EconomicEndpointKind.cash => registry.cashWallets,
      _ => null,
    };

    if (records != null) {
      final record = endpoint.referenceId == null
          ? null
          : records[endpoint.referenceId];
      final personId = endpoint.personId ?? record?.personId;
      return LedgerResolvedEndpoint(
        kind: endpoint.kind,
        referenceId: endpoint.referenceId,
        label: record?.label ?? _missingReferenceLabel(endpoint.kind),
        personId: personId,
        personLabel: _personLabel(personId),
        amount: endpoint.amount,
        usesHistoricalFallback: record == null,
      );
    }

    final personId = endpoint.personId;
    return LedgerResolvedEndpoint(
      kind: endpoint.kind,
      referenceId: endpoint.referenceId,
      label: _standaloneLabel(endpoint),
      personId: personId,
      personLabel: _personLabel(personId),
      amount: endpoint.amount,
      usesHistoricalFallback: false,
    );
  }

  LedgerResolvedEventEndpoints resolveEvent(EconomicEvent event) {
    return LedgerResolvedEventEndpoints(
      origins: event.origins.map(resolve).toList(),
      destinations: event.destinations.map(resolve).toList(),
    );
  }

  String? resolvePersonLabel(String? personId) => _personLabel(personId);

  String? _personLabel(String? personId) =>
      personId == null ? null : registry.people[personId]?.label;

  String _missingReferenceLabel(EconomicEndpointKind kind) => switch (kind) {
    EconomicEndpointKind.account => 'Conto non più disponibile',
    EconomicEndpointKind.fund => 'Fondo non più disponibile',
    EconomicEndpointKind.cash => 'Portafoglio non più disponibile',
    _ => 'Riferimento non più disponibile',
  };

  String _standaloneLabel(EconomicEndpoint endpoint) {
    final label = endpoint.label.trim();
    if (label.isNotEmpty) return label;
    return switch (endpoint.kind) {
      EconomicEndpointKind.external => 'Soggetto esterno',
      EconomicEndpointKind.openingBalance => 'Saldo iniziale',
      EconomicEndpointKind.other => 'Riferimento precedente',
      EconomicEndpointKind.account => 'Conto non più disponibile',
      EconomicEndpointKind.fund => 'Fondo non più disponibile',
      EconomicEndpointKind.cash => 'Portafoglio non più disponibile',
    };
  }
}
