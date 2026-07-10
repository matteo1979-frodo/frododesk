import '../../../utils/status_visual.dart';
import 'coverage_result_step_a.dart';
import '../../real_event_store.dart';

class FamilyNowSnapshot {
  final DateTime realNow;
  final DateTime now;
  final RealEventStore realEventStore;
  final DateTime nowDay;

  final bool matteoBusyNow;
  final bool chiaraBusyNow;
  final bool aliceIsOutNow;

  final String matteoNowLabel;
  final String chiaraNowLabel;
  final String aliceNowLabel;

  final String matteoTurnLabel;
  final String chiaraTurnLabel;

  final CoverageResultStepA cov;

  final bool isEmergency;
  final bool showSummerCampSpecialCard;
  final int ipsCoverage30;

  final StatusVisual matteoVisual;
  final StatusVisual chiaraVisual;
  final StatusVisual aliceVisual;

  const FamilyNowSnapshot({
    required this.realNow,
    required this.now,
    required this.realEventStore,
    required this.nowDay,
    required this.matteoBusyNow,
    required this.chiaraBusyNow,
    required this.aliceIsOutNow,
    required this.matteoNowLabel,
    required this.chiaraNowLabel,
    required this.aliceNowLabel,
    required this.matteoTurnLabel,
    required this.chiaraTurnLabel,
    required this.cov,
    required this.isEmergency,
    required this.showSummerCampSpecialCard,
    required this.ipsCoverage30,
    required this.matteoVisual,
    required this.chiaraVisual,
    required this.aliceVisual,
  });
}