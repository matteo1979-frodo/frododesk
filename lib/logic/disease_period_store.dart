import '../models/disease_period.dart';

class DiseasePeriodStore {
  final List<DiseasePeriod> _periods = [];

  List<DiseasePeriod> get all => List.unmodifiable(_periods);

  /// Aggiunge un periodo di malattia
  /// Non permette sovrapposizioni per la stessa persona
  void addPeriod(DiseasePeriod period) {
    for (final existing in _periods) {
      if (existing.personId != period.personId) continue;

      final overlaps =
          !(period.endDate.isBefore(existing.startDate) ||
              period.startDate.isAfter(existing.endDate));

      if (overlaps) {
        throw Exception('Periodo malattia sovrapposto per ${period.personId}');
      }
    }

    _periods.add(period);
  }

  /// Rimuove un periodo
  void removePeriod(DiseasePeriod period) {
    _periods.remove(period);
  }

  /// Ritorna il periodo attivo in un giorno (se esiste)
  DiseasePeriod? getPeriodForDay(String personId, DateTime day) {
    for (final p in _periods) {
      if (p.personId != personId) continue;
      if (p.containsDay(day)) {
        return p;
      }
    }
    return null;
  }

  /// Controlla se una persona è malata in un giorno
  bool isSick(String personId, DateTime day) {
    return getPeriodForDay(personId, day) != null;
  }
}
