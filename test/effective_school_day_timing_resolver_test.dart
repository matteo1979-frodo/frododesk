import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/effective_school_day_timing_resolver.dart';
import 'package:frododesk/logic/calendar/models/effective_school_day_timing.dart';

void main() {
  const resolver = EffectiveSchoolDayTimingResolver();

  EffectiveSchoolDayTimingInput input({
    bool hasEnabledSchoolConfiguration = true,
    TimeOfDay? configuredSchoolEntryAt = const TimeOfDay(hour: 8, minute: 25),
    TimeOfDay? configuredSchoolExitAt = const TimeOfDay(hour: 16, minute: 25),
    TimeOfDay? configuredSchoolPickupWindowEnd = const TimeOfDay(
      hour: 16,
      minute: 45,
    ),
    TimeOfDay? schoolOutStartOverride,
    TimeOfDay? schoolOutEndOverride,
    TimeOfDay? earlySchoolExitOverride,
    bool isGlobalEarlySchoolExitEnabled = false,
    TimeOfDay globalEarlySchoolExitAt = const TimeOfDay(hour: 13, minute: 0),
  }) {
    return EffectiveSchoolDayTimingInput(
      hasEnabledSchoolConfiguration: hasEnabledSchoolConfiguration,
      configuredSchoolEntryAt: configuredSchoolEntryAt,
      configuredSchoolExitAt: configuredSchoolExitAt,
      configuredSchoolPickupWindowEnd: configuredSchoolPickupWindowEnd,
      schoolOutStartOverride: schoolOutStartOverride,
      schoolOutEndOverride: schoolOutEndOverride,
      earlySchoolExitOverride: earlySchoolExitOverride,
      isGlobalEarlySchoolExitEnabled: isGlobalEarlySchoolExitEnabled,
      globalEarlySchoolExitAt: globalEarlySchoolExitAt,
    );
  }

  test('configurazione attiva 08:25 / 16:25 termina il pickup alle 16:45', () {
    final result = resolver.resolve(input());

    expect(result.schoolEntryAt, const TimeOfDay(hour: 8, minute: 25));
    expect(result.schoolExitAt, const TimeOfDay(hour: 16, minute: 25));
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 45));
  });

  test('configurazione assente usa i fallback del profilo H6.8A', () {
    final result = resolver.resolve(
      input(
        hasEnabledSchoolConfiguration: false,
        configuredSchoolEntryAt: null,
        configuredSchoolExitAt: null,
        configuredSchoolPickupWindowEnd: null,
      ),
    );

    expect(result.schoolEntryAt, const TimeOfDay(hour: 8, minute: 25));
    expect(result.schoolExitAt, const TimeOfDay(hour: 16, minute: 25));
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 45));
  });

  test('configurazione disabilitata ignora gli orari configurati', () {
    final result = resolver.resolve(
      input(
        hasEnabledSchoolConfiguration: false,
        configuredSchoolEntryAt: const TimeOfDay(hour: 9, minute: 10),
        configuredSchoolExitAt: const TimeOfDay(hour: 15, minute: 20),
        configuredSchoolPickupWindowEnd: const TimeOfDay(hour: 15, minute: 40),
      ),
    );

    expect(result.schoolEntryAt, const TimeOfDay(hour: 8, minute: 25));
    expect(result.schoolExitAt, const TimeOfDay(hour: 16, minute: 25));
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 45));
  });

  test('override schoolOutStart prevale sulla configurazione', () {
    final result = resolver.resolve(
      input(schoolOutStartOverride: const TimeOfDay(hour: 15, minute: 55)),
    );

    expect(result.schoolExitAt, const TimeOfDay(hour: 15, minute: 55));
  });

  test('override schoolOutEnd prevale sul rientro configurato', () {
    final result = resolver.resolve(
      input(schoolOutEndOverride: const TimeOfDay(hour: 16, minute: 35)),
    );

    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 35));
  });

  test('uscita anticipata giornaliera viene usata', () {
    final result = resolver.resolve(
      input(earlySchoolExitOverride: const TimeOfDay(hour: 12, minute: 45)),
    );

    expect(result.earlySchoolExitAt, const TimeOfDay(hour: 12, minute: 45));
    expect(result.hasEarlySchoolExit, isTrue);
  });

  test('uscita anticipata globale viene usata quando abilitata', () {
    final result = resolver.resolve(
      input(
        isGlobalEarlySchoolExitEnabled: true,
        globalEarlySchoolExitAt: const TimeOfDay(hour: 13, minute: 10),
      ),
    );

    expect(result.earlySchoolExitAt, const TimeOfDay(hour: 13, minute: 10));
    expect(result.hasEarlySchoolExit, isTrue);
  });

  test('nessuna uscita anticipata produce null e flag falso', () {
    final result = resolver.resolve(input());

    expect(result.earlySchoolExitAt, isNull);
    expect(result.hasEarlySchoolExit, isFalse);
  });

  test('uscita anticipata giornaliera prevale sul fallback globale', () {
    final result = resolver.resolve(
      input(
        earlySchoolExitOverride: const TimeOfDay(hour: 12, minute: 50),
        isGlobalEarlySchoolExitEnabled: true,
        globalEarlySchoolExitAt: const TimeOfDay(hour: 13, minute: 15),
      ),
    );

    expect(result.earlySchoolExitAt, const TimeOfDay(hour: 12, minute: 50));
  });

  test('uscita reale e termine pickup restano semanticamente distinti', () {
    final result = resolver.resolve(
      input(
        configuredSchoolExitAt: const TimeOfDay(hour: 16, minute: 5),
        configuredSchoolPickupWindowEnd: const TimeOfDay(hour: 16, minute: 25),
      ),
    );

    expect(result.schoolExitAt, const TimeOfDay(hour: 16, minute: 5));
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 25));
  });

  test('il profilo H6.8A non produce il fallback storico 17:15', () {
    final result = resolver.resolve(
      input(
        hasEnabledSchoolConfiguration: false,
        configuredSchoolEntryAt: null,
        configuredSchoolExitAt: null,
        configuredSchoolPickupWindowEnd: null,
      ),
    );

    expect(
      result.schoolPickupWindowEnd,
      isNot(const TimeOfDay(hour: 17, minute: 15)),
    );
    expect(result.schoolPickupWindowEnd, const TimeOfDay(hour: 16, minute: 45));
  });
}
