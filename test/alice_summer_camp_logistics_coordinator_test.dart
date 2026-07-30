import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/adult_logistics_availability_resolver.dart';
import 'package:frododesk/logic/calendar/builders/alice_logistic_provider_availability_resolver.dart';
import 'package:frododesk/logic/calendar/builders/alice_summer_camp_logistics_coordinator.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/disease_period_store.dart';
import 'package:frododesk/logic/real_event_store.dart';
import 'package:frododesk/logic/support_network_store.dart';
import 'package:frododesk/logic/turn_engine.dart';
import 'package:frododesk/logic/calendar/models/alice_summer_camp_logistics.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = DateTime(2026, 8, 11);
  final matteo = AliceLogisticProviderRef.parent(AliceLogisticParent.matteo);
  final chiara = AliceLogisticProviderRef.parent(AliceLogisticParent.chiara);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  _Harness harness({
    List<SupportPerson> support = const [],
    List<AliceSandraAvailabilityWindow> sandra = const [],
  }) {
    final settings = DaySettingsStore();
    final network = SupportNetworkStore();
    for (final person in support) {
      network.addPerson(person);
    }
    final adult = AdultLogisticsAvailabilityResolver(
      turnEngine: TurnEngine(),
      diseasePeriodStore: DiseasePeriodStore(),
      realEventStore: RealEventStore(),
    );
    return _Harness(
      day: day,
      settings: settings,
      sandra: sandra,
      coordinator: AliceSummerCampLogisticsCoordinator(
        daySettingsStore: settings,
        availabilityResolver: AliceLogisticProviderAvailabilityResolver(
          adultResolver: adult,
          daySettingsStore: settings,
          supportNetworkStore: network,
        ),
      ),
    );
  }

  test('centro non operativo: entrambe le tratte inactive', () {
    final h = harness();
    final result = h.resolve(operational: false);
    expect(result.dropOff.status, AliceLogisticDecisionStatus.inactive);
    expect(result.pickUp.status, AliceLogisticDecisionStatus.inactive);
    expect(result.dropOff.availableProviders, isEmpty);
  });

  test('Matteo assegnato: turno blocca drop-off ma non pick-up', () async {
    final h = harness();
    await h.settings.setSummerCampDropOffProviderForDay(day, matteo);
    await h.settings.setSummerCampPickUpProviderForDay(day, matteo);
    final result = h.resolve();
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
    expect(result.pickUp.status, AliceLogisticDecisionStatus.assignedValid);
  });

  test('Chiara assegnata e disponibile al pick-up', () async {
    final h = harness();
    await h.settings.setSummerCampPickUpProviderForDay(day, chiara);
    expect(
      h.resolve().pickUp.status,
      AliceLogisticDecisionStatus.assignedValid,
    );
  });

  test('Sandra richiede una finestra completa', () async {
    final complete = harness(
      sandra: const [
        AliceSandraAvailabilityWindow(
          enabled: true,
          start: TimeOfDay(hour: 7, minute: 30),
          end: TimeOfDay(hour: 8, minute: 0),
        ),
      ],
    );
    await complete.settings.setSummerCampDropOffProviderForDay(
      day,
      AliceLogisticProviderRef.sandra,
    );
    expect(
      complete.resolve().dropOff.status,
      AliceLogisticDecisionStatus.assignedValid,
    );

    final partial = harness(
      sandra: const [
        AliceSandraAvailabilityWindow(
          enabled: true,
          start: TimeOfDay(hour: 7, minute: 50),
          end: TimeOfDay(hour: 8, minute: 0),
        ),
      ],
    );
    await partial.settings.setSummerCampDropOffProviderForDay(
      day,
      AliceLogisticProviderRef.sandra,
    );
    expect(
      partial.resolve().dropOff.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
  });

  test(
    'SupportPerson conserva ID e richiede tutti i flag e slot completo',
    () async {
      const person = SupportPerson(
        id: 'support-z',
        name: 'Qualunque nome',
        enabled: true,
        start: TimeOfDay(hour: 7, minute: 30),
        end: TimeOfDay(hour: 8, minute: 0),
      );
      final h = harness(support: const [person]);
      final provider = AliceLogisticProviderRef.supportPerson('support-z');
      await h.settings.setSummerCampDropOffProviderForDay(day, provider);
      expect(
        h.resolve().dropOff.status,
        AliceLogisticDecisionStatus.assignedProviderUnavailable,
      );
      await h.settings.setSupportPersonEnabledForDay(day, 'support-z', true);
      final result = h.resolve();
      expect(result.dropOff.status, AliceLogisticDecisionStatus.assignedValid);
      expect(result.dropOff.availableProviders, contains(provider));
    },
  );

  test('provider rimosso resta assegnato e indisponibile', () async {
    final h = harness();
    final removed = AliceLogisticProviderRef.supportPerson('removed');
    await h.settings.setSummerCampDropOffProviderForDay(day, removed);
    final result = h.resolve();
    expect(result.dropOff.assignedProvider, removed);
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
  });

  test(
    'assegnazioni sono lette indipendentemente e lo store non viene scritto',
    () async {
      final h = harness();
      await h.settings.setSummerCampDropOffProviderForDay(day, chiara);
      await h.settings.setSummerCampPickUpProviderForDay(day, matteo);
      final beforeDrop = h.settings.summerCampDropOffProviderForDay(day);
      final beforePick = h.settings.summerCampPickUpProviderForDay(day);
      final result = h.resolve();
      expect(result.dropOff.assignedProvider, chiara);
      expect(result.pickUp.assignedProvider, matteo);
      expect(h.settings.summerCampDropOffProviderForDay(day), beforeDrop);
      expect(h.settings.summerCampPickUpProviderForDay(day), beforePick);
    },
  );

  test(
    'provider disponibili hanno ordine deterministico per identità',
    () async {
      const a = SupportPerson(
        id: 'a',
        name: 'Zeta',
        enabled: true,
        start: TimeOfDay(hour: 15, minute: 0),
        end: TimeOfDay(hour: 17, minute: 0),
      );
      const z = SupportPerson(
        id: 'z',
        name: 'Alfa',
        enabled: true,
        start: TimeOfDay(hour: 15, minute: 0),
        end: TimeOfDay(hour: 17, minute: 0),
      );
      final h = harness(
        support: const [z, a],
        sandra: const [
          AliceSandraAvailabilityWindow(
            enabled: true,
            start: TimeOfDay(hour: 15, minute: 0),
            end: TimeOfDay(hour: 17, minute: 0),
          ),
        ],
      );
      await h.settings.setSupportPersonEnabledForDay(day, 'a', true);
      await h.settings.setSupportPersonEnabledForDay(day, 'z', true);
      final providers = h.resolve().pickUp.availableProviders;
      expect(
        providers,
        containsAll([matteo, chiara, AliceLogisticProviderRef.sandra]),
      );
      expect(
        providers.indexOf(AliceLogisticProviderRef.supportPerson('a')),
        lessThan(
          providers.indexOf(AliceLogisticProviderRef.supportPerson('z')),
        ),
      );
    },
  );
}

class _Harness {
  final DateTime day;
  final DaySettingsStore settings;
  final List<AliceSandraAvailabilityWindow> sandra;
  final AliceSummerCampLogisticsCoordinator coordinator;

  const _Harness({
    required this.day,
    required this.settings,
    required this.sandra,
    required this.coordinator,
  });

  AliceSummerCampLogisticsResult resolve({bool operational = true}) =>
      coordinator.resolveDay(
        day: day,
        summerCampOperational: operational,
        effectiveStart: DateTime(day.year, day.month, day.day, 8),
        effectiveEnd: DateTime(day.year, day.month, day.day, 16),
        overrides: DayOverrides.empty(day),
        sandraWindows: sandra,
      );
}
