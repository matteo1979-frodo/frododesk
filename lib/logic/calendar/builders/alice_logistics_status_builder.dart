import '../models/alice_event_logistics.dart';

class AliceLogisticsStatus {
  final bool hasIncompleteLogistics;
  final bool hasLogisticConflict;

  const AliceLogisticsStatus({
    required this.hasIncompleteLogistics,
    required this.hasLogisticConflict,
  });
}

class AliceLogisticsStatusBuilder {
  const AliceLogisticsStatusBuilder();

  AliceLogisticsStatus build({
    required List<AliceEventLogisticsResolution> resolutions,
  }) {
    return AliceLogisticsStatus(
      hasIncompleteLogistics: resolutions.any(
        (resolution) =>
            resolution.missingDropOff || resolution.missingPickUp,
      ),
      hasLogisticConflict: resolutions.any(
        (resolution) =>
            resolution.dropOffConflict || resolution.pickUpConflict,
      ),
    );
  }
}
