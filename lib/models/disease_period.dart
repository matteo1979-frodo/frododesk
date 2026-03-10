enum DiseaseType {
  mild, // malattia leggera
  bed, // malattia a letto
}

class DiseasePeriod {
  final String personId;
  final DiseaseType type;
  final DateTime startDate;
  final DateTime endDate;

  const DiseasePeriod({
    required this.personId,
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  /// Controlla se una data è dentro il periodo (inclusivo)
  bool containsDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return !d.isBefore(start) && !d.isAfter(end);
  }
}
