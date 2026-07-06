import '../../models/frodo_observation.dart';

/// Contratto comune per tutti i moduli che vogliono
/// produrre osservazioni.
///
/// Ogni modulo di FrodoDesk implementerà questa interfaccia.
abstract class ObservationProvider {
  const ObservationProvider();

  List<FrodoObservation> buildObservations();
}
