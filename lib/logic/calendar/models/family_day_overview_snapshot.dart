import 'person_effective_status.dart';
import 'alice_day_context.dart';

class FamilyDayOverviewSnapshot {
  final DateTime day;

  final PersonEffectiveStatus matteoEffectiveStatus;
  final PersonEffectiveStatus chiaraEffectiveStatus;

  final String matteoTurnLabel;
  final String chiaraTurnLabel;

  final AliceDayContext aliceDayContext;

  const FamilyDayOverviewSnapshot({
    required this.day,
    required this.matteoEffectiveStatus,
    required this.chiaraEffectiveStatus,
    required this.matteoTurnLabel,
    required this.chiaraTurnLabel,
    required this.aliceDayContext,
  });
}
