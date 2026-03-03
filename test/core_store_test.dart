// test/core_store_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/core_store.dart';

void main() {
  test('CoreStore crea WeekStore e weekStart è lunedì', () {
    final core = CoreStore(initialDate: DateTime(2026, 2, 25)); // mercoledì
    final weekStart = core.weekStore.activeWeek.weekStart;

    expect(weekStart.weekday, DateTime.monday);
    expect(weekStart.hour, 0);
    expect(weekStart.minute, 0);
  });
}
