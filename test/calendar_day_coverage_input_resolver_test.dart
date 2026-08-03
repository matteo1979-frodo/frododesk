import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_coverage_input_resolver.dart';
import 'package:frododesk/logic/calendar/builders/calendar_logistics_availability_resolver.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/logic/day_settings_store.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final day = DateTime(2026, 7, 31);

  CalendarDayCoverageInputResolver resolver(CoreStore store) =>
      CalendarDayCoverageInputResolver(coreStore: store);

  Future<void> addSupport(
    CoreStore store, {
    bool enabled = true,
    bool enabledForDay = true,
    TimeOfDay start = const TimeOfDay(hour: 0, minute: 0),
    TimeOfDay end = const TimeOfDay(hour: 23, minute: 59),
  }) async {
    store.supportNetworkStore.addPerson(
      SupportPerson(
        id: 'support-1',
        name: 'Supporto',
        enabled: enabled,
        start: start,
        end: end,
        slots: [SupportTimeSlot(start: start, end: end)],
      ),
    );
    await store.daySettingsStore.setSupportPersonEnabledForDay(
      day,
      'support-1',
      enabledForDay,
    );
  }

  test('saved school choices and lunch choice take precedence', () {
    final store = CoreStore(initialDate: day);
    store.daySettingsStore
      ..setSchoolInCoverForDay(day, SchoolCoverChoice.matteo)
      ..setSchoolOutCoverForDay(day, SchoolCoverChoice.chiara)
      ..setLunchCoverForDay(day, SchoolCoverChoice.sandra);

    final inputs = resolver(
      store,
    ).resolve(selectedDay: day, overrides: DayOverrides.empty(day));

    expect(inputs.schoolInCover, SchoolCoverChoice.matteo);
    expect(inputs.schoolOutCover, SchoolCoverChoice.chiara);
    expect(inputs.lunchCover, SchoolCoverChoice.sandra);
  });

  test('none without support stays uncovered', () {
    final store = CoreStore(initialDate: day);
    final inputs = resolver(
      store,
    ).resolve(selectedDay: day, overrides: DayOverrides.empty(day));
    expect(inputs.schoolInCover, SchoolCoverChoice.none);
    expect(inputs.schoolOutCover, SchoolCoverChoice.none);
  });

  test('enabled daily support covering full windows becomes altro', () async {
    final store = CoreStore(initialDate: day);
    await addSupport(store);
    final inputs = resolver(
      store,
    ).resolve(selectedDay: day, overrides: DayOverrides.empty(day));
    expect(inputs.schoolInCover, SchoolCoverChoice.altro);
    expect(inputs.schoolOutCover, SchoolCoverChoice.altro);
  });

  test('globally disabled or daily inactive support is ignored', () async {
    final globallyDisabled = CoreStore(initialDate: day);
    await addSupport(globallyDisabled, enabled: false);
    expect(
      resolver(globallyDisabled)
          .resolve(selectedDay: day, overrides: DayOverrides.empty(day))
          .schoolInCover,
      SchoolCoverChoice.none,
    );

    final dailyInactive = CoreStore(initialDate: day);
    await addSupport(dailyInactive, enabledForDay: false);
    expect(
      resolver(dailyInactive)
          .resolve(selectedDay: day, overrides: DayOverrides.empty(day))
          .schoolInCover,
      SchoolCoverChoice.none,
    );
  });

  test('partial support slot does not cover the complete window', () async {
    final store = CoreStore(initialDate: day);
    await addSupport(
      store,
      start: const TimeOfDay(hour: 8, minute: 0),
      end: const TimeOfDay(hour: 8, minute: 5),
    );
    final inputs = resolver(
      store,
    ).resolve(selectedDay: day, overrides: DayOverrides.empty(day));
    expect(inputs.schoolInCover, SchoolCoverChoice.none);
  });

  test('early exit resolves lunch fallback and dynamic Sandra start', () async {
    final store = CoreStore(initialDate: day);
    const exit = TimeOfDay(hour: 12, minute: 30);
    store.daySettingsStore.setUscitaAnticipataTimeForDay(day, exit);
    await addSupport(
      store,
      start: exit,
      end: store.coverageEngine.sandraPranzoEnd,
    );

    final inputs = resolver(
      store,
    ).resolve(selectedDay: day, overrides: DayOverrides.empty(day));
    expect(inputs.earlySchoolExitAt, exit);
    expect(inputs.lunchCover, SchoolCoverChoice.altro);
    expect(inputs.sandraLunchStart, exit);
  });

  test('daily Sandra flags are typed coverage availability inputs', () {
    final store = CoreStore(initialDate: day);
    store.settingsStore.setSandraDisponibile(false);
    store.daySettingsStore.setSandraMattinaForDay(day, true);
    final inputs = resolver(
      store,
    ).resolve(selectedDay: day, overrides: DayOverrides.empty(day));
    expect(
      inputs.logisticsAvailability.sandraAvailableFor(
        SandraAvailabilityBand.mattina,
      ),
      false,
    );
  });

  test('Sandra requires global enablement and explicit daily activation', () {
    final store = CoreStore(initialDate: day);
    store.settingsStore.setSandraDisponibile(true);
    expect(
      resolver(store)
          .resolve(selectedDay: day, overrides: DayOverrides.empty(day))
          .logisticsAvailability
          .sandraAvailableFor(SandraAvailabilityBand.mattina),
      false,
    );

    store.daySettingsStore.setSandraMattinaForDay(day, true);
    expect(
      resolver(store)
          .resolve(selectedDay: day, overrides: DayOverrides.empty(day))
          .logisticsAvailability
          .sandraAvailableFor(SandraAvailabilityBand.mattina),
      true,
    );
  });
}
