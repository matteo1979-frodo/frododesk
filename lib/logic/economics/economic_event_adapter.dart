import '../../models/economic_event.dart';

abstract interface class EconomicEventAdapter<T> {
  EconomicEvent adapt(
    T source, {
    required DateTime observedAt,
    String? eventId,
  });
}
