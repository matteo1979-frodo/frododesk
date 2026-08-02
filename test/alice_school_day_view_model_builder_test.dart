import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/alice_event_store.dart';
import 'package:frododesk/logic/alice_events/alice_event_behavior.dart';
import 'package:frododesk/logic/calendar/builders/alice_school_day_view_model_builder.dart';
import 'package:frododesk/logic/calendar/view_models/alice_school_day_view_model.dart';
import 'package:frododesk/logic/core_store.dart';
import 'package:frododesk/models/alice_special_event.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:frododesk/models/school_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  CoreStore storeFor(DateTime day) {
    final store = CoreStore(initialDate: day);
    const config = SchoolDayConfig(
      enabled: true,
      entryMinutes: 8 * 60 + 25,
      exitRealMinutes: 16 * 60 + 25,
    );
    store.schoolStore.setPeriods([
      SchoolPeriod(
        id: 'school',
        name: 'Scuola test',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        weekConfig: const SchoolWeekConfig(
          monday: config,
          tuesday: config,
          wednesday: config,
          thursday: config,
          friday: config,
          saturday: SchoolDayConfig.off(),
        ),
      ),
    ]);
    return store;
  }

  AliceSchoolDayViewModel build(CoreStore store, DateTime day) =>
      AliceSchoolDayViewModelBuilder(
        store,
      ).build(day: day, expandedEventIds: const {});

  test('giorno scolastico usa timing effettivo e testi pronti per la UI', () {
    final day = DateTime(2026, 7, 28);
    final model = build(storeFor(day), day);

    expect(model.stateLabel, 'Scuola');
    expect(model.schoolHoursLabel, 'Orario: 08:25–16:25');
    expect(model.schoolEntryAt, const TimeOfDay(hour: 8, minute: 25));
    expect(model.schoolExitAt, const TimeOfDay(hour: 16, minute: 25));
    expect(model.schoolExitWindowEnd, const TimeOfDay(hour: 16, minute: 45));
    expect(model.periodLabel, isNull);
  });

  test('uscita anticipata giornaliera prevale nel testo mostrato', () {
    final day = DateTime(2026, 7, 28);
    final store = storeFor(day);
    store.daySettingsStore.setUscitaAnticipataTimeForDay(
      day,
      const TimeOfDay(hour: 12, minute: 40),
    );

    final model = build(store, day);

    expect(model.hasEarlySchoolExit, isTrue);
    expect(model.schoolHoursLabel, 'Orario: 08:25–12:40');
  });

  test('stati periodo mantengono label, icona e colore semantico', () {
    final cases = {
      AliceEventType.vacation: ('Vacanza', Colors.teal),
      AliceEventType.schoolClosure: ('Scuola chiusa', Colors.orange),
      AliceEventType.sickness: ('Malattia', Colors.red),
    };
    for (final entry in cases.entries) {
      final day = DateTime(2026, 7, 28);
      final store = storeFor(day);
      store.aliceEventStore.addEvent(
        AliceEventPeriod(start: day, end: day, type: entry.key),
      );

      final model = build(store, day);

      expect(model.stateLabel, entry.value.$1);
      expect(model.periodLabel, entry.value.$1);
      expect(model.stateColor, entry.value.$2);
    }
  });

  test('giorno senza attività presenta Alice a casa tutto il giorno', () {
    final day = DateTime(2026, 7, 26);
    final model = build(storeFor(day), day);

    expect(model.stateLabel, 'A casa');
    expect(model.schoolHoursLabel, 'Orario: Tutto il giorno');
  });

  test('evento reale futuro impedisce Tutto il giorno', () {
    final day = DateTime(2026, 7, 26);
    final store = storeFor(day);
    store.realEventStore.addEvent(
      RealEvent(
        id: 'alice-evening',
        startDate: day,
        endDate: day,
        title: 'Festa',
        startTime: const TimeOfDay(hour: 18, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 0),
        personKey: 'alice',
      ),
    );

    final model = build(store, day);

    expect(model.stateLabel, 'A casa');
    expect(model.schoolHoursLabel, isNot('Orario: Tutto il giorno'));
  });

  test('centro estivo usa il proprio timing anche nella riga Orario', () {
    final day = DateTime(2026, 7, 28);
    final store = storeFor(day);
    store.aliceEventStore.addEvent(
      AliceEventPeriod(
        start: day,
        end: day,
        type: AliceEventType.summerCamp,
        summerCampStart: const TimeOfDay(hour: 8, minute: 30),
        summerCampEnd: const TimeOfDay(hour: 16, minute: 30),
      ),
    );

    final model = build(store, day);

    expect(model.stateLabel, 'Centro estivo');
    expect(model.schoolHoursLabel, 'Orario: 08:30–16:30');
    expect(model.schoolHoursLabel, isNot(contains('16:25')));
    expect(model.schoolEntryAt, const TimeOfDay(hour: 8, minute: 30));
    expect(model.schoolExitAt, const TimeOfDay(hour: 16, minute: 30));
    expect(model.schoolExitWindowEnd, const TimeOfDay(hour: 16, minute: 50));
    expect(model.showSummerCampSpecialCard, isTrue);
  });

  test('evento speciale prevale sullo stato e gli eventi sono ordinati', () {
    final day = DateTime(2026, 7, 28);
    final store = storeFor(day);
    store.aliceSpecialEventStore.replaceEventsForDay(day, [
      _event(day, 'late', 'Danza', 18, AliceSpecialEventCategory.sport),
      _event(day, 'early', 'Dentista', 9, AliceSpecialEventCategory.health),
    ]);

    final model = build(store, day);

    expect(model.stateLabel, 'Dentista');
    expect(model.events.map((e) => e.event.id), ['early', 'late']);
    expect(model.events.first.categoryText, 'Categoria: Salute');
    expect(model.events.first.timeText, 'Orario: 09:00–10:00');
  });

  test('sovrapposizioni, massimo visibile e conteggio nascosti invariati', () {
    final day = DateTime(2026, 7, 28);
    final store = storeFor(day);
    store.aliceSpecialEventStore.replaceEventsForDay(day, [
      _event(day, 'a', 'A', 9, AliceSpecialEventCategory.school, endHour: 11),
      _event(day, 'b', 'B', 10, AliceSpecialEventCategory.activity),
      _event(day, 'c', 'C', 14, AliceSpecialEventCategory.other),
    ]);

    final model = build(store, day);

    expect(model.hasEventConflict, isTrue);
    expect(model.events.first.tile.isConflict, isTrue);
    expect(model.events.first.conflictWith, ['B']);
    expect(
      model.visibleEvents,
      hasLength(AliceSchoolDayViewModel.maxVisibleEvents),
    );
    expect(model.hiddenEventsCount, 1);
  });

  test('categorie sono italiane e non espongono enum.name o ID', () {
    final model = build(storeFor(DateTime(2026, 7, 28)), DateTime(2026, 7, 28));
    expect(model.categoryOptions.map((option) => option.label), [
      'Scuola',
      'Sport',
      'Salute',
      'Attività',
      'Altro',
    ]);
    for (final option in model.categoryOptions) {
      expect(option.label, isNot(option.value.name));
      expect(option.label, isNot(contains('id')));
    }
  });

  test(
    'ViewModel non contiene callback, editor o riferimento temporale implicito',
    () {
      final model = build(
        storeFor(DateTime(2026, 7, 28)),
        DateTime(2026, 7, 28),
      );
      expect(model.toString(), isNot(contains('TextEditingController')));
      expect(model.toString(), isNot(contains('VoidCallback')));
    },
  );
}

AliceSpecialEvent _event(
  DateTime day,
  String id,
  String label,
  int startHour,
  AliceSpecialEventCategory category, {
  int? endHour,
}) {
  return AliceSpecialEvent(
    id: id,
    label: label,
    category: category,
    behavior: AliceEventBehavior.logistic,
    date: day,
    start: TimeOfDay(hour: startHour, minute: 0),
    end: TimeOfDay(hour: endHour ?? startHour + 1, minute: 0),
  );
}
