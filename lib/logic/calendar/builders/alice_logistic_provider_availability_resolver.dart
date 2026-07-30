import 'package:flutter/material.dart';

import '../../../models/day_override.dart';
import '../../../models/support_person.dart';
import '../../adult_logistics_availability_resolver.dart';
import '../../day_settings_store.dart';
import '../../ferie_period_store.dart';
import '../../support_network_store.dart';
import '../../turn_engine.dart';
import '../models/alice_summer_camp_logistics.dart';

class AliceSandraAvailabilityWindow {
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  const AliceSandraAvailabilityWindow({
    required this.enabled,
    required this.start,
    required this.end,
  });
}

class AliceLogisticProviderAvailabilityResolver {
  final AdultLogisticsAvailabilityResolver adultResolver;
  final DaySettingsStore daySettingsStore;
  final SupportNetworkStore supportNetworkStore;

  const AliceLogisticProviderAvailabilityResolver({
    required this.adultResolver,
    required this.daySettingsStore,
    required this.supportNetworkStore,
  });

  List<AliceLogisticProviderAvailability> resolve({
    required DateTime day,
    required DateTime start,
    required DateTime end,
    required DayOverrides overrides,
    required List<AliceSandraAvailabilityWindow> sandraWindows,
    FeriePeriodStore? ferieStore,
  }) {
    final values = <AliceLogisticProviderAvailability>[
      _adult(AliceLogisticParent.matteo, TurnPerson.matteo, day, start, end, overrides, ferieStore),
      _adult(AliceLogisticParent.chiara, TurnPerson.chiara, day, start, end, overrides, ferieStore),
      AliceLogisticProviderAvailability(
        provider: AliceLogisticProviderRef.sandra,
        start: start,
        end: end,
        available: sandraWindows.any((window) => window.enabled && _slotCovers(day, window.start, window.end, start, end)),
      ),
    ];
    final people = [...supportNetworkStore.people]..sort((a, b) => a.id.compareTo(b.id));
    for (final person in people) {
      values.add(AliceLogisticProviderAvailability(
        provider: AliceLogisticProviderRef.supportPerson(person.id),
        start: start,
        end: end,
        available: _supportCovers(person, day, start, end),
      ));
    }
    return values;
  }

  AliceLogisticProviderAvailability _adult(
    AliceLogisticParent parent,
    TurnPerson person,
    DateTime day,
    DateTime start,
    DateTime end,
    DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  ) => AliceLogisticProviderAvailability(
    provider: AliceLogisticProviderRef.parent(parent),
    start: start,
    end: end,
    available: adultResolver.canCoverRange(
      personKey: parent.name,
      person: person,
      day: day,
      start: start,
      end: end,
      isHomePresenceWindow: false,
      overrides: overrides,
      ferieStore: ferieStore,
    ),
  );

  bool _supportCovers(SupportPerson person, DateTime day, DateTime start, DateTime end) =>
      person.enabled &&
      daySettingsStore.isSupportPersonEnabledForDay(day, person.id) &&
      person.effectiveSlots.any((slot) => _slotCovers(day, slot.start, slot.end, start, end));

  bool _slotCovers(DateTime day, TimeOfDay slotStart, TimeOfDay slotEnd, DateTime start, DateTime end) {
    final a = DateTime(day.year, day.month, day.day, slotStart.hour, slotStart.minute);
    final b = DateTime(day.year, day.month, day.day, slotEnd.hour, slotEnd.minute);
    return !a.isAfter(start) && !b.isBefore(end);
  }
}
