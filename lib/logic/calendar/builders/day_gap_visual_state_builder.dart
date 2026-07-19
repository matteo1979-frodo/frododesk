import 'package:flutter/material.dart';

import '../models/day_gap_visual_state.dart';

class DayGapVisualResult {
  final DayGapVisualState state;
  final Color color;
  final IconData icon;
  final String headline;
  final String subline;

  const DayGapVisualResult({
    required this.state,
    required this.color,
    required this.icon,
    required this.headline,
    required this.subline,
  });
}

class DayGapVisualStateBuilder {
  const DayGapVisualStateBuilder();

  DayGapVisualResult build({
    required DayGapVisualState baseState,
    required Color baseColor,
    required IconData baseIcon,
    required String baseHeadline,
    required String baseSubline,
    required bool hasLogisticConflict,
    required bool hasIncompleteLogistics,
    required bool hasRealCoverageGap,
  }) {
    final effectiveState = hasLogisticConflict || hasRealCoverageGap
        ? DayGapVisualState.realGap
        : hasIncompleteLogistics
        ? DayGapVisualState.coveredNeed
        : baseState == DayGapVisualState.coveredNeed
        ? DayGapVisualState.coveredNeed
        : DayGapVisualState.noProblem;

    final effectiveColor = effectiveState == DayGapVisualState.realGap
        ? Colors.red
        : effectiveState == DayGapVisualState.coveredNeed
        ? Colors.orange
        : baseColor;

    final effectiveIcon = effectiveState == DayGapVisualState.realGap
        ? Icons.error
        : effectiveState == DayGapVisualState.coveredNeed
        ? Icons.warning_amber_rounded
        : baseIcon;

    final effectiveHeadline = hasLogisticConflict
        ? "❗ Conflitto logistico Alice"
        : hasIncompleteLogistics
        ? "⚠ Logistica Alice incompleta"
        : baseHeadline;

    final effectiveSubline = hasLogisticConflict
        ? "Un evento Alice ha accompagnamento o ritiro assegnato a una persona non disponibile."
        : hasIncompleteLogistics
        ? "Un evento Alice richiede accompagnamento o ritiro, ma manca ancora una persona assegnata."
        : baseSubline;

    return DayGapVisualResult(
      state: effectiveState,
      color: effectiveColor,
      icon: effectiveIcon,
      headline: effectiveHeadline,
      subline: effectiveSubline,
    );
  }
}