import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/alice_events/alice_event_behavior.dart';
import 'package:frododesk/logic/alice_special_event_store.dart';
import 'package:frododesk/logic/home_event_note_updater.dart';
import 'package:frododesk/logic/real_event_store.dart';
import 'package:frododesk/models/alice_special_event.dart';
import 'package:frododesk/models/home_event_view_model.dart';
import 'package:frododesk/models/real_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = HomeEventViewModelBuilder();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('1. RealEvent di oggi conserva il solo orario HH:mm', () {
    final day = DateTime(2026, 8, 3);
    final item = builder.fromRealEvent(
      event: _real(id: 'today', day: day, startHour: 9, startMinute: 5),
      day: day,
    );

    expect(item.day, day);
    expect(item.startDateTime, DateTime(2026, 8, 3, 9, 5));
    expect(item.endDateTime, isNull);
    expect(HomeEventFormatter.time(item), '09:05');
  });

  test('2. RealEvent conserva inizio e fine tipizzati', () {
    final day = DateTime(2026, 8, 3);
    final item = builder.fromRealEvent(
      event: _real(
        id: 'range',
        day: day,
        startHour: 9,
        endHour: 11,
        endMinute: 30,
      ),
      day: day,
    );

    expect(item.startDateTime, DateTime(2026, 8, 3, 9));
    expect(item.endDateTime, DateTime(2026, 8, 3, 11, 30));
    expect(HomeEventFormatter.time(item), '09:00-11:30');
  });

  test('3. AliceSpecialEvent conserva ID, fonte e record', () {
    final event = _alice(id: 'alice-42', day: DateTime(2026, 8, 3));
    final item = builder.fromAliceSpecialEvent(event: event, day: event.date);

    expect(item.id, 'alice-42');
    expect(item.source, HomeEventSource.aliceSpecialEvent);
    expect(item.aliceSpecialEventRecord, same(event));
    expect(item.realEventRecord, isNull);
  });

  test('4. evento di un anno passato non perde anno e giorno', () {
    final day = DateTime(2021, 2, 14);
    final item = builder.fromRealEvent(
      event: _real(id: 'past', day: day, startHour: 8),
      day: day,
    );

    expect(item.day, day);
    expect(item.startDateTime!.year, 2021);
  });

  test('5. evento di un anno futuro non perde anno e giorno', () {
    final day = DateTime(2032, 10, 8);
    final item = builder.fromRealEvent(
      event: _real(id: 'future', day: day, startHour: 8),
      day: day,
    );

    expect(item.day, day);
    expect(item.startDateTime!.year, 2032);
  });

  test('6. evento del mese selezionato mantiene il mese reale', () {
    final day = DateTime(2026, 8, 20);
    final item = builder.fromRealEvent(
      event: _real(id: 'month', day: day),
      day: day,
    );

    expect(item.day.month, 8);
    expect(
      HomeEventFormatter.tileTime(
        item,
        dateStyle: HomeEventDateLabelStyle.dayMonth,
      ),
      '20/8 • Tutto il giorno',
    );
  });

  test('7. dicembre e gennaio restano in anni distinti', () {
    final december = DateTime(2025, 12, 31);
    final january = DateTime(2026, 1, 1);
    final items = [
      builder.fromRealEvent(
        event: _real(id: 'dec', day: december),
        day: december,
      ),
      builder.fromRealEvent(
        event: _real(id: 'jan', day: january),
        day: january,
      ),
    ];

    final grouped = HomeEventGrouping.byDay(items);
    expect(grouped.keys, [december, january]);
  });

  test('8. evento senza orario resta all-day', () {
    final day = DateTime(2026, 4, 9);
    final item = builder.fromRealEvent(
      event: _real(id: 'all-day', day: day),
      day: day,
    );

    expect(item.startDateTime, isNull);
    expect(item.endDateTime, isNull);
    expect(HomeEventFormatter.time(item), 'Tutto il giorno');
  });

  test('9. evento con più persone conserva ordine e label UI', () {
    final day = DateTime(2026, 4, 9);
    final item = builder.fromRealEvent(
      event: _real(
        id: 'family',
        day: day,
        participantKeys: const ['matteo', 'chiara', 'alice', 'family'],
      ),
      day: day,
    );

    expect(item.participants, ['Matteo', 'Chiara', 'Alice', 'Famiglia']);
  });

  test('10. raggruppamento usa DateTime completo come chiave', () {
    final dayA = DateTime(2025, 5, 2);
    final dayB = DateTime(2026, 5, 2);
    final items = [
      builder.fromRealEvent(
        event: _real(id: 'a', day: dayA),
        day: dayA,
      ),
      builder.fromRealEvent(
        event: _real(id: 'b', day: dayB),
        day: dayB,
      ),
    ];

    final grouped = HomeEventGrouping.byDay(items);
    expect(grouped.length, 2);
    expect(grouped.keys, [dayA, dayB]);
  });

  test('11. ordinamento usa orario tipizzato e mette all-day in fondo', () {
    final day = DateTime(2026, 8, 3);
    final result = builder.forDay(
      day: day,
      realEvents: [
        _real(id: 'late', day: day, startHour: 18),
        _real(id: 'all-day', day: day),
        _real(id: 'early', day: day, startHour: 7, startMinute: 30),
      ],
      aliceSpecialEvents: const [],
    );

    expect(result.map((event) => event.id), ['early', 'late', 'all-day']);
  });

  test('12. elenco annuale separa gli eventi per anno reale', () {
    final y2025 = DateTime(2025, 6, 1);
    final y2026 = DateTime(2026, 6, 1);
    final all = [
      builder.fromRealEvent(
        event: _real(id: 'old', day: y2025),
        day: y2025,
      ),
      builder.fromRealEvent(
        event: _real(id: 'new', day: y2026),
        day: y2026,
      ),
    ];

    final annual = all.where((event) => event.day.year == 2025).toList();
    expect(annual.map((event) => event.id), ['old']);
  });

  test('13. dettaglio mantiene il record sorgente corretto', () {
    final first = _real(id: 'first', day: DateTime(2026, 8, 3));
    final second = _real(id: 'second', day: DateTime(2026, 8, 3));
    final item = builder.fromRealEvent(event: second, day: second.startDate);

    expect(item.realEventRecord, same(second));
    expect(item.realEventRecord, isNot(same(first)));
  });

  test('14. modifica RealEvent aggiorna ID corretto senza cambiare giorno', () {
    final day = DateTime(2022, 7, 6);
    final realStore = RealEventStore();
    final aliceStore = AliceSpecialEventStore();
    final record = _real(id: 'real-edit', day: day);
    realStore.addEvent(record);
    final item = builder.fromRealEvent(event: record, day: day);

    final saved = HomeEventNoteUpdater(
      realEventStore: realStore,
      aliceSpecialEventStore: aliceStore,
    ).update(item, 'nota aggiornata');

    expect(saved, isTrue);
    expect(realStore.eventsForDay(day).single.notes, 'nota aggiornata');
    expect(realStore.eventsForDay(DateTime(2026, 7, 6)), isEmpty);
  });

  test('15. modifica Alice salva sul giorno e record corretti', () {
    final day = DateTime(2031, 1, 4);
    final realStore = RealEventStore();
    final aliceStore = AliceSpecialEventStore();
    final target = _alice(id: 'alice-target', day: day);
    final other = _alice(id: 'alice-other', day: day);
    aliceStore.replaceEventsForDay(day, [target, other]);
    final item = builder.fromAliceSpecialEvent(event: target, day: day);

    final saved = HomeEventNoteUpdater(
      realEventStore: realStore,
      aliceSpecialEventStore: aliceStore,
    ).update(item, 'solo target');

    final events = aliceStore.eventsForDay(day);
    expect(saved, isTrue);
    expect(
      events.singleWhere((event) => event.id == target.id).note,
      'solo target',
    );
    expect(events.singleWhere((event) => event.id == other.id).note, 'nota');
  });

  test('16. stesso titolo non confonde due ID differenti', () {
    final day = DateTime(2026, 8, 3);
    final items = builder.forDay(
      day: day,
      realEvents: [
        _real(id: 'one', day: day, title: 'Titolo uguale'),
        _real(id: 'two', day: day, title: 'Titolo uguale'),
      ],
      aliceSpecialEvents: const [],
    );

    expect(items.map((event) => event.id).toSet(), {'one', 'two'});
    expect(items.map((event) => event.realEventRecord!.id).toSet(), {
      'one',
      'two',
    });
  });

  test('17. formattazione UI di data e orario resta invariata', () {
    final day = DateTime(2026, 8, 3);
    final item = builder.fromRealEvent(
      event: _real(id: 'formatted', day: day, startHour: 9, endHour: 10),
      day: day,
    );

    expect(HomeEventFormatter.time(item), '09:00-10:00');
    expect(
      HomeEventFormatter.tileTime(
        item,
        dateStyle: HomeEventDateLabelStyle.dayMonthYear,
      ),
      '3/8/2026 • 09:00-10:00',
    );
    expect(HomeEventFormatter.readableDay(day), 'Lunedì 3 Agosto');
  });

  test('18-20. percorso decisionale Home non interpreta testo visuale', () {
    final source = File('lib/screens/home_screen.dart').readAsStringSync();
    final detailStart = source.indexOf('Future<void> _showEventDetailPopup');
    final detailEnd = source.indexOf('Widget _buildOggiDialogContent');
    final eventPath = source.substring(detailStart, detailEnd);

    expect(eventPath, isNot(contains('.split("/")')));
    expect(eventPath, isNot(contains('.split("•")')));
    expect(eventPath, isNot(contains('DateTime.now().year')));
    expect(eventPath, isNot(contains('event.time')));
  });

  test('21. navigazione Home verso Calendario resta tipizzata e invariata', () {
    final source = File('lib/screens/home_screen.dart').readAsStringSync();
    final navigationStart = source.indexOf('Future<void> _openCalendarToday');
    final navigationEnd = source.indexOf('List<Promemoria>');
    final navigation = source.substring(navigationStart, navigationEnd);

    expect(navigation, contains('CalendarioScreenStepAStabile'));
    expect(navigation, contains('initialSelectedDay: today'));
  });

  test('22. builder non dipende dalla Home né da contesto o tema', () {
    final source = File(
      'lib/models/home_event_view_model.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('home_screen.dart')));
    expect(source, isNot(contains('BuildContext')));
    expect(source, isNot(contains('Widget')));
    expect(source, isNot(contains('Color')));
    expect(source, isNot(contains('IconData')));
    expect(source, isNot(contains('DateTime.now')));
    expect(source, isNot(contains('.name')));
  });
}

RealEvent _real({
  required String id,
  required DateTime day,
  String title = 'Evento',
  int? startHour,
  int startMinute = 0,
  int? endHour,
  int endMinute = 0,
  List<String> participantKeys = const [],
}) {
  return RealEvent(
    id: id,
    startDate: day,
    endDate: day,
    title: title,
    startTime: startHour == null
        ? null
        : TimeOfDay(hour: startHour, minute: startMinute),
    endTime: endHour == null
        ? null
        : TimeOfDay(hour: endHour, minute: endMinute),
    participantKeys: participantKeys,
  );
}

AliceSpecialEvent _alice({required String id, required DateTime day}) {
  return AliceSpecialEvent(
    id: id,
    label: 'Evento Alice',
    category: AliceSpecialEventCategory.activity,
    behavior: AliceEventBehavior.logistic,
    date: day,
    start: const TimeOfDay(hour: 16, minute: 30),
    end: const TimeOfDay(hour: 18, minute: 0),
    note: 'nota',
  );
}
