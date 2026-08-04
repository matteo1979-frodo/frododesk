import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/logic/home_snapshot_coordinator.dart';
import 'package:frododesk/models/home_observed_at.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coordinator builds UI-ready reminder and event selections', () async {
    final today = DateTime(2026, 8, 4);
    SharedPreferences.setMockInitialValues({
      'promemoria_giorno': jsonEncode([
        _reminder('open', 'Matteo', 'Aperto', DateTime(2026, 8, 1)),
        _reminder(
          'done-today',
          'Alice',
          'Chiuso oggi',
          DateTime(2026, 8, 1),
          done: true,
          completedDay: today,
        ),
        _reminder(
          'done-before',
          'Chiara',
          'Chiuso prima',
          DateTime(2026, 8, 1),
          done: true,
          completedDay: DateTime(2026, 8, 3),
        ),
        _reminder('future', 'Famiglia', 'Futuro', DateTime(2026, 8, 5)),
      ]),
    });
    final coreStore = CoreStore(initialDate: today);
    await coreStore.promemoriaStore.load();
    coreStore.realEventStore.addEvent(
      RealEvent(
        id: 'today-event',
        startDate: today,
        endDate: today,
        title: 'Evento oggi',
        startTime: const TimeOfDay(hour: 9, minute: 0),
      ),
    );
    coreStore.realEventStore.addEvent(
      RealEvent(
        id: 'future-event',
        startDate: DateTime(2026, 8, 7),
        endDate: DateTime(2026, 8, 7),
        title: 'Evento futuro',
      ),
    );

    final snapshot = HomeSnapshotCoordinator(
      coreStore: coreStore,
    ).build(observedAt: HomeObservedAt(observedAt: DateTime(2026, 8, 4, 12)));

    expect(snapshot.today.reminderCount, 2);
    expect(snapshot.today.reminderGroups.map((group) => group.persona), [
      'Matteo',
      'Alice',
    ]);
    expect(snapshot.today.events.map((event) => event.id), ['today-event']);
    expect(snapshot.globalEvents.futureDayCount, 1);
    expect(
      snapshot.globalEvents.currentYearEvents
          .month(8)
          .events
          .map((event) => event.id),
      ['today-event', 'future-event'],
    );
  });

  test('HomeScreen delegates construction and coordinator stays UI-free', () {
    final home = File('lib/screens/home_screen.dart').readAsStringSync();
    final coordinator = File(
      'lib/logic/home_snapshot_coordinator.dart',
    ).readAsStringSync();

    expect(home, contains('_requestHomeSnapshot(observedAt)'));
    expect(home, isNot(contains('_buildTodayPromemoria')));
    expect(home, isNot(contains('_getAllEventsForDay')));
    expect(home, isNot(contains('_eventCountForYear')));
    expect(home, isNot(contains('HomeEventGrouping.byDay')));
    expect(coordinator, isNot(contains('BuildContext')));
    expect(coordinator, isNot(contains('Widget')));
    expect(coordinator, isNot(contains('Theme')));
    expect(coordinator, isNot(contains('DateTime.now')));
  });
}

Map<String, Object?> _reminder(
  String id,
  String persona,
  String text,
  DateTime createdDay, {
  bool done = false,
  DateTime? completedDay,
}) {
  return {
    'id': id,
    'persona': persona,
    'testo': text,
    'done': done,
    'createdDay': createdDay.toIso8601String(),
    'completedDay': completedDay?.toIso8601String(),
  };
}
