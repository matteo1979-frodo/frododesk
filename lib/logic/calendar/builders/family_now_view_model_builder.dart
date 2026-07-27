import '../../../utils/status_visual.dart';
import '../models/family_now_snapshot.dart';
import '../view_models/family_member_now_view_model.dart';
import '../view_models/family_now_view_model.dart';

class FamilyNowViewModelBuilder {
  const FamilyNowViewModelBuilder();

  FamilyNowViewModel build(
    FamilyNowSnapshot snapshot, {
    required bool isEmergency,
  }) {
    return FamilyNowViewModel(
      matteo: FamilyMemberNowViewModel(
        name: 'Matteo',
        label: snapshot.matteoNowLabel,
        visual: getStatusVisual(snapshot.matteoNowLabel),
        busy: snapshot.matteoBusyNow,
        isAlice: false,
        turnLabel: snapshot.matteoTurnLabel,
      ),
      chiara: FamilyMemberNowViewModel(
        name: 'Chiara',
        label: snapshot.chiaraNowLabel,
        visual: getStatusVisual(snapshot.chiaraNowLabel),
        busy: snapshot.chiaraBusyNow,
        isAlice: false,
        turnLabel: snapshot.chiaraTurnLabel,
      ),
      alice: FamilyMemberNowViewModel(
        name: 'Alice',
        label: snapshot.aliceNowLabel,
        visual: getStatusVisual(snapshot.aliceNowLabel),
        busy: snapshot.aliceIsOutNow,
        isAlice: true,
      ),
      emergency: isEmergency,
    );
  }
}
