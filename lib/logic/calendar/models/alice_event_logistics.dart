import '../../../models/alice_special_event.dart';
import 'alice_summer_camp_logistics.dart';

enum AliceEventLogisticsUnresolvedReason {
  unassigned,
  noProviderAvailable,
  noConcreteSupportProvider,
  assignedProviderUnavailable,
}

class AliceEventLogisticLegResolution {
  final AliceLogisticLeg leg;
  final DateTime start;
  final DateTime end;
  final String? assignmentKey;
  final AliceLogisticDecisionStatus status;
  final AliceLogisticProviderRef? assignedProvider;
  final AliceLogisticProviderRef? resolvedProvider;
  final AliceLogisticProviderRef? suggestedProvider;
  final List<AliceLogisticProviderRef> availableProviders;
  final AliceEventLogisticsUnresolvedReason? unresolvedReason;

  const AliceEventLogisticLegResolution({
    required this.leg,
    required this.start,
    required this.end,
    required this.assignmentKey,
    required this.status,
    required this.assignedProvider,
    required this.resolvedProvider,
    required this.suggestedProvider,
    required this.availableProviders,
    required this.unresolvedReason,
  });

  bool get isAssigned => assignmentKey != null;
  bool get hasConflict =>
      status == AliceLogisticDecisionStatus.assignedProviderUnavailable;
}

class AliceEventLogisticsResolution {
  final AliceSpecialEvent event;
  final AliceEventLogisticLegResolution outbound;
  final AliceEventLogisticLegResolution returnLeg;

  const AliceEventLogisticsResolution({
    required this.event,
    required this.outbound,
    required this.returnLeg,
  });

  AliceLogisticProviderRef? get outboundProvider => outbound.resolvedProvider;
  AliceLogisticProviderRef? get returnProvider => returnLeg.resolvedProvider;

  bool get sameAdult =>
      outbound.assignmentKey != null &&
      outbound.assignmentKey == returnLeg.assignmentKey;
  bool get missingDropOff => !outbound.isAssigned;
  bool get missingPickUp => !returnLeg.isAssigned;
  bool get usesMatteo =>
      outbound.assignmentKey == 'matteo' || returnLeg.assignmentKey == 'matteo';
  bool get usesChiara =>
      outbound.assignmentKey == 'chiara' || returnLeg.assignmentKey == 'chiara';
  bool get matteoBusy =>
      (outbound.assignmentKey == 'matteo' && outbound.hasConflict) ||
      (returnLeg.assignmentKey == 'matteo' && returnLeg.hasConflict);
  bool get chiaraBusy =>
      (outbound.assignmentKey == 'chiara' && outbound.hasConflict) ||
      (returnLeg.assignmentKey == 'chiara' && returnLeg.hasConflict);
  bool get canSuggestSupport =>
      outbound.suggestedProvider != null || returnLeg.suggestedProvider != null;
  bool get singleAdultManagesEvent => sameAdult;
  bool get splitLogistics =>
      outbound.assignmentKey != null &&
      returnLeg.assignmentKey != null &&
      outbound.assignmentKey != returnLeg.assignmentKey;
  bool get dropOffConflict => outbound.hasConflict;
  bool get pickUpConflict => returnLeg.hasConflict;
}
