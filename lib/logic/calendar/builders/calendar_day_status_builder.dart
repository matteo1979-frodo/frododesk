import '../../../models/coverage_criticality_detail.dart';
import '../../coverage_engine.dart';
import '../models/calendar_day_status.dart';

class CalendarDayStatusBuilder {
  const CalendarDayStatusBuilder();

  CalendarDayStatus build({
    required List<CoverageGapDetail> gapDetails,
    required List<CoverageCriticalityDetail> criticalityDetails,
    required bool hasLogisticGaps,
  }) {
    if (gapDetails.isNotEmpty || hasLogisticGaps) {
      return CalendarDayStatus.problem;
    }

    final hasSacrificedRecovery = criticalityDetails.any(
      (detail) => detail.kind == CoverageCriticalityKind.recoverySacrificed,
    );
    return hasSacrificedRecovery
        ? CalendarDayStatus.attention
        : CalendarDayStatus.ok;
  }
}
