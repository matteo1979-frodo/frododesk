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

const _oldStart = TimeOfDay(hour: 5, minute: 0);
const _oldEnd = TimeOfDay(hour: 6, minute: 35);
const _newStart = TimeOfDay(hour: 7, minute: 30);
const _newEnd = TimeOfDay(hour: 14, minute: 30);
const _secondStart = TimeOfDay(hour: 18, minute: 0);
const _secondEnd = TimeOfDay(hour: 20, minute: 0);

SupportPerson _person({List<SupportTimeSlot> slots = const []}) {
  return SupportPerson(
    id: 'support-1',
    name: 'Supporto',
    enabled: true,
    start: _oldStart,
    end: _oldEnd,
    slots: slots,
  );
}

void _expectSlot(
  SupportTimeSlot slot,
  TimeOfDay expectedStart,
  TimeOfDay expectedEnd,
) {
  expect(slot.start, expectedStart);
  expect(slot.end, expectedEnd);
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

  test('persona legacy usa start/end come fascia effettiva', () {
    final person = _person();

    expect(person.slots, isEmpty);
    _expectSlot(person.effectiveSlots.single, _oldStart, _oldEnd);
  });

  test('persona con singolo slot usa quello slot', () {
    final person = _person(
      slots: const [SupportTimeSlot(start: _oldStart, end: _oldEnd)],
    );

    expect(person.effectiveSlots, hasLength(1));
    _expectSlot(person.effectiveSlots.single, _oldStart, _oldEnd);
  });

  test('modifica start/end aggiorna il primo slot', () {
    final updated = _person(
      slots: const [SupportTimeSlot(start: _oldStart, end: _oldEnd)],
    ).copyWith(start: _newStart, end: _newEnd);

    expect(updated.start, _newStart);
    expect(updated.end, _newEnd);
    _expectSlot(updated.slots.single, _newStart, _newEnd);
  });

  test('modifica del solo start aggiorna solo lo start del primo slot', () {
    final updated = _person(
      slots: const [SupportTimeSlot(start: _oldStart, end: _oldEnd)],
    ).copyWith(start: _newStart);

    expect(updated.start, _newStart);
    expect(updated.end, _oldEnd);
    _expectSlot(updated.slots.single, _newStart, _oldEnd);
  });

  test('modifica del solo end aggiorna solo la fine del primo slot', () {
    final updated = _person(
      slots: const [SupportTimeSlot(start: _oldStart, end: _oldEnd)],
    ).copyWith(end: _newEnd);

    expect(updated.start, _oldStart);
    expect(updated.end, _newEnd);
    _expectSlot(updated.slots.single, _oldStart, _newEnd);
  });

  test('modifica della prima fascia conserva il secondo slot in memoria', () {
    final updated = _person(
      slots: const [
        SupportTimeSlot(start: _oldStart, end: _oldEnd),
        SupportTimeSlot(start: _secondStart, end: _secondEnd),
      ],
    ).copyWith(start: _newStart, end: _newEnd);

    expect(updated.slots, hasLength(2));
    _expectSlot(updated.slots.first, _newStart, _newEnd);
    _expectSlot(updated.slots[1], _secondStart, _secondEnd);
  });

  test(
    'save/reload usa il formato precedente e conserva la prima fascia',
    () async {
      final store = SupportNetworkStore();
      store.addPerson(
        _person(
          slots: const [SupportTimeSlot(start: _oldStart, end: _oldEnd)],
        ).copyWith(start: _newStart, end: _newEnd),
      );
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('frododesk_support_network_people_v1');
      final saved = (jsonDecode(raw!) as List).single as Map;
      expect(saved['startMin'], 7 * 60 + 30);
      expect(saved['endMin'], 14 * 60 + 30);
      expect(saved.containsKey('slots'), isFalse);

      final reloaded = SupportNetworkStore();
      await reloaded.load();
      final person = reloaded.people.single;
      expect(person.start, _newStart);
      expect(person.end, _newEnd);
      _expectSlot(person.effectiveSlots.single, _newStart, _newEnd);
    },
  );

  test('AlicePresenceEngine copre la nuova fascia', () {
    final day = DateTime(2026, 7, 28);
    final supportStore = SupportNetworkStore();
    supportStore.addPerson(
      _person(
        slots: const [SupportTimeSlot(start: _oldStart, end: _oldEnd)],
      ).copyWith(start: _newStart, end: _newEnd),
    );
    final daySettingsStore = DaySettingsStore();
    daySettingsStore.setSupportPersonEnabledForDay(day, 'support-1', true);

    expect(
      _engine(supportStore, daySettingsStore).isCoveredBySupportNetwork(
        day: day,
        start: DateTime(2026, 7, 28, 8),
        end: DateTime(2026, 7, 28, 9),
      ),
      isTrue,
    );
  });

  test('AlicePresenceEngine non copre più la vecchia fascia', () {
    final day = DateTime(2026, 7, 28);
    final supportStore = SupportNetworkStore();
    supportStore.addPerson(
      _person(
        slots: const [SupportTimeSlot(start: _oldStart, end: _oldEnd)],
      ).copyWith(start: _newStart, end: _newEnd),
    );
    final daySettingsStore = DaySettingsStore();
    daySettingsStore.setSupportPersonEnabledForDay(day, 'support-1', true);

    expect(
      _engine(supportStore, daySettingsStore).isCoveredBySupportNetwork(
        day: day,
        start: DateTime(2026, 7, 28, 5, 15),
        end: DateTime(2026, 7, 28, 6),
      ),
      isFalse,
    );
  });

  test('persona disabilitata o non abilitata nel giorno non copre', () {
    final day = DateTime(2026, 7, 28);
    final supportStore = SupportNetworkStore();
    supportStore.addPerson(
      _person().copyWith(start: _newStart, end: _newEnd, enabled: false),
    );
    final daySettingsStore = DaySettingsStore();
    daySettingsStore.setSupportPersonEnabledForDay(day, 'support-1', true);
    final engine = _engine(supportStore, daySettingsStore);
    final start = DateTime(2026, 7, 28, 8);
    final end = DateTime(2026, 7, 28, 9);

    expect(
      engine.isCoveredBySupportNetwork(day: day, start: start, end: end),
      isFalse,
    );

    supportStore.updatePerson(
      'support-1',
      supportStore.people.single.copyWith(enabled: true),
    );
    daySettingsStore.setSupportPersonEnabledForDay(day, 'support-1', false);

    expect(
      engine.isCoveredBySupportNetwork(day: day, start: start, end: end),
      isFalse,
    );
  });
}
