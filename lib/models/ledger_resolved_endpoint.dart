import 'dart:collection';

import 'economic_event.dart';

class LedgerEndpointRecord {
  final String id;
  final String label;
  final String? personId;

  const LedgerEndpointRecord({
    required this.id,
    required this.label,
    this.personId,
  }) : assert(id != ''),
       assert(label != '');
}

class LedgerPersonRecord {
  final String id;
  final String label;

  const LedgerPersonRecord({required this.id, required this.label})
    : assert(id != ''),
      assert(label != '');
}

class LedgerEndpointRegistry {
  final UnmodifiableMapView<String, LedgerEndpointRecord> accounts;
  final UnmodifiableMapView<String, LedgerEndpointRecord> funds;
  final UnmodifiableMapView<String, LedgerEndpointRecord> cashWallets;
  final UnmodifiableMapView<String, LedgerPersonRecord> people;

  LedgerEndpointRegistry({
    Map<String, LedgerEndpointRecord> accounts = const {},
    Map<String, LedgerEndpointRecord> funds = const {},
    Map<String, LedgerEndpointRecord> cashWallets = const {},
    Map<String, LedgerPersonRecord> people = const {},
  }) : accounts = UnmodifiableMapView(Map.of(accounts)),
       funds = UnmodifiableMapView(Map.of(funds)),
       cashWallets = UnmodifiableMapView(Map.of(cashWallets)),
       people = UnmodifiableMapView(Map.of(people));
}

class LedgerResolvedEndpoint {
  final EconomicEndpointKind kind;
  final String? referenceId;
  final String label;
  final String? personId;
  final String? personLabel;
  final double amount;
  final bool usesHistoricalFallback;

  const LedgerResolvedEndpoint({
    required this.kind,
    required this.label,
    required this.amount,
    required this.usesHistoricalFallback,
    this.referenceId,
    this.personId,
    this.personLabel,
  }) : assert(label != ''),
       assert(amount >= 0);
}

class LedgerResolvedEventEndpoints {
  final UnmodifiableListView<LedgerResolvedEndpoint> origins;
  final UnmodifiableListView<LedgerResolvedEndpoint> destinations;

  LedgerResolvedEventEndpoints({
    required List<LedgerResolvedEndpoint> origins,
    required List<LedgerResolvedEndpoint> destinations,
  }) : origins = UnmodifiableListView(List.of(origins)),
       destinations = UnmodifiableListView(List.of(destinations));
}
