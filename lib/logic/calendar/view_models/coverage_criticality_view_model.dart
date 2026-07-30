import '../../../models/coverage_criticality_detail.dart';

class CoverageCriticalityViewModel {
  final CoverageCriticalityDetail detail;
  final String title;
  final String text;
  final String realityText;
  final String timeRange;

  const CoverageCriticalityViewModel({
    required this.detail,
    required this.title,
    required this.text,
    required this.realityText,
    required this.timeRange,
  });

  CoverageCriticalityKind get kind => detail.kind;
}
