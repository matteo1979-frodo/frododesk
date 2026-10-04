import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/adult_logistics_availability_resolver.dart';
import 'package:frododesk/logic/disease_period_store.dart';
import 'package:frododesk/logic/real_event_store.dart';
import 'package:frododesk/logic/turn_engine.dart';
import 'package:frododesk/logic/turn_override_store.dart';
import 'package:frododesk/models/adult_constraint_interval.dart';
import 'package:frododesk/models/day_override.dart';
import 'package:frododesk/models/turn_override.dart';

void main() {
  final monday = DateTime(2026, 10, 5);

  test('Giornata giornaliera produce lavoro e viaggi completi', () {
    final overrides = TurnOverrideStore()
      ..setDailyOverride(
        person: TurnPersonId.matteo,
        day: monday,
        newShift: TurnOverrideShift.giornata,
      );
    final engine = TurnEngine(turnOverrideStore: overrides);

    final plan = engine.turnPlanForPersonDay(
      person: TurnPerson.matteo,
      day: monday,
    );
    expect(plan.type, TurnType.giornata);
    expect(plan.start, const TimeOfDay(hour: 8, minute: 0));
    expect(plan.end, const TimeOfDay(hour: 17, minute: 0));
    expect(plan.isOff, isFalse);

    final constraints = engine.constraintsForPersonDay(
      person: TurnPerson.matteo,
      day: monday,
    );
    expect(
      constraints.where((c) => c.kind == AdultConstraintKind.outboundTravel),
      contains(
        isA<AdultConstraintInterval>()
            .having((c) => c.start, 'start', DateTime(2026, 10, 5, 7))
            .having((c) => c.end, 'end', DateTime(2026, 10, 5, 8)),
      ),
    );
    expect(
      constraints.where((c) => c.kind == AdultConstraintKind.work),
      contains(
        isA<AdultConstraintInterval>()
            .having((c) => c.start, 'start', DateTime(2026, 10, 5, 8))
            .having((c) => c.end, 'end', DateTime(2026, 10, 5, 17)),
      ),
    );
    expect(
      constraints.where((c) => c.kind == AdultConstraintKind.returnTravel),
      contains(
        isA<AdultConstraintInterval>()
            .having((c) => c.start, 'start', DateTime(2026, 10, 5, 17))
            .having((c) => c.end, 'end', DateTime(2026, 10, 5, 17, 45)),
      ),
    );
    expect(
      constraints.any((c) => c.kind == AdultConstraintKind.recovery),
      isFalse,
    );

    final busy = engine.busyShiftsForPerson(
      person: TurnPerson.matteo,
      day: monday,
    );
    expect(busy, hasLength(1));
    expect(busy.single.start, DateTime(2026, 10, 5, 7));
    expect(busy.single.end, DateTime(2026, 10, 5, 17, 45));
    expect(
      busy.single.overlaps(
        DateTime(2026, 10, 5, 12),
        DateTime(2026, 10, 5, 13),
      ),
      isTrue,
    );
  });

  test('Giornata di periodo vale nel periodo e il giornaliero prevale', () {
    final overrides = TurnOverrideStore()
      ..setPeriodOverride(
        person: TurnPersonId.matteo,
        startDay: monday,
        endDay: monday.add(const Duration(days: 4)),
        newShift: TurnOverrideShift.giornata,
      )
      ..setDailyOverride(
        person: TurnPersonId.matteo,
        day: monday.add(const Duration(days: 2)),
        newShift: TurnOverrideShift.off,
      );
    final engine = TurnEngine(turnOverrideStore: overrides);

    expect(
      engine.turnPlanForPersonDay(person: TurnPerson.matteo, day: monday).type,
      TurnType.giornata,
    );
    expect(
      engine
          .turnPlanForPersonDay(
            person: TurnPerson.matteo,
            day: monday.add(const Duration(days: 2)),
          )
          .type,
      TurnType.off,
    );
    expect(
      engine
          .turnPlanForPersonDay(
            person: TurnPerson.matteo,
            day: monday.add(const Duration(days: 4)),
          )
          .type,
      TurnType.giornata,
    );
    expect(
      engine
          .turnPlanForPersonDay(
            person: TurnPerson.matteo,
            day: monday.add(const Duration(days: 5)),
          )
          .type,
      isNot(TurnType.giornata),
    );
  });

  test('copertura Alice considera indisponibili mensa e ritorno', () {
    final overrides = TurnOverrideStore()
      ..setDailyOverride(
        person: TurnPersonId.matteo,
        day: monday,
        newShift: TurnOverrideShift.giornata,
      );
    final resolver = AdultLogisticsAvailabilityResolver(
      turnEngine: TurnEngine(turnOverrideStore: overrides),
      diseasePeriodStore: DiseasePeriodStore(),
      realEventStore: RealEventStore(),
    );

    bool canCover(int startHour, int startMinute, int endHour, int endMinute) {
      return resolver.canCoverRange(
        personKey: 'matteo',
        person: TurnPerson.matteo,
        day: monday,
        start: DateTime(2026, 10, 5, startHour, startMinute),
        end: DateTime(2026, 10, 5, endHour, endMinute),
        isHomePresenceWindow: true,
        overrides: DayOverrides.empty(monday),
      );
    }

    expect(canCover(12, 0, 13, 0), isFalse);
    expect(canCover(17, 30, 17, 40), isFalse);
    expect(canCover(17, 45, 18, 0), isTrue);
  });

  test('ritorno standard e 45 minuti e andata resta 60 per ogni turno', () {
    final policy = TravelDurationPolicy();

    for (final type in TurnType.values.where((type) => type != TurnType.off)) {
      expect(
        policy.travelDurationFor(
          personId: 'matteo',
          shiftType: type,
          direction: TravelDirection.outbound,
        ),
        const Duration(minutes: 60),
      );
      expect(
        policy.travelDurationFor(
          personId: 'chiara',
          shiftType: type,
          direction: TravelDirection.returnTrip,
        ),
        const Duration(minutes: 45),
      );
    }
  });

  test('Calendario offre Giornata nei cambi giornaliero e di periodo', () {
    final source = File(
      'lib/screens/calendario_screen_stepa.dart',
    ).readAsStringSync();
    expect(
      RegExp(
        r'Navigator\.pop\(context, TurnType\.giornata\)',
      ).allMatches(source),
      hasLength(2),
    );
    expect(
      RegExp(
        r'TurnType\.giornata => TurnOverrideShift\.giornata',
      ).allMatches(source),
      hasLength(2),
    );
  });
}
