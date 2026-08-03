import 'package:flutter/material.dart';

import '../../coverage_engine.dart';
import '../../alice_companion_store.dart';
import 'calendar_logistics_availability_resolver.dart';

typedef CoverageGapAdultBusyReader =
    bool Function(DateTime rangeStart, DateTime rangeEnd);

enum CoverageGapCompanionKind { parent, supportPerson, sandra }

class CoverageGapCompanionCandidate {
  final String providerId;
  final CoverageGapCompanionKind kind;
  final String displayName;
  final bool activeForDay;

  const CoverageGapCompanionCandidate({
    required this.providerId,
    required this.kind,
    required this.displayName,
    this.activeForDay = true,
  });
}

class CoverageGapCompanionResolution {
  final CoverageGapDetail gap;
  final List<CoverageGapCompanionCandidate> availableCandidates;
  final List<CoverageGapCompanionCandidate> inactiveSupportCandidates;

  const CoverageGapCompanionResolution({
    required this.gap,
    required this.availableCandidates,
    required this.inactiveSupportCandidates,
  });

  CoverageGapCompanionCandidate? firstOf(CoverageGapCompanionKind kind) {
    for (final candidate in availableCandidates) {
      if (candidate.kind == kind) return candidate;
    }
    return null;
  }

  AliceCompanionPerson get suggestedAliceCompanion {
    final parent = firstOf(CoverageGapCompanionKind.parent);
    switch (parent?.providerId) {
      case 'matteo':
        return AliceCompanionPerson.matteo;
      case 'chiara':
        return AliceCompanionPerson.chiara;
      default:
        return AliceCompanionPerson.nessuno;
    }
  }
}

class CoverageGapCompanionResolver {
  const CoverageGapCompanionResolver();

  CoverageGapCompanionResolution resolve({
    required DateTime day,
    required CoverageGapDetail gap,
    required CoverageGapAdultBusyReader isMatteoBusy,
    required CoverageGapAdultBusyReader isChiaraBusy,
    required CalendarLogisticsAvailabilityResult availability,
  }) {
    final start = _at(day, gap.start);
    final end = _at(day, gap.end);
    final available = <CoverageGapCompanionCandidate>[];
    final inactive = <CoverageGapCompanionCandidate>[];

    if (!isMatteoBusy(start, end)) {
      available.add(
        const CoverageGapCompanionCandidate(
          providerId: 'matteo',
          kind: CoverageGapCompanionKind.parent,
          displayName: 'Matteo',
        ),
      );
    }
    if (!isChiaraBusy(start, end)) {
      available.add(
        const CoverageGapCompanionCandidate(
          providerId: 'chiara',
          kind: CoverageGapCompanionKind.parent,
          displayName: 'Chiara',
        ),
      );
    }

    for (final person in availability.supportNetworkStore.people) {
      if (!person.enabled) continue;
      final active = availability.daySettingsStore.isSupportPersonEnabledForDay(
        day,
        person.id,
      );
      final matches = availability
          .supportForWindow(
            gap.start,
            gap.end,
            requireActiveForDay: false,
          )
          .where((match) => match.providerId == person.id);
      if (matches.isEmpty) continue;
      final candidate = CoverageGapCompanionCandidate(
        providerId: person.id,
        kind: CoverageGapCompanionKind.supportPerson,
        displayName: _displayName(person.name),
        activeForDay: active,
      );
      (active ? available : inactive).add(candidate);
    }

    if (availability.sandraCovers(gap.start, gap.end)) {
      available.add(
        const CoverageGapCompanionCandidate(
          providerId: 'sandra',
          kind: CoverageGapCompanionKind.sandra,
          displayName: 'Sandra',
        ),
      );
    }

    return CoverageGapCompanionResolution(
      gap: gap,
      availableCandidates: List.unmodifiable(available),
      inactiveSupportCandidates: List.unmodifiable(inactive),
    );
  }

  DateTime _at(DateTime day, TimeOfDay time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  String _displayName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Supporto';
    return '${clean[0].toUpperCase()}${clean.substring(1)}';
  }
}
