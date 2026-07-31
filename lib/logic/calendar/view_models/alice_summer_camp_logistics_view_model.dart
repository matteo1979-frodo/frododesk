import '../models/alice_summer_camp_logistics.dart';

enum AliceSummerCampLogisticVisualState { success, decision, conflict, gap }

class AliceLogisticProviderOptionViewModel {
  final AliceLogisticProviderRef? provider;
  final String label;

  const AliceLogisticProviderOptionViewModel({
    required this.provider,
    required this.label,
  });
}

class AliceSummerCampLogisticLegViewModel {
  final AliceLogisticLeg leg;
  final String fieldLabel;
  final AliceLogisticProviderRef? assignedProvider;
  final String assignedProviderLabel;
  final List<AliceLogisticProviderOptionViewModel> options;
  final AliceLogisticDecisionStatus status;
  final String title;
  final String description;
  final String intervalLabel;
  final List<String> alternatives;
  final AliceSummerCampLogisticVisualState visualState;
  final String realityText;

  const AliceSummerCampLogisticLegViewModel({
    required this.leg,
    required this.fieldLabel,
    required this.assignedProvider,
    required this.assignedProviderLabel,
    required this.options,
    required this.status,
    required this.title,
    required this.description,
    required this.intervalLabel,
    required this.alternatives,
    required this.visualState,
    required this.realityText,
  });
}

class AliceSummerCampLogisticsViewModel {
  final String sectionTitle;
  final AliceSummerCampLogisticLegViewModel dropOff;
  final AliceSummerCampLogisticLegViewModel pickUp;

  const AliceSummerCampLogisticsViewModel({
    required this.sectionTitle,
    required this.dropOff,
    required this.pickUp,
  });

  Iterable<AliceSummerCampLogisticLegViewModel> get legs => [dropOff, pickUp];
  Iterable<AliceSummerCampLogisticLegViewModel> get logisticGaps => legs.where(
    (leg) => switch (leg.status) {
      AliceLogisticDecisionStatus.unassignedProviderAvailable ||
      AliceLogisticDecisionStatus.assignedProviderUnavailable ||
      AliceLogisticDecisionStatus.noProviderAvailable => true,
      AliceLogisticDecisionStatus.inactive ||
      AliceLogisticDecisionStatus.assignedValid => false,
    },
  );

  int get logisticGapCount => logisticGaps.length;
  bool get hasLogisticGaps => logisticGapCount > 0;
  int get conflictCount => legs
      .where(
        (leg) =>
            leg.status ==
            AliceLogisticDecisionStatus.assignedProviderUnavailable,
      )
      .length;
  int get gapCount => legs
      .where(
        (leg) => leg.status == AliceLogisticDecisionStatus.noProviderAvailable,
      )
      .length;
}
