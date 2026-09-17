import '../../models/economic_event.dart';
import '../../models/expense_replacement_metadata.dart';
import '../../models/ledger_projected_event.dart';

/// Projects complete expense-replacement components without modifying their
/// canonical [EconomicEvent] inputs.
///
/// Any incomplete or ambiguous component is left fully visible as independent
/// events. The projector deliberately applies no legacy inference or timeline
/// sorting.
class ExpenseReplacementLedgerProjector {
  const ExpenseReplacementLedgerProjector();

  List<LedgerProjectedEvent> project(Iterable<EconomicEvent> input) {
    final events = List<EconomicEvent>.of(input);
    final facts = <String, List<int>>{};
    final relations = <_RelationKey, _RelationMarkers>{};

    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      final factId = event.economicFactId;
      if (factId != null) {
        facts.putIfAbsent(factId, () => <int>[]).add(index);
      }

      final metadata = event.expenseReplacementMetadata;
      if (metadata == null) continue;
      final key = _RelationKey(
        metadata.originalEconomicFactId,
        metadata.replacementEconomicFactId,
      );
      final markers = relations.putIfAbsent(key, _RelationMarkers.new);
      switch (metadata.role) {
        case ExpenseReplacementRole.compensation:
          markers.compensationIndexes.add(index);
        case ExpenseReplacementRole.replacement:
          markers.replacementIndexes.add(index);
      }
    }

    if (relations.isEmpty) {
      return [
        for (final event in events) LedgerProjectedEvent(currentEvent: event),
      ];
    }

    final adjacency = <String, Set<String>>{};
    for (final key in relations.keys) {
      adjacency
          .putIfAbsent(key.originalFactId, () => <String>{})
          .add(key.replacementFactId);
      adjacency
          .putIfAbsent(key.replacementFactId, () => <String>{})
          .add(key.originalFactId);
    }

    final projectedAtIndex = <int, LedgerProjectedEvent>{};
    final hiddenIndexes = <int>{};
    final visitedFacts = <String>{};

    for (final start in adjacency.keys) {
      if (!visitedFacts.add(start)) continue;
      final componentFacts = <String>{start};
      final pending = <String>[start];
      while (pending.isNotEmpty) {
        final factId = pending.removeLast();
        for (final neighbor in adjacency[factId] ?? const <String>{}) {
          if (visitedFacts.add(neighbor)) {
            componentFacts.add(neighbor);
            pending.add(neighbor);
          }
        }
      }

      final componentRelations = relations.keys
          .where(
            (key) =>
                componentFacts.contains(key.originalFactId) ||
                componentFacts.contains(key.replacementFactId),
          )
          .toList();
      final projection = _projectComponent(
        events: events,
        facts: facts,
        relations: relations,
        keys: componentRelations,
      );
      if (projection == null) continue;
      projectedAtIndex[projection.currentIndex] = LedgerProjectedEvent(
        currentEvent: events[projection.currentIndex],
        replacementHistory: projection.history,
      );
      hiddenIndexes.addAll(projection.hiddenIndexes);
    }

    return [
      for (var index = 0; index < events.length; index++)
        if (projectedAtIndex.containsKey(index))
          projectedAtIndex[index]!
        else if (!hiddenIndexes.contains(index))
          LedgerProjectedEvent(currentEvent: events[index]),
    ];
  }

  _ComponentProjection? _projectComponent({
    required List<EconomicEvent> events,
    required Map<String, List<int>> facts,
    required Map<_RelationKey, _RelationMarkers> relations,
    required List<_RelationKey> keys,
  }) {
    final outgoing = <String, _RelationKey>{};
    final incoming = <String, _RelationKey>{};
    final resolved = <_RelationKey, _ResolvedRelation>{};

    for (final key in keys) {
      if (key.originalFactId == key.replacementFactId ||
          outgoing.containsKey(key.originalFactId) ||
          incoming.containsKey(key.replacementFactId)) {
        return null;
      }
      outgoing[key.originalFactId] = key;
      incoming[key.replacementFactId] = key;

      final markers = relations[key]!;
      final originalIndexes = facts[key.originalFactId] ?? const <int>[];
      final replacementIndexes = facts[key.replacementFactId] ?? const <int>[];
      if (markers.compensationIndexes.length != 1 ||
          markers.replacementIndexes.length != 1 ||
          originalIndexes.length != 1 ||
          replacementIndexes.length != 1) {
        return null;
      }

      final originalIndex = originalIndexes.single;
      final compensationIndex = markers.compensationIndexes.single;
      final replacementIndex = replacementIndexes.single;
      if (markers.replacementIndexes.single != replacementIndex ||
          originalIndex == compensationIndex ||
          originalIndex == replacementIndex ||
          compensationIndex == replacementIndex) {
        return null;
      }

      final compensation = events[compensationIndex];
      final replacement = events[replacementIndex];
      final compensationFactId = compensation.economicFactId;
      if (compensationFactId == null ||
          (facts[compensationFactId]?.length ?? 0) != 1 ||
          compensationFactId == key.originalFactId ||
          compensationFactId == key.replacementFactId ||
          !_matches(compensation, key, ExpenseReplacementRole.compensation) ||
          !_matches(replacement, key, ExpenseReplacementRole.replacement)) {
        return null;
      }

      resolved[key] = _ResolvedRelation(
        originalIndex: originalIndex,
        compensationIndex: compensationIndex,
        replacementIndex: replacementIndex,
      );
    }

    final roots = outgoing.keys
        .where((factId) => !incoming.containsKey(factId))
        .toList();
    if (roots.length != 1) return null;

    final history = <LedgerReplacementHistoryEdge>[];
    final hiddenIndexes = <int>{};
    final traversed = <_RelationKey>{};
    final visitedFacts = <String>{};
    var currentFactId = roots.single;
    var next = outgoing[currentFactId];
    while (next != null) {
      final key = next;
      if (!visitedFacts.add(currentFactId) || !traversed.add(key)) {
        return null;
      }
      final relation = resolved[key]!;
      history.add(
        LedgerReplacementHistoryEdge(
          originalEvent: events[relation.originalIndex],
          compensationEvent: events[relation.compensationIndex],
          replacementEvent: events[relation.replacementIndex],
          originalEconomicFactId: key.originalFactId,
          replacementEconomicFactId: key.replacementFactId,
        ),
      );
      hiddenIndexes
        ..add(relation.originalIndex)
        ..add(relation.compensationIndex);
      currentFactId = key.replacementFactId;
      next = outgoing[currentFactId];
    }

    if (traversed.length != keys.length || history.isEmpty) return null;
    final currentIndexes = facts[currentFactId] ?? const <int>[];
    if (currentIndexes.length != 1) return null;
    final currentIndex = currentIndexes.single;
    hiddenIndexes.remove(currentIndex);
    return _ComponentProjection(
      currentIndex: currentIndex,
      hiddenIndexes: hiddenIndexes,
      history: history,
    );
  }

  bool _matches(
    EconomicEvent event,
    _RelationKey key,
    ExpenseReplacementRole role,
  ) {
    final metadata = event.expenseReplacementMetadata;
    return metadata != null &&
        metadata.originalEconomicFactId == key.originalFactId &&
        metadata.replacementEconomicFactId == key.replacementFactId &&
        metadata.role == role;
  }
}

class _RelationKey {
  final String originalFactId;
  final String replacementFactId;

  const _RelationKey(this.originalFactId, this.replacementFactId);

  @override
  bool operator ==(Object other) =>
      other is _RelationKey &&
      originalFactId == other.originalFactId &&
      replacementFactId == other.replacementFactId;

  @override
  int get hashCode => Object.hash(originalFactId, replacementFactId);
}

class _RelationMarkers {
  final List<int> compensationIndexes = [];
  final List<int> replacementIndexes = [];
}

class _ResolvedRelation {
  final int originalIndex;
  final int compensationIndex;
  final int replacementIndex;

  const _ResolvedRelation({
    required this.originalIndex,
    required this.compensationIndex,
    required this.replacementIndex,
  });
}

class _ComponentProjection {
  final int currentIndex;
  final Set<int> hiddenIndexes;
  final List<LedgerReplacementHistoryEdge> history;

  const _ComponentProjection({
    required this.currentIndex,
    required this.hiddenIndexes,
    required this.history,
  });
}
