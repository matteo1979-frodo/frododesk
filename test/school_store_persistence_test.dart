import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/school_store.dart';
import 'package:frododesk/models/school_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round-trip persiste e ricarica il periodo cross-year', () async {
    final store = SchoolStore();
    await store.addPeriod(_schoolYear());

    final reloaded = SchoolStore();
    await reloaded.load();

    expect(reloaded.periods, hasLength(1));
    expect(reloaded.periods.single.id, 'school-2026-2027');
    expect(reloaded.periods.single.startDate, DateTime(2026, 9, 15));
    expect(reloaded.periods.single.endDate, DateTime(2027, 6, 10));
  });

  test('confini inclusivi del periodo 15/09/2026-10/06/2027', () async {
    final store = SchoolStore();
    await store.addPeriod(_schoolYear());

    expect(store.activePeriodForDay(DateTime(2026, 7, 31)), isNull);
    expect(store.activePeriodForDay(DateTime(2026, 9, 15)), isNotNull);
    expect(store.activePeriodForDay(DateTime(2027, 6, 10)), isNotNull);
    expect(store.activePeriodForDay(DateTime(2027, 6, 11)), isNull);
  });

  test('due add ravvicinati vengono persistiti in ordine FIFO', () async {
    final memory = <String, String>{};
    final starts = <String>[];
    final firstGate = Completer<void>();
    var writes = 0;
    final store = _memoryStore(
      memory,
      save: (key, value) async {
        writes++;
        starts.add(value);
        if (writes == 1) await firstGate.future;
        memory[key] = value;
      },
    );

    final first = store.addPeriod(_period('a'));
    final second = store.addPeriod(_period('b'));
    await Future<void>.delayed(Duration.zero);
    expect(starts, hasLength(1));

    firstGate.complete();
    await Future.wait([first, second]);
    final reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.periods.map((period) => period.id), ['a', 'b']);
  });

  test('add seguito da update conserva la versione finale', () async {
    final memory = <String, String>{};
    final store = _memoryStore(memory);
    await Future.wait([
      store.addPeriod(_period('a')),
      store.updatePeriod(_period('a').copyWith(name: 'Aggiornato')),
    ]);

    final reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.periods.single.name, 'Aggiornato');
  });

  test('add seguito da remove non fa riapparire il periodo', () async {
    final memory = <String, String>{};
    final store = _memoryStore(memory);
    await Future.wait([store.addPeriod(_period('a')), store.removePeriod('a')]);

    final reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.periods, isEmpty);
  });

  test('setPeriods seguito da clear termina con store vuoto', () async {
    final memory = <String, String>{};
    final store = _memoryStore(memory);
    await Future.wait([
      store.setPeriods([_period('a'), _period('b')]),
      store.clear(),
    ]);

    final reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.periods, isEmpty);
  });

  test('JSON precedente continua a caricarsi senza migrazione', () async {
    final legacy = jsonEncode([_legacyJson(_schoolYear())]);
    final store = SchoolStore(loadString: (_) async => legacy);

    await store.load();

    expect(store.periods.single.startDate, DateTime(2026, 9, 15));
    expect(store.periods.single.endDate, DateTime(2027, 6, 10));
    expect(store.hasSchoolOn(DateTime(2026, 9, 15)), isTrue);
  });

  test('errore di salvataggio non blocca quelli successivi', () async {
    final memory = <String, String>{};
    var attempt = 0;
    final store = _memoryStore(
      memory,
      save: (key, value) async {
        attempt++;
        if (attempt == 1) throw StateError('errore simulato');
        memory[key] = value;
      },
    );

    await expectLater(store.addPeriod(_period('a')), throwsStateError);
    await store.addPeriod(_period('b'));

    final reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.periods.map((period) => period.id), ['a', 'b']);
  });
}

SchoolStore _memoryStore(
  Map<String, String> memory, {
  SchoolStoreSaveString? save,
}) {
  return SchoolStore(
    loadString: (key) async => memory[key],
    saveString: save ?? (key, value) async => memory[key] = value,
  );
}

SchoolPeriod _schoolYear() => SchoolPeriod(
  id: 'school-2026-2027',
  name: 'Anno scolastico 2026/2027',
  startDate: DateTime(2026, 9, 15),
  endDate: DateTime(2027, 6, 10),
  weekConfig: _weekConfig,
);

SchoolPeriod _period(String id) => SchoolPeriod(
  id: id,
  name: 'Periodo $id',
  startDate: DateTime(2026, 9, 15),
  endDate: DateTime(2027, 6, 10),
  weekConfig: _weekConfig,
);

const _schoolDay = SchoolDayConfig(
  enabled: true,
  entryMinutes: 8 * 60 + 25,
  exitRealMinutes: 16 * 60 + 25,
);

const _weekConfig = SchoolWeekConfig(
  monday: _schoolDay,
  tuesday: _schoolDay,
  wednesday: _schoolDay,
  thursday: _schoolDay,
  friday: _schoolDay,
  saturday: SchoolDayConfig.off(),
);

Map<String, Object> _legacyJson(SchoolPeriod period) => {
  'id': period.id,
  'name': period.name,
  'startYear': period.startDate.year,
  'startMonth': period.startDate.month,
  'startDay': period.startDate.day,
  'endYear': period.endDate.year,
  'endMonth': period.endDate.month,
  'endDay': period.endDate.day,
  'weekConfig': {
    'monday': _dayJson(_schoolDay),
    'tuesday': _dayJson(_schoolDay),
    'wednesday': _dayJson(_schoolDay),
    'thursday': _dayJson(_schoolDay),
    'friday': _dayJson(_schoolDay),
    'saturday': _dayJson(const SchoolDayConfig.off()),
  },
};

Map<String, Object> _dayJson(SchoolDayConfig day) => {
  'enabled': day.enabled,
  'entryHour': day.entryMinutes ~/ 60,
  'entryMinute': day.entryMinutes % 60,
  'exitHour': day.exitRealMinutes ~/ 60,
  'exitMinute': day.exitRealMinutes % 60,
};
