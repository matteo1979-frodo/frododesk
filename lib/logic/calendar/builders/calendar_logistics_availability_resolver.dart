import 'package:flutter/material.dart';

import '../../day_settings_store.dart';
import '../../settings_store.dart';
import '../../support_network_store.dart';

enum SandraAvailabilityBand { mattina, pranzo, sera }

class SandraAvailabilityWindow {
  final SandraAvailabilityBand band;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool available;

  const SandraAvailabilityWindow({
    required this.band,
    required this.start,
    required this.end,
    required this.available,
  });
}

class SupportWindowAvailability {
  final String providerId;
  final String displayName;
  final TimeOfDay slotStart;
  final TimeOfDay slotEnd;

  const SupportWindowAvailability({
    required this.providerId,
    required this.displayName,
    required this.slotStart,
    required this.slotEnd,
  });
}

class CalendarLogisticsAvailabilityResult {
  final DateTime day;
  final List<SandraAvailabilityWindow> sandraWindows;
  final SupportNetworkStore supportNetworkStore;
  final DaySettingsStore daySettingsStore;

  const CalendarLogisticsAvailabilityResult({
    required this.day,
    required this.sandraWindows,
    required this.supportNetworkStore,
    required this.daySettingsStore,
  });

  bool get sandraAvailable => sandraWindows.any((window) => window.available);

  bool sandraCovers(TimeOfDay start, TimeOfDay end) => sandraWindows.any(
    (window) =>
        window.available && _covers(window.start, window.end, start, end),
  );

  List<SupportWindowAvailability> supportForWindow(
    TimeOfDay start,
    TimeOfDay end, {
    bool requireActiveForDay = true,
  }) {
    final matches = <SupportWindowAvailability>[];
    for (final person in supportNetworkStore.people) {
      if (!person.enabled ||
          (requireActiveForDay &&
              !daySettingsStore.isSupportPersonEnabledForDay(day, person.id))) {
        continue;
      }
      for (final slot in person.effectiveSlots) {
        if (!_covers(slot.start, slot.end, start, end)) continue;
        matches.add(
          SupportWindowAvailability(
            providerId: person.id,
            displayName: person.name,
            slotStart: slot.start,
            slotEnd: slot.end,
          ),
        );
        break;
      }
    }
    return List.unmodifiable(matches);
  }

  bool supportCovers(TimeOfDay start, TimeOfDay end) =>
      supportForWindow(start, end).isNotEmpty;

  static bool _covers(
    TimeOfDay slotStart,
    TimeOfDay slotEnd,
    TimeOfDay start,
    TimeOfDay end,
  ) =>
      _minutes(slotStart) <= _minutes(start) &&
      _minutes(slotEnd) >= _minutes(end);

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
}

class CalendarLogisticsAvailabilityResolver {
  final SettingsStore settingsStore;
  final DaySettingsStore daySettingsStore;
  final SupportNetworkStore supportNetworkStore;

  const CalendarLogisticsAvailabilityResolver({
    required this.settingsStore,
    required this.daySettingsStore,
    required this.supportNetworkStore,
  });

  CalendarLogisticsAvailabilityResult resolve({
    required DateTime day,
    required TimeOfDay mattinaStart,
    required TimeOfDay mattinaEnd,
    required TimeOfDay pranzoStart,
    required TimeOfDay pranzoEnd,
    required TimeOfDay seraStart,
    required TimeOfDay seraEnd,
  }) {
    final d0 = DateTime(day.year, day.month, day.day);
    final globallyEnabled = settingsStore.isSandraDisponibile;
    return CalendarLogisticsAvailabilityResult(
      day: d0,
      supportNetworkStore: supportNetworkStore,
      daySettingsStore: daySettingsStore,
      sandraWindows: List.unmodifiable([
        SandraAvailabilityWindow(
          band: SandraAvailabilityBand.mattina,
          start: mattinaStart,
          end: mattinaEnd,
          available:
              globallyEnabled &&
              daySettingsStore.sandraMattinaForDay(d0) == true,
        ),
        SandraAvailabilityWindow(
          band: SandraAvailabilityBand.pranzo,
          start: pranzoStart,
          end: pranzoEnd,
          available:
              globallyEnabled &&
              daySettingsStore.sandraPranzoForDay(d0) == true,
        ),
        SandraAvailabilityWindow(
          band: SandraAvailabilityBand.sera,
          start: seraStart,
          end: seraEnd,
          available:
              globallyEnabled && daySettingsStore.sandraSeraForDay(d0) == true,
        ),
      ]),
    );
  }
}
