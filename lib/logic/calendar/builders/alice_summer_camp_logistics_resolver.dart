import '../models/alice_summer_camp_logistics.dart';

class AliceSummerCampLogisticsResolver {
  static const _transferDuration = Duration(minutes: 20);

  const AliceSummerCampLogisticsResolver();

  AliceSummerCampLogisticsResult resolve({
    required bool summerCampOperational,
    required DateTime effectiveStart,
    required DateTime effectiveEnd,
    required AliceLogisticProviderRef? dropOffAssignedProvider,
    required AliceLogisticProviderRef? pickUpAssignedProvider,
    required List<AliceLogisticProviderAvailability> dropOffAvailabilities,
    required List<AliceLogisticProviderAvailability> pickUpAvailabilities,
  }) {
    if (effectiveEnd.isBefore(effectiveStart)) {
      throw ArgumentError.value(
        effectiveEnd,
        'effectiveEnd',
        'Must not be before effectiveStart.',
      );
    }

    final dropOffStart = effectiveStart.subtract(_transferDuration);
    final pickUpEnd = effectiveEnd.add(_transferDuration);

    return AliceSummerCampLogisticsResult(
      dropOff: _resolveLeg(
        operational: summerCampOperational,
        leg: AliceLogisticLeg.dropOff,
        start: dropOffStart,
        end: effectiveStart,
        assignedProvider: dropOffAssignedProvider,
        availabilities: dropOffAvailabilities,
      ),
      pickUp: _resolveLeg(
        operational: summerCampOperational,
        leg: AliceLogisticLeg.pickUp,
        start: effectiveEnd,
        end: pickUpEnd,
        assignedProvider: pickUpAssignedProvider,
        availabilities: pickUpAvailabilities,
      ),
    );
  }

  AliceLogisticDecisionResult _resolveLeg({
    required bool operational,
    required AliceLogisticLeg leg,
    required DateTime start,
    required DateTime end,
    required AliceLogisticProviderRef? assignedProvider,
    required List<AliceLogisticProviderAvailability> availabilities,
  }) {
    if (!operational) {
      return AliceLogisticDecisionResult(
        leg: leg,
        start: start,
        end: end,
        status: AliceLogisticDecisionStatus.inactive,
        assignedProvider: assignedProvider,
        availableProviders: const [],
      );
    }

    final availableProviders =
        availabilities
            .where(
              (availability) =>
                  availability.available &&
                  !availability.start.isAfter(start) &&
                  !availability.end.isBefore(end),
            )
            .map((availability) => availability.provider)
            .toSet()
            .toList()
          ..sort(_compareProviders);

    final status = switch (assignedProvider) {
      final provider? when availableProviders.contains(provider) =>
        AliceLogisticDecisionStatus.assignedValid,
      final AliceLogisticProviderRef _ =>
        AliceLogisticDecisionStatus.assignedProviderUnavailable,
      null when availableProviders.isNotEmpty =>
        AliceLogisticDecisionStatus.unassignedProviderAvailable,
      null => AliceLogisticDecisionStatus.noProviderAvailable,
    };

    return AliceLogisticDecisionResult(
      leg: leg,
      start: start,
      end: end,
      status: status,
      assignedProvider: assignedProvider,
      availableProviders: List.unmodifiable(availableProviders),
    );
  }

  // Stable family-neutral ordering: known parents, Sandra, then support IDs.
  static int _compareProviders(
    AliceLogisticProviderRef left,
    AliceLogisticProviderRef right,
  ) {
    final kindComparison = left.kind.index.compareTo(right.kind.index);
    if (kindComparison != 0) {
      return kindComparison;
    }
    if (left.kind == AliceLogisticProviderKind.parent) {
      return _parentRank(left).compareTo(_parentRank(right));
    }
    return left.providerId.compareTo(right.providerId);
  }

  static int _parentRank(AliceLogisticProviderRef provider) =>
      provider == AliceLogisticProviderRef.parent(AliceLogisticParent.matteo)
      ? 0
      : 1;
}
