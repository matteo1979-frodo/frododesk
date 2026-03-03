// lib/models/ips_detail.dart
import 'package:flutter/foundation.dart';

/// Moduli IPS (estendibile in futuro: finanze, salute, auto, ecc.)
enum IpsModule { coverage, finances, health, car }

/// Livello IPS strutturato (deriva dal numero, NON dalla UI)
enum IpsLevel { green, yellow, red }

/// Decisione: Dettaglio mostra SOLO il modulo dominante.
/// Questa struttura rappresenta la spiegazione ufficiale del livello attuale.
@immutable
class IpsDetail {
  final IpsModule dominantModule;

  /// Score 0–100 del modulo dominante (es. copertura 80/60/0).
  final int score;

  /// Livello derivato dal numero (green/yellow/red).
  final IpsLevel level;

  /// Sintesi umana (una frase breve, come Home).
  final String summary;

  /// Dettagli opzionali espandibili (righe).
  final List<String> details;

  /// Impatto reale: cosa rischi / cosa succede se non intervieni.
  final String impact;

  /// Azione suggerita (testo umano). Non decide al posto dell’utente.
  final String suggestedActionLabel;

  /// Rotta logica per navigazione: NON UI hardcoded.
  /// Il CoreStore userà questa chiave per decidere dove portare l’utente.
  final String navigationKey;

  /// Giorno a cui l’azione deve portarti (es. giorno del primo buco).
  /// Nullable: non tutti i moduli avranno una data specifica.
  final DateTime? focusDay;

  const IpsDetail({
    required this.dominantModule,
    required this.score,
    required this.level,
    required this.summary,
    required this.details,
    required this.impact,
    required this.suggestedActionLabel,
    required this.navigationKey,
    this.focusDay,
  });

  IpsDetail copyWith({
    IpsModule? dominantModule,
    int? score,
    IpsLevel? level,
    String? summary,
    List<String>? details,
    String? impact,
    String? suggestedActionLabel,
    String? navigationKey,
    DateTime? focusDay,
  }) {
    return IpsDetail(
      dominantModule: dominantModule ?? this.dominantModule,
      score: score ?? this.score,
      level: level ?? this.level,
      summary: summary ?? this.summary,
      details: details ?? this.details,
      impact: impact ?? this.impact,
      suggestedActionLabel: suggestedActionLabel ?? this.suggestedActionLabel,
      navigationKey: navigationKey ?? this.navigationKey,
      focusDay: focusDay ?? this.focusDay,
    );
  }
}

/// Helpers strutturali (centrali, riusabili)
IpsLevel ipsLevelFromScore(int score) {
  if (score >= 70) return IpsLevel.red;
  if (score >= 40) return IpsLevel.yellow;
  return IpsLevel.green;
}

/// Nomi UI 100% italiano (regola lingua)
String ipsLevelLabelIt(IpsLevel level) {
  switch (level) {
    case IpsLevel.green:
      return "VERDE";
    case IpsLevel.yellow:
      return "GIALLO";
    case IpsLevel.red:
      return "ROSSO";
  }
}

String ipsModuleLabelIt(IpsModule module) {
  switch (module) {
    case IpsModule.coverage:
      return "Copertura";
    case IpsModule.finances:
      return "Finanze";
    case IpsModule.health:
      return "Salute";
    case IpsModule.car:
      return "Auto";
  }
}
