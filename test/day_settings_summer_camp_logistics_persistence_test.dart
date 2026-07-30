import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/models/alice_summer_camp_logistics.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'frododesk_day_settings_store_v1';
final _day = DateTime(2026, 8, 11, 18, 30);
final _nextDay = DateTime(2026, 8, 12);
final _matteo = AliceLogisticProviderRef.parent(AliceLogisticParent.matteo);
final _chiara = AliceLogisticProviderRef.parent(AliceLogisticParent.chiara);
const _sandra = AliceLogisticProviderRef.sandra;

Future<DaySettingsStore> _reload() async {
  final store = DaySettingsStore();
  await store.load();
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('carica JSON precedente senza assegnazioni logistiche', () async {
    SharedPreferences.setMockInitialValues({
      _storageKey: jsonEncode({
        'sandraDisponibile': {'2026-08-11': true},
        'schoolInCover': {'2026-08-11': 'matteo'},
        'schoolOutCover': {'2026-08-11': 'chiara'},
        'supportPeopleEnabledForDay': {
          '2026-08-11': ['support-a'],
        },
      }),
    });

    final store = await _reload();

    expect(store.summerCampDropOffProviderForDay(_day), isNull);
    expect(store.summerCampPickUpProviderForDay(_day), isNull);
    expect(store.sandraForDay(_day), isTrue);
    expect(store.schoolInCoverForDay(_day), SchoolCoverChoice.matteo);
    expect(store.schoolOutCoverForDay(_day), SchoolCoverChoice.chiara);
    expect(store.supportPeopleEnabledIdsForDay(_day), {'support-a'});
  });

  test('round-trip Matteo al drop-off e Chiara al pick-up', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _matteo);
    await store.setSummerCampPickUpProviderForDay(_day, _chiara);

    final reloaded = await _reload();
    expect(reloaded.summerCampDropOffProviderForDay(_day), _matteo);
    expect(reloaded.summerCampPickUpProviderForDay(_day), _chiara);
  });

  test('round-trip Sandra', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _sandra);

    expect((await _reload()).summerCampDropOffProviderForDay(_day), _sandra);
  });

  test('round-trip SupportPerson con ID concreto', () async {
    final provider = AliceLogisticProviderRef.supportPerson('support-a');
    final store = DaySettingsStore();
    await store.setSummerCampPickUpProviderForDay(_day, provider);

    expect((await _reload()).summerCampPickUpProviderForDay(_day), provider);
  });

  test('support-a e support-b restano distinti', () async {
    final supportA = AliceLogisticProviderRef.supportPerson('support-a');
    final supportB = AliceLogisticProviderRef.supportPerson('support-b');
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, supportA);
    await store.setSummerCampPickUpProviderForDay(_day, supportB);

    final reloaded = await _reload();
    expect(reloaded.summerCampDropOffProviderForDay(_day), supportA);
    expect(reloaded.summerCampPickUpProviderForDay(_day), supportB);
    expect(supportA, isNot(supportB));
  });

  test('drop-off e pick-up sono indipendenti nello stesso giorno', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _matteo);
    expect(store.summerCampPickUpProviderForDay(_day), isNull);
    await store.setSummerCampPickUpProviderForDay(_day, _chiara);
    expect(store.summerCampDropOffProviderForDay(_day), _matteo);
  });

  test('giorni differenti sono indipendenti', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _matteo);
    await store.setSummerCampDropOffProviderForDay(_nextDay, _chiara);

    final reloaded = await _reload();
    expect(reloaded.summerCampDropOffProviderForDay(_day), _matteo);
    expect(reloaded.summerCampDropOffProviderForDay(_nextDay), _chiara);
  });

  test('sostituisce il provider', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _matteo);
    await store.setSummerCampDropOffProviderForDay(_day, _sandra);

    expect((await _reload()).summerCampDropOffProviderForDay(_day), _sandra);
  });

  test('null cancella solo il drop-off', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _matteo);
    await store.setSummerCampPickUpProviderForDay(_day, _chiara);
    await store.setSummerCampDropOffProviderForDay(_day, null);

    final reloaded = await _reload();
    expect(reloaded.summerCampDropOffProviderForDay(_day), isNull);
    expect(reloaded.summerCampPickUpProviderForDay(_day), _chiara);
  });

  test('null cancella solo il pick-up', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _matteo);
    await store.setSummerCampPickUpProviderForDay(_day, _chiara);
    await store.setSummerCampPickUpProviderForDay(_day, null);

    final reloaded = await _reload();
    expect(reloaded.summerCampDropOffProviderForDay(_day), _matteo);
    expect(reloaded.summerCampPickUpProviderForDay(_day), isNull);
  });

  test('record non validi vengono ignorati senza perdere il resto', () async {
    SharedPreferences.setMockInitialValues({
      _storageKey: jsonEncode({
        'sandraDisponibile': {'2026-08-11': true},
        'summerCampDropOffProvider': {
          '2026-08-11': {'kind': 'unknown', 'providerId': 'matteo'},
          '2026-08-12': {'kind': 'parent', 'providerId': 'arbitrary'},
        },
        'summerCampPickUpProvider': {
          '2026-08-11': {'kind': 'supportPerson', 'providerId': '  '},
          '2026-08-12': 'corrotto',
        },
      }),
    });

    final store = await _reload();
    expect(store.sandraForDay(_day), isTrue);
    expect(store.summerCampDropOffProviderForDay(_day), isNull);
    expect(store.summerCampDropOffProviderForDay(_nextDay), isNull);
    expect(store.summerCampPickUpProviderForDay(_day), isNull);
    expect(store.summerCampPickUpProviderForDay(_nextDay), isNull);
  });

  test('JSON usa kind e providerId stabili', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _matteo);
    await store.setSummerCampPickUpProviderForDay(
      _day,
      AliceLogisticProviderRef.supportPerson('support-a'),
    );

    final prefs = await SharedPreferences.getInstance();
    final json =
        jsonDecode(prefs.getString(_storageKey)!) as Map<String, dynamic>;
    expect(json['summerCampDropOffProvider'], {
      '2026-08-11': {'kind': 'parent', 'providerId': 'matteo'},
    });
    expect(json['summerCampPickUpProvider'], {
      '2026-08-11': {'kind': 'supportPerson', 'providerId': 'support-a'},
    });
  });

  test('salvataggi ravvicinati rispettano la coda FIFO', () async {
    final store = DaySettingsStore();
    final dropOff = store.setSummerCampDropOffProviderForDay(_day, _matteo);
    final pickUp = store.setSummerCampPickUpProviderForDay(_day, _chiara);
    await Future.wait([dropOff, pickUp]);

    final reloaded = await _reload();
    expect(reloaded.summerCampDropOffProviderForDay(_day), _matteo);
    expect(reloaded.summerCampPickUpProviderForDay(_day), _chiara);
  });

  test(
    'clearDay elimina entrambe le assegnazioni e gli altri dati del giorno',
    () async {
      final store = DaySettingsStore();
      await store.setSummerCampDropOffProviderForDay(_day, _matteo);
      await store.setSummerCampPickUpProviderForDay(_day, _chiara);
      store.setSchoolInCoverForDay(_day, SchoolCoverChoice.sandra);
      await store.setSupportPersonEnabledForDay(_day, 'support-a', true);
      await store.clearDay(_day);

      final reloaded = await _reload();
      expect(reloaded.summerCampDropOffProviderForDay(_day), isNull);
      expect(reloaded.summerCampPickUpProviderForDay(_day), isNull);
      expect(reloaded.schoolInCoverForDay(_day), SchoolCoverChoice.none);
      expect(reloaded.supportPeopleEnabledIdsForDay(_day), isEmpty);
    },
  );

  test('clearAll elimina entrambe le mappe', () async {
    final store = DaySettingsStore();
    await store.setSummerCampDropOffProviderForDay(_day, _matteo);
    await store.setSummerCampPickUpProviderForDay(_nextDay, _chiara);
    await store.clearAll();

    final reloaded = await _reload();
    expect(reloaded.summerCampDropOffProviderForDay(_day), isNull);
    expect(reloaded.summerCampPickUpProviderForDay(_nextDay), isNull);
  });

  test('assegnazioni non alterano scuola e rete di supporto', () async {
    final store = DaySettingsStore();
    store.setSchoolInCoverForDay(_day, SchoolCoverChoice.matteo);
    store.setSchoolOutCoverForDay(_day, SchoolCoverChoice.chiara);
    await store.setSupportPersonEnabledForDay(_day, 'support-a', true);
    await store.setSummerCampDropOffProviderForDay(_day, _sandra);
    await store.setSummerCampPickUpProviderForDay(_day, _matteo);

    final reloaded = await _reload();
    expect(reloaded.schoolInCoverForDay(_day), SchoolCoverChoice.matteo);
    expect(reloaded.schoolOutCoverForDay(_day), SchoolCoverChoice.chiara);
    expect(reloaded.supportPeopleEnabledIdsForDay(_day), {'support-a'});
  });
}
