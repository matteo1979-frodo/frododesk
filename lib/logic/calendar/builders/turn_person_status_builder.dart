import '../../../models/day_override.dart';
import '../../../models/disease_period.dart';

class TurnPersonStatusBuilder {
  const TurnPersonStatusBuilder();

  String? build({
    required PersonDayOverride? manualOverride,
    required DiseasePeriod? diseasePeriod,
    required bool isOnHoliday,
    required String? turnOverrideStatusText,
  }) {
    if (turnOverrideStatusText != null) {
      return turnOverrideStatusText;
    }

    if (manualOverride != null) {
      switch (manualOverride.status) {
        case OverrideStatus.normal:
          break;

        case OverrideStatus.permesso:
          final range = manualOverride.permessoRange;

          if (range != null) {
            return "Permesso ${range.toDisplayString()}";
          }

          return "Permesso";

        case OverrideStatus.ferie:
          return "Ferie";

        case OverrideStatus.malattiaLeggera:
          return "Malattia leggera";

        case OverrideStatus.malattiaALetto:
          return "Malattia a letto";
      }
    }

    if (diseasePeriod != null) {
      switch (diseasePeriod.type) {
        case DiseaseType.mild:
          return "Malattia leggera";

        case DiseaseType.bed:
          return "Malattia a letto";
      }
    }

    if (isOnHoliday) {
      return "Ferie";
    }

    return null;
  }
}