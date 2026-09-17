import 'dart:collection';

import 'economic_event.dart';

class LedgerReplacementHistoryEdge {
  final EconomicEvent originalEvent;
  final EconomicEvent compensationEvent;
  final EconomicEvent replacementEvent;
  final String originalEconomicFactId;
  final String replacementEconomicFactId;

  const LedgerReplacementHistoryEdge({
    required this.originalEvent,
    required this.compensationEvent,
    required this.replacementEvent,
    required this.originalEconomicFactId,
    required this.replacementEconomicFactId,
  });
}

class LedgerProjectedEvent {
  final EconomicEvent currentEvent;
  final UnmodifiableListView<LedgerReplacementHistoryEdge> replacementHistory;

  LedgerProjectedEvent({
    required this.currentEvent,
    List<LedgerReplacementHistoryEdge> replacementHistory = const [],
  }) : replacementHistory = UnmodifiableListView(
         List<LedgerReplacementHistoryEdge>.of(replacementHistory),
       );
}
