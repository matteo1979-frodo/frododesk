import 'dart:collection';

import '../../models/economic_event.dart';
import '../../models/ledger_event_view_model.dart';
import '../../models/ledger_resolved_endpoint.dart';
import 'ledger_endpoint_resolver.dart';

class LedgerTimelineBuilder {
  final LedgerEndpointResolver endpointResolver;
  final String currencyCode;

  const LedgerTimelineBuilder({
    required this.endpointResolver,
    this.currencyCode = 'EUR',
  }) : assert(currencyCode != '');

  UnmodifiableListView<LedgerEventViewModel> build(
    List<EconomicEvent> canonicalEvents,
  ) {
    final timeline = canonicalEvents.map(_buildEvent).toList()
      ..sort(_compareTimelineEvents);
    return UnmodifiableListView(timeline);
  }

  LedgerEventViewModel _buildEvent(EconomicEvent event) {
    final resolved = endpointResolver.resolveEvent(event);
    final counterparties = <LedgerEventCounterparty>[
      ...resolved.origins.map(
        (endpoint) => _counterparty(endpoint, LedgerCounterpartyRole.origin),
      ),
      ...resolved.destinations.map(
        (endpoint) =>
            _counterparty(endpoint, LedgerCounterpartyRole.destination),
      ),
    ];

    return LedgerEventViewModel(
      eventId: event.id,
      title: _title(event),
      subtitle: _subtitle(resolved),
      amount: event.amount,
      currencyCode: currencyCode,
      economicSign: _economicSign(event.nature),
      nature: event.nature,
      personId: event.personId,
      personLabel: endpointResolver.resolvePersonLabel(event.personId),
      category: event.category,
      observedAt: event.observedAt,
      occurredAt: event.occurredAt,
      logicalIcon: _logicalIcon(event, resolved),
      logicalColor: _logicalColor(event.nature),
      counterparties: counterparties,
      badges: _badges(event, resolved),
      sourceLinks: event.sourceLinks,
    );
  }

  String _title(EconomicEvent event) {
    final description = event.description.trim();
    if (description.isNotEmpty) return description;
    return switch (event.nature) {
      EconomicNature.income => 'Entrata',
      EconomicNature.outflow => 'Uscita',
      EconomicNature.internalTransfer => 'Trasferimento interno',
    };
  }

  String _subtitle(LedgerResolvedEventEndpoints endpoints) {
    final origins = endpoints.origins
        .map((endpoint) => endpoint.label)
        .join(', ');
    final destinations = endpoints.destinations
        .map((endpoint) => endpoint.label)
        .join(', ');
    if (origins.isEmpty) return destinations;
    if (destinations.isEmpty) return origins;
    return '$origins → $destinations';
  }

  LedgerEconomicSign _economicSign(EconomicNature nature) => switch (nature) {
    EconomicNature.income => LedgerEconomicSign.positive,
    EconomicNature.outflow => LedgerEconomicSign.negative,
    EconomicNature.internalTransfer => LedgerEconomicSign.neutral,
  };

  LedgerLogicalColor _logicalColor(EconomicNature nature) => switch (nature) {
    EconomicNature.income => LedgerLogicalColor.positive,
    EconomicNature.outflow => LedgerLogicalColor.negative,
    EconomicNature.internalTransfer => LedgerLogicalColor.transfer,
  };

  LedgerLogicalIcon _logicalIcon(
    EconomicEvent event,
    LedgerResolvedEventEndpoints endpoints,
  ) {
    final kinds = {
      ...endpoints.origins.map((endpoint) => endpoint.kind),
      ...endpoints.destinations.map((endpoint) => endpoint.kind),
    };
    if (kinds.contains(EconomicEndpointKind.openingBalance)) {
      return LedgerLogicalIcon.openingBalance;
    }
    if (event.nature == EconomicNature.internalTransfer) {
      if (kinds.contains(EconomicEndpointKind.cash)) {
        return LedgerLogicalIcon.cash;
      }
      if (kinds.contains(EconomicEndpointKind.fund)) {
        return LedgerLogicalIcon.fund;
      }
      return LedgerLogicalIcon.transfer;
    }
    return event.nature == EconomicNature.income
        ? LedgerLogicalIcon.income
        : LedgerLogicalIcon.expense;
  }

  List<LedgerEventBadge> _badges(
    EconomicEvent event,
    LedgerResolvedEventEndpoints endpoints,
  ) {
    final result = <LedgerEventBadge>[
      switch (event.nature) {
        EconomicNature.income => const LedgerEventBadge(
          label: 'Entrata',
          tone: LedgerBadgeTone.positive,
        ),
        EconomicNature.outflow => const LedgerEventBadge(
          label: 'Uscita',
          tone: LedgerBadgeTone.negative,
        ),
        EconomicNature.internalTransfer => const LedgerEventBadge(
          label: 'Trasferimento',
          tone: LedgerBadgeTone.transfer,
        ),
      },
    ];
    final usesHistoricalFallback = [
      ...endpoints.origins,
      ...endpoints.destinations,
    ].any((endpoint) => endpoint.usesHistoricalFallback);
    if (usesHistoricalFallback) {
      result.add(
        const LedgerEventBadge(
          label: 'Riferimento storico',
          tone: LedgerBadgeTone.warning,
        ),
      );
    }
    return result;
  }

  LedgerEventCounterparty _counterparty(
    LedgerResolvedEndpoint endpoint,
    LedgerCounterpartyRole role,
  ) => LedgerEventCounterparty(
    role: role,
    kind: endpoint.kind,
    referenceId: endpoint.referenceId,
    label: endpoint.label,
    personId: endpoint.personId,
    personLabel: endpoint.personLabel,
    amount: endpoint.amount,
  );

  int _compareTimelineEvents(
    LedgerEventViewModel left,
    LedgerEventViewModel right,
  ) {
    final occurred = right.timelineDate.compareTo(left.timelineDate);
    if (occurred != 0) return occurred;
    final observed = right.observedAt.compareTo(left.observedAt);
    if (observed != 0) return observed;
    return left.eventId.compareTo(right.eventId);
  }
}
