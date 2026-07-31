import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/alice_event_store.dart';
import 'package:frododesk/logic/calendar/builders/family_now_snapshot_coordinator.dart';
import 'package:frododesk/logic/calendar/builders/family_now_view_model_builder.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/logic/ferie_period_store.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const coordinator = FamilyNowSnapshotCoordinator();
  final day = DateTime(2026, 7, 31);
  final observedAt = DateTime(2026, 7, 31, 10);

  test('assembla uno snapshot libero e conserva lo stesso observedAt', () {
    final store = CoreStore(initialDate: day);

    final snapshot = coordinator.build(
      selectedDay: day,
      observedAt: observedAt,
      coreStore: store,
    );

    expect(snapshot.realNow, same(observedAt));
    expect(snapshot.now, same(observedAt));
    expect(snapshot.matteoNowLabel, isNotEmpty);
    expect(snapshot.chiaraNowLabel, isNotEmpty);
    expect(snapshot.aliceNowLabel, 'a casa');
  });

  test('malattia leggera e ferie mantengono le precedenze esistenti', () {
    final store = CoreStore(initialDate: day);
    store.feriePeriodStore.add(
      FeriePeriod(person: FeriePerson.chiara, startDay: day, endDay: day),
    );
    final overrides = DayOverrides(
      day: day,
      matteo: PersonDayOverride(status: OverrideStatus.malattiaLeggera),
    );

    final snapshot = coordinator.build(
      selectedDay: day,
      observedAt: observedAt,
      coreStore: store,
      overrides: overrides,
    );

    expect(snapshot.matteoNowLabel, 'malattia leggera');
    expect(snapshot.matteoBusyNow, isFalse);
    expect(snapshot.chiaraNowLabel, 'libero • ferie');
  });

  test('evento reale attivo prevale sullo stato ordinario per gli adulti', () {
    final store = CoreStore(initialDate: day);
    store.realEventStore.addEvent(
      RealEvent(
        id: 'matteo-now',
        startDate: day,
        endDate: day,
        title: 'Evento',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        personKey: 'matteo',
      ),
    );

    final snapshot = coordinator.build(
      selectedDay: day,
      observedAt: observedAt,
      coreStore: store,
    );

    expect(snapshot.matteoBusyNow, isTrue);
    expect(snapshot.matteoNowLabel, 'occupato • evento');
  });

  test('Alice al centro estivo usa observedAt e gli orari del periodo', () {
    final store = CoreStore(initialDate: day);
    store.aliceEventStore.addEvent(
      AliceEventPeriod(
        start: day,
        end: day,
        type: AliceEventType.summerCamp,
        summerCampStart: const TimeOfDay(hour: 8, minute: 30),
        summerCampEnd: const TimeOfDay(hour: 16, minute: 30),
      ),
    );

    final snapshot = coordinator.build(
      selectedDay: day,
      observedAt: observedAt,
      coreStore: store,
    );

    expect(snapshot.aliceIsOutNow, isTrue);
    expect(snapshot.aliceNowLabel, 'fuori • centro estivo');
  });

  test('evento reale Alice prevale sullo stato casa', () {
    final store = CoreStore(initialDate: day);
    store.aliceEventStore.addEvent(
      AliceEventPeriod(start: day, end: day, type: AliceEventType.vacation),
    );
    store.realEventStore.addEvent(
      RealEvent(
        id: 'alice-now',
        startDate: day,
        endDate: day,
        title: 'Visita medica',
        startTime: const TimeOfDay(hour: 9, minute: 30),
        endTime: const TimeOfDay(hour: 10, minute: 30),
        personKey: 'alice',
      ),
    );

    final snapshot = coordinator.build(
      selectedDay: day,
      observedAt: observedAt,
      coreStore: store,
    );

    expect(snapshot.aliceIsOutNow, isTrue);
    expect(snapshot.aliceNowLabel, 'fuori • visita');
  });

  test('ViewModel resta una proiezione fedele dello snapshot', () {
    final snapshot = coordinator.build(
      selectedDay: day,
      observedAt: observedAt,
      coreStore: CoreStore(initialDate: day),
    );

    final viewModel = const FamilyNowViewModelBuilder().build(
      snapshot,
      isEmergency: true,
    );

    expect(viewModel.matteo.label, snapshot.matteoNowLabel);
    expect(viewModel.chiara.label, snapshot.chiaraNowLabel);
    expect(viewModel.alice.label, snapshot.aliceNowLabel);
    expect(viewModel.matteo.turnLabel, snapshot.matteoTurnLabel);
    expect(viewModel.chiara.turnLabel, snapshot.chiaraTurnLabel);
    expect(viewModel.emergency, isTrue);
  });

  test('il coordinator non contiene DateTime.now', () {
    final source = File(
      'lib/logic/calendar/builders/family_now_snapshot_coordinator.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('DateTime.now')));
  });
}
