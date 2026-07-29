enum CoverageCriticalityKind { recoverySacrificed, recoveryProtected }

enum CoverageSource {
  parentNormal,
  parentForced,
  supportNetwork,
  school,
  summerCamp,
  event,
  companion,
}

abstract final class CoverageProviderIds {
  static const String sandraLegacy = 'legacy:sandra';
}

class CoverageCriticalityDetail {
  final CoverageCriticalityKind kind;
  final String personId;
  final DateTime start;
  final DateTime end;
  final CoverageSource source;
  final String? coverageProviderId;

  const CoverageCriticalityDetail({
    required this.kind,
    required this.personId,
    required this.start,
    required this.end,
    required this.source,
    required this.coverageProviderId,
  });
}
