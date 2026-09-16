import 'dart:collection';

import 'economic_operation_metadata.dart';

enum EconomicNature { income, outflow, internalTransfer }

enum EconomicEndpointKind {
  account,
  fund,
  cash,
  external,
  openingBalance,
  other,
}

enum EconomicSourceKind {
  realExpense,
  financeTransaction,
  financeAssetMovement,
  other,
}

enum EconomicTransactionOrigin { recurringItem, manual, fund, adjustment }

class EconomicEndpoint {
  final EconomicEndpointKind kind;
  final String? referenceId;
  final String label;
  final String? personId;
  final double amount;

  const EconomicEndpoint({
    required this.kind,
    required this.label,
    required this.amount,
    this.referenceId,
    this.personId,
  }) : assert(amount >= 0);
}

class EconomicCategoryRef {
  final String id;
  final String label;

  const EconomicCategoryRef({required this.id, required this.label});

  factory EconomicCategoryRef.fromLabel(String label) {
    final cleanLabel = label.trim();
    final normalizedId = cleanLabel
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return EconomicCategoryRef(
      id: normalizedId.isEmpty ? 'uncategorized' : normalizedId,
      label: cleanLabel.isEmpty ? 'Senza categoria' : cleanLabel,
    );
  }
}

class EconomicSourceLink {
  final EconomicSourceKind kind;
  final String recordId;

  const EconomicSourceLink({required this.kind, required this.recordId});
}

class EconomicEvent {
  final String id;
  final DateTime observedAt;
  final DateTime occurredAt;
  final UnmodifiableListView<EconomicEndpoint> origins;
  final UnmodifiableListView<EconomicEndpoint> destinations;
  final EconomicCategoryRef? category;
  final String? personId;
  final String description;
  final double amount;
  final EconomicNature nature;
  final UnmodifiableListView<EconomicSourceLink> sourceLinks;
  final UnmodifiableListView<String> relatedEventIds;
  final UnmodifiableListView<String> notes;
  final UnmodifiableListView<EconomicTransactionOrigin> transactionOrigins;
  final UnmodifiableListView<String> recurringItemIds;
  final String? economicFactId;
  final EconomicOperationMetadata? operationMetadata;

  EconomicEvent({
    required this.id,
    required this.observedAt,
    required this.occurredAt,
    required List<EconomicEndpoint> origins,
    required List<EconomicEndpoint> destinations,
    required this.description,
    required this.amount,
    required this.nature,
    List<EconomicSourceLink> sourceLinks = const [],
    List<String> relatedEventIds = const [],
    List<String> notes = const [],
    List<EconomicTransactionOrigin> transactionOrigins = const [],
    List<String> recurringItemIds = const [],
    this.category,
    this.personId,
    this.economicFactId,
    this.operationMetadata,
  }) : assert(id != ''),
       assert(amount >= 0),
       origins = UnmodifiableListView(List<EconomicEndpoint>.of(origins)),
       destinations = UnmodifiableListView(
         List<EconomicEndpoint>.of(destinations),
       ),
       sourceLinks = UnmodifiableListView(
         List<EconomicSourceLink>.of(sourceLinks),
       ),
       relatedEventIds = UnmodifiableListView(List<String>.of(relatedEventIds)),
       notes = UnmodifiableListView(List<String>.of(notes)),
       transactionOrigins = UnmodifiableListView(
         List<EconomicTransactionOrigin>.of(transactionOrigins),
       ),
       recurringItemIds = UnmodifiableListView(
         List<String>.of(recurringItemIds),
       );
}
