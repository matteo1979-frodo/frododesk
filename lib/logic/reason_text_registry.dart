// lib/logic/reason_text_registry.dart
//
// FRODODESK - ReasonText Registry
// Aggrega i dizionari dei moduli.
// Non contiene logica IPS.
// Non decide dominanza.
// Fa solo lookup.

import '../models/ips_snapshot.dart';
import '../modules/coverage/coverage_reason_texts.dart';

typedef ReasonDictionary = Map<String, ReasonText>;

class ReasonTextRegistry {
  final Map<IpsModule, ReasonDictionary> _registry;

  ReasonTextRegistry._(this._registry);

  /// Factory che costruisce il registry aggregando i moduli attivi.
  factory ReasonTextRegistry.build() {
    return ReasonTextRegistry._({
      IpsModule.coverage: coverageReasonTexts,
      // Futuri moduli verranno aggiunti qui
    });
  }

  /// Lookup sicuro.
  /// Se non trova il reasonCode, ritorna fallback neutro.
  ReasonText lookup(IpsModule module, String reasonCode) {
    final moduleDict = _registry[module];
    if (moduleDict == null) {
      return _fallback(reasonCode);
    }

    final reason = moduleDict[reasonCode];
    if (reason == null) {
      return _fallback(reasonCode);
    }

    return reason;
  }

  ReasonText _fallback(String reasonCode) {
    return ReasonText(
      title: "Informazione disponibile",
      description: "Dettaglio non disponibile per il codice $reasonCode.",
      actionLabel: "Apri calendario",
      action: const ActionIntent(target: ActionTargetType.calendarDay),
    );
  }
}
