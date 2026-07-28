import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/effective_school_day_timing_reader.dart';
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
    required SchoolDayConfig schoolDay,
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

  test('normalizza un giorno con componente oraria non zero', () {
    final coreStore = CoreStore(initialDate: DateTime(2026, 7, 28));
    final normalizedDay = DateTime(2026, 7, 28);

    coreStore.daySettingsStore.setSchoolOutTimesForDay(
      normalizedDay,
      const TimeOfDay(hour: 15, minute: 50),
      const TimeOfDay(hour: 16, minute: 10),
    );

    final result = EffectiveSchoolDayTimingReader(
      coreStore,
    ).read(DateTime(2026, 7, 28, 22, 37));

    expect(result.schoolExitAt, const TimeOfDay(hour: 15, minute: 50));
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 10));
  });

  test('mappa entry, exit e returnHome di una configurazione non standard', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(
      day: day,
      schoolDay: const SchoolDayConfig(
        enabled: true,
        entryMinutes: 8 * 60 + 10,
        exitRealMinutes: 15 * 60 + 35,
      ),
    );

    final result = EffectiveSchoolDayTimingReader(coreStore).read(day);

    expect(result.schoolEntryAt, const TimeOfDay(hour: 8, minute: 10));
    expect(result.schoolExitAt, const TimeOfDay(hour: 15, minute: 35));
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 15, minute: 55));
  });

  test('configurazione disabilitata applica i fallback H6.8A', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(
      day: day,
      schoolDay: const SchoolDayConfig(
        enabled: false,
        entryMinutes: 9 * 60,
        exitRealMinutes: 15 * 60,
      ),
    );

    final result = EffectiveSchoolDayTimingReader(coreStore).read(day);

    expect(result.schoolEntryAt, const TimeOfDay(hour: 8, minute: 25));
    expect(result.schoolExitAt, const TimeOfDay(hour: 16, minute: 25));
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 45));
  });

  test('override uscita e termine pickup prevalgono sulla configurazione', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = coreStoreWithSchoolDay(
      day: day,
      schoolDay: const SchoolDayConfig(
        enabled: true,
        entryMinutes: 8 * 60 + 25,
        exitRealMinutes: 16 * 60 + 25,
      ),
    );
    coreStore.daySettingsStore.setSchoolOutTimesForDay(
      day,
      const TimeOfDay(hour: 15, minute: 40),
      const TimeOfDay(hour: 16, minute: 5),
    );

    final result = EffectiveSchoolDayTimingReader(coreStore).read(day);

    expect(result.schoolExitAt, const TimeOfDay(hour: 15, minute: 40));
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 5));
  });

  test('uscita anticipata giornaliera prevale su quella globale', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = CoreStore(initialDate: day);
    coreStore.settingsStore.setUscitaAnticipataDefaultTime(
      const TimeOfDay(hour: 13, minute: 10),
    );
    coreStore.settingsStore.setUscitaAnticipata13(true);
    coreStore.daySettingsStore.setUscitaAnticipataTimeForDay(
      day,
      const TimeOfDay(hour: 12, minute: 45),
    );

    final result = EffectiveSchoolDayTimingReader(coreStore).read(day);

    expect(result.earlySchoolExitAt, const TimeOfDay(hour: 12, minute: 45));
  });

  test('uscita anticipata globale viene usata senza override giornaliero', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = CoreStore(initialDate: day);
    coreStore.settingsStore.setUscitaAnticipataDefaultTime(
      const TimeOfDay(hour: 13, minute: 20),
    );
    coreStore.settingsStore.setUscitaAnticipata13(true);

    final result = EffectiveSchoolDayTimingReader(coreStore).read(day);

    expect(result.earlySchoolExitAt, const TimeOfDay(hour: 13, minute: 20));
  });

  test('globale disabilitato produce null anche con orario valorizzato', () {
    final day = DateTime(2026, 7, 28);
    final coreStore = CoreStore(initialDate: day);
    coreStore.settingsStore.setUscitaAnticipataDefaultTime(
      const TimeOfDay(hour: 13, minute: 25),
    );
    coreStore.settingsStore.setUscitaAnticipata13(false);

    final result = EffectiveSchoolDayTimingReader(coreStore).read(day);

    expect(result.earlySchoolExitAt, isNull);
    expect(result.hasEarlySchoolExit, isFalse);
  });
}
