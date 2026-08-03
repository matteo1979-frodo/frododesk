import 'package:flutter/material.dart';

import '../../../models/day_override.dart';
import '../../adult_logistics_availability_resolver.dart';
import '../../ferie_period_store.dart';
import '../../turn_engine.dart';
import '../models/alice_summer_camp_logistics.dart';
import 'calendar_logistics_availability_resolver.dart';

class AliceLogisticProviderAvailabilityResolver {
  final AdultLogisticsAvailabilityResolver adultResolver;
  final CalendarLogisticsAvailabilityResult logisticsAvailability;

  const AliceLogisticProviderAvailabilityResolver({
    required this.adultResolver,
    required this.logisticsAvailability,
  });

  List<AliceLogisticProviderAvailability> resolve({
    required DateTime day,
    required DateTime start,
    required DateTime end,
    required DayOverrides overrides,
    FeriePeriodStore? ferieStore,
  }) {
    final values = <AliceLogisticProviderAvailability>[
      _adult(
        AliceLogisticParent.matteo,
        TurnPerson.matteo,
        day,
        start,
        end,
        overrides,
        ferieStore,
      ),
      _adult(
        AliceLogisticParent.chiara,
        TurnPerson.chiara,
        day,
        start,
        end,
        overrides,
        ferieStore,
      ),
      AliceLogisticProviderAvailability(
        provider: AliceLogisticProviderRef.sandra,
        start: start,
        end: end,
        available: logisticsAvailability.sandraCovers(
          TimeOfDay.fromDateTime(start),
          TimeOfDay.fromDateTime(end),
        ),
      ),
    ];
    final people = [...logisticsAvailability.supportNetworkStore.people]
      ..sort((a, b) => a.id.compareTo(b.id));
    final supportMatches = logisticsAvailability.supportForWindow(
      TimeOfDay.fromDateTime(start),
      TimeOfDay.fromDateTime(end),
    );
    for (final person in people) {
      values.add(
        AliceLogisticProviderAvailability(
          provider: AliceLogisticProviderRef.supportPerson(person.id),
          start: start,
          end: end,
          available: supportMatches.any(
            (match) => match.providerId == person.id,
          ),
        ),
      );
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
}
