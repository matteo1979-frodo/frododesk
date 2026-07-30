import 'package:flutter/material.dart';

import '../../coverage_engine.dart';
import '../../day_settings_store.dart';
import '../../support_network_store.dart';
import '../../../models/support_person.dart';
import '../view_models/coverage_gap_recommendation_view_model.dart';

typedef AdultBusyReader = bool Function(DateTime rangeStart, DateTime rangeEnd);

class CoverageGapRecommendationViewModelBuilder {
  const CoverageGapRecommendationViewModelBuilder();

  CoverageGapRecommendationsViewModel buildAll({
    required DateTime day,
    required List<CoverageGapDetail> gaps,
    required AdultBusyReader isMatteoBusy,
    required AdultBusyReader isChiaraBusy,
    required SupportNetworkStore supportNetworkStore,
    required DaySettingsStore daySettingsStore,
    required List<CoverageSandraWindow> sandraWindows,
  }) {
    final recommendations = gaps
        .map(
          (gap) => build(
            day: day,
            gap: gap,
            isMatteoBusy: isMatteoBusy,
            isChiaraBusy: isChiaraBusy,
            supportNetworkStore: supportNetworkStore,
            daySettingsStore: daySettingsStore,
            sandraWindows: sandraWindows,
          ),
        )
        .toList(growable: false);

    return CoverageGapRecommendationsViewModel(
      countText: gaps.length == 1
          ? "C'è 1 problema da gestire oggi"
          : "Ci sono ${gaps.length} problemi da gestire oggi",
      guidanceText: 'Valuta di attivare un supporto o modificare un turno',
      recommendations: recommendations,
    );
  }

  CoverageGapRecommendationViewModel build({
    required DateTime day,
    required CoverageGapDetail gap,
    required AdultBusyReader isMatteoBusy,
    required AdultBusyReader isChiaraBusy,
    required SupportNetworkStore supportNetworkStore,
    required DaySettingsStore daySettingsStore,
    required List<CoverageSandraWindow> sandraWindows,
  }) {
    final start = _at(day, gap.start);
    final end = _at(day, gap.end);
    final matteoAvailable = !isMatteoBusy(start, end);
    final chiaraAvailable = !isChiaraBusy(start, end);
    final support = _supportFor(
      day: day,
      gap: gap,
      supportNetworkStore: supportNetworkStore,
      daySettingsStore: daySettingsStore,
    );
    final sandraAvailable = sandraWindows.any(
      (window) =>
          window.active &&
          _minutes(window.start) <= _minutes(gap.start) &&
          _minutes(window.end) >= _minutes(gap.end),
    );

    if (matteoAvailable && chiaraAvailable) {
      return _model(
        gap,
        day,
        'Suggerimento: possono coprire Matteo o Chiara',
        CoverageGapRecommendationKind.useParent,
        providerDisplayName: 'Matteo o Chiara',
      );
    }
    if (matteoAvailable) {
      return _model(
        gap,
        day,
        'Suggerimento: può coprire Matteo',
        CoverageGapRecommendationKind.useParent,
        providerId: 'matteo',
        providerDisplayName: 'Matteo',
      );
    }
    if (chiaraAvailable) {
      return _model(
        gap,
        day,
        'Suggerimento: può coprire Chiara',
        CoverageGapRecommendationKind.useParent,
        providerId: 'chiara',
        providerDisplayName: 'Chiara',
      );
    }
    if (support.active != null && sandraAvailable) {
      return _model(
        gap,
        day,
        'Suggerimento: verifica Supporto oppure Sandra',
        CoverageGapRecommendationKind.useSupportNetwork,
        providerId: support.active!.id,
        providerDisplayName: _displayName(support.active!.name),
      );
    }
    if (support.active != null) {
      return _model(
        gap,
        day,
        'Suggerimento: verifica Supporto',
        CoverageGapRecommendationKind.useSupportNetwork,
        providerId: support.active!.id,
        providerDisplayName: _displayName(support.active!.name),
      );
    }
    if (sandraAvailable) {
      return _model(
        gap,
        day,
        'Suggerimento: attiva Sandra',
        CoverageGapRecommendationKind.useSandra,
        providerId: 'sandra',
        providerDisplayName: 'Sandra',
      );
    }
    if (support.inactive != null) {
      final name = _displayName(support.inactive!.name);
      return _model(
        gap,
        day,
        'Suggerimento: attiva $name nella rete di supporto',
        CoverageGapRecommendationKind.useSupportNetwork,
        providerId: support.inactive!.id,
        providerDisplayName: name,
        canExecuteAction: true,
      );
    }
    return _model(
      gap,
      day,
      'Suggerimento: nessun genitore libero: attiva Sandra o Supporto '
      'oppure modifica turno / chiedi permesso',
      CoverageGapRecommendationKind.changeShiftOrRequestLeave,
    );
  }

  CoverageGapRecommendationViewModel _model(
    CoverageGapDetail gap,
    DateTime day,
    String description,
    CoverageGapRecommendationKind kind, {
    String? providerId,
    String? providerDisplayName,
    bool canExecuteAction = false,
  }) {
    return CoverageGapRecommendationViewModel(
      start: _at(day, gap.start),
      end: _at(day, gap.end),
      title: 'Alice a casa: ${_format(gap.start)}–${_format(gap.end)}',
      description: description,
      kind: kind,
      providerId: providerId,
      providerDisplayName: providerDisplayName,
      canExecuteAction: canExecuteAction,
    );
  }

  _SupportCandidates _supportFor({
    required DateTime day,
    required CoverageGapDetail gap,
    required SupportNetworkStore supportNetworkStore,
    required DaySettingsStore daySettingsStore,
  }) {
    SupportPerson? active;
    SupportPerson? inactive;
    for (final person in supportNetworkStore.people) {
      if (!person.enabled || !_personCovers(person, gap)) continue;
      if (daySettingsStore.isSupportPersonEnabledForDay(day, person.id)) {
        active ??= person;
      } else {
        inactive ??= person;
      }
    }
    return _SupportCandidates(active: active, inactive: inactive);
  }

  bool _personCovers(SupportPerson person, CoverageGapDetail gap) {
    return person.effectiveSlots.any(
      (slot) =>
          _minutes(slot.start) <= _minutes(gap.start) &&
          _minutes(slot.end) >= _minutes(gap.end),
    );
  }

  DateTime _at(DateTime day, TimeOfDay time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String _displayName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Supporto';
    return '${clean[0].toUpperCase()}${clean.substring(1)}';
  }
}

class _SupportCandidates {
  final SupportPerson? active;
  final SupportPerson? inactive;

  const _SupportCandidates({required this.active, required this.inactive});
}
