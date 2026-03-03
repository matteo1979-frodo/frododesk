// lib/models/ips_contribution.dart
import 'package:flutter/foundation.dart';

/// Orizzonte temporale del contributo IPS.
/// NOTA: la UI mostrerà testi in italiano, ma il codice resta tecnico in inglese.
enum IpsHorizon {
  short, // breve termine
  medium, // medio termine
  long, // lungo termine
}

/// Contributo standard di un modulo all'IPS.
///
/// Regole strutturali:
/// - score: 0..100 (pressione interna del modulo)
/// - reasons: max 3 frasi umane (in italiano) da mostrare in dettaglio IPS
/// - Il colore (verde/giallo/rosso) NON è qui: lo calcola IPS centralmente.
@immutable
class IpsContribution {
  final String moduleName; // es: "coverage", "finance", "health"
  final int score; // 0..100
  final List<String> reasons; // max 3
  final IpsHorizon horizon;

  const IpsContribution({
    required this.moduleName,
    required this.score,
    required this.reasons,
    required this.horizon,
  }) : assert(score >= 0 && score <= 100, 'score must be between 0 and 100'),
       assert(reasons.length <= 3, 'reasons must contain at most 3 items');

  IpsContribution copyWith({
    String? moduleName,
    int? score,
    List<String>? reasons,
    IpsHorizon? horizon,
  }) {
    return IpsContribution(
      moduleName: moduleName ?? this.moduleName,
      score: score ?? this.score,
      reasons: reasons ?? this.reasons,
      horizon: horizon ?? this.horizon,
    );
  }

  @override
  String toString() {
    return 'IpsContribution(moduleName: $moduleName, score: $score, horizon: $horizon, reasons: $reasons)';
  }
}
