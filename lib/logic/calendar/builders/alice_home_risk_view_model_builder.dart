import '../../coverage_engine.dart';
import '../view_models/alice_home_risk_view_model.dart';

class AliceHomeRiskViewModelBuilder {
  const AliceHomeRiskViewModelBuilder();

  AliceHomeRiskViewModel build({
    required List<CoverageGapDetail> gapDetails,
    required DateTime selectedDay,
    required DateTime observedAt,
  }) {
    final selectedDate = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final observedDate = DateTime(
      observedAt.year,
      observedAt.month,
      observedAt.day,
    );

    if (selectedDate != observedDate) {
      return AliceHomeRiskViewModel(gapDetails: gapDetails);
    }

    final nowMinutes = observedAt.hour * 60 + observedAt.minute;
    return AliceHomeRiskViewModel(
      gapDetails: gapDetails
          .where((detail) {
            final endMinutes = detail.end.hour * 60 + detail.end.minute;
            return endMinutes > nowMinutes;
          })
          .toList(growable: false),
    );
  }
}
