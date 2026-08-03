import '../../../models/alice_special_event.dart';
import '../../../models/day_override.dart';
import '../../ferie_period_store.dart';
import '../models/alice_event_logistics.dart';
import 'alice_event_logistics_builder.dart';
import 'alice_logistic_provider_availability_resolver.dart';

class AliceEventLogisticsCoordinator {
  static const _transferDuration = Duration(minutes: 20);

  final AliceLogisticProviderAvailabilityResolver availabilityResolver;
  final AliceEventLogisticsBuilder logisticsBuilder;

  const AliceEventLogisticsCoordinator({
    required this.availabilityResolver,
    this.logisticsBuilder = const AliceEventLogisticsBuilder(),
  });

  AliceEventLogisticsResolution resolve({
    required DateTime day,
    required AliceSpecialEvent event,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final eventStart = _at(day, event.start.hour, event.start.minute);
    final eventEnd = _at(day, event.end.hour, event.end.minute);
    final outboundStart = eventStart.subtract(_transferDuration);
    final returnEnd = eventEnd.add(_transferDuration);

    return logisticsBuilder.build(
      event: event,
      outboundStart: outboundStart,
      outboundEnd: eventStart,
      returnStart: eventEnd,
      returnEnd: returnEnd,
      outboundAvailabilities: availabilityResolver.resolve(
        day: day,
        start: outboundStart,
        end: eventStart,
        overrides: overrides,
        ferieStore: ferieStore,
      ),
      returnAvailabilities: availabilityResolver.resolve(
        day: day,
        start: eventEnd,
        end: returnEnd,
        overrides: overrides,
        ferieStore: ferieStore,
      ),
    );
  }

  DateTime _at(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);
}
