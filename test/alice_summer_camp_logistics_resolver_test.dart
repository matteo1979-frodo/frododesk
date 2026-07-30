import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/calendar/builders/alice_summer_camp_logistics_resolver.dart';
import 'package:frododesk/logic/calendar/models/alice_summer_camp_logistics.dart';

void main() {
  final start = DateTime(2026, 8, 11, 8, 30);
  final end = DateTime(2026, 8, 11, 16, 30);
  final matteo = AliceLogisticProviderRef.parent(AliceLogisticParent.matteo);
  final chiara = AliceLogisticProviderRef.parent(AliceLogisticParent.chiara);
  const sandra = AliceLogisticProviderRef.sandra;
  final supportA = AliceLogisticProviderRef.supportPerson('support-a');
  final supportB = AliceLogisticProviderRef.supportPerson('support-b');
  const resolver = AliceSummerCampLogisticsResolver();

  AliceLogisticProviderAvailability availability(
    AliceLogisticProviderRef provider,
    DateTime slotStart,
    DateTime slotEnd, {
    bool available = true,
  }) => AliceLogisticProviderAvailability(
    provider: provider,
    start: slotStart,
    end: slotEnd,
    available: available,
  );

  AliceSummerCampLogisticsResult resolve({
    bool operational = true,
    AliceLogisticProviderRef? dropOff,
    AliceLogisticProviderRef? pickUp,
    List<AliceLogisticProviderAvailability>? dropOffAvailabilities,
    List<AliceLogisticProviderAvailability>? pickUpAvailabilities,
  }) => resolver.resolve(
    summerCampOperational: operational,
    effectiveStart: start,
    effectiveEnd: end,
    dropOffAssignedProvider: dropOff,
    pickUpAssignedProvider: pickUp,
    dropOffAvailabilities: dropOffAvailabilities ?? const [],
    pickUpAvailabilities: pickUpAvailabilities ?? const [],
  );

  final matteoDropOff = availability(
    matteo,
    start.subtract(const Duration(minutes: 20)),
    start,
  );
  final matteoPickUp = availability(
    matteo,
    end,
    end.add(const Duration(minutes: 20)),
  );

  test('non-operational camp makes both legs inactive', () {
    final result = resolve(operational: false);
    expect(result.dropOff.status, AliceLogisticDecisionStatus.inactive);
    expect(result.pickUp.status, AliceLogisticDecisionStatus.inactive);
  });

  test('both assigned and available are valid', () {
    final result = resolve(
      dropOff: matteo,
      pickUp: chiara,
      dropOffAvailabilities: [matteoDropOff],
      pickUpAvailabilities: [
        availability(chiara, end, end.add(const Duration(minutes: 20))),
      ],
    );
    expect(result.dropOff.status, AliceLogisticDecisionStatus.assignedValid);
    expect(result.pickUp.status, AliceLogisticDecisionStatus.assignedValid);
  });

  test('only valid drop-off leaves pick-up decision open with candidates', () {
    final result = resolve(
      dropOff: matteo,
      dropOffAvailabilities: [matteoDropOff],
      pickUpAvailabilities: [matteoPickUp],
    );
    expect(result.dropOff.status, AliceLogisticDecisionStatus.assignedValid);
    expect(
      result.pickUp.status,
      AliceLogisticDecisionStatus.unassignedProviderAvailable,
    );
    expect(result.pickUp.availableProviders, [matteo]);
  });

  test('only valid pick-up leaves drop-off decision open with candidates', () {
    final result = resolve(
      pickUp: matteo,
      dropOffAvailabilities: [matteoDropOff],
      pickUpAvailabilities: [matteoPickUp],
    );
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.unassignedProviderAvailable,
    );
    expect(result.pickUp.status, AliceLogisticDecisionStatus.assignedValid);
  });

  test('unassigned leg reports Matteo when available', () {
    final result = resolve(dropOffAvailabilities: [matteoDropOff]);
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.unassignedProviderAvailable,
    );
    expect(result.dropOff.availableProviders, [matteo]);
  });

  test('multiple providers are retained in deterministic order', () {
    final windowStart = start.subtract(const Duration(minutes: 20));
    final result = resolve(
      dropOffAvailabilities: [
        availability(supportB, windowStart, start),
        availability(sandra, windowStart, start),
        availability(chiara, windowStart, start),
        availability(supportA, windowStart, start),
        availability(matteo, windowStart, start),
        availability(chiara, windowStart, start),
      ],
    );
    expect(result.dropOff.availableProviders, [
      matteo,
      chiara,
      sandra,
      supportA,
      supportB,
    ]);
  });

  test('unassigned leg without providers is a true logistic gap', () {
    final result = resolve();
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.noProviderAvailable,
    );
    expect(
      result.pickUp.status,
      AliceLogisticDecisionStatus.noProviderAvailable,
    );
  });

  test('assigned unavailable Matteo is a conflict', () {
    final result = resolve(dropOff: matteo);
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
  });

  test('available Chiara remains an alternative to unavailable Matteo', () {
    final result = resolve(
      dropOff: matteo,
      dropOffAvailabilities: [
        availability(
          chiara,
          start.subtract(const Duration(minutes: 20)),
          start,
        ),
      ],
    );
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
    expect(result.dropOff.availableProviders, [chiara]);
  });

  test('Sandra can be assigned and available', () {
    final result = resolve(
      pickUp: sandra,
      pickUpAvailabilities: [
        availability(sandra, end, end.add(const Duration(minutes: 20))),
      ],
    );
    expect(result.pickUp.status, AliceLogisticDecisionStatus.assignedValid);
  });

  test('assigned unavailable Sandra is a conflict', () {
    final result = resolve(pickUp: sandra);
    expect(
      result.pickUp.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
  });

  test('specific assigned support person keeps its stable ID', () {
    final result = resolve(
      dropOff: supportA,
      dropOffAvailabilities: [
        availability(
          supportA,
          start.subtract(const Duration(minutes: 20)),
          start,
        ),
      ],
    );
    expect(result.dropOff.status, AliceLogisticDecisionStatus.assignedValid);
    expect(result.dropOff.assignedProvider, supportA);
    expect(result.dropOff.assignedProvider!.providerId, 'support-a');
  });

  test('support B does not satisfy an assignment to support A', () {
    final result = resolve(
      dropOff: supportA,
      dropOffAvailabilities: [
        availability(
          supportB,
          start.subtract(const Duration(minutes: 20)),
          start,
        ),
      ],
    );
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
    expect(result.dropOff.availableProviders, [supportB]);
  });

  test('a slot covering only part of the leg is unavailable', () {
    final result = resolve(
      dropOff: matteo,
      dropOffAvailabilities: [
        availability(
          matteo,
          start.subtract(const Duration(minutes: 10)),
          start,
        ),
      ],
    );
    expect(
      result.dropOff.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
    expect(result.dropOff.availableProviders, isEmpty);
  });

  test('uses canonical drop-off and pick-up windows', () {
    final result = resolve();
    expect(result.dropOff.start, start.subtract(const Duration(minutes: 20)));
    expect(result.dropOff.end, start);
    expect(result.pickUp.start, end);
    expect(result.pickUp.end, end.add(const Duration(minutes: 20)));
  });

  test('drop-off and pick-up availability are independent', () {
    final result = resolve(
      dropOff: matteo,
      pickUp: matteo,
      dropOffAvailabilities: [matteoDropOff],
    );
    expect(result.dropOff.status, AliceLogisticDecisionStatus.assignedValid);
    expect(
      result.pickUp.status,
      AliceLogisticDecisionStatus.assignedProviderUnavailable,
    );
  });

  test('unordered inputs always produce the same output', () {
    final windowStart = start.subtract(const Duration(minutes: 20));
    final first = resolve(
      dropOffAvailabilities: [
        availability(supportB, windowStart, start),
        availability(matteo, windowStart, start),
        availability(chiara, windowStart, start),
      ],
    );
    final second = resolve(
      dropOffAvailabilities: [
        availability(chiara, windowStart, start),
        availability(supportB, windowStart, start),
        availability(matteo, windowStart, start),
      ],
    );
    expect(first.dropOff.availableProviders, second.dropOff.availableProviders);
  });

  test('support person IDs must be concrete and non-empty', () {
    expect(
      () => AliceLogisticProviderRef.supportPerson('  '),
      throwsArgumentError,
    );
  });

  test(
    'resolver source has no clock, school choice, labels, UI, or stores',
    () {
      final source = File(
        'lib/logic/calendar/builders/'
        'alice_summer_camp_logistics_resolver.dart',
      ).readAsStringSync();
      for (final forbidden in [
        'DateTime.now',
        'SchoolCoverChoice',
        'schoolInCover',
        'schoolOutCover',
        'BuildContext',
        'CoverageGapDetail',
        'Store',
        'label',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
    },
  );
}
