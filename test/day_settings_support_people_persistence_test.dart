import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/alice_companion_store.dart';
import 'package:frododesk/logic/alice_event_store.dart';
import 'package:frododesk/logic/alice_presence_engine.dart';
import 'package:frododesk/logic/alice_special_event_store.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/logic/real_event_store.dart';
import 'package:frododesk/logic/school_store.dart';
import 'package:frododesk/logic/summer_camp_schedule_store.dart';
import 'package:frododesk/logic/summer_camp_special_event_store.dart';
import 'package:frododesk/logic/support_network_store.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _day = DateTime(2026, 8, 11);
final _nextDay = DateTime(2026, 8, 12);

Future<DaySettingsStore> _reload() async {
  final store = DaySettingsStore();
  await store.load();
  return store;
}

AlicePresenceEngine _engine(
  SupportNetworkStore supportStore,
  DaySettingsStore daySettingsStore,
) {
  return AlicePresenceEngine(
    aliceEventStore: AliceEventStore(),
    aliceSpecialEventStore: AliceSpecialEventStore(),
    realEventStore: RealEventStore(),
    schoolStore: SchoolStore(),
    summerCampScheduleStore: SummerCampScheduleStore(),
    summerCampSpecialEventStore: SummerCampSpecialEventStore(),
    aliceCompanionStore: AliceCompanionStore(),
    supportNetworkStore: supportStore,
    daySettingsStore: daySettingsStore,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('attivazione sopravvive al reload', () async {
    final store = DaySettingsStore();
    await store.setSupportPersonEnabledForDay(_day, 'personA', true);

    final reloaded = await _reload();

    expect(reloaded.isSupportPersonEnabledForDay(_day, 'personA'), isTrue);
  });

  test('disattivazione sopravvive a un secondo reload', () async {
    final first = DaySettingsStore();
    await first.setSupportPersonEnabledForDay(_day, 'personA', true);

    final second = await _reload();
    await second.setSupportPersonEnabledForDay(_day, 'personA', false);

    final third = await _reload();
    expect(third.isSupportPersonEnabledForDay(_day, 'personA'), isFalse);
  });

  test('giorni differenti restano indipendenti', () async {
    final store = DaySettingsStore();
    await store.setSupportPersonEnabledForDay(_day, 'personA', true);
    await store.setSupportPersonEnabledForDay(_nextDay, 'personB', true);

    final reloaded = await _reload();

    expect(reloaded.isSupportPersonEnabledForDay(_day, 'personA'), isTrue);
    expect(reloaded.isSupportPersonEnabledForDay(_day, 'personB'), isFalse);
    expect(reloaded.isSupportPersonEnabledForDay(_nextDay, 'personA'), isFalse);
    expect(reloaded.isSupportPersonEnabledForDay(_nextDay, 'personB'), isTrue);
  });

  test('più ID nello stesso giorno vengono conservati', () async {
    final store = DaySettingsStore();
    await store.setSupportPersonEnabledForDay(_day, 'personA', true);
    await store.setSupportPersonEnabledForDay(_day, 'personB', true);

    final reloaded = await _reload();

    expect(reloaded.supportPeopleEnabledIdsForDay(_day), {
      'personA',
      'personB',
    });
  });

  test(
    'disabilitare un ID conserva gli altri ID dello stesso giorno',
    () async {
      final store = DaySettingsStore();
      await store.setSupportPersonEnabledForDay(_day, 'personA', true);
      await store.setSupportPersonEnabledForDay(_day, 'personB', true);
      await store.setSupportPersonEnabledForDay(_day, 'personA', false);

      final reloaded = await _reload();

      expect(reloaded.supportPeopleEnabledIdsForDay(_day), {'personB'});
    },
  );

  test(
    'JSON precedente senza supportPeopleEnabledForDay resta compatibile',
    () async {
      SharedPreferences.setMockInitialValues({
        'frododesk_day_settings_store_v1': jsonEncode({
          'sandraDisponibile': {'2026-08-11': true},
        }),
      });

      final store = await _reload();

      expect(store.sandraForDay(_day), isTrue);
      expect(store.supportPeopleEnabledIdsForDay(_day), isEmpty);
    },
  );

  test('JSON mantiene data yyyy-MM-dd e lista di ID esistenti', () async {
    final store = DaySettingsStore();
    await store.setSupportPersonEnabledForDay(
      DateTime(2026, 8, 11, 21, 45),
      'personA',
      true,
    );

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('frododesk_day_settings_store_v1');
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final support = json['supportPeopleEnabledForDay'] as Map;

    expect(support.keys, ['2026-08-11']);
    expect(support['2026-08-11'], ['personA']);
  });

  test('due mutazioni ravvicinate rispettano ordine FIFO', () async {
    final store = DaySettingsStore();

    final enable = store.setSupportPersonEnabledForDay(_day, 'personA', true);
    final disable = store.setSupportPersonEnabledForDay(_day, 'personA', false);
    await Future.wait([enable, disable]);

    final reloaded = await _reload();
    expect(reloaded.isSupportPersonEnabledForDay(_day, 'personA'), isFalse);
  });

  test(
    'salvataggi ravvicinati di categorie diverse non perdono il supporto',
    () async {
      final store = DaySettingsStore();

      final supportWrite = store.setSupportPersonEnabledForDay(
        _day,
        'personA',
        true,
      );
      store.setSandraForDay(_day, true);
      final queueBarrier = store.setSupportPersonEnabledForDay(
        _day,
        'personA',
        true,
      );
      await Future.wait([supportWrite, queueBarrier]);

      final reloaded = await _reload();
      expect(reloaded.isSupportPersonEnabledForDay(_day, 'personA'), isTrue);
      expect(reloaded.sandraForDay(_day), isTrue);
    },
  );

  test(
    'AlicePresenceEngine usa attivazione ricaricata nel giorno corretto',
    () async {
      final settings = DaySettingsStore();
      await settings.setSupportPersonEnabledForDay(_day, 'personA', true);
      final reloadedSettings = await _reload();

      final supportStore = SupportNetworkStore();
      supportStore.addPerson(
        const SupportPerson(
          id: 'personA',
          name: 'Supporto',
          enabled: true,
          start: TimeOfDay(hour: 5, minute: 0),
          end: TimeOfDay(hour: 6, minute: 35),
        ),
      );
      final engine = _engine(supportStore, reloadedSettings);

      expect(
        engine.isCoveredBySupportNetwork(
          day: _day,
          start: DateTime(2026, 8, 11, 5, 15),
          end: DateTime(2026, 8, 11, 6),
        ),
        isTrue,
      );
      expect(
        engine.isCoveredBySupportNetwork(
          day: _nextDay,
          start: DateTime(2026, 8, 12, 5, 15),
          end: DateTime(2026, 8, 12, 6),
        ),
        isFalse,
      );
    },
  );
}
