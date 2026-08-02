import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/turn_presentation_state_builder.dart';
import 'package:frododesk/logic/calendar/models/turn_presentation_state.dart';
import 'package:frododesk/logic/turn_engine.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/disease_period.dart';

void main() {
  const builder = TurnPresentationStateBuilder();
  final day = DateTime(2026, 8, 3);

  TurnPresentationState build({
    TurnPlan plan = const TurnPlan.mattina(),
    DateTime? observedAt,
    PersonDayOverride? manualOverride,
    DiseasePeriod? diseasePeriod,
    bool isOnHoliday = false,
    bool isSick = false,
    bool isBedSick = false,
    bool isManualShiftChange = false,
    String? statusText,
    TurnSourceKind sourceKind = TurnSourceKind.standard,
    String? sourceText,
    bool hasConflict = false,
  }) => builder.build(
    day: day,
    observedAt: observedAt ?? DateTime(2026, 8, 3, 10),
    plan: plan,
    manualOverride: manualOverride,
    diseasePeriod: diseasePeriod,
    isOnHoliday: isOnHoliday,
    isSick: isSick,
    isBedSick: isBedSick,
    isManualShiftChange: isManualShiftChange,
    statusText: statusText,
    sourceKind: sourceKind,
    sourceText: sourceText,
    hasConflict: hasConflict,
  );

  test('preserves the Italian labels and semantic visuals for every turn', () {
    final cases = <TurnPlan, (String, String, TurnPresentationIcon)>{
      const TurnPlan.mattina(): ('M', '06:00–14:00', TurnPresentationIcon.work),
      const TurnPlan.pomeriggio(): (
        'P',
        '14:00–22:00',
        TurnPresentationIcon.work,
      ),
      const TurnPlan.notte(): ('N', '22:00–06:00', TurnPresentationIcon.work),
      const TurnPlan.off(): ('OFF', 'OFF', TurnPresentationIcon.rest),
    };

    for (final entry in cases.entries) {
      final state = build(plan: entry.key);
      expect(state.turnLabel, entry.value.$1);
      expect(state.timeLabel, entry.value.$2);
      expect(state.icon, entry.value.$3);
      expect(
        state.statusTone,
        entry.key.isOff
            ? TurnPresentationTone.rest
            : TurnPresentationTone.standard,
      );
    }
  });

  test(
    'uses typed sickness including bed sickness without reading its label',
    () {
      final mild = build(
        diseasePeriod: DiseasePeriod(
          personId: 'matteo',
          type: DiseaseType.mild,
          startDate: day,
          endDate: day,
        ),
        isSick: true,
        statusText: 'testo arbitrario',
      );
      final bed = build(
        diseasePeriod: DiseasePeriod(
          personId: 'matteo',
          type: DiseaseType.bed,
          startDate: day,
          endDate: day,
        ),
        isSick: true,
        isBedSick: true,
        statusText: 'testo senza parole chiave',
      );
      expect(mild.statusKind, TurnStatusKind.mildSickness);
      expect(mild.icon, TurnPresentationIcon.sickness);
      expect(bed.statusKind, TurnStatusKind.bedSickness);
      expect(bed.statusTone, TurnPresentationTone.sickness);
      expect(bed.isBedSick, isTrue);
    },
  );

  test('uses typed leave and preserves its current primary tone', () {
    final state = build(
      manualOverride: PersonDayOverride(status: OverrideStatus.ferie),
      isOnHoliday: true,
      statusText: 'Ferie',
    );
    expect(state.statusKind, TurnStatusKind.leave);
    expect(state.statusTone, TurnPresentationTone.standard);
    expect(state.icon, TurnPresentationIcon.leave);
  });

  test('uses typed manual shift change without reading status text', () {
    final state = build(
      isManualShiftChange: true,
      statusText: 'contenuto irrilevante',
      sourceKind: TurnSourceKind.dailyOverride,
      sourceText: 'Cambio turno (solo oggi)',
    );
    expect(state.statusKind, TurnStatusKind.manualShiftChange);
    expect(state.statusTone, TurnPresentationTone.manualOverride);
    expect(state.icon, TurnPresentationIcon.manualOverride);
    expect(state.sourceTone, TurnSourceTone.manualOverride);
  });

  test('maps every typed source to the same semantic color family', () {
    expect(build().sourceTone, TurnSourceTone.standard);
    expect(
      build(sourceKind: TurnSourceKind.fourthShift).sourceTone,
      TurnSourceTone.fourthShift,
    );
    expect(
      build(sourceKind: TurnSourceKind.periodOverride).sourceTone,
      TurnSourceTone.manualOverride,
    );
    expect(
      build(sourceKind: TurnSourceKind.rotationOverride).sourceTone,
      TurnSourceTone.rotationOverride,
    );
  });

  test(
    'carries the existing typed conflict result without recalculating it',
    () {
      expect(build(hasConflict: true).hasConflict, isTrue);
      expect(build(hasConflict: false).hasConflict, isFalse);
    },
  );

  test('resolves active, completed and future turns from injected time', () {
    expect(
      build(observedAt: DateTime(2026, 8, 3, 10)).temporalState,
      TurnTemporalState.active,
    );
    expect(
      build(observedAt: DateTime(2026, 8, 3, 15)).temporalState,
      TurnTemporalState.completed,
    );
    expect(
      build(observedAt: DateTime(2026, 8, 3, 5)).temporalState,
      TurnTemporalState.future,
    );
  });

  test('night turn remains active after midnight', () {
    final state = builder.build(
      day: day,
      observedAt: DateTime(2026, 8, 4, 2),
      plan: const TurnPlan.notte(),
      manualOverride: null,
      diseasePeriod: null,
      isOnHoliday: false,
      isSick: false,
      isBedSick: false,
      isManualShiftChange: false,
      statusText: null,
      sourceKind: TurnSourceKind.standard,
      sourceText: null,
      hasConflict: false,
    );
    expect(state.temporalState, TurnTemporalState.active);
  });

  test(
    'preserves current precedence: manual shift, override, disease, leave',
    () {
      final disease = DiseasePeriod(
        personId: 'matteo',
        type: DiseaseType.bed,
        startDate: day,
        endDate: day,
      );
      expect(
        build(
          isManualShiftChange: true,
          manualOverride: PersonDayOverride(status: OverrideStatus.ferie),
          diseasePeriod: disease,
          isOnHoliday: true,
          isBedSick: true,
        ).statusKind,
        TurnStatusKind.manualShiftChange,
      );
      expect(
        build(
          manualOverride: PersonDayOverride(
            status: OverrideStatus.malattiaALetto,
          ),
          diseasePeriod: disease,
          isOnHoliday: true,
        ).statusKind,
        TurnStatusKind.bedSickness,
      );
      expect(
        build(diseasePeriod: disease, isOnHoliday: true).statusKind,
        TurnStatusKind.bedSickness,
      );
      expect(build(isOnHoliday: true).statusKind, TurnStatusKind.leave);
    },
  );

  test('presenter has no text parsing, enum.name, clock, or UI dependency', () {
    final source = File(
      'lib/logic/calendar/builders/turn_presentation_state_builder.dart',
    ).readAsStringSync();
    for (final forbidden in [
      '.contains(',
      '.toLowerCase(',
      '.startsWith(',
      '.name',
      'DateTime.now(',
      'package:flutter/',
      'Color',
      'IconData',
      'BuildContext',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
