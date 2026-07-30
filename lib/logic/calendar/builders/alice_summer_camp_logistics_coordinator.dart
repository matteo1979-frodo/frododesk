import '../../../models/day_override.dart';
import '../../day_settings_store.dart';
import '../../ferie_period_store.dart';
import '../models/alice_summer_camp_logistics.dart';
import 'alice_logistic_provider_availability_resolver.dart';
import 'alice_summer_camp_logistics_resolver.dart';

class AliceSummerCampLogisticsCoordinator {
  static const _transferDuration = Duration(minutes: 20);
  final DaySettingsStore daySettingsStore;
  final AliceLogisticProviderAvailabilityResolver availabilityResolver;
  final AliceSummerCampLogisticsResolver logisticsResolver;

  const AliceSummerCampLogisticsCoordinator({
    required this.daySettingsStore,
    required this.availabilityResolver,
    this.logisticsResolver = const AliceSummerCampLogisticsResolver(),
  });

  AliceSummerCampLogisticsResult resolveDay({
    required DateTime day,
    required bool summerCampOperational,
    required DateTime effectiveStart,
    required DateTime effectiveEnd,
    required DayOverrides overrides,
    required List<AliceSandraAvailabilityWindow> sandraWindows,
    FeriePeriodStore? ferieStore,
  }) {
    final dropAssigned = daySettingsStore.summerCampDropOffProviderForDay(day);
    final pickAssigned = daySettingsStore.summerCampPickUpProviderForDay(day);
    if (!summerCampOperational) {
      return logisticsResolver.resolve(
        summerCampOperational: false,
        effectiveStart: effectiveStart,
        effectiveEnd: effectiveEnd,
        dropOffAssignedProvider: dropAssigned,
        pickUpAssignedProvider: pickAssigned,
        dropOffAvailabilities: const [],
        pickUpAvailabilities: const [],
      );
    }
    final dropStart = effectiveStart.subtract(_transferDuration);
    final pickEnd = effectiveEnd.add(_transferDuration);
    return logisticsResolver.resolve(
      summerCampOperational: true,
      effectiveStart: effectiveStart,
      effectiveEnd: effectiveEnd,
      dropOffAssignedProvider: dropAssigned,
      pickUpAssignedProvider: pickAssigned,
      dropOffAvailabilities: availabilityResolver.resolve(
        day: day, start: dropStart, end: effectiveStart, overrides: overrides,
        sandraWindows: sandraWindows, ferieStore: ferieStore,
      ),
      pickUpAvailabilities: availabilityResolver.resolve(
        day: day, start: effectiveEnd, end: pickEnd, overrides: overrides,
        sandraWindows: sandraWindows, ferieStore: ferieStore,
      ),
    );
  }
}
