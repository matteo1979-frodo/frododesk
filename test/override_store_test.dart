// test/override_store_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:frododesk/logic/override_store.dart';
import 'package:frododesk/models/day_override.dart';

void main() {
  test('OverrideStore: salva e recupera override per giorno', () {
    final store = OverrideStore();

    final day = DateTime(2026, 2, 21, 15, 30); // orario qualsiasi
    expect(store.hasOverride(day), false);

    // 1) all'inizio: deve tornare "vuoto"
    final before = store.getForDay(day);
    expect(before.day, dayKey(day));
    expect(before.matteo, null);
    expect(before.chiara, null);

    // 2) salvo un override finto per Matteo: FERIE
    final fake = DayOverrides(
      day: dayKey(day),
      matteo: PersonDayOverride(status: OverrideStatus.ferie),
    );

    store.setForDay(day, fake);

    // 3) ora deve esistere e recuperarlo identico
    expect(store.hasOverride(day), true);

    final after = store.getForDay(
      DateTime(2026, 2, 21, 8, 0),
    ); // stesso giorno, altro orario
    expect(after.day, dayKey(day));
    expect(after.matteo?.status, OverrideStatus.ferie);
    expect(after.chiara, null);

    // 4) pulisco e torno al default
    store.clearDay(day);
    expect(store.hasOverride(day), false);

    final finalRead = store.getForDay(day);
    expect(finalRead.matteo, null);
    expect(finalRead.chiara, null);
  });

  test('PersonDayOverride: permesso richiede range', () {
    expect(
      () => PersonDayOverride(status: OverrideStatus.permesso),
      throwsArgumentError,
    );

    final ok = PersonDayOverride(
      status: OverrideStatus.permesso,
      permessoRange: TimeRangeMinutes(startMin: 9 * 60, endMin: 12 * 60),
    );

    expect(ok.status, OverrideStatus.permesso);
    expect(ok.permessoRange?.startMin, 9 * 60);
  });
}
