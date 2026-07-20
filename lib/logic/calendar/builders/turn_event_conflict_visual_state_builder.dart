import 'package:flutter/material.dart';

import '../../../utils/calendario_formatters.dart';
import '../models/turn_event_conflict.dart';
import '../models/turn_event_conflict_visual_state.dart';

class TurnEventConflictVisualStateBuilder {
  const TurnEventConflictVisualStateBuilder();

  TurnEventConflictVisualState build({
    required TurnEventConflictState worst,
    required bool isForced,
    required bool isBedSick,
    required String personName,
  }) {
    final color = isForced ? Colors.orange : conflictStateColor(worst);

    final String title;
    final String subtitle;

    switch (worst) {
      case TurnEventConflictState.open:
        if (isForced) {
          title = "⚠ Uscita imprescindibile — $personName";
          subtitle =
              "Hai forzato l'uscita nonostante il conflitto. Il sistema non la blocca ma la considera rischio.";
        } else if (isBedSick) {
          title = "⚠ Conflitto reale — $personName";
          subtitle =
              "Evento incompatibile con malattia a letto (uscita non possibile).";
        } else {
          title = "Conflitto turno / evento — $personName";
          subtitle = "Serve una decisione operativa.";
        }
        break;

      case TurnEventConflictState.partial:
        title = "Conflitto turno / evento — $personName";
        subtitle = "Esiste una copertura parziale.";
        break;

      case TurnEventConflictState.resolved:
        title = "Conflitto turno / evento — $personName";
        subtitle = "Conflitto risolto da una decisione valida.";
        break;
    }

    return TurnEventConflictVisualState(
      color: color,
      title: title,
      subtitle: subtitle,
    );
  }
}
