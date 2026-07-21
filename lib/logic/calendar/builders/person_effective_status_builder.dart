import '../../../models/day_override.dart';
import '../../../models/disease_period.dart';

class PersonEffectiveStatusBuilder {
  const PersonEffectiveStatusBuilder();

  bool isBedSick({
    required PersonDayOverride? manualOverride,
    required DiseasePeriod? diseasePeriod,
  }) {
    return manualOverride?.status == OverrideStatus.malattiaALetto ||
        diseasePeriod?.type == DiseaseType.bed;
  }

  bool isMildSick({
    required PersonDayOverride? manualOverride,
    required DiseasePeriod? diseasePeriod,
  }) {
    return manualOverride?.status == OverrideStatus.malattiaLeggera ||
        diseasePeriod?.type == DiseaseType.mild;
  }

  bool isSick({
    required PersonDayOverride? manualOverride,
    required DiseasePeriod? diseasePeriod,
  }) {
    return isMildSick(
          manualOverride: manualOverride,
          diseasePeriod: diseasePeriod,
        ) ||
        isBedSick(manualOverride: manualOverride, diseasePeriod: diseasePeriod);
  }

  bool isOnHoliday({
    required PersonDayOverride? manualOverride,
    required bool isInHolidayPeriod,
  }) {
    return manualOverride?.status == OverrideStatus.ferie || isInHolidayPeriod;
  }

  String buildNowLabel({
    required bool isMildSick,
    required bool isBedSick,
    required bool isOnHoliday,
    required bool isBusyForEvent,
    required bool isBusyForTurn,
  }) {
    if (isMildSick) {
      return "malattia leggera";
    }

    if (isBedSick) {
      return "occupato • malattia a letto";
    }

    if (isOnHoliday) {
      return "libero • ferie";
    }

    if (isBusyForEvent) {
      return "occupato • evento";
    }

    if (isBusyForTurn) {
      return "occupato • turno";
    }

    return "libero";
  }

  String buildNowTurnLabel({
    required bool isOff,
    required String startText,
    required String endText,
  }) {
    if (isOff) {
      return "Turno non previsto";
    }

    return "Turno $startText–$endText";
  }

  bool isBusyNow({
    required bool isBedSick,
    required bool isBusyForEvent,
    required bool isBusyForTurn,
  }) {
    return isBedSick || isBusyForEvent || isBusyForTurn;
  }
}
