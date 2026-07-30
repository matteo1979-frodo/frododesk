enum AliceLogisticLeg { dropOff, pickUp }

enum AliceLogisticProviderKind { parent, sandra, supportPerson }

enum AliceLogisticParent { matteo, chiara }

enum AliceLogisticDecisionStatus {
  inactive,
  assignedValid,
  unassignedProviderAvailable,
  assignedProviderUnavailable,
  noProviderAvailable,
}

class AliceLogisticProviderRef {
  static const String _matteoId = 'matteo';
  static const String _chiaraId = 'chiara';
  static const String _sandraId = 'sandra';

  final AliceLogisticProviderKind kind;
  final String providerId;

  const AliceLogisticProviderRef._({
    required this.kind,
    required this.providerId,
  });

  factory AliceLogisticProviderRef.parent(AliceLogisticParent parent) {
    return switch (parent) {
      AliceLogisticParent.matteo => const AliceLogisticProviderRef._(
        kind: AliceLogisticProviderKind.parent,
        providerId: _matteoId,
      ),
      AliceLogisticParent.chiara => const AliceLogisticProviderRef._(
        kind: AliceLogisticProviderKind.parent,
        providerId: _chiaraId,
      ),
    };
  }

  static const sandra = AliceLogisticProviderRef._(
    kind: AliceLogisticProviderKind.sandra,
    providerId: _sandraId,
  );

  factory AliceLogisticProviderRef.supportPerson(String providerId) {
    final normalizedId = providerId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        providerId,
        'providerId',
        'A support person must have a stable, non-empty ID.',
      );
    }
    return AliceLogisticProviderRef._(
      kind: AliceLogisticProviderKind.supportPerson,
      providerId: normalizedId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AliceLogisticProviderRef &&
          kind == other.kind &&
          providerId == other.providerId;

  @override
  int get hashCode => Object.hash(kind, providerId);
}

class AliceLogisticProviderAvailability {
  final AliceLogisticProviderRef provider;
  final DateTime start;
  final DateTime end;
  final bool available;

  AliceLogisticProviderAvailability({
    required this.provider,
    required this.start,
    required this.end,
    required this.available,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'Must not be before start.');
    }
  }
}

class AliceLogisticDecisionResult {
  final AliceLogisticLeg leg;
  final DateTime start;
  final DateTime end;
  final AliceLogisticDecisionStatus status;
  final AliceLogisticProviderRef? assignedProvider;
  final List<AliceLogisticProviderRef> availableProviders;

  const AliceLogisticDecisionResult({
    required this.leg,
    required this.start,
    required this.end,
    required this.status,
    required this.assignedProvider,
    required this.availableProviders,
  });
}

class AliceSummerCampLogisticsResult {
  final AliceLogisticDecisionResult dropOff;
  final AliceLogisticDecisionResult pickUp;

  const AliceSummerCampLogisticsResult({
    required this.dropOff,
    required this.pickUp,
  });
}
