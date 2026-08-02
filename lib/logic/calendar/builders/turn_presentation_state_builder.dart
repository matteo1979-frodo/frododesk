import '../../../models/day_override.dart';
import '../../../models/disease_period.dart';
import '../../../utils/calendario_formatters.dart';
import '../../turn_engine.dart';
import '../models/turn_presentation_state.dart';

class TurnPresentationStateBuilder {
  const TurnPresentationStateBuilder();

  String labelFor(TurnType type) => _turnLabel(type);

  String summaryFor(TurnPlan plan) {
    if (plan.isOff) return 'OFF';
    return '${_turnLabel(plan.type)} '
        '${fmtTimeOfDay(plan.start)} ${fmtTimeOfDay(plan.end)}';
  }

  TurnPresentationState build({
    required DateTime day,
    required DateTime observedAt,
    required TurnPlan plan,
    required PersonDayOverride? manualOverride,
    required DiseasePeriod? diseasePeriod,
    required bool isOnHoliday,
    required bool isSick,
    required bool isBedSick,
    required bool isManualShiftChange,
    required String? statusText,
    required TurnSourceKind sourceKind,
    required String? sourceText,
    required bool hasConflict,
  }) {
    final statusKind = _statusKind(
      manualOverride: manualOverride,
      diseasePeriod: diseasePeriod,
      isOnHoliday: isOnHoliday,
      isSick: isSick,
      isBedSick: isBedSick,
      isManualShiftChange: isManualShiftChange,
    );

    return TurnPresentationState(
      turnType: plan.type,
      turnLabel: _turnLabel(plan.type),
      timeLabel: plan.isOff
          ? 'OFF'
          : '${fmtTimeOfDay(plan.start)}–${fmtTimeOfDay(plan.end)}',
      statusText: statusText,
      statusKind: statusKind,
      statusTone: _statusTone(statusKind, plan),
      icon: _icon(statusKind, plan),
      sourceKind: sourceKind,
      sourceText: sourceText,
      sourceTone: _sourceTone(sourceKind),
      temporalState: _temporalState(day, observedAt, plan),
      hasConflict: hasConflict,
    );
  }

  String _turnLabel(TurnType type) {
    switch (type) {
      case TurnType.mattina:
        return 'M';
      case TurnType.pomeriggio:
        return 'P';
      case TurnType.notte:
        return 'N';
      case TurnType.off:
        return 'OFF';
    }
  }

  TurnStatusKind _statusKind({
    required PersonDayOverride? manualOverride,
    required DiseasePeriod? diseasePeriod,
    required bool isOnHoliday,
    required bool isSick,
    required bool isBedSick,
    required bool isManualShiftChange,
  }) {
    if (isManualShiftChange) return TurnStatusKind.manualShiftChange;
    if (manualOverride != null) {
      switch (manualOverride.status) {
        case OverrideStatus.normal:
          break;
        case OverrideStatus.permesso:
          return TurnStatusKind.permission;
        case OverrideStatus.ferie:
          return TurnStatusKind.leave;
        case OverrideStatus.malattiaLeggera:
          return TurnStatusKind.mildSickness;
        case OverrideStatus.malattiaALetto:
          return TurnStatusKind.bedSickness;
      }
    }
    if (diseasePeriod != null) {
      return diseasePeriod.type == DiseaseType.bed
          ? TurnStatusKind.bedSickness
          : TurnStatusKind.mildSickness;
    }
    if (isBedSick) return TurnStatusKind.bedSickness;
    if (isSick) return TurnStatusKind.mildSickness;
    if (isOnHoliday) return TurnStatusKind.leave;
    return TurnStatusKind.standard;
  }

  TurnPresentationTone _statusTone(TurnStatusKind kind, TurnPlan plan) {
    switch (kind) {
      case TurnStatusKind.bedSickness:
        return TurnPresentationTone.sickness;
      case TurnStatusKind.manualShiftChange:
        return TurnPresentationTone.manualOverride;
      case TurnStatusKind.standard:
        return plan.isOff
            ? TurnPresentationTone.rest
            : TurnPresentationTone.standard;
      case TurnStatusKind.permission:
      case TurnStatusKind.leave:
      case TurnStatusKind.mildSickness:
        return TurnPresentationTone.standard;
    }
  }

  TurnPresentationIcon _icon(TurnStatusKind kind, TurnPlan plan) {
    switch (kind) {
      case TurnStatusKind.bedSickness:
      case TurnStatusKind.mildSickness:
        return TurnPresentationIcon.sickness;
      case TurnStatusKind.leave:
        return TurnPresentationIcon.leave;
      case TurnStatusKind.manualShiftChange:
        return TurnPresentationIcon.manualOverride;
      case TurnStatusKind.standard:
      case TurnStatusKind.permission:
        return plan.isOff
            ? TurnPresentationIcon.rest
            : TurnPresentationIcon.work;
    }
  }

  TurnSourceTone _sourceTone(TurnSourceKind kind) {
    switch (kind) {
      case TurnSourceKind.fourthShift:
        return TurnSourceTone.fourthShift;
      case TurnSourceKind.dailyOverride:
      case TurnSourceKind.periodOverride:
        return TurnSourceTone.manualOverride;
      case TurnSourceKind.rotationOverride:
        return TurnSourceTone.rotationOverride;
      case TurnSourceKind.standard:
        return TurnSourceTone.standard;
    }
  }

  TurnTemporalState _temporalState(
    DateTime day,
    DateTime observedAt,
    TurnPlan plan,
  ) {
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      plan.start.hour,
      plan.start.minute,
    );
    var end = DateTime(
      day.year,
      day.month,
      day.day,
      plan.end.hour,
      plan.end.minute,
    );
    if (!plan.isOff && !end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    if (observedAt.isBefore(start)) {
      return TurnTemporalState.future;
    }
    if (!plan.isOff && observedAt.isBefore(end)) {
      return TurnTemporalState.active;
    }
    return TurnTemporalState.completed;
  }
}
