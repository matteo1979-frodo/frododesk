import '../../models/finance_asset_movement.dart';
import '../../models/finance_transaction.dart';
import '../../models/ledger_snapshot.dart';
import '../../models/real_expense.dart';
import 'economic_event_collector.dart';
import 'economic_event_correlator.dart';
import 'ledger_snapshot_builder.dart';
import 'ledger_timeline_builder.dart';

class LedgerCoordinator {
  final EconomicEventCollector collector;
  final EconomicEventCorrelator correlator;
  final LedgerTimelineBuilder timelineBuilder;
  final LedgerSnapshotBuilder snapshotBuilder;

  const LedgerCoordinator({
    required this.timelineBuilder,
    this.collector = const EconomicEventCollector(),
    this.correlator = const EconomicEventCorrelator(),
    this.snapshotBuilder = const LedgerSnapshotBuilder(),
  });

  LedgerSnapshot build({
    required Iterable<FinanceTransaction> transactions,
    required Iterable<FinanceAssetMovement> assetMovements,
    required Iterable<RealExpense> realExpenses,
    required DateTime observedAt,
    String query = '',
    Set<String> selectedFilterIds = const <String>{},
  }) {
    final rawEvents = collector.collect(
      transactions: transactions,
      assetMovements: assetMovements,
      realExpenses: realExpenses,
      observedAt: observedAt,
    );
    final canonicalEvents = correlator.correlate(rawEvents);
    final timeline = timelineBuilder.build(canonicalEvents);
    return snapshotBuilder.build(
      observedAt: observedAt,
      timeline: timeline,
      query: query,
      selectedFilterIds: selectedFilterIds,
    );
  }
}
