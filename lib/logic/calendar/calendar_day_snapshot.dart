import '../../models/frodo_observation.dart';

class CalendarDaySnapshot {
  final DateTime day;
  final DateTime realNow;

  final List<FrodoObservation> observations;

  const CalendarDaySnapshot({
    required this.day,
    required this.realNow,
    this.observations = const [],
  });

  bool get hasObservations => observations.isNotEmpty;
}
