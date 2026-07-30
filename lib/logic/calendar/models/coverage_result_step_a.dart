import '../../coverage_engine.dart';
import '../../../models/coverage_criticality_detail.dart';

class CoverageResultStepA {
  final List<String> details;
  final List<CoverageGapDetail> gapDetails;
  final List<CoverageCriticalityDetail> criticalityDetails;
  final String bannerText;

  const CoverageResultStepA({
    required this.details,
    required this.gapDetails,
    this.criticalityDetails = const [],
    required this.bannerText,
  });

  bool get ok => gapDetails.isEmpty;

  int get gapCount => gapDetails.length;

  int get criticalDecisionCount => criticalityDetails
      .where(
        (detail) =>
            detail.kind == CoverageCriticalityKind.recoverySacrificed,
      )
      .length;

  int get protectedRecoveryCount => criticalityDetails
      .where(
        (detail) => detail.kind == CoverageCriticalityKind.recoveryProtected,
      )
      .length;

  CoverageResultStepA copyWith({
    List<String>? details,
    List<CoverageGapDetail>? gapDetails,
    List<CoverageCriticalityDetail>? criticalityDetails,
    String? bannerText,
  }) {
    return CoverageResultStepA(
      details: details ?? this.details,
      gapDetails: gapDetails ?? this.gapDetails,
      criticalityDetails: criticalityDetails ?? this.criticalityDetails,
      bannerText: bannerText ?? this.bannerText,
    );
  }
}
