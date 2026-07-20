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
}
