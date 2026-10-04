import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/logic/turn_engine.dart';
import 'package:frododesk/logic/turn_override_store.dart';
import 'package:frododesk/models/adult_constraint_interval.dart';
import 'package:frododesk/models/turn_override.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _monday = DateTime(2026, 10, 5);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'round-trip di tutti i turni, entrambe le persone e i due tipi',
    () async {
      final memory = <String, String>{};
      final store = _memoryStore(memory);
      final shifts = TurnOverrideShift.values;

      for (var index = 0; index < shifts.length; index++) {
        await store.setDailyOverride(
          person: index.isEven ? TurnPersonId.matteo : TurnPersonId.chiara,
          day: _monday.add(Duration(days: index)),
          newShift: shifts[index],
        );
        await store.setPeriodOverride(
          person: index.isEven ? TurnPersonId.chiara : TurnPersonId.matteo,
          startDay: _monday.add(Duration(days: 10 + index * 2)),
          endDay: _monday.add(Duration(days: 11 + index * 2)),
          newShift: shifts[index],
        );
      }

      final reloaded = _memoryStore(memory);
      await reloaded.load();

      expect(reloaded.items, hasLength(shifts.length * 2));
      expect(
        reloaded.items.map((item) => item.shift).toSet(),
        TurnOverrideShift.values.toSet(),
      );
      expect(reloaded.items.map((item) => item.person).toSet(), {
        TurnPersonId.matteo,
        TurnPersonId.chiara,
      });
      expect(reloaded.items.where((item) => item.isDaily), hasLength(5));
      expect(reloaded.items.where((item) => item.isPeriod), hasLength(5));
    },
  );

  test(
    'formato JSON usa stringhe stabili, date normalizzate e tutti i campi',
    () async {
      final memory = <String, String>{};
      final store = _memoryStore(memory);

      await store.add(
        TurnOverride(
          type: TurnOverrideType.rotationProfileChange,
          person: TurnPersonId.chiara,
          startDate: DateTime(2026, 10, 5, 18, 30),
          shift: TurnOverrideShift.notte,
          rotationIndex: 2,
        ),
      );

      final json = jsonDecode(memory.values.single) as List<dynamic>;
      expect(json.single, {
        'type': 'rotationProfileChange',
        'person': 'chiara',
        'startDate': '2026-10-05',
        'endDate': null,
        'shift': 'notte',
        'rotationIndex': 2,
      });

      final reloaded = _memoryStore(memory);
      await reloaded.load();
      expect(reloaded.items.single.startDate, DateTime(2026, 10, 5));
      expect(reloaded.items.single.rotationIndex, 2);
    },
  );

  test('ordine e precedenza restano invariati dopo reload', () async {
    final memory = <String, String>{};
    final store = _memoryStore(memory);
    await store.add(
      TurnOverride(
        type: TurnOverrideType.periodShiftChange,
        person: TurnPersonId.matteo,
        startDate: _monday,
        endDate: _monday.add(const Duration(days: 4)),
        shift: TurnOverrideShift.mattina,
      ),
    );
    await store.add(
      TurnOverride(
        type: TurnOverrideType.periodShiftChange,
        person: TurnPersonId.matteo,
        startDate: _monday.add(const Duration(days: 1)),
        endDate: _monday.add(const Duration(days: 3)),
        shift: TurnOverrideShift.giornata,
      ),
    );

    final reloaded = _memoryStore(memory);
    await reloaded.load();

    expect(reloaded.items.map((item) => item.shift), [
      TurnOverrideShift.mattina,
      TurnOverrideShift.giornata,
    ]);
    expect(
      reloaded
          .periodOverrideFor(
            person: TurnPersonId.matteo,
            day: _monday.add(const Duration(days: 2)),
          )
          ?.shift,
      TurnOverrideShift.giornata,
    );
  });

  test('giornaliero OFF continua a prevalere sul periodo Giornata', () async {
    final memory = <String, String>{};
    final store = _memoryStore(memory);
    await store.setPeriodOverride(
      person: TurnPersonId.matteo,
      startDay: _monday,
      endDay: _monday.add(const Duration(days: 4)),
      newShift: TurnOverrideShift.giornata,
    );
    await store.setDailyOverride(
      person: TurnPersonId.matteo,
      day: _monday.add(const Duration(days: 2)),
      newShift: TurnOverrideShift.off,
    );

    final reloaded = _memoryStore(memory);
    await reloaded.load();
    final engine = TurnEngine(turnOverrideStore: reloaded);

    expect(
      engine.turnPlanForPersonDay(person: TurnPerson.matteo, day: _monday).type,
      TurnType.giornata,
    );
    expect(
      engine
          .turnPlanForPersonDay(
            person: TurnPerson.matteo,
            day: _monday.add(const Duration(days: 2)),
          )
          .type,
      TurnType.off,
    );
  });

  test('sostituisce giornaliero e periodo con gli stessi estremi', () async {
    final memory = <String, String>{};
    final store = _memoryStore(memory);
    await store.setDailyOverride(
      person: TurnPersonId.chiara,
      day: _monday,
      newShift: TurnOverrideShift.mattina,
    );
    await store.setDailyOverride(
      person: TurnPersonId.chiara,
      day: _monday,
      newShift: TurnOverrideShift.notte,
    );
    await store.setPeriodOverride(
      person: TurnPersonId.matteo,
      startDay: _monday,
      endDay: _monday.add(const Duration(days: 4)),
      newShift: TurnOverrideShift.pomeriggio,
    );
    await store.setPeriodOverride(
      person: TurnPersonId.matteo,
      startDay: _monday,
      endDay: _monday.add(const Duration(days: 4)),
      newShift: TurnOverrideShift.giornata,
    );

    final reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.items, hasLength(2));
    expect(
      reloaded
          .dailyOverrideFor(person: TurnPersonId.chiara, day: _monday)
          ?.shift,
      TurnOverrideShift.notte,
    );
    expect(
      reloaded
          .periodOverrideFor(person: TurnPersonId.matteo, day: _monday)
          ?.shift,
      TurnOverrideShift.giornata,
    );
  });

  test('rimozione e clearAll restano persistenti', () async {
    final memory = <String, String>{};
    final store = _memoryStore(memory);
    await store.setDailyOverride(
      person: TurnPersonId.matteo,
      day: _monday,
      newShift: TurnOverrideShift.giornata,
    );
    await store.remove(store.items.single);

    var reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.items, isEmpty);

    await store.setDailyOverride(
      person: TurnPersonId.chiara,
      day: _monday,
      newShift: TurnOverrideShift.off,
    );
    await store.clearAll();
    reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.items, isEmpty);
  });

  test('chiave assente, stringa vuota e JSON corrotto sono sicuri', () async {
    for (final raw in <String?>[null, '', '{non-json', '{"not":"a-list"}']) {
      final store = TurnOverrideStore(loadString: (_) async => raw);
      await store.load();
      expect(store.items, isEmpty);
    }
  });

  test('lista mista conserva solo record validi', () async {
    final valid = _jsonItem();
    final invalid = <dynamic>[
      {...valid, 'type': 'futureType'},
      {...valid, 'person': 'altra-persona'},
      {...valid, 'shift': 'turno-futuro'},
      {...valid, 'startDate': '2026-02-30'},
      {...valid, 'startDate': 123},
      {...valid, 'type': 'periodShiftChange', 'endDate': null},
      {
        ...valid,
        'type': 'periodShiftChange',
        'startDate': '2026-10-09',
        'endDate': '2026-10-05',
      },
    ];
    final store = TurnOverrideStore(
      loadString: (_) async =>
          jsonEncode([invalid[0], valid, ...invalid.skip(1)]),
    );

    await store.load();

    expect(store.items, hasLength(1));
    expect(store.items.single.shift, TurnOverrideShift.giornata);
  });

  test('scritture ravvicinate rispettano FIFO e snapshot', () async {
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

    final first = store.setDailyOverride(
      person: TurnPersonId.matteo,
      day: _monday,
      newShift: TurnOverrideShift.mattina,
    );
    final second = store.setDailyOverride(
      person: TurnPersonId.chiara,
      day: _monday,
      newShift: TurnOverrideShift.giornata,
    );
    await Future<void>.delayed(Duration.zero);
    expect(starts, hasLength(1));

    firstGate.complete();
    await Future.wait([first, second]);
    final reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.items, hasLength(2));
  });

  test(
    'aggiunta seguita subito da rimozione non fa riapparire override',
    () async {
      final memory = <String, String>{};
      final store = _memoryStore(memory);
      final item = TurnOverride(
        type: TurnOverrideType.dailyShiftChange,
        person: TurnPersonId.matteo,
        startDate: _monday,
        shift: TurnOverrideShift.giornata,
      );

      await Future.wait([store.add(item), store.remove(item)]);

      final reloaded = _memoryStore(memory);
      await reloaded.load();
      expect(reloaded.items, isEmpty);
    },
  );

  test('errore di scrittura non blocca la scrittura successiva', () async {
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

    await expectLater(
      store.setDailyOverride(
        person: TurnPersonId.matteo,
        day: _monday,
        newShift: TurnOverrideShift.mattina,
      ),
      throwsStateError,
    );
    await store.setDailyOverride(
      person: TurnPersonId.chiara,
      day: _monday,
      newShift: TurnOverrideShift.giornata,
    );

    final reloaded = _memoryStore(memory);
    await reloaded.load();
    expect(reloaded.items, hasLength(2));
  });

  test(
    'CoreStore ricarica periodo Giornata con orari e viaggi invariati',
    () async {
      final first = CoreStore(initialDate: _monday);
      await first.turnOverrideStore.setPeriodOverride(
        person: TurnPersonId.matteo,
        startDay: _monday,
        endDay: _monday.add(const Duration(days: 4)),
        newShift: TurnOverrideShift.giornata,
      );

      final second = CoreStore(initialDate: _monday);
      await second.init();

      for (var offset = 0; offset < 5; offset++) {
        expect(
          second.turnEngine
              .turnPlanForPersonDay(
                person: TurnPerson.matteo,
                day: _monday.add(Duration(days: offset)),
              )
              .type,
          TurnType.giornata,
        );
      }
      final outside = _monday.add(const Duration(days: 7));
      expect(
        second.turnEngine
            .turnPlanForPersonDay(person: TurnPerson.matteo, day: outside)
            .type,
        TurnEngine()
            .turnPlanForPersonDay(person: TurnPerson.matteo, day: outside)
            .type,
      );

      final constraints = second.turnEngine.constraintsForPersonDay(
        person: TurnPerson.matteo,
        day: _monday,
      );
      expect(
        constraints,
        contains(
          isA<AdultConstraintInterval>()
              .having(
                (value) => value.kind,
                'kind',
                AdultConstraintKind.outboundTravel,
              )
              .having((value) => value.start, 'start', DateTime(2026, 10, 5, 7))
              .having((value) => value.end, 'end', DateTime(2026, 10, 5, 8)),
        ),
      );
      expect(
        constraints,
        contains(
          isA<AdultConstraintInterval>()
              .having((value) => value.kind, 'kind', AdultConstraintKind.work)
              .having((value) => value.start, 'start', DateTime(2026, 10, 5, 8))
              .having((value) => value.end, 'end', DateTime(2026, 10, 5, 17)),
        ),
      );
      expect(
        constraints,
        contains(
          isA<AdultConstraintInterval>()
              .having(
                (value) => value.kind,
                'kind',
                AdultConstraintKind.returnTravel,
              )
              .having(
                (value) => value.start,
                'start',
                DateTime(2026, 10, 5, 17),
              )
              .having(
                (value) => value.end,
                'end',
                DateTime(2026, 10, 5, 17, 45),
              ),
        ),
      );
    },
  );

  test('CoreStore ricarica override solo oggi e la rimozione', () async {
    final first = CoreStore(initialDate: _monday);
    await first.turnOverrideStore.setDailyOverride(
      person: TurnPersonId.chiara,
      day: _monday,
      newShift: TurnOverrideShift.giornata,
    );

    final second = CoreStore(initialDate: _monday);
    await second.init();
    expect(
      second.turnEngine
          .turnPlanForPersonDay(person: TurnPerson.chiara, day: _monday)
          .type,
      TurnType.giornata,
    );
    expect(
      second.turnEngine
          .turnPlanForPersonDay(
            person: TurnPerson.chiara,
            day: _monday.add(const Duration(days: 1)),
          )
          .type,
      isNot(TurnType.giornata),
    );

    await second.turnOverrideStore.remove(
      second.turnOverrideStore.items.single,
    );
    final third = CoreStore(initialDate: _monday);
    await third.init();
    expect(third.turnOverrideStore.items, isEmpty);
  });
}

TurnOverrideStore _memoryStore(
  Map<String, String> memory, {
  TurnOverrideStoreSaveString? save,
}) {
  return TurnOverrideStore(
    loadString: (key) async => memory[key],
    saveString: save ?? (key, value) async => memory[key] = value,
  );
}

Map<String, dynamic> _jsonItem() => {
  'type': 'dailyShiftChange',
  'person': 'matteo',
  'startDate': '2026-10-05',
  'endDate': null,
  'shift': 'giornata',
  'rotationIndex': null,
};
