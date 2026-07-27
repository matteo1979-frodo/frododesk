import '../../../utils/status_visual.dart';
import '../../real_event_store.dart';
import '../models/adult_now_state.dart';
import '../models/alice_now_state.dart';
import '../models/coverage_result_step_a.dart';
import '../models/family_now_snapshot.dart';

class FamilyNowSnapshotBuilder {
  const FamilyNowSnapshotBuilder();

  FamilyNowSnapshot build({
    required DateTime realNow,
    required DateTime now,
    required DateTime nowDay,
    required RealEventStore realEventStore,
    required AdultNowState matteo,
    required AdultNowState chiara,
    required AliceNowState alice,
    required CoverageResultStepA coverage,
    required bool isEmergency,
    required bool showSummerCampSpecialCard,
    required int ipsCoverage30,
    required StatusVisual matteoVisual,
    required StatusVisual chiaraVisual,
  }) {
    return FamilyNowSnapshot(
      realNow: realNow,
      now: now,
      realEventStore: realEventStore,
      nowDay: nowDay,
      matteoBusyNow: matteo.isBusyNow,
      chiaraBusyNow: chiara.isBusyNow,
      aliceIsOutNow: alice.isOutNow,
      matteoNowLabel: matteo.nowLabel,
      chiaraNowLabel: chiara.nowLabel,
      aliceNowLabel: alice.nowLabel,
      matteoTurnLabel: matteo.turnLabel,
      chiaraTurnLabel: chiara.turnLabel,
      cov: coverage,
      isEmergency: isEmergency,
      showSummerCampSpecialCard: showSummerCampSpecialCard,
      ipsCoverage30: ipsCoverage30,
      matteoVisual: matteoVisual,
      chiaraVisual: chiaraVisual,
      aliceVisual: alice.visual,
    );
  }
}
