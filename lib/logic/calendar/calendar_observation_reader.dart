import '../../models/frodo_observation.dart';
import 'calendar_day_snapshot.dart';

class CalendarObservationReader {
  static List<FrodoObservation> read(CalendarDaySnapshot snapshot) {
    return snapshot.observations;
  }
}
