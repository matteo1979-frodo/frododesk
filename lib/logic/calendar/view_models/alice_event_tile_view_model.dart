import 'package:flutter/material.dart';

class AliceEventTileViewModel {
  final String id;
  final String title;
  final String timeLabel;
  final String categoryLabel;
  final IconData categoryIcon;

  final bool isConflict;
  final bool isExpanded;
  final bool hasNote;
  final bool requiresLogistics;
  final Color badgeColor;
  final Color badgeBackground;

  const AliceEventTileViewModel({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.isConflict,
    required this.isExpanded,
    required this.hasNote,
    required this.requiresLogistics,
    required this.badgeColor,
    required this.badgeBackground,
  });
}
