import 'package:flutter/material.dart';

import '../../../models/alice_special_event.dart';
import '../../../utils/calendario_formatters.dart';
import '../view_models/alice_event_tile_view_model.dart';

class AliceEventTileViewModelBuilder {
  const AliceEventTileViewModelBuilder();

  AliceEventTileViewModel build({
    required AliceSpecialEvent event,
    required bool isConflict,
    required bool isExpanded,
    required bool requiresLogistics,
    required IconData categoryIcon,
    required String categoryLabel,
  }) {
    return AliceEventTileViewModel(
      id: event.id,
      title: event.label,
      timeLabel: "${fmtTimeOfDay(event.start)}–${fmtTimeOfDay(event.end)}",
      categoryLabel: categoryLabel,
      categoryIcon: categoryIcon,
      isConflict: isConflict,
      isExpanded: isExpanded,
      hasNote: event.note.trim().isNotEmpty,
      requiresLogistics: requiresLogistics,
    );
  }
}
