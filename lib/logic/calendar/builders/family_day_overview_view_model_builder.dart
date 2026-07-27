import '../models/family_day_overview_snapshot.dart';
import '../models/person_effective_status.dart';
import '../view_models/alice_day_overview_view_model.dart';
import '../view_models/family_day_overview_view_model.dart';
import '../view_models/family_member_day_overview_view_model.dart';

class FamilyDayOverviewViewModelBuilder {
  const FamilyDayOverviewViewModelBuilder();

  FamilyDayOverviewViewModel build(FamilyDayOverviewSnapshot snapshot) {
    return FamilyDayOverviewViewModel(
      day: snapshot.day,
      matteo: FamilyMemberDayOverviewViewModel(
        name: 'Matteo',
        statusLabel: _statusLabel(snapshot.matteoEffectiveStatus),
        turnLabel: snapshot.matteoTurnLabel,
      ),
      chiara: FamilyMemberDayOverviewViewModel(
        name: 'Chiara',
        statusLabel: _statusLabel(snapshot.chiaraEffectiveStatus),
        turnLabel: snapshot.chiaraTurnLabel,
      ),
      alice: AliceDayOverviewViewModel(
        name: 'Alice',
        statusLabel:
            snapshot.aliceDayContext.dayStateLabel ?? 'Giornata ordinaria',
      ),
    );
  }

  String _statusLabel(PersonEffectiveStatus status) {
    if (status.isBedSick) {
      return 'Malattia a letto';
    }

    if (status.isMildSick) {
      return 'Malattia leggera';
    }

    if (status.isOnHoliday) {
      return 'Ferie';
    }

    return 'Giornata ordinaria';
  }
}
