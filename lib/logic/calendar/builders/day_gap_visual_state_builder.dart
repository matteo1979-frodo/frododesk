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
    required bool hasLogisticConflict,
    required bool hasIncompleteLogistics,
    required bool hasRealCoverageGap,
  }) {
    final state = hasLogisticConflict || hasRealCoverageGap
        ? DayGapVisualState.realGap
        : hasIncompleteLogistics
        ? DayGapVisualState.coveredNeed
        : DayGapVisualState.noProblem;

    final color = state == DayGapVisualState.realGap
        ? Colors.red
        : state == DayGapVisualState.coveredNeed
        ? Colors.orange
        : Colors.green;

    final icon = state == DayGapVisualState.realGap
        ? Icons.error
        : state == DayGapVisualState.coveredNeed
        ? Icons.warning_amber_rounded
        : Icons.check_circle;

    final headline = hasLogisticConflict
        ? "❗ Conflitto logistico Alice"
        : hasIncompleteLogistics
        ? "⚠ Logistica Alice incompleta"
        : state == DayGapVisualState.realGap
        ? "❗ Buco reale da risolvere"
        : state == DayGapVisualState.coveredNeed
        ? "⚠ Copertura necessaria ma risolta"
        : "✓ Nessun problema oggi";

    final subline = hasLogisticConflict
        ? "Un evento Alice ha accompagnamento o ritiro assegnato a una persona non disponibile."
        : hasIncompleteLogistics
        ? "Un evento Alice richiede accompagnamento o ritiro, ma manca ancora una persona assegnata."
        : state == DayGapVisualState.realGap
        ? "Esistono fasce senza copertura reale."
        : state == DayGapVisualState.coveredNeed
        ? "La giornata è coperta, ma solo grazie a supporti o decisioni manuali."
        : "Nessun buco rilevato dal motore.";

    return DayGapVisualResult(
      state: state,
      color: color,
      icon: icon,
      headline: headline,
      subline: subline,
    );
  }
}