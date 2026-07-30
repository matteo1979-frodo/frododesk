import 'package:flutter/material.dart';

enum CoverageGapRecommendationKind {
  useParent,
  useSupportNetwork,
  useSandra,
  changeShiftOrRequestLeave,
  unresolved,
}

class CoverageGapRecommendationViewModel {
  final DateTime start;
  final DateTime end;
  final String title;
  final String description;
  final CoverageGapRecommendationKind kind;
  final String? providerId;
  final String? providerDisplayName;
  final bool canExecuteAction;

  const CoverageGapRecommendationViewModel({
    required this.start,
    required this.end,
    required this.title,
    required this.description,
    required this.kind,
    this.providerId,
    this.providerDisplayName,
    this.canExecuteAction = false,
  });
}

class CoverageGapRecommendationsViewModel {
  final String countText;
  final String guidanceText;
  final List<CoverageGapRecommendationViewModel> recommendations;

  const CoverageGapRecommendationsViewModel({
    required this.countText,
    required this.guidanceText,
    required this.recommendations,
  });
}

class CoverageSandraWindow {
  final TimeOfDay start;
  final TimeOfDay end;
  final bool active;

  const CoverageSandraWindow({
    required this.start,
    required this.end,
    required this.active,
  });
}
