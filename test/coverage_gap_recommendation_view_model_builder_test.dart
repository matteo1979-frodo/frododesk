import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/coverage_gap_recommendation_view_model_builder.dart';
import 'package:frododesk/logic/calendar/view_models/coverage_gap_recommendation_view_model.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/support_network_store.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  const builder = CoverageGapRecommendationViewModelBuilder();
  final day = DateTime(2026, 8, 11);

  CoverageGapDetail gap({
    String label = '',
    int startHour = 10,
    int endHour = 11,
  }) {
    return CoverageGapDetail(
      label: label,
      lines: const [],
      start: TimeOfDay(hour: startHour, minute: 0),
      end: TimeOfDay(hour: endHour, minute: 0),
    );
  }

  Future<CoverageGapRecommendationViewModel> build({
    CoverageGapDetail? detail,
    bool matteoBusy = true,
    bool chiaraBusy = true,
    SupportPerson? support,
    bool supportActive = false,
    List<CoverageSandraWindow> sandraWindows = const [],
  }) async {
    final supportStore = SupportNetworkStore();
    final settings = DaySettingsStore();
    if (support != null) {
      supportStore.addPerson(support);
      if (supportActive) {
        await settings.setSupportPersonEnabledForDay(day, support.id, true);
      }
    }
    return builder.build(
      day: day,
      gap: detail ?? gap(),
      isMatteoBusy: (_, _) => matteoBusy,
      isChiaraBusy: (_, _) => chiaraBusy,
      supportNetworkStore: supportStore,
      daySettingsStore: settings,
      sandraWindows: sandraWindows,
    );
  }

  const support = SupportPerson(
    id: 'nonna-id',
    name: 'nonna',
    enabled: true,
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 12, minute: 0),
  );

  test('gap con Matteo disponibile', () async {
    final model = await build(matteoBusy: false);
    expect(model.kind, CoverageGapRecommendationKind.useParent);
    expect(model.providerDisplayName, 'Matteo');
    expect(model.description, contains('può coprire Matteo'));
  });

  test('gap con Chiara disponibile', () async {
    final model = await build(chiaraBusy: false);
    expect(model.providerDisplayName, 'Chiara');
    expect(model.description, contains('può coprire Chiara'));
  });

  test('solo support network già attivo', () async {
    final model = await build(support: support, supportActive: true);
    expect(model.kind, CoverageGapRecommendationKind.useSupportNetwork);
    expect(model.providerId, 'nonna-id');
    expect(model.providerDisplayName, 'Nonna');
    expect(model.description, 'Suggerimento: verifica Supporto');
  });

  test('supporto esistente ma non abilitato nel giorno', () async {
    final model = await build(support: support);
    expect(model.providerDisplayName, 'Nonna');
    expect(model.canExecuteAction, isTrue);
    expect(model.description, contains('attiva Nonna'));
  });

  test('Sandra disponibile', () async {
    final model = await build(
      sandraWindows: const [
        CoverageSandraWindow(
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 12, minute: 0),
          active: true,
        ),
      ],
    );
    expect(model.kind, CoverageGapRecommendationKind.useSandra);
    expect(model.providerDisplayName, 'Sandra');
  });

  test('nessun provider: modifica turno o richiesta permesso', () async {
    final model = await build();
    expect(model.kind, CoverageGapRecommendationKind.changeShiftOrRequestLeave);
    expect(model.providerId, isNull);
    expect(model.description, contains('modifica turno / chiedi permesso'));
  });

  test('testo italiano e orario derivato da gap.start/end', () async {
    final model = await build(
      detail: gap(label: '99:99–88:88', startHour: 7, endHour: 9),
      matteoBusy: false,
    );
    expect(model.title, 'Alice a casa: 07:00–09:00');
    expect(model.description, 'Suggerimento: può coprire Matteo');
    expect(model.description, isNot(contains(model.kind.name)));
  });

  test(
    'label vuota, orari falsi e Alice non influenzano il risultato',
    () async {
      final labels = ['', 'Alice 23:15–23:45', 'Bob 04:00–05:00'];
      final models = <CoverageGapRecommendationViewModel>[];
      for (final label in labels) {
        models.add(await build(detail: gap(label: label), chiaraBusy: false));
      }
      expect(models.map((model) => model.title).toSet(), hasLength(1));
      expect(models.map((model) => model.description).toSet(), hasLength(1));
      expect(models.map((model) => model.kind).toSet(), hasLength(1));
    },
  );

  test('più gap mantengono ordine e conteggio nel builder reale', () {
    final result = builder.buildAll(
      day: day,
      gaps: [gap(startHour: 8, endHour: 9), gap(startHour: 14, endHour: 15)],
      isMatteoBusy: (_, _) => false,
      isChiaraBusy: (_, _) => true,
      supportNetworkStore: SupportNetworkStore(),
      daySettingsStore: DaySettingsStore(),
      sandraWindows: const [],
    );
    expect(result.countText, 'Ci sono 2 problemi da gestire oggi');
    expect(result.recommendations.map((model) => model.title), [
      'Alice a casa: 08:00–09:00',
      'Alice a casa: 14:00–15:00',
    ]);
  });
}
