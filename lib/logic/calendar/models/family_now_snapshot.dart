class FamilyNowSnapshot {
  final DateTime realNow;
  final DateTime now;

  final bool matteoBusyNow;
  final bool chiaraBusyNow;
  final bool aliceIsOutNow;

  final String matteoNowLabel;
  final String chiaraNowLabel;
  final String aliceNowLabel;

  final String matteoTurnLabel;
  final String chiaraTurnLabel;

  const FamilyNowSnapshot({
    required this.realNow,
    required this.now,
    required this.matteoBusyNow,
    required this.chiaraBusyNow,
    required this.aliceIsOutNow,
    required this.matteoNowLabel,
    required this.chiaraNowLabel,
    required this.aliceNowLabel,
    required this.matteoTurnLabel,
    required this.chiaraTurnLabel,
  });
}
