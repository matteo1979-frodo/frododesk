// lib/modules/coverage/coverage_reason_texts.dart
//
// FRODODESK - Coverage Reason Texts
// Il modulo Coverage possiede il suo linguaggio umano.
// Nessuna logica IPS qui.
// Solo mapping reasonCode -> ReasonText.

import '../../models/ips_snapshot.dart';

final Map<String, ReasonText> coverageReasonTexts = {
  "coverage.no_gaps_30_days": const ReasonText(
    title: "Copertura stabile",
    description: "Nei prossimi 30 giorni non risultano buchi di copertura.",
    actionLabel: "Apri calendario",
    action: ActionIntent(target: ActionTargetType.calendarDay),
  ),
  "coverage.gap_within_7_days": const ReasonText(
    title: "Buco di copertura imminente",
    description:
        "È stato rilevato un buco di copertura entro i prossimi 7 giorni.",
    actionLabel: "Vai al giorno critico",
    action: ActionIntent(target: ActionTargetType.calendarDay),
  ),
  "coverage.gap_within_30_days": const ReasonText(
    title: "Buco di copertura futuro",
    description:
        "È stato rilevato un buco di copertura entro i prossimi 30 giorni.",
    actionLabel: "Controlla il calendario",
    action: ActionIntent(target: ActionTargetType.calendarDay),
  ),
  "coverage.no_coverage_today": const ReasonText(
    title: "Copertura assente oggi",
    description:
        "Oggi non risulta copertura disponibile in una o più fasce critiche.",
    actionLabel: "Verifica subito",
    action: ActionIntent(target: ActionTargetType.calendarDay),
  ),
};
