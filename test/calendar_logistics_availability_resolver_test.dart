import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/calendar_logistics_availability_resolver.dart';
import 'package:frododesk/logic/calendar/builders/alice_event_logistics_builder.dart';
import 'package:frododesk/logic/alice_events/alice_event_engine.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/settings_store.dart';
import 'package:frododesk/logic/support_network_store.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:frododesk/models/alice_special_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = DateTime(2026, 8, 11);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<CalendarLogisticsAvailabilityResult> resolve({
    required bool globalSandra,
    bool? mattina,
    bool? pranzo,
    bool? sera,
    List<SupportPerson> people = const [],
    Set<String> activeSupport = const {},
  }) async {
    final settings = SettingsStore();
    settings.sandraDisponibile.value = globalSandra;
    final daily = DaySettingsStore();
    if (mattina != null) daily.setSandraMattinaForDay(day, mattina);
    if (pranzo != null) daily.setSandraPranzoForDay(day, pranzo);
    if (sera != null) daily.setSandraSeraForDay(day, sera);
    final support = SupportNetworkStore();
    for (final person in people) {
      support.addPerson(person);
      if (activeSupport.contains(person.id)) {
        await daily.setSupportPersonEnabledForDay(day, person.id, true);
      }
    }
    return CalendarLogisticsAvailabilityResolver(
      settingsStore: settings,
      daySettingsStore: daily,
      supportNetworkStore: support,
    ).resolve(
      day: day,
      mattinaStart: const TimeOfDay(hour: 7, minute: 30),
      mattinaEnd: const TimeOfDay(hour: 8, minute: 30),
      pranzoStart: const TimeOfDay(hour: 13, minute: 0),
      pranzoEnd: const TimeOfDay(hour: 14, minute: 0),
      seraStart: const TimeOfDay(hour: 16, minute: 0),
      seraEnd: const TimeOfDay(hour: 18, minute: 0),
    );
  }

  test(
    'Sandra richiede abilitazione globale e attivazione esplicita per fascia',
    () async {
      expect(
        (await resolve(
          globalSandra: true,
        )).sandraWindows.map((window) => window.available),
        [false, false, false],
      );
      expect(
        (await resolve(
          globalSandra: true,
          mattina: true,
        )).sandraWindows.map((window) => window.available),
        [true, false, false],
      );
      expect(
        (await resolve(
          globalSandra: true,
          pranzo: true,
        )).sandraWindows.map((window) => window.available),
        [false, true, false],
      );
      expect(
        (await resolve(
          globalSandra: true,
          sera: true,
        )).sandraWindows.map((window) => window.available),
        [false, false, true],
      );
      expect(
        (await resolve(
          globalSandra: true,
          mattina: true,
          pranzo: true,
          sera: true,
        )).sandraWindows.map((window) => window.available),
        [true, true, true],
      );
      expect(
        (await resolve(
          globalSandra: false,
          mattina: true,
        )).sandraWindows.map((window) => window.available),
        [false, false, false],
      );
      expect(
        (await resolve(
          globalSandra: true,
          mattina: false,
        )).sandraWindows.map((window) => window.available),
        [false, false, false],
      );
    },
  );

  test(
    'le attivazioni Sandra non vengono ereditate dal giorno successivo',
    () async {
      final settings = SettingsStore();
      settings.sandraDisponibile.value = true;
      final daily = DaySettingsStore();
      daily.setSandraMattinaForDay(day, true);
      final resolver = CalendarLogisticsAvailabilityResolver(
        settingsStore: settings,
        daySettingsStore: daily,
        supportNetworkStore: SupportNetworkStore(),
      );
      CalendarLogisticsAvailabilityResult forDay(DateTime value) =>
          resolver.resolve(
            day: value,
            mattinaStart: const TimeOfDay(hour: 7, minute: 30),
            mattinaEnd: const TimeOfDay(hour: 8, minute: 30),
            pranzoStart: const TimeOfDay(hour: 13, minute: 0),
            pranzoEnd: const TimeOfDay(hour: 14, minute: 0),
            seraStart: const TimeOfDay(hour: 16, minute: 0),
            seraEnd: const TimeOfDay(hour: 18, minute: 0),
          );
      expect(forDay(day).sandraWindows[0].available, isTrue);
      expect(
        forDay(
          day.add(const Duration(days: 1)),
        ).sandraWindows.map((window) => window.available),
        [false, false, false],
      );
    },
  );

  test(
    'la stessa decisione Sandra serve coverage, gap ed entrambe le logistiche',
    () async {
      final availability = await resolve(
        globalSandra: true,
        mattina: true,
        pranzo: false,
      );
      expect(
        availability.sandraAvailableFor(SandraAvailabilityBand.mattina),
        isTrue,
      ); // coverage
      expect(
        availability.sandraCovers(
          const TimeOfDay(hour: 7, minute: 40),
          const TimeOfDay(hour: 8, minute: 0),
        ),
        isTrue,
      ); // gap / evento Alice / ingresso centro estivo
      expect(
        availability.sandraCovers(
          const TimeOfDay(hour: 13, minute: 10),
          const TimeOfDay(hour: 13, minute: 30),
        ),
        isFalse,
      );
    },
  );

  test(
    'supporto richiede enabled, attivazione giornaliera e slot completo',
    () async {
      const full = SupportPerson(
        id: 'nonna-id',
        name: 'Nonna',
        enabled: true,
        start: TimeOfDay(hour: 7, minute: 30),
        end: TimeOfDay(hour: 8, minute: 30),
      );
      expect(
        (await resolve(
          globalSandra: false,
          people: const [full],
        )).supportCovers(
          const TimeOfDay(hour: 7, minute: 40),
          const TimeOfDay(hour: 8, minute: 0),
        ),
        isFalse,
      );
      final active = await resolve(
        globalSandra: false,
        people: const [full],
        activeSupport: const {'nonna-id'},
      );
      expect(
        active
            .supportForWindow(
              const TimeOfDay(hour: 7, minute: 40),
              const TimeOfDay(hour: 8, minute: 0),
            )
            .single
            .providerId,
        'nonna-id',
      );
      expect(
        active.supportCovers(
          const TimeOfDay(hour: 7, minute: 20),
          const TimeOfDay(hour: 8, minute: 0),
        ),
        isFalse,
      );
    },
  );

  test('slot separati non vengono sommati', () async {
    const split = SupportPerson(
      id: 'split',
      name: 'Split',
      enabled: true,
      start: TimeOfDay(hour: 7, minute: 30),
      end: TimeOfDay(hour: 8, minute: 30),
      slots: [
        SupportTimeSlot(
          start: TimeOfDay(hour: 7, minute: 30),
          end: TimeOfDay(hour: 8, minute: 0),
        ),
        SupportTimeSlot(
          start: TimeOfDay(hour: 8, minute: 0),
          end: TimeOfDay(hour: 8, minute: 30),
        ),
      ],
    );
    final value = await resolve(
      globalSandra: false,
      people: const [split],
      activeSupport: const {'split'},
    );
    expect(
      value.supportCovers(
        const TimeOfDay(hour: 7, minute: 40),
        const TimeOfDay(hour: 8, minute: 20),
      ),
      isFalse,
    );
  });

  test('ingresso e uscita centro estivo sono risolti separatamente', () async {
    const person = SupportPerson(
      id: 'drop-only',
      name: 'Drop only',
      enabled: true,
      start: TimeOfDay(hour: 7, minute: 30),
      end: TimeOfDay(hour: 8, minute: 0),
    );
    final value = await resolve(
      globalSandra: false,
      people: const [person],
      activeSupport: const {'drop-only'},
    );
    expect(
      value
          .supportForWindow(
            const TimeOfDay(hour: 7, minute: 40),
            const TimeOfDay(hour: 8, minute: 0),
          )
          .single
          .providerId,
      'drop-only',
    );
    expect(
      value.supportForWindow(
        const TimeOfDay(hour: 16, minute: 0),
        const TimeOfDay(hour: 16, minute: 20),
      ),
      isEmpty,
    );
  });

  test(
    'evento Alice usa supporto attivo con slot completo, non solo enabled',
    () async {
      const person = SupportPerson(
        id: 'event-support',
        name: 'Supporto evento',
        enabled: true,
        start: TimeOfDay(hour: 9, minute: 0),
        end: TimeOfDay(hour: 10, minute: 0),
      );
      final event = AliceSpecialEvent(
        id: 'event',
        label: 'Evento',
        category: AliceSpecialEventCategory.sport,
        dropOffAdultKey: 'matteo',
        pickUpAdultKey: 'matteo',
        date: day,
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 0),
      );
      AliceEventLogisticsResult build(
        CalendarLogisticsAvailabilityResult availability,
      ) => const AliceEventLogisticsBuilder().build(
        day: day,
        event: event,
        aliceEventEngine: const AliceEventEngine(),
        isMatteoBusy: (_, _) => true,
        isChiaraBusy: (_, _) => false,
        hasAvailableSupport: (start, end) => availability.supportCovers(
          TimeOfDay.fromDateTime(start),
          TimeOfDay.fromDateTime(end),
        ),
      );

      expect(
        build(
          await resolve(globalSandra: false, people: const [person]),
        ).canSuggestSupport,
        isFalse,
      );
      expect(
        build(
          await resolve(
            globalSandra: false,
            people: const [person],
            activeSupport: const {'event-support'},
          ),
        ).canSuggestSupport,
        isTrue,
      );
    },
  );

  test(
    'CalendarioScreen non decide disponibilita con iterazioni o null false',
    () {
      final source = File(
        'lib/screens/calendario_screen_stepa.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('people.any')));
      expect(source, isNot(contains('effectiveSlots')));
      expect(source, isNot(contains('_effSandraMattina')));
      expect(source, isNot(contains('_effSandraPranzo')));
      expect(source, isNot(contains('_effSandraSera')));
      expect(source, isNot(contains('_coverageSandraWindows')));
      expect(
        source,
        contains('daySettingsStore.sandraMattinaForDay(_selectedDay) == true'),
      );
      expect(
        RegExp(
          r'sandra(?:Mattina|Pranzo|Sera)ForDay\([^)]*\)\s*\?\?\s*false',
        ).hasMatch(source),
        isFalse,
      );
    },
  );
}
