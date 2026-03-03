// lib/logic/turn_pattern_fourth_squad.dart
//
// FRODODESK - Fourth Squad Turn Pattern (LOGICA PURA)
//
// Pattern ciclico 4 settimane (durata indefinita finché attivo).
// ✅ Start week configurabile (1..4): puoi partire da settimana 1, 2, 3 o 4.
// ✅ Nessuna dipendenza da CoverageEngine.
// ✅ Nessuna UI. Nessuna persistenza.
// Solo: dato un giorno, ti dice che tipo di turno è in Quarta Squadra.
//
// Schema ufficiale:
// Week 1: 6 mattine (Lun–Sab), Dom OFF
// Week 2: 2 pomeriggi (Lun–Mar), Mer OFF, 3 notti (Gio–Sab notte)
// Week 3: 4 pomeriggi (Mer–Sab), resto OFF
// Week 4: 3 notti (Lun–Mer notte), resto OFF
//
// Nota: "notte Sab" = turno notte che parte Sab sera e finisce Dom mattina (cross-day).

enum FourthSquadShiftType { morning, afternoon, night, off }

class FourthSquadPattern {
  /// Ritorna il turno Quarta Squadra per [day].
  ///
  /// [cycleRefMonday] = un lunedì di riferimento per "ancorare" il ciclo.
  /// [startWeek] = 1..4 (default 1). Serve per far partire il ciclo da una settimana diversa.
  ///
  /// Esempio: se l'azienda "parte" dalla settimana 2, imposti startWeek=2.
  static FourthSquadShiftType shiftForDay({
    required DateTime day,
    required DateTime cycleRefMonday,
    required int startWeek,
  }) {
    final d0 = _onlyDate(day);
    final refMon = _mondayOf(cycleRefMonday);
    final dayMon = _mondayOf(d0);

    final weeks = _weeksBetween(refMon, dayMon);

    // baseWeek: 1..4 (ciclo naturale)
    final baseWeek = ((weeks % 4) + 4) % 4 + 1;

    // startWeek: 1..4
    final sw = _clampStartWeek(startWeek);

    // offset: se startWeek=2, allora "week 2" diventa week1 del ciclo visibile
    // cioè: visibleWeek = baseWeek - (startWeek-1)  (con wrap 1..4)
    final visibleWeek = _wrap1to4(baseWeek - (sw - 1));

    return _shiftForVisibleWeekAndWeekday(
      visibleWeek: visibleWeek,
      weekday: d0.weekday, // 1=Mon ... 7=Sun
    );
  }

  // -----------------------
  // Internals
  // -----------------------

  static FourthSquadShiftType _shiftForVisibleWeekAndWeekday({
    required int visibleWeek, // 1..4
    required int weekday, // 1..7
  }) {
    // Week 1: 6 mattine (Mon-Sat), Sun off
    if (visibleWeek == 1) {
      if (weekday >= DateTime.monday && weekday <= DateTime.saturday) {
        return FourthSquadShiftType.morning;
      }
      return FourthSquadShiftType.off;
    }

    // Week 2: Mon-Tue afternoon, Wed off, Thu-Sat night, Sun off
    if (visibleWeek == 2) {
      if (weekday == DateTime.monday || weekday == DateTime.tuesday) {
        return FourthSquadShiftType.afternoon;
      }
      if (weekday == DateTime.wednesday) {
        return FourthSquadShiftType.off;
      }
      if (weekday == DateTime.thursday ||
          weekday == DateTime.friday ||
          weekday == DateTime.saturday) {
        return FourthSquadShiftType.night;
      }
      return FourthSquadShiftType.off; // Sunday
    }

    // Week 3: 4 afternoons (Wed-Sat), rest off
    if (visibleWeek == 3) {
      if (weekday == DateTime.wednesday ||
          weekday == DateTime.thursday ||
          weekday == DateTime.friday ||
          weekday == DateTime.saturday) {
        return FourthSquadShiftType.afternoon;
      }
      return FourthSquadShiftType.off;
    }

    // Week 4: 3 nights (Mon-Wed), rest off
    // ("3 notti da lun" = lun, mar, mer notte)
    if (visibleWeek == 4) {
      if (weekday == DateTime.monday ||
          weekday == DateTime.tuesday ||
          weekday == DateTime.wednesday) {
        return FourthSquadShiftType.night;
      }
      return FourthSquadShiftType.off;
    }

    return FourthSquadShiftType.off;
  }

  static int _clampStartWeek(int v) {
    if (v < 1) return 1;
    if (v > 4) return 4;
    return v;
  }

  static int _wrap1to4(int v) {
    // Wrap in range 1..4
    final x = ((v - 1) % 4 + 4) % 4; // 0..3
    return x + 1;
  }

  static DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _mondayOf(DateTime d) {
    final sd = _onlyDate(d);
    final delta = sd.weekday - DateTime.monday;
    return sd.subtract(Duration(days: delta));
  }

  static int _weeksBetween(DateTime aMonday, DateTime bMonday) {
    final a = _onlyDate(aMonday);
    final b = _onlyDate(bMonday);
    final diffDays = b.difference(a).inDays;
    return diffDays ~/ 7;
  }
}
