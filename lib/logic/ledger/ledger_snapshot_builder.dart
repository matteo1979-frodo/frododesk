import 'dart:collection';

import '../../models/economic_event.dart';
import '../../models/ledger_event_view_model.dart';
import '../../models/ledger_snapshot.dart';

class LedgerSnapshotBuilder {
  const LedgerSnapshotBuilder();

  LedgerSnapshot build({
    required DateTime observedAt,
    required List<LedgerEventViewModel> timeline,
    String query = '',
    Set<String> selectedFilterIds = const <String>{},
  }) {
    final completeTimeline = List<LedgerEventViewModel>.of(timeline);
    final normalizedQuery = _normalizeText(query);
    final availableFilters = _buildAvailableFilters(completeTimeline);
    final availableById = {
      for (final option in availableFilters) option.id: option,
    };
    final effectiveFilterIds = SplayTreeSet<String>.of(
      selectedFilterIds.where(availableById.containsKey),
    );
    final selectedByKind = <LedgerFilterKind, Set<String>>{};
    for (final id in effectiveFilterIds) {
      final option = availableById[id]!;
      selectedByKind.putIfAbsent(option.kind, () => <String>{}).add(id);
    }

    final filtered = completeTimeline.where((event) {
      if (!_matchesQuery(event, normalizedQuery)) return false;
      final eventFilters = _eventFilterIds(event);
      return selectedByKind.entries.every(
        (selection) => selection.value.any(eventFilters.contains),
      );
    }).toList();

    return LedgerSnapshot(
      observedAt: observedAt,
      timeline: filtered,
      query: normalizedQuery,
      selectedFilterIds: effectiveFilterIds,
      availableFilters: availableFilters,
      totalEventCount: completeTimeline.length,
      filteredEventCount: filtered.length,
    );
  }

  List<LedgerFilterOption> _buildAvailableFilters(
    List<LedgerEventViewModel> timeline,
  ) {
    final byId = <String, LedgerFilterOption>{};
    for (final event in timeline) {
      _addOption(
        byId,
        LedgerFilterOption(
          id: _id(LedgerFilterKind.nature, event.nature.name),
          kind: LedgerFilterKind.nature,
          label: _natureLabel(event.nature),
        ),
      );
      final period = _periodValue(event.timelineDate);
      _addOption(
        byId,
        LedgerFilterOption(
          id: _id(LedgerFilterKind.period, period),
          kind: LedgerFilterKind.period,
          label: _periodLabel(event.timelineDate),
        ),
      );
      _addPersonOption(byId, event.personId, event.personLabel);
      for (final counterparty in event.counterparties) {
        _addPersonOption(byId, counterparty.personId, counterparty.personLabel);
        final referenceId = counterparty.referenceId;
        if (referenceId == null) continue;
        if (counterparty.kind == EconomicEndpointKind.account) {
          _addOption(
            byId,
            LedgerFilterOption(
              id: _id(LedgerFilterKind.account, referenceId),
              kind: LedgerFilterKind.account,
              label: counterparty.label,
            ),
          );
        } else if (counterparty.kind == EconomicEndpointKind.fund) {
          _addOption(
            byId,
            LedgerFilterOption(
              id: _id(LedgerFilterKind.fund, referenceId),
              kind: LedgerFilterKind.fund,
              label: counterparty.label,
            ),
          );
        }
      }
      final category = event.category;
      if (category != null) {
        _addOption(
          byId,
          LedgerFilterOption(
            id: _id(LedgerFilterKind.category, category.id),
            kind: LedgerFilterKind.category,
            label: category.label,
          ),
        );
      }
      for (final source in event.sourceLinks) {
        _addOption(
          byId,
          LedgerFilterOption(
            id: _id(LedgerFilterKind.source, source.kind.name),
            kind: LedgerFilterKind.source,
            label: _sourceLabel(source.kind),
          ),
        );
      }
    }
    final result = byId.values.toList()..sort(_compareOptions);
    return result;
  }

  Set<String> _eventFilterIds(LedgerEventViewModel event) {
    final result = <String>{
      _id(LedgerFilterKind.nature, event.nature.name),
      _id(LedgerFilterKind.period, _periodValue(event.timelineDate)),
    };
    if (event.personId != null) {
      result.add(_id(LedgerFilterKind.person, event.personId!));
    }
    for (final counterparty in event.counterparties) {
      if (counterparty.personId != null) {
        result.add(_id(LedgerFilterKind.person, counterparty.personId!));
      }
      final referenceId = counterparty.referenceId;
      if (referenceId == null) continue;
      if (counterparty.kind == EconomicEndpointKind.account) {
        result.add(_id(LedgerFilterKind.account, referenceId));
      } else if (counterparty.kind == EconomicEndpointKind.fund) {
        result.add(_id(LedgerFilterKind.fund, referenceId));
      }
    }
    if (event.category != null) {
      result.add(_id(LedgerFilterKind.category, event.category!.id));
    }
    for (final source in event.sourceLinks) {
      result.add(_id(LedgerFilterKind.source, source.kind.name));
    }
    return result;
  }

  bool _matchesQuery(LedgerEventViewModel event, String query) {
    if (query.isEmpty) return true;
    final searchable = <String>[
      event.title,
      event.subtitle,
      ...event.counterparties.map((item) => item.label),
      ...event.counterparties.map((item) => item.personLabel ?? ''),
      ...event.badges.map((item) => item.label),
      event.category?.label ?? '',
      event.personLabel ?? '',
      ...event.sourceLinks.map((item) => _sourceLabel(item.kind)),
    ];
    return searchable.any((value) => _normalizeText(value).contains(query));
  }

  void _addPersonOption(
    Map<String, LedgerFilterOption> byId,
    String? personId,
    String? personLabel,
  ) {
    if (personId == null || personLabel == null || personLabel.trim().isEmpty) {
      return;
    }
    _addOption(
      byId,
      LedgerFilterOption(
        id: _id(LedgerFilterKind.person, personId),
        kind: LedgerFilterKind.person,
        label: personLabel,
      ),
    );
  }

  void _addOption(
    Map<String, LedgerFilterOption> byId,
    LedgerFilterOption candidate,
  ) {
    final current = byId[candidate.id];
    if (current == null || _compareLabels(candidate, current) < 0) {
      byId[candidate.id] = candidate;
    }
  }

  int _compareOptions(LedgerFilterOption left, LedgerFilterOption right) {
    final kind = left.kind.index.compareTo(right.kind.index);
    if (kind != 0) return kind;
    if (left.kind == LedgerFilterKind.nature) {
      return _natureRank(left.id).compareTo(_natureRank(right.id));
    }
    if (left.kind == LedgerFilterKind.period) {
      return right.id.compareTo(left.id);
    }
    return _compareLabels(left, right);
  }

  int _compareLabels(LedgerFilterOption left, LedgerFilterOption right) {
    final label = _normalizeText(
      left.label,
    ).compareTo(_normalizeText(right.label));
    return label != 0 ? label : left.id.compareTo(right.id);
  }

  int _natureRank(String id) {
    if (id == _id(LedgerFilterKind.nature, EconomicNature.income.name)) {
      return 0;
    }
    if (id == _id(LedgerFilterKind.nature, EconomicNature.outflow.name)) {
      return 1;
    }
    return 2;
  }

  String _id(LedgerFilterKind kind, String value) =>
      '${kind.name}:${Uri.encodeComponent(value)}';

  String _periodValue(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  String _periodLabel(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.year}';

  String _normalizeText(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _natureLabel(EconomicNature nature) => switch (nature) {
    EconomicNature.income => 'Entrate',
    EconomicNature.outflow => 'Uscite',
    EconomicNature.internalTransfer => 'Trasferimenti',
  };

  String _sourceLabel(EconomicSourceKind kind) => switch (kind) {
    EconomicSourceKind.realExpense => 'Spese',
    EconomicSourceKind.financeTransaction => 'Movimenti dei conti',
    EconomicSourceKind.financeAssetMovement => 'Movimenti patrimoniali',
    EconomicSourceKind.other => 'Altra provenienza',
  };

  static const _monthNames = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];
}
