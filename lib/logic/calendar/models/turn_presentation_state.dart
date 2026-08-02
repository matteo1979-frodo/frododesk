import '../../turn_engine.dart';

enum TurnSourceKind {
  standard,
  dailyOverride,
  periodOverride,
  rotationOverride,
  fourthShift,
}

enum TurnStatusKind {
  standard,
  permission,
  leave,
  mildSickness,
  bedSickness,
  manualShiftChange,
}

enum TurnPresentationTone { standard, rest, sickness, manualOverride }

enum TurnSourceTone { standard, fourthShift, manualOverride, rotationOverride }

enum TurnPresentationIcon { work, rest, sickness, leave, manualOverride }

enum TurnTemporalState { active, completed, future }

class TurnPresentationState {
  final TurnType turnType;
  final String turnLabel;
  final String timeLabel;
  final String? statusText;
  final TurnStatusKind statusKind;
  final TurnPresentationTone statusTone;
  final TurnPresentationIcon icon;
  final TurnSourceKind sourceKind;
  final String? sourceText;
  final TurnSourceTone sourceTone;
  final TurnTemporalState temporalState;
  final bool hasConflict;

  const TurnPresentationState({
    required this.turnType,
    required this.turnLabel,
    required this.timeLabel,
    required this.statusText,
    required this.statusKind,
    required this.statusTone,
    required this.icon,
    required this.sourceKind,
    required this.sourceText,
    required this.sourceTone,
    required this.temporalState,
    required this.hasConflict,
  });

  bool get isBedSick => statusKind == TurnStatusKind.bedSickness;
}
