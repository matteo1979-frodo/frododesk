import 'person_effective_status.dart';

class FamilyDayOverviewSnapshot {
  final DateTime day;

  final PersonEffectiveStatus matteoEffectiveStatus;
  final PersonEffectiveStatus chiaraEffectiveStatus;

  final String matteoTurnLabel;
  final String chiaraTurnLabel;

  const FamilyDayOverviewSnapshot({
    required this.day,
    required this.matteoEffectiveStatus,
    required this.chiaraEffectiveStatus,
    required this.matteoTurnLabel,
    required this.chiaraTurnLabel,
  });
}
