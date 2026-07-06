import 'package:flutter/material.dart';

import '../../models/day_override.dart';
import '../coverage_engine.dart';
import 'coverage_decision.dart';

class CoverageDecisionEngine {
  static List<CoverageDecision> analyzeToday({
    required CoverageEngine coverageEngine,
    required DayOverrides overrides,
    required bool uscita13,
    required bool sandraMattinaOn,
    required bool sandraPranzoOn,
    required bool sandraSeraOn,
    required TimeOfDay schoolStart,
    TimeOfDay schoolOutStart = const TimeOfDay(hour: 16, minute: 25),
    TimeOfDay schoolOutEnd = const TimeOfDay(hour: 16, minute: 45),
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final details = coverageEngine.aliceHomeRiskDetailsForDay(
      day: today,
      uscita13: uscita13,
      sandraMattinaOn: sandraMattinaOn,
      sandraPranzoOn: sandraPranzoOn,
      sandraSeraOn: sandraSeraOn,
      schoolStart: schoolStart,
      overrides: overrides,
      schoolOutStart: schoolOutStart,
      schoolOutEnd: schoolOutEnd,
    );

    if (details.isEmpty) {
      return [
        CoverageDecision(
          id: 'coverage_today_ok',
          type: CoverageDecisionType.noIssue,
          level: CoverageDecisionLevel.success,
          title: 'Copertura stabile oggi',
          message: 'Alice risulta coperta per la giornata.',
          priority: 35,
          targetDate: today,
          decisionTrace: const [
            CoverageDecisionTrace(
              reason: CoverageDecisionReason.generic,
              level: CoverageDecisionTraceLevel.positive,
              message: 'Non risultano fasce scoperte per oggi.',
            ),
          ],
        ),
      ];
    }

    final first = details.first;

    return [
      CoverageDecision(
        id: 'coverage_today_gap_${today.year}_${today.month}_${today.day}',
        type: CoverageDecisionType.aliceUncovered,
        level: CoverageDecisionLevel.problem,
        title: 'Alice scoperta oggi',
        message:
            'Alice risulta scoperta nella fascia ${_time(first.start)}–${_time(first.end)}.',
        priority: 98,
        targetDate: today,
        decisionTrace: [
          CoverageDecisionTrace(
            reason: CoverageDecisionReason.coverageGap,
            level: CoverageDecisionTraceLevel.critical,
            message:
                'Ho trovato una fascia scoperta oggi: ${_time(first.start)}–${_time(first.end)}.',
          ),
          for (final line in first.lines)
            CoverageDecisionTrace(
              reason: CoverageDecisionReason.generic,
              level: CoverageDecisionTraceLevel.neutral,
              message: line,
            ),
        ],
      ),
    ];
  }

  static String _time(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
