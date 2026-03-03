// lib/logic/ips/ips_detail_snapshot.dart

import 'ips_types.dart';

/// Snapshot strutturale puro per la UI del Dettaglio IPS (Fase 2).
/// La UI legge questo oggetto e formatta le stringhe.
/// Nessuna logica UI qui.
class IpsDetailSnapshot {
  final IpsModuleId moduleId;
  final int score; // 0..100
  final IpsLevel level;

  /// True solo se il modulo dominante è in Evento Critico certificato.
  final bool isCriticalEvent;

  /// Reason code definito dal modulo dominante (enum specifico modulo).
  /// Tipizzato tramite interfaccia comune.
  final ModuleReasonCode reasonCode;

  /// Data di riferimento per navigazione al giorno critico (se applicabile).
  /// Esempio: per Copertura può essere il giorno del primo buco critico.
  final DateTime? referenceDate;

  /// Payload modulo-specifico (dati puri, niente stringhe UI).
  /// Esempio Copertura: lista buchi con start/end.
  final Object? payload;

  const IpsDetailSnapshot({
    required this.moduleId,
    required this.score,
    required this.level,
    required this.isCriticalEvent,
    required this.reasonCode,
    this.referenceDate,
    this.payload,
  });

  /// Safety: clamp score in range 0..100 (utile per test/debug).
  IpsDetailSnapshot normalized() {
    final clamped = score.clamp(0, 100);
    return IpsDetailSnapshot(
      moduleId: moduleId,
      score: clamped,
      level: level,
      isCriticalEvent: isCriticalEvent,
      reasonCode: reasonCode,
      referenceDate: referenceDate,
      payload: payload,
    );
  }
}
