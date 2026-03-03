// lib/models/ips_snapshot.dart
//
// FRODODESK - IPS Snapshot v1
// Strutture DATI PURE (fotografia), nessuna logica di calcolo.
//
// Regole:
// - Immutabile
// - Versioning incluso
// - ReasonCode strutturato: "modulo.codice_evento"
// - reasons[] completo + dominantReasonKey
// - meta minimale (Map) senza duplicare il motore
// - ActionTarget tipizzato (enum + payload base)

import 'package:flutter/foundation.dart';

/// Livello IPS derivato dallo score (il calcolo vive nel Core, non qui).
enum IpsLevel { green, yellow, red }

/// Modulo dominante (espandibile in futuro).
enum IpsModule { coverage, finance, health, auto, unknown }

/// Target di navigazione stabile (no stringhe fragili).
enum ActionTargetType {
  calendarDay,
  coverage,
  financeOverview,
  healthOverview,
  autoOverview,
  none,
}

/// Payload minimo e tipizzato per la navigazione.
/// (Per ora: solo referenceDate; espandibile senza rompere lo schema grazie a version).
@immutable
class ActionPayload {
  final DateTime? referenceDate;

  const ActionPayload({this.referenceDate});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'referenceDate': referenceDate?.toIso8601String(),
  };

  factory ActionPayload.fromJson(Map<String, dynamic> json) {
    final rd = json['referenceDate'];
    return ActionPayload(
      referenceDate: (rd is String) ? DateTime.tryParse(rd) : null,
    );
  }
}

/// Intent di azione suggerita: target + payload tipizzato.
@immutable
class ActionIntent {
  final ActionTargetType target;
  final ActionPayload payload;

  const ActionIntent({
    required this.target,
    this.payload = const ActionPayload(),
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'target': target.name,
    'payload': payload.toJson(),
  };

  factory ActionIntent.fromJson(Map<String, dynamic> json) {
    final t = json['target'];
    return ActionIntent(
      target: _parseActionTargetType(t),
      payload: json['payload'] is Map<String, dynamic>
          ? ActionPayload.fromJson(json['payload'] as Map<String, dynamic>)
          : const ActionPayload(),
    );
  }
}

/// Testo umano per la Card (Scelta B: title/description/actionLabel/actionTarget).
/// La severità NON vive qui (vive in score/level).
@immutable
class ReasonText {
  final String title;
  final String description;
  final String actionLabel;
  final ActionIntent action;

  const ReasonText({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.action,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'description': description,
    'actionLabel': actionLabel,
    'action': action.toJson(),
  };

  factory ReasonText.fromJson(Map<String, dynamic> json) => ReasonText(
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    actionLabel: (json['actionLabel'] ?? '').toString(),
    action: json['action'] is Map<String, dynamic>
        ? ActionIntent.fromJson(json['action'] as Map<String, dynamic>)
        : const ActionIntent(target: ActionTargetType.none),
  );
}

/// Una reason strutturale (fotografia), non interpretata.
/// key = "coverage.gap_within_7_days"
@immutable
class IpsReason {
  final String key;
  final IpsModule module;
  final bool eventCritical;

  /// Meta minimale. Regola CNC: non duplicare liste di fasce buco ecc.
  /// Esempi ammessi:
  /// - referenceDate (ISO string)
  /// - daysAhead (int)
  final Map<String, dynamic> meta;

  const IpsReason({
    required this.key,
    required this.module,
    required this.eventCritical,
    this.meta = const <String, dynamic>{},
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'module': module.name,
    'eventCritical': eventCritical,
    'meta': meta,
  };

  factory IpsReason.fromJson(Map<String, dynamic> json) => IpsReason(
    key: (json['key'] ?? '').toString(),
    module: _parseIpsModule(json['module']),
    eventCritical: json['eventCritical'] == true,
    meta: (json['meta'] is Map<String, dynamic>)
        ? (json['meta'] as Map<String, dynamic>)
        : const <String, dynamic>{},
  );
}

/// Snapshot IPS v1 (versionato) - fotografia pura.
/// Generato dal Core, letto da UI, salvato nello storico.
@immutable
class IpsSnapshot {
  /// Versione schema snapshot. v1 = 1
  final int version;

  final int score;
  final IpsLevel level;

  final IpsModule dominantModule;
  final bool eventCritical;

  /// Giorno di riferimento per l’azione / causa dominante (se applicabile).
  final DateTime referenceDate;

  /// Lista completa delle reasons (Scelta B).
  final List<IpsReason> reasons;

  /// Chiave della reason dominante (es: "coverage.gap_within_7_days").
  final String dominantReasonKey;

  const IpsSnapshot._({
    required this.version,
    required this.score,
    required this.level,
    required this.dominantModule,
    required this.eventCritical,
    required this.referenceDate,
    required this.reasons,
    required this.dominantReasonKey,
  });

  /// Factory controllata (immutabile + validazioni leggere, ZERO logica IPS).
  factory IpsSnapshot.v1({
    required int score,
    required IpsLevel level,
    required IpsModule dominantModule,
    required bool eventCritical,
    required DateTime referenceDate,
    required List<IpsReason> reasons,
    required String dominantReasonKey,
  }) {
    // Validazioni minime (non “motore”, solo coerenza dati).
    final safeScore = score.clamp(0, 100);
    final safeReasons = List<IpsReason>.unmodifiable(reasons);

    if (dominantReasonKey.isEmpty && safeReasons.isNotEmpty) {
      throw ArgumentError(
        'dominantReasonKey non può essere vuoto se reasons non è vuota',
      );
    }
    if (safeReasons.isNotEmpty &&
        !safeReasons.any((r) => r.key == dominantReasonKey)) {
      throw ArgumentError('dominantReasonKey deve esistere dentro reasons');
    }

    return IpsSnapshot._(
      version: 1,
      score: safeScore,
      level: level,
      dominantModule: dominantModule,
      eventCritical: eventCritical,
      referenceDate: referenceDate,
      reasons: safeReasons,
      dominantReasonKey: dominantReasonKey,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': version,
    'score': score,
    'level': level.name,
    'dominantModule': dominantModule.name,
    'eventCritical': eventCritical,
    'referenceDate': referenceDate.toIso8601String(),
    'dominantReasonKey': dominantReasonKey,
    'reasons': reasons.map((r) => r.toJson()).toList(growable: false),
  };

  factory IpsSnapshot.fromJson(Map<String, dynamic> json) {
    final v = (json['version'] is int) ? (json['version'] as int) : 1;

    // Per ora supportiamo v1. In futuro: switch(v) con migrazioni.
    if (v != 1) {
      throw UnsupportedError('IpsSnapshot version $v non supportata');
    }

    final rd = (json['referenceDate'] is String)
        ? DateTime.tryParse(json['referenceDate'] as String)
        : null;

    final reasonsJson = json['reasons'];
    final parsedReasons = <IpsReason>[];
    if (reasonsJson is List) {
      for (final item in reasonsJson) {
        if (item is Map<String, dynamic>) {
          parsedReasons.add(IpsReason.fromJson(item));
        }
      }
    }

    return IpsSnapshot.v1(
      score: (json['score'] is int) ? (json['score'] as int) : 0,
      level: _parseIpsLevel(json['level']),
      dominantModule: _parseIpsModule(json['dominantModule']),
      eventCritical: json['eventCritical'] == true,
      referenceDate: rd ?? DateTime.now(),
      reasons: parsedReasons,
      dominantReasonKey: (json['dominantReasonKey'] ?? '').toString(),
    );
  }
}

/* ----------------- Helpers (parsing enums) ----------------- */

IpsLevel _parseIpsLevel(dynamic v) {
  final s = (v ?? '').toString();
  for (final e in IpsLevel.values) {
    if (e.name == s) return e;
  }
  // fallback conservativo
  return IpsLevel.green;
}

IpsModule _parseIpsModule(dynamic v) {
  final s = (v ?? '').toString();
  for (final e in IpsModule.values) {
    if (e.name == s) return e;
  }
  return IpsModule.unknown;
}

ActionTargetType _parseActionTargetType(dynamic v) {
  final s = (v ?? '').toString();
  for (final e in ActionTargetType.values) {
    if (e.name == s) return e;
  }
  return ActionTargetType.none;
}
