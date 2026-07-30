import '../../coverage_engine.dart';

class AliceHomeRiskViewModel {
  final List<CoverageGapDetail> gapDetails;

  const AliceHomeRiskViewModel({required this.gapDetails});

  bool get hasRisk => gapDetails.isNotEmpty;
}
