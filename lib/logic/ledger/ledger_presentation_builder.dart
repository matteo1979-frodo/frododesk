import '../../models/ledger_presentation_data.dart';
import '../../models/ledger_snapshot.dart';

class LedgerPresentationBuilder {
  const LedgerPresentationBuilder();

  LedgerPresentationData build(LedgerSnapshot snapshot) =>
      LedgerPresentationData(
        observedAt: snapshot.observedAt,
        state: snapshot.isArchiveEmpty
            ? LedgerPresentationState.archiveEmpty
            : snapshot.hasNoResults
            ? LedgerPresentationState.noResults
            : LedgerPresentationState.results,
        entries: snapshot.timeline,
        query: snapshot.query,
        selectedFilterIds: snapshot.selectedFilterIds,
        availableFilters: snapshot.availableFilters,
        totalEventCount: snapshot.totalEventCount,
        filteredEventCount: snapshot.filteredEventCount,
      );
}
