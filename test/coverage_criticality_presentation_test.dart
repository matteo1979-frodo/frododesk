import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/coverage_criticality_view_model_builder.dart';
import 'package:frododesk/logic/calendar/builders/coverage_result_step_a_builder.dart';
import 'package:frododesk/logic/calendar/models/coverage_result_step_a.dart';
import 'package:frododesk/logic/calendar/view_models/coverage_criticality_view_model.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/models/coverage_criticality_detail.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:frododesk/widgets/calendar/coverage_criticalities_panel.dart';

void main() {
  final day = DateTime(2026, 8, 11);

  CoverageCriticalityDetail detail({
    required CoverageCriticalityKind kind,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required CoverageSource source,
    required String providerId,
  }) {
    return CoverageCriticalityDetail(
      kind: kind,
      personId: 'chiara',
      start: DateTime(2026, 8, 11, startHour, startMinute),
      end: DateTime(2026, 8, 11, endHour, endMinute),
      source: source,
      coverageProviderId: providerId,
    );
  }

  CoverageGapDetail gap() {
    return const CoverageGapDetail(
      label: 'Alice scoperta 05:00–06:35',
      start: TimeOfDay(hour: 5, minute: 0),
      end: TimeOfDay(hour: 6, minute: 35),
      lines: ['Alice è scoperta.'],
    );
  }

  group('CoverageResultStepA', () {
    final criticality = detail(
      kind: CoverageCriticalityKind.recoverySacrificed,
      startHour: 6,
      startMinute: 35,
      endHour: 14,
      endMinute: 30,
      source: CoverageSource.parentForced,
      providerId: 'chiara',
    );

    test('una criticità senza gap mantiene Copertura OK', () {
      final result = CoverageResultStepA(
        details: const [],
        gapDetails: const [],
        criticalityDetails: [criticality],
        bannerText: 'Copertura OK',
      );

      expect(result.ok, isTrue);
      expect(result.gapCount, 0);
      expect(result.criticalDecisionCount, 1);
      expect(result.protectedRecoveryCount, 0);
    });

    test('un gap e una criticità contano un solo buco', () {
      final result = CoverageResultStepA(
        details: const [],
        gapDetails: [gap()],
        criticalityDetails: [criticality],
        bannerText: 'BUCO (1)',
      );

      expect(result.ok, isFalse);
      expect(result.gapCount, 1);
      expect(result.criticalDecisionCount, 1);
    });

    test('copyWith conserva separati gap e criticità', () {
      final result = CoverageResultStepA(
        details: const [],
        gapDetails: const [],
        criticalityDetails: [criticality],
        bannerText: 'Copertura OK',
      ).copyWith(gapDetails: [gap()]);

      expect(result.gapCount, 1);
      expect(result.criticalDecisionCount, 1);
    });

    test('CoverageDayAnalysis attraversa il builder senza ricalcolo', () {
      final analysis = CoverageDayAnalysis(
        gaps: const [],
        details: const [],
        criticalityDetails: [criticality],
      );

      final result = const CoverageResultStepABuilder().build(
        analysis: analysis,
        filteredGapDetails: const [],
        summaryDetails: const [],
        bannerText: 'Copertura OK',
      );

      expect(result.criticalityDetails.single, same(criticality));
    });
  });

  group('CoverageCriticalityViewModelBuilder', () {
    const builder = CoverageCriticalityViewModelBuilder();
    const supportPeople = [
      SupportPerson(
        id: 'support-id',
        name: 'Nonna Lina',
        enabled: true,
        start: TimeOfDay(hour: 10, minute: 0),
        end: TimeOfDay(hour: 12, minute: 0),
      ),
    ];

    CoverageCriticalityViewModel buildOne(
      CoverageCriticalityDetail value, {
      List<SupportPerson> people = supportPeople,
    }) {
      return builder.build(details: [value], supportPeople: people).single;
    }

    test('testo italiano sacrificed e intervallo HH:mm–HH:mm', () {
      final model = buildOne(
        detail(
          kind: CoverageCriticalityKind.recoverySacrificed,
          startHour: 6,
          startMinute: 35,
          endHour: 14,
          endMinute: 30,
          source: CoverageSource.parentForced,
          providerId: 'chiara',
        ),
      );

      expect(model.title, 'Recupero post-notte sacrificato');
      expect(
        model.text,
        'Chiara copre Alice sacrificando il recupero post-notte.',
      );
      expect(model.timeRange, '06:35–14:30');
      expect(
        model.realityText,
        '06:35–14:30 — Alice coperta da Chiara; recupero post-notte sacrificato.',
      );
    });

    test('protected risolve Matteo, Sandra e SupportPerson', () {
      CoverageCriticalityViewModel protected(String provider) => buildOne(
        detail(
          kind: CoverageCriticalityKind.recoveryProtected,
          startHour: 14,
          startMinute: 30,
          endHour: 21,
          endMinute: 0,
          source: provider == 'support-id'
              ? CoverageSource.supportNetwork
              : CoverageSource.parentNormal,
          providerId: provider,
        ),
      );

      expect(
        protected('matteo').text,
        'Chiara può recuperare grazie a Matteo.',
      );
      expect(
        protected(CoverageProviderIds.sandraLegacy).text,
        'Chiara può recuperare grazie a Sandra.',
      );
      expect(
        protected('support-id').text,
        'Chiara può recuperare grazie a Nonna Lina.',
      );
    });

    test('fallback non mostra enum o ID tecnici', () {
      final model = buildOne(
        CoverageCriticalityDetail(
          kind: CoverageCriticalityKind.recoveryProtected,
          personId: 'adulto-2',
          start: day,
          end: day.add(const Duration(hours: 1)),
          source: CoverageSource.supportNetwork,
          coverageProviderId: 'provider_raw_id',
        ),
        people: const [],
      );

      expect(model.text, isNot(contains('adulto-2')));
      expect(model.text, isNot(contains('provider_raw_id')));
      expect(model.text, isNot(contains('recoveryProtected')));
      expect(model.text, contains('una persona di supporto'));
    });

    test('supporti differenti non vengono uniti nel presenter', () {
      final values = builder.build(
        details: [
          detail(
            kind: CoverageCriticalityKind.recoveryProtected,
            startHour: 10,
            startMinute: 0,
            endHour: 11,
            endMinute: 0,
            source: CoverageSource.supportNetwork,
            providerId: 'support-a',
          ),
          detail(
            kind: CoverageCriticalityKind.recoveryProtected,
            startHour: 11,
            startMinute: 0,
            endHour: 12,
            endMinute: 0,
            source: CoverageSource.supportNetwork,
            providerId: 'support-b',
          ),
        ],
        supportPeople: const [
          SupportPerson(
            id: 'support-a',
            name: 'Anna',
            enabled: true,
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 11, minute: 0),
          ),
          SupportPerson(
            id: 'support-b',
            name: 'Paola',
            enabled: true,
            start: TimeOfDay(hour: 11, minute: 0),
            end: TimeOfDay(hour: 12, minute: 0),
          ),
        ],
      );

      expect(values, hasLength(2));
      expect(values.map((item) => item.text), [
        'Chiara può recuperare grazie a Anna.',
        'Chiara può recuperare grazie a Paola.',
      ]);
    });
  });

  group('widget criticità', () {
    Future<void> pump(
      WidgetTester tester,
      List<CoverageCriticalityViewModel> items,
    ) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CoverageCriticalitiesPanel(items: items)),
        ),
      );
    }

    CoverageCriticalityViewModel model(CoverageCriticalityKind kind) {
      final value = detail(
        kind: kind,
        startHour: 6,
        startMinute: 35,
        endHour: 14,
        endMinute: 30,
        source: kind == CoverageCriticalityKind.recoverySacrificed
            ? CoverageSource.parentForced
            : CoverageSource.parentNormal,
        providerId: kind == CoverageCriticalityKind.recoverySacrificed
            ? 'chiara'
            : 'matteo',
      );
      return const CoverageCriticalityViewModelBuilder()
          .build(details: [value], supportPeople: const [])
          .single;
    }

    testWidgets('mostra le tre sezioni semanticamente distinte', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Buchi reali'),
                CoverageCriticalitiesPanel(
                  items: [
                    model(CoverageCriticalityKind.recoverySacrificed),
                    model(CoverageCriticalityKind.recoveryProtected),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Buchi reali'), findsOneWidget);
      expect(find.text('Decisioni critiche'), findsOneWidget);
      expect(find.text('Recuperi protetti'), findsOneWidget);
      expect(
        find.text('1 decisione critica • 1 recupero protetto'),
        findsOneWidget,
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('non mostra la sezione vuota', (tester) async {
      await pump(tester, [model(CoverageCriticalityKind.recoveryProtected)]);

      expect(find.text('Decisioni critiche'), findsNothing);
      expect(find.text('Recuperi protetti'), findsOneWidget);
    });

    testWidgets('realtà e decisioni condividono gli stessi dati tipizzati', (
      tester,
    ) async {
      final item = model(CoverageCriticalityKind.recoveryProtected);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CoverageCriticalityRealityList(items: [item]),
                CoverageCriticalitiesPanel(items: [item]),
              ],
            ),
          ),
        ),
      );

      expect(find.text(item.realityText), findsOneWidget);
      expect(find.text(item.text), findsOneWidget);
      expect(find.text(item.timeRange), findsOneWidget);
    });
  });
}
