import '../models/adult_now_state.dart';
import '../models/alice_now_state.dart';
import '../models/family_now_snapshot.dart';

class FamilyNowSnapshotBuilder {
  const FamilyNowSnapshotBuilder();

  FamilyNowSnapshot build({
    required DateTime realNow,
    required DateTime now,
    required DateTime nowDay,
    required AdultNowState matteo,
    required AdultNowState chiara,
    required AliceNowState alice,
    required bool isEmergency,
    required bool showSummerCampSpecialCard,
    required int ipsCoverage30,
  }) {
    return FamilyNowSnapshot(
      realNow: realNow,
      now: now,
      nowDay: nowDay,
      matteoBusyNow: matteo.isBusyNow,
      chiaraBusyNow: chiara.isBusyNow,
      aliceIsOutNow: alice.isOutNow,
      matteoNowLabel: matteo.nowLabel,
      chiaraNowLabel: chiara.nowLabel,
      aliceNowLabel: alice.nowLabel,
      matteoTurnLabel: matteo.turnLabel,
      chiaraTurnLabel: chiara.turnLabel,
      isEmergency: isEmergency,
      showSummerCampSpecialCard: showSummerCampSpecialCard,
      ipsCoverage30: ipsCoverage30,
    );
  }
}