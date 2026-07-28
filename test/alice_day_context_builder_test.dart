import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/alice_event_store.dart';
import 'package:frododesk/logic/calendar/builders/alice_day_context_builder.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/models/school_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  CoreStore coreStoreWithSchoolDay({
    required DateTime day,
    SchoolDayConfig schoolDay = const SchoolDayConfig(
      enabled: true,
      entryMinutes: 8 * 60 + 25,
      exitRealMinutes: 16 * 60 + 25,
    ),
  }) {
    final coreStore = CoreStore(initialDate: day);
    coreStore.schoolStore.setPeriods([
      SchoolPeriod(
        id: 'school-test',
        name: 'Scuola test',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        weekConfig: SchoolWeekConfig(
          monday: schoolDay,
          tuesday: schoolDay,
          wednesday: schoolDay,
          thursday: schoolDay,
          friday: schoolDay,
          saturday: const SchoolDayConfig.off(),
        ),
      ),
    ]);
    return coreStore;
  }

  test('costruisce lo stesso evento Scuola con rientro configurato', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(day: day);

    final context = AliceDayContextBuilder(coreStore).build(day);

    expect(context.isSchoolDay, isTrue);
    expect(context.events, hasLength(1));
    expect(context.events.single.title, 'Scuola');
    expect(context.events.single.start, const TimeOfDay(hour: 8, minute: 25));
    expect(context.events.single.end, const TimeOfDay(hour: 16, minute: 45));
  });

  test('configurazione disabilitata non aggiunge evento Scuola', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(
      day: day,
      schoolDay: const SchoolDayConfig(
        enabled: false,
        entryMinutes: 8 * 60 + 25,
        exitRealMinutes: 16 * 60 + 25,
      ),
    );

    final context = AliceDayContextBuilder(coreStore).build(day);

    expect(context.isSchoolDay, isFalse);
    expect(context.events.where((event) => event.title == 'Scuola'), isEmpty);
  });

  test('periodi non scolastici prevalgono sulla scuola configurata', () {
    final cases = <AliceEventType, String>{
      AliceEventType.vacation: 'Vacanza',
      AliceEventType.schoolClosure: 'Scuola chiusa',
      AliceEventType.sickness: 'Malattia',
    };

    for (final entry in cases.entries) {
      final day = DateTime(2026, 7, 28);
      final coreStore = coreStoreWithSchoolDay(day: day);
      coreStore.aliceEventStore.addEvent(
        AliceEventPeriod(start: day, end: day, type: entry.key),
      );

      final context = AliceDayContextBuilder(coreStore).build(day);

      expect(context.isSchoolDay, isFalse, reason: entry.key.name);
      expect(context.dayStateLabel, entry.value, reason: entry.key.name);
      expect(
        context.events.where((event) => event.title == 'Scuola'),
        isEmpty,
        reason: entry.key.name,
      );
    }
  });

  test('uscita anticipata giornaliera termina evento Scuola', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(day: day);
    coreStore.daySettingsStore.setUscitaAnticipataTimeForDay(
      day,
      const TimeOfDay(hour: 12, minute: 40),
    );

    final context = AliceDayContextBuilder(coreStore).build(day);

    expect(context.events.single.end, const TimeOfDay(hour: 12, minute: 40));
  });

  test('uscita anticipata globale termina evento Scuola', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(day: day);
    coreStore.settingsStore.setUscitaAnticipataDefaultTime(
      const TimeOfDay(hour: 13, minute: 15),
    );
    coreStore.settingsStore.setUscitaAnticipata13(true);

    final context = AliceDayContextBuilder(coreStore).build(day);

    expect(context.events.single.end, const TimeOfDay(hour: 13, minute: 15));
  });

  test('uscita giornaliera prevale su quella globale', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(day: day);
    coreStore.settingsStore.setUscitaAnticipataDefaultTime(
      const TimeOfDay(hour: 13, minute: 20),
    );
    coreStore.settingsStore.setUscitaAnticipata13(true);
    coreStore.daySettingsStore.setUscitaAnticipataTimeForDay(
      day,
      const TimeOfDay(hour: 12, minute: 50),
    );

    final context = AliceDayContextBuilder(coreStore).build(day);

    expect(context.events.single.end, const TimeOfDay(hour: 12, minute: 50));
  });

  test('centro estivo mantiene evento e orari configurati', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(day: day);
    coreStore.aliceEventStore.addEvent(
      AliceEventPeriod(
        start: day,
        end: day,
        type: AliceEventType.summerCamp,
        summerCampStart: const TimeOfDay(hour: 8, minute: 15),
        summerCampEnd: const TimeOfDay(hour: 16, minute: 20),
      ),
    );

    final context = AliceDayContextBuilder(coreStore).build(day);

    expect(context.isSchoolDay, isFalse);
    expect(context.isSummerCampDay, isTrue);
    expect(context.events, hasLength(1));
    expect(context.events.single.title, 'Centro estivo');
    expect(context.events.single.start, const TimeOfDay(hour: 8, minute: 15));
    expect(context.events.single.end, const TimeOfDay(hour: 16, minute: 20));
  });
}
