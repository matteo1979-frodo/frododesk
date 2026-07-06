import '../../models/frodo_observation.dart';

/// ObservationEngine
///
/// Scopo:
/// Decidere QUALI osservazioni meritano di essere mostrate
/// nella Home di FrodoDesk.
///
/// Non crea Widget.
/// Non prende decisioni economiche.
/// Non modifica dati.
///
/// Riceve osservazioni già prodotte dai vari moduli
/// (Finanze, Calendario, Copertura, ecc.)
/// e le ordina secondo la loro importanza.
class ObservationEngine {
  const ObservationEngine();

  List<FrodoObservation> prioritize(List<FrodoObservation> observations) {
    final result = [...observations];

    result.sort(_compare);

    return result;
  }

  int _compare(FrodoObservation a, FrodoObservation b) {
    final levelCompare = _levelWeight(b.level).compareTo(_levelWeight(a.level));

    if (levelCompare != 0) {
      return levelCompare;
    }

    return b.priority.compareTo(a.priority);
  }

  int _levelWeight(FrodoObservationLevel level) {
    switch (level) {
      case FrodoObservationLevel.problem:
        return 5;

      case FrodoObservationLevel.attention:
        return 4;

      case FrodoObservationLevel.opportunity:
        return 3;

      case FrodoObservationLevel.success:
        return 2;

      case FrodoObservationLevel.info:
        return 1;
    }
  }
}
