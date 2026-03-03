// lib/logic/fourth_squad_store.dart
//
// FRODODESK — Fourth Squad Store (stato reale)
// Stato minimale e deterministico per attivare/disattivare la "Quarta Squadra"
// separatamente per Matteo e Chiara, con start-week configurabile.

enum PersonId { matteo, chiara }

// -----------------
// Helpers date (TOP LEVEL)
// -----------------

DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _mondayOf(DateTime d) {
  final dd = _onlyDate(d);
  final delta = dd.weekday - DateTime.monday;
  return dd.subtract(Duration(days: delta));
}

class FourthSquadState {
  final bool enabled;
  final DateTime? anchorMonday;
  final int startWeekIndex; // 1..4

  const FourthSquadState._({
    required this.enabled,
    required this.anchorMonday,
    required this.startWeekIndex,
  });

  factory FourthSquadState.disabled() {
    return const FourthSquadState._(
      enabled: false,
      anchorMonday: null,
      startWeekIndex: 1,
    );
  }

  factory FourthSquadState.enabled({
    required DateTime anchorMonday,
    required int startWeekIndex,
  }) {
    final a = _onlyDate(anchorMonday);
    if (a.weekday != DateTime.monday) {
      throw ArgumentError('anchorMonday deve essere un LUNEDÌ');
    }

    final s = startWeekIndex.clamp(1, 4);

    return FourthSquadState._(
      enabled: true,
      anchorMonday: a,
      startWeekIndex: s,
    );
  }

  FourthSquadState copyWith({
    bool? enabled,
    DateTime? anchorMonday,
    int? startWeekIndex,
  }) {
    return FourthSquadState._(
      enabled: enabled ?? this.enabled,
      anchorMonday: anchorMonday ?? this.anchorMonday,
      startWeekIndex: (startWeekIndex ?? this.startWeekIndex).clamp(1, 4),
    );
  }

  @override
  String toString() {
    return 'FourthSquadState(enabled: $enabled, anchorMonday: $anchorMonday, startWeekIndex: $startWeekIndex)';
  }
}

class FourthSquadStore {
  final Map<PersonId, FourthSquadState> _byPerson = {
    PersonId.matteo: FourthSquadState.disabled(),
    PersonId.chiara: FourthSquadState.disabled(),
  };

  FourthSquadState stateOf(PersonId person) => _byPerson[person]!;

  bool isEnabled(PersonId person) => stateOf(person).enabled;

  void enable({
    required PersonId person,
    required DateTime anchorMonday,
    required int startWeekIndex,
  }) {
    _byPerson[person] = FourthSquadState.enabled(
      anchorMonday: _onlyDate(anchorMonday),
      startWeekIndex: startWeekIndex,
    );
  }

  void disable(PersonId person) {
    _byPerson[person] = FourthSquadState.disabled();
  }

  int? weekIndexForDay(PersonId person, DateTime day) {
    final st = stateOf(person);
    if (!st.enabled || st.anchorMonday == null) return null;

    final dMon = _mondayOf(day);
    final aMon = st.anchorMonday!;

    final diffDays = _onlyDate(dMon).difference(_onlyDate(aMon)).inDays;
    final weeks = diffDays ~/ 7;

    final zeroBased = (st.startWeekIndex - 1) + weeks;
    final idx0 = ((zeroBased % 4) + 4) % 4;
    return idx0 + 1;
  }
}
