import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/alice_companion_store.dart';
import 'package:frododesk/logic/calendar/builders/calendar_day_coverage_pipeline.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/logic/coverage_engine.dart';
import 'package:frododesk/logic/turn_engine.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:frododesk/models/school_model.dart';
import 'package:frododesk/models/support_person.dart';
import 'package:frododesk/models/turn_override.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _day = DateTime(2026, 10, 5);

Future<CoreStore> _schoolDayStore({bool sandraMorning = true}) async {
  final store = CoreStore(initialDate: _day);
  store.settingsStore.setSandraDisponibile(true);
  store.daySettingsStore.setSandraMattinaForDay(_day, sandraMorning);
  store.daySettingsStore.setSandraPranzoForDay(_day, false);
  store.daySettingsStore.setSandraSeraForDay(_day, false);
  await store.schoolStore.addPeriod(
    SchoolPeriod(
      id: 'school-2026',
      name: 'Scuola',
      startDate: _day,
      endDate: _day,
      weekConfig: SchoolWeekConfig.empty().copyWith(
        monday: const SchoolDayConfig(
          enabled: true,
          entryMinutes: 8 * 60 + 25,
          exitRealMinutes: 16 * 60 + 25,
        ),
      ),
    ),
  );
  store.turnOverrideStore.setPeriodOverride(
    person: TurnPersonId.matteo,
    startDay: _day,
    endDay: _day.add(const Duration(days: 4)),
    newShift: TurnOverrideShift.giornata,
  );
  return store;
}

CoverageDayAnalysis _analyze(CoreStore store, {bool sandraMorning = true}) {
  return store.coverageEngine.analyzeDay(
    day: _day,
    uscita13: false,
    sandraMorningAvailable: sandraMorning,
    sandraLunchAvailable: false,
    sandraEveningAvailable: false,
    overrides: DayOverrides.empty(_day),
  );
}

bool _hasRange(
  Iterable<CoverageGapDetail> details,
  int startHour,
  int startMinute,
  int endHour,
  int endMinute,
) {
  return details.any(
    (detail) =>
        detail.start == TimeOfDay(hour: startHour, minute: startMinute) &&
        detail.end == TimeOfDay(hour: endHour, minute: endMinute),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('scuola: distingue casa, ingresso e uscita nel caso reale', () async {
    final store = await _schoolDayStore();

    expect(
      store.turnEngine
          .turnPlanForPersonDay(person: TurnPerson.chiara, day: _day)
          .type,
      TurnType.mattina,
    );

    final analysis = _analyze(store);

    expect(analysis.gaps, contains('Alice a casa: 07:00–08:05'));
    expect(analysis.gaps, contains('Alice ingresso: 08:05–08:25'));
    expect(analysis.gaps, contains('Alice uscita: 16:25–16:45'));
    expect(
      analysis.details.any(
        (detail) =>
            detail.start == const TimeOfDay(hour: 6, minute: 45) &&
            detail.end == const TimeOfDay(hour: 7, minute: 0),
      ),
      isFalse,
    );
    expect(
      analysis.details.any(
        (detail) =>
            detail.label.startsWith('Alice a casa') &&
            detail.start.hour * 60 + detail.start.minute < 8 * 60 + 25 &&
            detail.end.hour * 60 + detail.end.minute > 8 * 60 + 5 &&
            detail.start != const TimeOfDay(hour: 7, minute: 0),
      ),
      isFalse,
    );
  });

  test('Sandra fino alle 06:45 non copre il gap successivo', () async {
    final store = await _schoolDayStore();

    final analysis = _analyze(store);

    expect(analysis.gaps, contains('Alice a casa: 07:00–08:05'));
  });

  test('senza coperture il periodo scoperto è unico e completo', () async {
    final store = await _schoolDayStore(sandraMorning: false);

    final analysis = _analyze(store, sandraMorning: false);
    final homeGaps = analysis.gaps.where(
      (label) => label.startsWith('Alice a casa'),
    );

    expect(homeGaps, ['Alice a casa: 07:00–08:05']);
  });

  test('Supporto 07:00-08:05 elimina soltanto il gap domestico', () async {
    final store = await _schoolDayStore();
    store.supportNetworkStore.addPerson(
      const SupportPerson(
        id: 'support',
        name: 'Supporto',
        enabled: true,
        start: TimeOfDay(hour: 7, minute: 0),
        end: TimeOfDay(hour: 8, minute: 5),
      ),
    );
    await store.daySettingsStore.setSupportPersonEnabledForDay(
      _day,
      'support',
      true,
    );

    final analysis = _analyze(store);

    expect(analysis.gaps, isNot(contains('Alice a casa: 07:00–08:05')));
    expect(analysis.gaps, contains('Alice ingresso: 08:05–08:25'));
  });

  test('Supporti consecutivi e slot multipli segmentano la finestra', () async {
    final store = await _schoolDayStore();
    store.supportNetworkStore.addPerson(
      const SupportPerson(
        id: 'support-a',
        name: 'Supporto A',
        enabled: true,
        start: TimeOfDay(hour: 0, minute: 0),
        end: TimeOfDay(hour: 0, minute: 1),
        slots: [
          SupportTimeSlot(
            start: TimeOfDay(hour: 7, minute: 0),
            end: TimeOfDay(hour: 7, minute: 30),
          ),
          SupportTimeSlot(
            start: TimeOfDay(hour: 7, minute: 30),
            end: TimeOfDay(hour: 7, minute: 45),
          ),
        ],
      ),
    );
    store.supportNetworkStore.addPerson(
      const SupportPerson(
        id: 'support-b',
        name: 'Supporto B',
        enabled: true,
        start: TimeOfDay(hour: 7, minute: 45),
        end: TimeOfDay(hour: 8, minute: 5),
      ),
    );
    await store.daySettingsStore.setSupportPersonEnabledForDay(
      _day,
      'support-a',
      true,
    );
    await store.daySettingsStore.setSupportPersonEnabledForDay(
      _day,
      'support-b',
      true,
    );

    final analysis = _analyze(store);

    expect(
      analysis.details.where(
        (detail) => detail.label.startsWith('Alice a casa'),
      ),
      isEmpty,
    );
  });

  test('un genitore disponibile elimina il gap pre-scuola', () async {
    final store = await _schoolDayStore();
    store.turnOverrideStore.setDailyOverride(
      person: TurnPersonId.chiara,
      day: _day,
      newShift: TurnOverrideShift.off,
    );

    final analysis = _analyze(store);

    expect(analysis.gaps, isNot(contains('Alice a casa: 07:00–08:05')));
  });

  test('evento reale di Alice non produce falsi gap mentre è fuori', () async {
    final store = await _schoolDayStore();
    store.realEventStore.addEvent(
      RealEvent(
        id: 'alice-away',
        startDate: _day,
        endDate: _day,
        title: 'Alice fuori casa',
        startTime: const TimeOfDay(hour: 7, minute: 20),
        endTime: const TimeOfDay(hour: 7, minute: 50),
        personKey: 'alice',
      ),
    );

    final analysis = _analyze(store);
    final homeDetails = analysis.details.where(
      (detail) => detail.label.startsWith('Alice a casa'),
    );

    expect(_hasRange(homeDetails, 7, 0, 7, 20), isTrue);
    expect(_hasRange(homeDetails, 7, 20, 7, 50), isFalse);
    expect(_hasRange(homeDetails, 7, 50, 8, 5), isTrue);
  });

  test('accompagnamento parziale segmenta il gap ai propri estremi', () async {
    final store = await _schoolDayStore();
    store.aliceCompanionStore.addEntry(
      AliceCompanionEntry(
        day: _day,
        start: const TimeOfDay(hour: 7, minute: 20),
        end: const TimeOfDay(hour: 7, minute: 50),
        person: AliceCompanionPerson.chiara,
      ),
    );

    final analysis = _analyze(store);
    final homeDetails = analysis.details.where(
      (detail) => detail.label.startsWith('Alice a casa'),
    );

    expect(_hasRange(homeDetails, 7, 0, 7, 20), isTrue);
    expect(_hasRange(homeDetails, 7, 20, 7, 50), isFalse);
    expect(_hasRange(homeDetails, 7, 50, 8, 5), isTrue);
  });

  test('pipeline e filtro mantengono il gap domestico pre-scuola', () async {
    final store = await _schoolDayStore();

    final result = CalendarDayCoveragePipeline(coreStore: store).build(
      selectedDay: _day,
      observedAt: _day.subtract(const Duration(days: 1)),
    );

    final labels = result.gapDetails.map((detail) => detail.label);
    expect(labels, contains('Alice a casa: 07:00–08:05'));
    expect(labels, contains('Alice ingresso: 08:05–08:25'));
    expect(labels, contains('Alice uscita: 16:25–16:45'));
    expect(
      result.gapDetails.any(
        (detail) =>
            detail.label.startsWith('Alice a casa') &&
            detail.start == const TimeOfDay(hour: 8, minute: 25) &&
            detail.end == const TimeOfDay(hour: 16, minute: 25),
      ),
      isFalse,
    );
  });
}
