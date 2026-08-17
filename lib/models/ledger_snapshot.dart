import 'dart:collection';

import 'ledger_event_view_model.dart';

enum LedgerFilterKind {
  nature,
  period,
  person,
  account,
  fund,
  category,
  source,
}

class LedgerFilterOption {
  final String id;
  final LedgerFilterKind kind;
  final String label;

  const LedgerFilterOption({
    required this.id,
    required this.kind,
    required this.label,
  }) : assert(id != ''),
       assert(label != '');
}

class LedgerSnapshot {
  final DateTime observedAt;
  final UnmodifiableListView<LedgerEventViewModel> timeline;
  final String query;
  final UnmodifiableSetView<String> selectedFilterIds;
  final UnmodifiableListView<LedgerFilterOption> availableFilters;
  final int totalEventCount;
  final int filteredEventCount;

  LedgerSnapshot({
    required this.observedAt,
    required List<LedgerEventViewModel> timeline,
    required this.query,
    required Set<String> selectedFilterIds,
    required List<LedgerFilterOption> availableFilters,
    required this.totalEventCount,
    required this.filteredEventCount,
  }) : assert(totalEventCount >= 0),
       assert(filteredEventCount >= 0),
       assert(filteredEventCount <= totalEventCount),
       assert(timeline.length == filteredEventCount),
       timeline = UnmodifiableListView(List<LedgerEventViewModel>.of(timeline)),
       selectedFilterIds = UnmodifiableSetView(
         Set<String>.of(selectedFilterIds),
       ),
       availableFilters = UnmodifiableListView(
         List<LedgerFilterOption>.of(availableFilters),
       );

  bool get isArchiveEmpty => totalEventCount == 0;

  bool get hasNoResults => totalEventCount > 0 && filteredEventCount == 0;
}
