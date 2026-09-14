import 'dart:collection';

import 'ledger_event_view_model.dart';
import 'ledger_snapshot.dart';

enum LedgerPresentationState { archiveEmpty, noResults, results }

class LedgerPresentationData {
  final DateTime observedAt;
  final LedgerPresentationState state;
  final UnmodifiableListView<LedgerEventViewModel> entries;
  final String query;
  final UnmodifiableSetView<String> selectedFilterIds;
  final UnmodifiableListView<LedgerFilterOption> availableFilters;
  final int totalEventCount;
  final int filteredEventCount;

  LedgerPresentationData({
    required this.observedAt,
    required this.state,
    required List<LedgerEventViewModel> entries,
    required this.query,
    required Set<String> selectedFilterIds,
    required List<LedgerFilterOption> availableFilters,
    required this.totalEventCount,
    required this.filteredEventCount,
  }) : assert(totalEventCount >= 0),
       assert(filteredEventCount >= 0),
       assert(filteredEventCount <= totalEventCount),
       assert(entries.length == filteredEventCount),
       entries = UnmodifiableListView(List.of(entries)),
       selectedFilterIds = UnmodifiableSetView(Set.of(selectedFilterIds)),
       availableFilters = UnmodifiableListView(List.of(availableFilters));
}
