import '../models/frodo_observation.dart';
import '../logic/observations/observation_engine.dart';

class HomeStore {
  final ObservationEngine observationEngine;

  List<FrodoObservation> _observations = [];

  HomeStore({ObservationEngine? observationEngine})
    : observationEngine = observationEngine ?? const ObservationEngine();

  List<FrodoObservation> get observations => List.unmodifiable(_observations);

  void updateObservations(List<FrodoObservation> observations) {
    _observations = observationEngine.prioritize(observations);
  }

  void addObservations(List<FrodoObservation> observations) {
    updateObservations([..._observations, ...observations]);
  }

  void clearObservations() {
    _observations = [];
  }

  bool get hasObservations => _observations.isNotEmpty;
}
