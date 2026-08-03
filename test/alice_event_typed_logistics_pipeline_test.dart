import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/adult_logistics_availability_resolver.dart';
import 'package:frododesk/logic/alice_events/alice_event_behavior.dart';
import 'package:frododesk/logic/calendar/builders/alice_event_logistics_coordinator.dart';
import 'package:frododesk/logic/calendar/builders/alice_event_logistics_text_builder.dart';
import 'package:frododesk/logic/calendar/builders/alice_logistic_provider_availability_resolver.dart';
import 'package:frododesk/logic/calendar/builders/alice_logistics_status_builder.dart';
import 'package:frododesk/logic/calendar/builders/calendar_logistics_availability_resolver.dart';
import 'package:frododesk/logic/calendar/models/alice_event_logistics.dart';
import 'package:frododesk/logic/calendar/models/alice_summer_camp_logistics.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/disease_period_store.dart';
import 'package:frododesk/logic/real_event_store.dart';
import 'package:frododesk/logic/settings_store.dart';
import 'package:frododesk/logic/support_network_store.dart';
import 'package:frododesk/logic/turn_engine.dart';
import 'package:frododesk/models/alice_special_event.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = DateTime(2026, 8, 11);
  final matteo = AliceLogisticProviderRef.parent(AliceLogisticParent.matteo);
  final chiara = AliceLogisticProviderRef.parent(AliceLogisticParent.chiara);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  AliceSpecialEvent event({
    String? dropOff = 'matteo',
    String? pickUp = 'chiara',
    AliceEventBehavior behavior = AliceEventBehavior.logistic,
  }) => AliceSpecialEvent(
    id: 'alice-event',
    label: 'Sport Alice',
    category: AliceSpecialEventCategory.sport,
    behavior: behavior,
    dropOffAdultKey: dropOff,
    pickUpAdultKey: pickUp,
    date: day,
    start: const TimeOfDay(hour: 9, minute: 0),
    end: const TimeOfDay(hour: 10, minute: 0),
  );

  test('Matteo disponibile per accompagnamento conserva il provider', () async {
    final h = await _Harness.create(day: day);
    final result = h.resolve(event());
    expect(result.outboundProvider, matteo);
    expect(result.outbound.status, AliceLogisticDecisionStatus.assignedValid);
    expect(result.outbound.start, DateTime(2026, 8, 11, 8, 40));
    expect(result.outbound.end, DateTime(2026, 8, 11, 9));
  });

  test('Chiara disponibile per ritiro conserva il provider', () async {
    final h = await _Harness.create(day: day);
    final result = h.resolve(event());
    expect(result.returnProvider, chiara);
    expect(result.returnLeg.status, AliceLogisticDecisionStatus.assignedValid);
    expect(result.returnLeg.start, DateTime(2026, 8, 11, 10));
    expect(result.returnLeg.end, DateTime(2026, 8, 11, 10, 20));
  });

  test('Sandra globale senza fascia attiva non e disponibile', () async {
    final h = await _Harness.create(day: day, globalSandra: true);
    final result = h.resolve(event(dropOff: 'sandra'));
    expect(result.outboundProvider, isNull);
    expect(
      result.outbound.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
  });

  test('Sandra con fascia attiva arriva come provider concreto', () async {
    final h = await _Harness.create(
      day: day,
      globalSandra: true,
      sandraMorningActive: true,
    );
    final result = h.resolve(event(dropOff: 'sandra'));
    expect(result.outboundProvider, AliceLogisticProviderRef.sandra);
    expect(result.outboundProvider?.providerId, 'sandra');
  });

  test('support person solo enabled non e disponibile', () async {
    final h = await _Harness.create(day: day, support: [_fullSupport('nonna')]);
    final result = h.resolve(event(dropOff: 'supporto'));
    expect(result.outboundProvider, isNull);
    expect(
      result.outbound.unresolvedReason,
      AliceEventLogisticsUnresolvedReason.noConcreteSupportProvider,
    );
  });

  test('support person attiva con slot parziale non e disponibile', () async {
    final h = await _Harness.create(
      day: day,
      support: [
        _fullSupport(
          'parziale',
          start: const TimeOfDay(hour: 8, minute: 50),
          end: const TimeOfDay(hour: 9, minute: 0),
        ),
      ],
      activeSupport: const {'parziale'},
    );
    expect(h.resolve(event(dropOff: 'supporto')).outboundProvider, isNull);
  });

  test('support person con slot completo conserva providerId', () async {
    final h = await _Harness.create(
      day: day,
      support: [_fullSupport('nonna-id')],
      activeSupport: const {'nonna-id'},
    );
    final result = h.resolve(event(dropOff: 'supporto'));
    expect(
      result.outboundProvider?.kind,
      AliceLogisticProviderKind.supportPerson,
    );
    expect(result.outboundProvider?.providerId, 'nonna-id');
  });

  test('due slot separati non formano copertura continua', () async {
    final split = SupportPerson(
      id: 'split',
      name: 'Split',
      enabled: true,
      start: const TimeOfDay(hour: 8, minute: 40),
      end: const TimeOfDay(hour: 9, minute: 0),
      slots: const [
        SupportTimeSlot(
          start: TimeOfDay(hour: 8, minute: 40),
          end: TimeOfDay(hour: 8, minute: 50),
        ),
        SupportTimeSlot(
          start: TimeOfDay(hour: 8, minute: 50),
          end: TimeOfDay(hour: 9, minute: 0),
        ),
      ],
    );
    final h = await _Harness.create(
      day: day,
      support: [split],
      activeSupport: const {'split'},
    );
    expect(h.resolve(event(dropOff: 'supporto')).outboundProvider, isNull);
  });

  test('piu supporti mantengono la precedenza stabile per id', () async {
    final h = await _Harness.create(
      day: day,
      support: [_fullSupport('z-support'), _fullSupport('a-support')],
      activeSupport: const {'z-support', 'a-support'},
    );
    final result = h.resolve(event(dropOff: 'supporto'));
    expect(result.outboundProvider?.providerId, 'a-support');
  });

  test('nessun provider produce stato logistico non risolto', () async {
    final h = await _Harness.create(day: day, blockBothAdults: true);
    final result = h.resolve(event(dropOff: null, pickUp: null));
    expect(
      result.outbound.status,
      AliceLogisticDecisionStatus.noProviderAvailable,
    );
    expect(
      result.returnLeg.status,
      AliceLogisticDecisionStatus.noProviderAvailable,
    );
  });

  test('provider disponibile soltanto all andata', () async {
    final h = await _Harness.create(
      day: day,
      support: [
        _fullSupport(
          'andata',
          start: const TimeOfDay(hour: 8, minute: 40),
          end: const TimeOfDay(hour: 9, minute: 0),
        ),
      ],
      activeSupport: const {'andata'},
    );
    final result = h.resolve(event(dropOff: 'supporto', pickUp: 'supporto'));
    expect(result.outboundProvider?.providerId, 'andata');
    expect(result.returnProvider, isNull);
  });

  test('provider disponibile soltanto al ritorno', () async {
    final h = await _Harness.create(
      day: day,
      support: [
        _fullSupport(
          'ritorno',
          start: const TimeOfDay(hour: 10, minute: 0),
          end: const TimeOfDay(hour: 10, minute: 20),
        ),
      ],
      activeSupport: const {'ritorno'},
    );
    final result = h.resolve(event(dropOff: 'supporto', pickUp: 'supporto'));
    expect(result.outboundProvider, isNull);
    expect(result.returnProvider?.providerId, 'ritorno');
  });

  test('provider diversi per andata e ritorno', () async {
    final h = await _Harness.create(
      day: day,
      support: [
        _fullSupport(
          'andata',
          start: const TimeOfDay(hour: 8, minute: 40),
          end: const TimeOfDay(hour: 9, minute: 0),
        ),
        _fullSupport(
          'ritorno',
          start: const TimeOfDay(hour: 10, minute: 0),
          end: const TimeOfDay(hour: 10, minute: 20),
        ),
      ],
      activeSupport: const {'andata', 'ritorno'},
    );
    final result = h.resolve(event(dropOff: 'andata', pickUp: 'ritorno'));
    expect(result.outboundProvider?.providerId, 'andata');
    expect(result.returnProvider?.providerId, 'ritorno');
  });

  test('providerId arriva fino al ViewModel consumato dalla UI', () async {
    final h = await _Harness.create(
      day: day,
      support: [_fullSupport('vm-provider')],
      activeSupport: const {'vm-provider'},
    );
    final resolution = h.resolve(event(dropOff: 'supporto'));
    final viewModel = const AliceEventLogisticsTextBuilder().build(resolution);
    expect(viewModel.dropOffProvider?.providerId, 'vm-provider');
  });

  test('stato globale e dettagli usano la stessa risoluzione', () async {
    final h = await _Harness.create(
      day: day,
      blockMatteoOutbound: true,
      support: [_fullSupport('suggerito')],
      activeSupport: const {'suggerito'},
    );
    final resolution = h.resolve(event());
    final status = const AliceLogisticsStatusBuilder().build(
      resolutions: [resolution],
    );
    final viewModel = const AliceEventLogisticsTextBuilder().build(resolution);
    expect(status.hasLogisticConflict, isTrue);
    expect(viewModel.conflictText, 'Conflitto su accompagnamento');
    expect(viewModel.dropOffSuggestedProvider?.providerId, 'suggerito');
  });

  test('nessun booleano supportCovers parallelo nel percorso produttivo', () {
    final screen = File(
      'lib/screens/calendario_screen_stepa.dart',
    ).readAsStringSync();
    final builder = File(
      'lib/logic/calendar/builders/alice_event_logistics_builder.dart',
    ).readAsStringSync();
    expect(screen, isNot(contains('supportCovers')));
    expect(screen, isNot(contains('hasAvailableSupport')));
    expect(screen, isNot(contains('effectiveSlots')));
    expect(screen, isNot(contains('people.any')));
    expect(builder, isNot(contains('hasAvailableSupport')));
    expect(builder, isNot(contains('required bool')));
  });

  test('evento Alice previsto piu tardi resta futureAutonomous', () {
    final value = event(behavior: AliceEventBehavior.futureAutonomous);
    expect(value.behavior, AliceEventBehavior.futureAutonomous);
    expect(value.behavior.isLogistic, isFalse);
  });
}

SupportPerson _fullSupport(
  String id, {
  TimeOfDay start = const TimeOfDay(hour: 8, minute: 40),
  TimeOfDay end = const TimeOfDay(hour: 10, minute: 20),
}) => SupportPerson(id: id, name: id, enabled: true, start: start, end: end);

class _Harness {
  final DateTime day;
  final AliceEventLogisticsCoordinator coordinator;
  final DayOverrides overrides;

  const _Harness({
    required this.day,
    required this.coordinator,
    required this.overrides,
  });

  static Future<_Harness> create({
    required DateTime day,
    bool globalSandra = false,
    bool sandraMorningActive = false,
    List<SupportPerson> support = const [],
    Set<String> activeSupport = const {},
    bool blockBothAdults = false,
    bool blockMatteoOutbound = false,
  }) async {
    final settings = SettingsStore();
    settings.sandraDisponibile.value = globalSandra;
    final daily = DaySettingsStore();
    if (sandraMorningActive) {
      daily.setSandraMattinaForDay(day, true);
    }
    final network = SupportNetworkStore();
    for (final person in support) {
      network.addPerson(person);
      if (activeSupport.contains(person.id)) {
        await daily.setSupportPersonEnabledForDay(day, person.id, true);
      }
    }
    final calendarAvailability =
        CalendarLogisticsAvailabilityResolver(
          settingsStore: settings,
          daySettingsStore: daily,
          supportNetworkStore: network,
        ).resolve(
          day: day,
          mattinaStart: const TimeOfDay(hour: 8, minute: 0),
          mattinaEnd: const TimeOfDay(hour: 12, minute: 0),
          pranzoStart: const TimeOfDay(hour: 12, minute: 0),
          pranzoEnd: const TimeOfDay(hour: 14, minute: 0),
          seraStart: const TimeOfDay(hour: 16, minute: 0),
          seraEnd: const TimeOfDay(hour: 20, minute: 0),
        );
    final realEvents = RealEventStore();
    if (blockBothAdults) {
      realEvents.addEvent(
        RealEvent(
          id: 'both-busy',
          startDate: day,
          endDate: day,
          title: 'Entrambi occupati',
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 59),
          participantKeys: const ['matteo', 'chiara'],
        ),
      );
    } else if (blockMatteoOutbound) {
      realEvents.addEvent(
        RealEvent(
          id: 'matteo-busy-outbound',
          startDate: day,
          endDate: day,
          title: 'Matteo occupato',
          startTime: const TimeOfDay(hour: 8, minute: 30),
          endTime: const TimeOfDay(hour: 9, minute: 1),
          participantKeys: const ['matteo'],
        ),
      );
    }
    final providerAvailability = AliceLogisticProviderAvailabilityResolver(
      adultResolver: AdultLogisticsAvailabilityResolver(
        turnEngine: TurnEngine(),
        diseasePeriodStore: DiseasePeriodStore(),
        realEventStore: realEvents,
      ),
      logisticsAvailability: calendarAvailability,
    );
    return _Harness(
      day: day,
      coordinator: AliceEventLogisticsCoordinator(
        availabilityResolver: providerAvailability,
      ),
      overrides: blockBothAdults || blockMatteoOutbound
          ? DayOverrides.empty(day)
          : DayOverrides(
              day: day,
              matteo: PersonDayOverride(status: OverrideStatus.ferie),
              chiara: PersonDayOverride(status: OverrideStatus.ferie),
            ),
    );
  }

  AliceEventLogisticsResolution resolve(AliceSpecialEvent event) =>
      coordinator.resolve(day: day, event: event, overrides: overrides);
}
