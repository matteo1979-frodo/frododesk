import '../../coverage_engine.dart';
import '../models/coverage_result_step_a.dart';

class CoverageResultStepABuilder {
  const CoverageResultStepABuilder();

  CoverageResultStepA build({
    required CoverageDayAnalysis analysis,
    required List<CoverageGapDetail> filteredGapDetails,
    required List<String> summaryDetails,
    required String bannerText,
  }) {
    return CoverageResultStepA(
      details: summaryDetails,
      gapDetails: filteredGapDetails,
      criticalityDetails: analysis.criticalityDetails,
      bannerText: bannerText,
    );
  }
}
