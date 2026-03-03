// lib/logic/ips/ips_module_status.dart

import 'ips_types.dart';

/// Stato strutturale di un modulo IPS.
/// Viene prodotto dal modulo.
/// Il Core lo legge e decide la dominanza.
/// Nessuna logica qui dentro.
class IpsModuleStatus {
  final IpsModuleId moduleId;

  /// Score 0..100 prodotto dal modulo.
  final int score;

  /// True solo se il modulo è in Evento Critico certificato.
  final bool isCriticalEvent;

  /// Reason tecnico definito dal modulo.
  final ModuleReasonCode reasonCode;

  const IpsModuleStatus({
    required this.moduleId,
    required this.score,
    required this.isCriticalEvent,
    required this.reasonCode,
  });
}
