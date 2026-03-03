// lib/logic/ips_detail_builder.dart
import '../../models/ips_detail.dart';

/// Chiavi di navigazione (NON UI hardcoded).
/// Il CoreStore mapperà queste chiavi alle schermate reali.
class IpsNavKeys {
  static const String coverage = "nav.coverage";
  static const String finances = "nav.finances";
  static const String health = "nav.health";
  static const String car = "nav.car";
}

/// Builder centrale del Dettaglio IPS.
/// Decisione: mostra SOLO il modulo dominante.
///
/// Nota: per ora supporta Copertura (già reale).
/// Gli altri moduli verranno aggiunti quando esisteranno i loro contributi.
class IpsDetailBuilder {
  const IpsDetailBuilder();

  /// Costruisce un IpsDetail coerente con le regole:
  /// - Livello deriva dal numero
  /// - Sintesi prima, dettagli espandibili dopo
  /// - Impatto + azione suggerita
  /// - Navigazione delegata (navigationKey)
  IpsDetail buildCoverageDetail({
    required int score, // 0 / 60 / 80
    required String summary, // frase umana breve (come Home)
    required List<String> details, // righe espandibili (anche vuote)
    DateTime? focusDay, // ✅ NUOVO: giorno critico
  }) {
    final level = ipsLevelFromScore(score);

    // Impatto (testo umano) - per ora semplice, evolverà.
    final impact = switch (level) {
      IpsLevel.red =>
        "Rischio alto: entro pochi giorni potresti trovarti senza copertura per Alice. Serve una decisione preventiva.",
      IpsLevel.yellow =>
        "Rischio medio: entro 30 giorni potrebbe presentarsi un buco di copertura. Meglio preparare una soluzione.",
      IpsLevel.green =>
        "Situazione stabile: non risultano buchi di copertura nei prossimi giorni.",
    };

    // Azione suggerita (NON decide).
    final suggested = switch (level) {
      IpsLevel.red => "Apri Calendario e verifica il giorno critico",
      IpsLevel.yellow => "Apri Calendario e controlla i prossimi giorni",
      IpsLevel.green => "Apri Copertura per conferma",
    };

    return IpsDetail(
      dominantModule: IpsModule.coverage,
      score: score.clamp(0, 100),
      level: level,
      summary: summary,
      details: details,
      impact: impact,
      suggestedActionLabel: suggested,
      navigationKey: IpsNavKeys.coverage,
      focusDay: focusDay, // ✅ passato dentro
    );
  }
}
