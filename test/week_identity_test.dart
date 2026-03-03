// test/week_identity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/week_identity.dart';

void main() {
  test('WeekIdentity.fromDate calcola sempre il lunedì 00:00', () {
    final w = WeekIdentity.fromDate(DateTime(2026, 2, 25, 15, 30));

    expect(w.weekStart.weekday, DateTime.monday);
    expect(w.weekStart.hour, 0);
    expect(w.weekStart.minute, 0);
    expect(w.weekStart.second, 0);
  });

  test('days genera 7 giorni consecutivi da lunedì a domenica', () {
    final w = WeekIdentity.fromDate(DateTime(2026, 2, 25));

    final d = w.days;
    expect(d.length, 7);
    expect(d.first.weekday, DateTime.monday);
    expect(d.last.weekday, DateTime.sunday);

    for (int i = 1; i < d.length; i++) {
      final diff = d[i].difference(d[i - 1]).inDays;
      expect(diff, 1);
    }
  });

  test('nextWeek e previousWeek si muovono di 7 giorni', () {
    final w = WeekIdentity.fromDate(DateTime(2026, 2, 25));
    final next = w.nextWeek();
    final prev = w.previousWeek();

    expect(next.weekStart.difference(w.weekStart).inDays, 7);
    expect(w.weekStart.difference(prev.weekStart).inDays, 7);
  });
}
