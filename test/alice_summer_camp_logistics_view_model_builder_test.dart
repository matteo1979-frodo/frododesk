import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/alice_summer_camp_logistics_view_model_builder.dart';
import 'package:frododesk/logic/calendar/builders/day_gap_visual_state_builder.dart';
import 'package:frododesk/logic/calendar/models/alice_summer_camp_logistics.dart';
import 'package:frododesk/logic/calendar/models/coverage_result_step_a.dart';
import 'package:frododesk/logic/calendar/models/day_gap_visual_state.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:frododesk/widgets/calendar/summer_camp_logistics_section.dart';

void main() {
  const builder = AliceSummerCampLogisticsViewModelBuilder();
  final matteo = AliceLogisticProviderRef.parent(AliceLogisticParent.matteo);
  final chiara = AliceLogisticProviderRef.parent(AliceLogisticParent.chiara);

  AliceLogisticDecisionResult leg(
    AliceLogisticLeg leg,
    AliceLogisticDecisionStatus status, {
    AliceLogisticProviderRef? assigned,
    List<AliceLogisticProviderRef> available = const [],
  }) {
    final start = leg == AliceLogisticLeg.dropOff
        ? DateTime(2026, 8, 10, 8, 10)
        : DateTime(2026, 8, 10, 17, 30);
    return AliceLogisticDecisionResult(
      leg: leg,
      start: start,
      end: start.add(const Duration(minutes: 20)),
      status: status,
      assignedProvider: assigned,
      availableProviders: available,
    );
  }

  AliceSummerCampLogisticsResult result(
    AliceLogisticDecisionStatus drop,
    AliceLogisticDecisionStatus pick, {
    AliceLogisticProviderRef? dropAssigned,
    AliceLogisticProviderRef? pickAssigned,
    List<AliceLogisticProviderRef> dropAvailable = const [],
    List<AliceLogisticProviderRef> pickAvailable = const [],
  }) => AliceSummerCampLogisticsResult(
    dropOff: leg(
      AliceLogisticLeg.dropOff,
      drop,
      assigned: dropAssigned,
      available: dropAvailable,
    ),
    pickUp: leg(
      AliceLogisticLeg.pickUp,
      pick,
      assigned: pickAssigned,
      available: pickAvailable,
    ),
  );

  test('giorno non operativo non produce la sezione', () {
    expect(
      builder.build(
        result: result(
          AliceLogisticDecisionStatus.inactive,
          AliceLogisticDecisionStatus.inactive,
        ),
        supportPeople: const [],
      ),
      isNull,
    );
  });

  test('giorno operativo presenta due tratte e intervalli distinti', () {
    final model = builder.build(
      result: result(
        AliceLogisticDecisionStatus.assignedValid,
        AliceLogisticDecisionStatus.assignedValid,
        dropAssigned: matteo,
        pickAssigned: chiara,
      ),
      supportPeople: const [],
    )!;
    expect(model.sectionTitle, 'Logistica centro estivo');
    expect(model.dropOff.fieldLabel, 'Accompagna');
    expect(model.pickUp.fieldLabel, 'Riprende');
    expect(model.dropOff.intervalLabel, '08:10–08:30');
    expect(model.pickUp.intervalLabel, '17:30–17:50');
    expect(
      model.dropOff.description,
      'Matteo accompagna Alice al centro estivo.',
    );
    expect(
      model.pickUp.description,
      'Chiara riprende Alice dal centro estivo.',
    );
    expect(model.logisticGapCount, 0);
    expect(model.hasLogisticGaps, isFalse);
  });

  test('opzioni includono Sandra e nome reale della rete di supporto', () {
    const person = SupportPerson(
      id: 'support-42',
      name: 'Nonna Rosa',
      enabled: true,
      start: TimeOfDay(hour: 7, minute: 0),
      end: TimeOfDay(hour: 19, minute: 0),
    );
    final model = builder.build(
      result: result(
        AliceLogisticDecisionStatus.unassignedProviderAvailable,
        AliceLogisticDecisionStatus.unassignedProviderAvailable,
        dropAvailable: [
          matteo,
          AliceLogisticProviderRef.sandra,
          AliceLogisticProviderRef.supportPerson('support-42'),
        ],
      ),
      supportPeople: const [person],
    )!;
    expect(
      model.dropOff.options.map((e) => e.label),
      containsAll(['Da assegnare', 'Sandra', 'Nonna Rosa']),
    );
    expect(model.dropOff.alternatives, ['Matteo', 'Sandra', 'Nonna Rosa']);
    expect(
      model.dropOff.description,
      'Devi scegliere chi accompagna Alice al centro estivo.',
    );
    expect(model.logisticGapCount, 2);
    expect(model.hasLogisticGaps, isTrue);
  });

  test('conflitto mostra assegnato e alternative senza ID tecnici', () {
    final model = builder.build(
      result: result(
        AliceLogisticDecisionStatus.assignedProviderUnavailable,
        AliceLogisticDecisionStatus.noProviderAvailable,
        dropAssigned: matteo,
        dropAvailable: [chiara],
      ),
      supportPeople: const [],
    )!;
    expect(model.dropOff.title, 'Conflitto logistico');
    expect(
      model.dropOff.description,
      'Matteo è assegnato, ma non è disponibile per accompagnare Alice.',
    );
    expect(model.dropOff.alternatives, ['Chiara']);
    expect(model.pickUp.title, 'Buco logistico');
    expect(model.conflictCount, 1);
    expect(model.gapCount, 1);
    expect(model.logisticGapCount, 2);
  });

  test('provider rimosso conserva assegnazione e usa fallback sicuro', () {
    final missing = AliceLogisticProviderRef.supportPerson('technical-id');
    final model = builder.build(
      result: result(
        AliceLogisticDecisionStatus.assignedProviderUnavailable,
        AliceLogisticDecisionStatus.assignedValid,
        dropAssigned: missing,
        pickAssigned: chiara,
      ),
      supportPeople: const [],
    )!;
    expect(model.dropOff.assignedProvider, missing);
    expect(
      model.dropOff.assignedProviderLabel,
      'Persona di supporto non disponibile',
    );
    expect(model.dropOff.options.last.provider, missing);
    expect(model.dropOff.description, isNot(contains('technical-id')));
  });

  test('una sola tratta non assegnata resta un buco con alternative', () {
    final model = builder.build(
      result: result(
        AliceLogisticDecisionStatus.unassignedProviderAvailable,
        AliceLogisticDecisionStatus.assignedValid,
        pickAssigned: chiara,
        dropAvailable: [matteo],
      ),
      supportPeople: const [],
    )!;

    expect(model.logisticGapCount, 1);
    expect(model.logisticGaps.single, same(model.dropOff));
    expect(model.dropOff.title, 'Buco logistico da assegnare');
    expect(model.dropOff.alternatives, ['Matteo']);
  });

  for (final status in [
    AliceLogisticDecisionStatus.assignedProviderUnavailable,
    AliceLogisticDecisionStatus.noProviderAvailable,
  ]) {
    test('${status.name} è un buco logistico e rende il giorno rosso', () {
      final model = builder.build(
        result: result(
          status,
          AliceLogisticDecisionStatus.assignedValid,
          dropAssigned:
              status == AliceLogisticDecisionStatus.assignedProviderUnavailable
              ? matteo
              : null,
          pickAssigned: chiara,
          dropAvailable:
              status == AliceLogisticDecisionStatus.assignedProviderUnavailable
              ? [chiara]
              : const [],
        ),
        supportPeople: const [],
      )!;
      final visual = const DayGapVisualStateBuilder().build(
        hasLogisticConflict: false,
        hasIncompleteLogistics: false,
        hasRealCoverageGap: false,
        hasSummerCampLogisticGaps: model.hasLogisticGaps,
      );

      expect(model.logisticGapCount, 1);
      expect(visual.state, DayGapVisualState.realGap);
      expect(visual.color, Colors.red);
    });
  }

  test('stato globale separa coverage e buchi logistici', () {
    const coverageOk = CoverageResultStepA(
      details: [],
      gapDetails: [],
      bannerText: 'OK',
    );
    final twoLogisticGaps = builder.build(
      result: result(
        AliceLogisticDecisionStatus.unassignedProviderAvailable,
        AliceLogisticDecisionStatus.noProviderAvailable,
        dropAvailable: [matteo, chiara],
      ),
      supportPeople: const [],
    )!;
    final logisticRed = const DayGapVisualStateBuilder().build(
      hasLogisticConflict: false,
      hasIncompleteLogistics: false,
      hasRealCoverageGap: coverageOk.gapDetails.isNotEmpty,
      hasSummerCampLogisticGaps: twoLogisticGaps.hasLogisticGaps,
    );

    expect(coverageOk.ok, isTrue);
    expect(coverageOk.gapCount, 0);
    expect(twoLogisticGaps.logisticGapCount, 2);
    expect(logisticRed.state, DayGapVisualState.realGap);
    expect(logisticRed.color, Colors.red);
    expect(logisticRed.headline, isNot(contains('Nessun problema oggi')));

    const coverageWithGap = CoverageResultStepA(
      details: [],
      gapDetails: [
        CoverageGapDetail(
          label: 'gap',
          lines: ['gap'],
          start: TimeOfDay(hour: 8, minute: 0),
          end: TimeOfDay(hour: 9, minute: 0),
        ),
      ],
      bannerText: 'Gap',
    );
    final bothRed = const DayGapVisualStateBuilder().build(
      hasLogisticConflict: false,
      hasIncompleteLogistics: false,
      hasRealCoverageGap: true,
      hasSummerCampLogisticGaps: twoLogisticGaps.hasLogisticGaps,
    );
    expect(coverageWithGap.gapCount, 1);
    expect(twoLogisticGaps.logisticGapCount, 2);
    expect(bothRed.state, DayGapVisualState.realGap);
  });

  test('nessun gap di alcun tipo produce stato globale verde', () {
    final model = builder.build(
      result: result(
        AliceLogisticDecisionStatus.assignedValid,
        AliceLogisticDecisionStatus.assignedValid,
        dropAssigned: matteo,
        pickAssigned: chiara,
      ),
      supportPeople: const [],
    )!;
    final visual = const DayGapVisualStateBuilder().build(
      hasLogisticConflict: false,
      hasIncompleteLogistics: false,
      hasRealCoverageGap: false,
      hasSummerCampLogisticGaps: model.hasLogisticGaps,
    );

    expect(visual.state, DayGapVisualState.noProblem);
    expect(visual.color, Colors.green);
  });

  testWidgets('pannello mostra due buchi logistici e le alternative', (
    tester,
  ) async {
    final model = builder.build(
      result: result(
        AliceLogisticDecisionStatus.unassignedProviderAvailable,
        AliceLogisticDecisionStatus.unassignedProviderAvailable,
        dropAvailable: [matteo],
        pickAvailable: [chiara, AliceLogisticProviderRef.sandra],
      ),
      supportPeople: const [],
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummerCampLogisticsSection(
            model: model,
            onDropOffChanged: (_) {},
            onPickUpChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Buchi logistici'), findsOneWidget);
    expect(find.text('2 buchi logistici'), findsOneWidget);
    expect(find.text('Alternativa disponibile: Matteo.'), findsWidgets);
    expect(find.text('Alternative disponibili: Chiara, Sandra.'), findsWidgets);
    expect(find.textContaining('decisioni logistiche'), findsNothing);
    expect(find.textContaining('Nessun problema oggi'), findsNothing);
  });
}
