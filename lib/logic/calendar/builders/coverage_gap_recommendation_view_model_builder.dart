import 'package:flutter/material.dart';

import '../../coverage_engine.dart';
import '../view_models/coverage_gap_recommendation_view_model.dart';
import 'coverage_gap_companion_resolver.dart';

class CoverageGapRecommendationViewModelBuilder {
  const CoverageGapRecommendationViewModelBuilder();

  CoverageGapRecommendationsViewModel buildAll({
    required DateTime day,
    required List<CoverageGapDetail> gaps,
    required List<CoverageGapCompanionResolution> resolutions,
  }) {
    final recommendations = gaps
        .asMap()
        .entries
        .map(
          (entry) => build(
            day: day,
            gap: entry.value,
            resolution: resolutions[entry.key],
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
    required CoverageGapCompanionResolution resolution,
  }) {
    final parents = resolution.availableCandidates
        .where((candidate) => candidate.kind == CoverageGapCompanionKind.parent)
        .toList(growable: false);
    final matteoAvailable = parents.any(
      (candidate) => candidate.providerId == 'matteo',
    );
    final chiaraAvailable = parents.any(
      (candidate) => candidate.providerId == 'chiara',
    );
    final support = resolution.firstOf(CoverageGapCompanionKind.supportPerson);
    final sandraAvailable =
        resolution.firstOf(CoverageGapCompanionKind.sandra) != null;

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
    if (support != null && sandraAvailable) {
      return _model(
        gap,
        day,
        'Suggerimento: verifica Supporto oppure Sandra',
        CoverageGapRecommendationKind.useSupportNetwork,
        providerId: support.providerId,
        providerDisplayName: support.displayName,
      );
    }
    if (support != null) {
      return _model(
        gap,
        day,
        'Suggerimento: verifica Supporto',
        CoverageGapRecommendationKind.useSupportNetwork,
        providerId: support.providerId,
        providerDisplayName: support.displayName,
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
    if (resolution.inactiveSupportCandidates.isNotEmpty) {
      final candidate = resolution.inactiveSupportCandidates.first;
      final name = candidate.displayName;
      return _model(
        gap,
        day,
        'Suggerimento: attiva $name nella rete di supporto',
        CoverageGapRecommendationKind.useSupportNetwork,
        providerId: candidate.providerId,
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

  DateTime _at(DateTime day, TimeOfDay time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}
