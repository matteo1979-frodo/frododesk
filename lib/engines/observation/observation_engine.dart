import '../../models/frodo_observation.dart';
import 'observation_registry.dart';

class ObservationEngine {
  static final Map<String, FrodoObservation> _memory = {};

  static List<FrodoObservation> collect({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final observations = <FrodoObservation>[];

    for (final provider in ObservationRegistry.providers) {
      for (final observation in provider.generate()) {
        final processed = _applyLifecycle(observation, currentTime);
        final previous = _memory[processed.id];

        final merged = previous == null
            ? processed
            : _mergeObservation(previous, processed);

        _memory[merged.id] = merged;

        observations.add(merged);
      }
    }

    return observations;
  }

  static List<FrodoObservation> collectForModule(String module) {
    return collect()
        .where((observation) => observation.module == module)
        .toList();
  }

  static List<FrodoObservation> selectForHome({int limit = 6}) {
    final active = collect().where((o) => o.isActive).toList();

    active.sort((a, b) {
      final levelCompare = _levelWeight(
        b.level,
      ).compareTo(_levelWeight(a.level));

      if (levelCompare != 0) return levelCompare;

      final priorityCompare = b.priority.compareTo(a.priority);

      if (priorityCompare != 0) return priorityCompare;

      return b.weight.compareTo(a.weight);
    });

    return active.take(limit).toList();
  }

  static FrodoObservation _mergeObservation(
    FrodoObservation previous,
    FrodoObservation current,
  ) {
    final hasChanged = current.isMeaningfullyDifferentFrom(previous);

    if (hasChanged) {
      return current.copyWith(status: FrodoObservationStatus.active);
    }

    return current.copyWith(
      status: previous.status,
      createdAt: previous.createdAt,
    );
  }

  static FrodoObservation _applyLifecycle(
    FrodoObservation observation,
    DateTime now,
  ) {
    if (observation.isActive && observation.isExpired(now)) {
      return observation.expire();
    }

    return observation;
  }

  static int _levelWeight(FrodoObservationLevel level) {
    switch (level) {
      case FrodoObservationLevel.problem:
        return 5;
      case FrodoObservationLevel.attention:
        return 4;
      case FrodoObservationLevel.opportunity:
        return 3;
      case FrodoObservationLevel.success:
        return 2;
      case FrodoObservationLevel.info:
        return 1;
    }
  }
}
