import '../../../models/alice_special_event.dart';
import '../models/alice_event_logistics.dart';
import '../models/alice_summer_camp_logistics.dart';

class AliceEventLogisticsBuilder {
  const AliceEventLogisticsBuilder();

  AliceEventLogisticsResolution build({
    required AliceSpecialEvent event,
    required DateTime outboundStart,
    required DateTime outboundEnd,
    required DateTime returnStart,
    required DateTime returnEnd,
    required List<AliceLogisticProviderAvailability> outboundAvailabilities,
    required List<AliceLogisticProviderAvailability> returnAvailabilities,
  }) {
    return AliceEventLogisticsResolution(
      event: event,
      outbound: _resolveLeg(
        leg: AliceLogisticLeg.dropOff,
        start: outboundStart,
        end: outboundEnd,
        assignmentKey: event.dropOffAdultKey,
        availabilities: outboundAvailabilities,
      ),
      returnLeg: _resolveLeg(
        leg: AliceLogisticLeg.pickUp,
        start: returnStart,
        end: returnEnd,
        assignmentKey: event.pickUpAdultKey,
        availabilities: returnAvailabilities,
      ),
    );
  }

  AliceEventLogisticLegResolution _resolveLeg({
    required AliceLogisticLeg leg,
    required DateTime start,
    required DateTime end,
    required String? assignmentKey,
    required List<AliceLogisticProviderAvailability> availabilities,
  }) {
    final normalizedKey = _normalizedKey(assignmentKey);
    final availableProviders = <AliceLogisticProviderRef>[];
    for (final availability in availabilities) {
      if (!availability.available ||
          availability.start.isAfter(start) ||
          availability.end.isBefore(end) ||
          availableProviders.contains(availability.provider)) {
        continue;
      }
      availableProviders.add(availability.provider);
    }

    final assignedProvider = _assignedProvider(
      normalizedKey,
      availableProviders,
    );
    final status = switch (normalizedKey) {
      null when availableProviders.isNotEmpty =>
        AliceLogisticDecisionStatus.unassignedProviderAvailable,
      null => AliceLogisticDecisionStatus.noProviderAvailable,
      _
          when assignedProvider != null &&
              availableProviders.contains(assignedProvider) =>
        AliceLogisticDecisionStatus.assignedValid,
      _ => AliceLogisticDecisionStatus.assignedProviderUnavailable,
    };
    final resolvedProvider = status == AliceLogisticDecisionStatus.assignedValid
        ? assignedProvider
        : null;
    final suggestedProvider =
        status == AliceLogisticDecisionStatus.assignedProviderUnavailable &&
            (normalizedKey == 'matteo' || normalizedKey == 'chiara')
        ? _firstSupportProvider(availableProviders, excluding: assignedProvider)
        : null;

    return AliceEventLogisticLegResolution(
      leg: leg,
      start: start,
      end: end,
      assignmentKey: normalizedKey,
      status: status,
      assignedProvider: assignedProvider,
      resolvedProvider: resolvedProvider,
      suggestedProvider: suggestedProvider,
      availableProviders: List.unmodifiable(availableProviders),
      unresolvedReason: switch (status) {
        AliceLogisticDecisionStatus.unassignedProviderAvailable =>
          AliceEventLogisticsUnresolvedReason.unassigned,
        AliceLogisticDecisionStatus.noProviderAvailable =>
          AliceEventLogisticsUnresolvedReason.noProviderAvailable,
        AliceLogisticDecisionStatus.assignedProviderUnavailable
            when normalizedKey == 'supporto' =>
          AliceEventLogisticsUnresolvedReason.noConcreteSupportProvider,
        AliceLogisticDecisionStatus.assignedProviderUnavailable =>
          AliceEventLogisticsUnresolvedReason.assignedProviderUnavailable,
        AliceLogisticDecisionStatus.inactive ||
        AliceLogisticDecisionStatus.assignedValid => null,
      },
    );
  }

  String? _normalizedKey(String? key) {
    final normalized = key?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  AliceLogisticProviderRef? _assignedProvider(
    String? key,
    List<AliceLogisticProviderRef> availableProviders,
  ) {
    switch (key) {
      case null:
        return null;
      case 'matteo':
        return AliceLogisticProviderRef.parent(AliceLogisticParent.matteo);
      case 'chiara':
        return AliceLogisticProviderRef.parent(AliceLogisticParent.chiara);
      case 'sandra':
        return AliceLogisticProviderRef.sandra;
      case 'supporto':
        return _firstSupportProvider(availableProviders);
      default:
        return AliceLogisticProviderRef.supportPerson(key);
    }
  }

  AliceLogisticProviderRef? _firstSupportProvider(
    List<AliceLogisticProviderRef> providers, {
    AliceLogisticProviderRef? excluding,
  }) {
    for (final provider in providers) {
      if (provider.kind == AliceLogisticProviderKind.supportPerson &&
          provider != excluding) {
        return provider;
      }
    }
    return null;
  }
}
