import '../models/adult_now_state.dart';
import 'person_effective_status_builder.dart';
import '../models/person_effective_status.dart';

class AdultNowStateBuilder {
  const AdultNowStateBuilder();

  AdultNowState build({
    required bool isBusyForEventNow,
    required bool isBusyForTurn,
    required PersonEffectiveStatus effectiveStatus,
    required String turnLabel,
  }) {
    const effectiveStatusBuilder = PersonEffectiveStatusBuilder();

    final isBusyNow = effectiveStatusBuilder.isBusyNow(
      isBedSick: effectiveStatus.isBedSick,
      isBusyForEvent: isBusyForEventNow,
      isBusyForTurn: isBusyForTurn,
    );

    final nowLabel = effectiveStatusBuilder.buildNowLabel(
      isMildSick: effectiveStatus.isMildSick,
      isBedSick: effectiveStatus.isBedSick,
      isOnHoliday: effectiveStatus.isOnHoliday,
      isBusyForEvent: isBusyForEventNow,
      isBusyForTurn: isBusyForTurn,
    );

    return AdultNowState(
      isBusyNow: isBusyNow,
      isBusyForEventNow: isBusyForEventNow,
      isBusyForTurn: isBusyForTurn,
      isBedSick: effectiveStatus.isBedSick,
      isOnHoliday: effectiveStatus.isOnHoliday,
      nowLabel: nowLabel,
      turnLabel: turnLabel,
    );
  }
}
