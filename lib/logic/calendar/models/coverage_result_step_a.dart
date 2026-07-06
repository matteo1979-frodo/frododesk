import '../../coverage_engine.dart';

class CoverageResultStepA {
  final bool ok;
  final List<String> details;
  final List<CoverageGapDetail> gapDetails;
  final String bannerText;

  const CoverageResultStepA({
    required this.ok,
    required this.details,
    required this.gapDetails,
    required this.bannerText,
  });
}
