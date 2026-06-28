import '../../models/frodo_observation.dart';

abstract class ObservationProvider {
  String get module;

  List<FrodoObservation> generate();
}
