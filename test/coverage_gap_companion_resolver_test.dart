import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/coverage_gap_companion_resolver.dart';
import 'package:frododesk/logic/calendar/builders/calendar_logistics_availability_resolver.dart';
import 'package:frododesk/logic/calendar/view_models/coverage_gap_recommendation_view_model.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/support_network_store.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const resolver = CoverageGapCompanionResolver();
  final day = DateTime(2026, 8, 11);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  CoverageGapDetail gap({String label = 'gap'}) => CoverageGapDetail(
    label: label,
    lines: const [],
    start: const TimeOfDay(hour: 5, minute: 0),
    end: const TimeOfDay(hour: 6, minute: 35),
  );

  Future<CoverageGapCompanionResolution> resolve({
    bool matteoBusy = true,
    bool chiaraBusy = true,
    List<SupportPerson> people = const [],
    Set<String> active = const {},
    List<CoverageSandraWindow> sandra = const [],
    CoverageGapDetail? detail,
  }) async {
    final store = SupportNetworkStore();
    final settings = DaySettingsStore();
    for (final person in people) {
      store.addPerson(person);
      if (active.contains(person.id)) {
        await settings.setSupportPersonEnabledForDay(day, person.id, true);
      }
    }
    return resolver.resolve(
      day: day,
      gap: detail ?? gap(),
      isMatteoBusy: (_, _) => matteoBusy,
      isChiaraBusy: (_, _) => chiaraBusy,
      availability: CalendarLogisticsAvailabilityResult(
        day: day,
        supportNetworkStore: store,
        daySettingsStore: settings,
        sandraWindows: sandra
            .map(
              (window) => SandraAvailabilityWindow(
                band: SandraAvailabilityBand.mattina,
                start: window.start,
                end: window.end,
                available: window.active,
              ),
            )
            .toList(),
      ),
    );
  }

  const full = SupportPerson(
    id: 'provider-id',
    name: 'sandra',
    enabled: true,
    start: TimeOfDay(hour: 4, minute: 30),
    end: TimeOfDay(hour: 7, minute: 0),
  );

  test(
    'adulti disponibili mantengono identita e ordine Matteo, Chiara',
    () async {
      final value = await resolve(matteoBusy: false, chiaraBusy: false);
      expect(value.availableCandidates.map((e) => e.providerId), [
        'matteo',
        'chiara',
      ]);
    },
  );

  test(
    'adulto occupato parzialmente o totalmente viene escluso dal reader',
    () async {
      final value = await resolve(matteoBusy: true, chiaraBusy: false);
      expect(value.availableCandidates.map((e) => e.providerId), ['chiara']);
    },
  );

  test('nessun candidato', () async {
    expect((await resolve()).availableCandidates, isEmpty);
  });

  test(
    'supporto abilitato e attivo copre tutto e preserva providerId',
    () async {
      final value = await resolve(
        people: const [full],
        active: const {'provider-id'},
      );
      expect(value.availableCandidates.single.providerId, 'provider-id');
      expect(
        value.availableCandidates.single.kind,
        CoverageGapCompanionKind.supportPerson,
      );
    },
  );

  test('supporto disabilitato globalmente viene escluso', () async {
    final value = await resolve(
      people: [full.copyWith(enabled: false)],
      active: const {'provider-id'},
    );
    expect(value.availableCandidates, isEmpty);
    expect(value.inactiveSupportCandidates, isEmpty);
  });

  test('supporto non attivo nel giorno resta inattivo tipizzato', () async {
    final value = await resolve(people: const [full]);
    expect(value.availableCandidates, isEmpty);
    expect(value.inactiveSupportCandidates.single.providerId, 'provider-id');
  });

  test('slot parziale non copre il gap', () async {
    final value = await resolve(
      people: [full.copyWith(end: const TimeOfDay(hour: 6, minute: 0))],
      active: const {'provider-id'},
    );
    expect(value.availableCandidates, isEmpty);
  });

  test(
    'slot multipli separati non vengono uniti in uno slot continuo',
    () async {
      final split = full.copyWith(
        slots: const [
          SupportTimeSlot(
            start: TimeOfDay(hour: 5, minute: 0),
            end: TimeOfDay(hour: 5, minute: 45),
          ),
          SupportTimeSlot(
            start: TimeOfDay(hour: 5, minute: 45),
            end: TimeOfDay(hour: 6, minute: 35),
          ),
        ],
      );
      final value = await resolve(
        people: [split],
        active: const {'provider-id'},
      );
      expect(value.availableCandidates, isEmpty);
    },
  );

  test('11 agosto 05:00-06:35 senza e con Sandra', () async {
    expect((await resolve()).availableCandidates, isEmpty);
    final value = await resolve(
      sandra: const [
        CoverageSandraWindow(
          start: TimeOfDay(hour: 5, minute: 0),
          end: TimeOfDay(hour: 6, minute: 35),
          active: true,
        ),
      ],
    );
    expect(value.availableCandidates.single.providerId, 'sandra');
  });

  test('gap scuola e centro estivo restano dati opachi e invariati', () async {
    for (final label in ['scuola', 'centro estivo']) {
      final detail = gap(label: label);
      final value = await resolve(detail: detail, matteoBusy: false);
      expect(value.gap, same(detail));
      expect(value.availableCandidates.single.providerId, 'matteo');
    }
  });
}
