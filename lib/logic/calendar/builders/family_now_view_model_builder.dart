import '../models/family_now_snapshot.dart';
import '../view_models/family_member_now_view_model.dart';
import '../view_models/family_now_view_model.dart';

class FamilyNowViewModelBuilder {
  const FamilyNowViewModelBuilder();

  FamilyNowViewModel build(FamilyNowSnapshot snapshot) {
    return FamilyNowViewModel(
      matteo: FamilyMemberNowViewModel(
        name: 'Matteo',
        label: snapshot.matteoNowLabel,
        visual: snapshot.matteoVisual,
        busy: snapshot.matteoBusyNow,
        isAlice: false,
        turnLabel: snapshot.matteoTurnLabel,
      ),
      chiara: FamilyMemberNowViewModel(
        name: 'Chiara',
        label: snapshot.chiaraNowLabel,
        visual: snapshot.chiaraVisual,
        busy: snapshot.chiaraBusyNow,
        isAlice: false,
        turnLabel: snapshot.chiaraTurnLabel,
      ),
      alice: FamilyMemberNowViewModel(
        name: 'Alice',
        label: snapshot.aliceNowLabel,
        visual: snapshot.aliceVisual,
        busy: snapshot.aliceIsOutNow,
        isAlice: true,
      ),
      emergency: snapshot.isEmergency,
    );
  }
}
