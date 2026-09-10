import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/models/frodo_observation.dart';
import 'package:frododesk/screens/statistiche_screen.dart';
import 'package:frododesk/widgets/observation/observation_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Statistics formats precise costs and hourly rates in Italian', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final coreStore = CoreStore(initialDate: now);
    coreStore.daySettingsStore.setSandraMattinaForDay(now, true);
    coreStore.settingsStore.setSandraHourlyRate(779727.09);

    await tester.pumpWidget(
      MaterialApp(home: StatisticheScreen(coreStore: coreStore)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sandra • €1.234.567,89'), findsOneWidget);

    await tester.tap(find.text('Supporto familiare'));
    await tester.pumpAndSettle();

    expect(find.textContaining('€1.234.567,89'), findsWidgets);
    expect(find.text('(€779.727,09/h)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Statistics keeps zero precise and input formatting untouched', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final coreStore = CoreStore(initialDate: DateTime.now());
    coreStore.settingsStore.setSandraHourlyRate(12.5);

    await tester.pumpWidget(
      MaterialApp(home: StatisticheScreen(coreStore: coreStore)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sandra • €0,00'), findsOneWidget);
  });

  testWidgets('Observation UI formats numeric scenarios but preserves messages', (
    tester,
  ) async {
    const narrative = 'Hai circa €100 disponibili: testo già composto.';
    final observation = FrodoObservation(
      id: 'observation',
      module: 'finance',
      category: FrodoObservationCategory.finance,
      title: 'Scenario economico',
      message: narrative,
      priority: 1,
      level: FrodoObservationLevel.info,
      createdAt: DateTime(2026, 8, 21),
      scenarios: const [
        FrodoObservationScenario(
          title: 'Negativo',
          message: 'Scenario negativo',
          projectedBalance: -1234567.89,
          level: FrodoObservationLevel.problem,
        ),
        FrodoObservationScenario(
          title: 'Zero',
          message: 'Scenario zero',
          projectedBalance: -0.0,
          level: FrodoObservationLevel.info,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox(width: 600, child: ObservationCard(observation: observation)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(narrative), findsOneWidget);
    expect(find.text('Saldo previsto: -€1.234.567,89'), findsOneWidget);
    expect(find.text('Saldo previsto: €0,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Statistics and Observation UI delegate precise money presentation', () {
    final statistics = File(
      'lib/screens/statistiche_screen.dart',
    ).readAsStringSync();
    final observation = File(
      'lib/widgets/observation/observation_card.dart',
    ).readAsStringSync();

    expect(statistics, contains("import '../utils/euro_formatter.dart';"));
    expect(
      observation,
      contains("import '../../utils/euro_formatter.dart';"),
    );
  });
}
