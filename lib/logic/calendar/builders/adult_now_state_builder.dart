import '../models/adult_now_state.dart';
import 'person_effective_status_builder.dart';

class AdultNowStateBuilder {
  const AdultNowStateBuilder();

  AdultNowState build({
    required bool isMildSick,
    required bool isBusyForEventNow,
    required bool isBusyForTurn,
    required bool isBedSick,
    required bool isOnHoliday,
    required String turnLabel,
  }) {
    const effectiveStatusBuilder = PersonEffectiveStatusBuilder();

    final isBusyNow = effectiveStatusBuilder.isBusyNow(
      isBedSick: isBedSick,
      isBusyForEvent: isBusyForEventNow,
      isBusyForTurn: isBusyForTurn,
    );

    final nowLabel = effectiveStatusBuilder.buildNowLabel(
      isMildSick: isMildSick,
      isBedSick: isBedSick,
      isOnHoliday: isOnHoliday,
      isBusyForEvent: isBusyForEventNow,
      isBusyForTurn: isBusyForTurn,
    );

    return AdultNowState(
      isBusyNow: isBusyNow,
      isBusyForEventNow: isBusyForEventNow,
      isBusyForTurn: isBusyForTurn,
      isBedSick: isBedSick,
      isOnHoliday: isOnHoliday,
      nowLabel: nowLabel,
      turnLabel: turnLabel,
    );
  }
}
