// lib/logic/ips/ips_dominance.dart

import 'ips_module_status.dart';
import 'ips_types.dart';

/// Risultato della dominanza IPS.
/// Contiene il modulo dominante e un flag che dice se la dominanza è scattata
/// per Evento Critico (true) oppure per semplice prevenzione (false).
class IpsDominanceResult {
  final IpsModuleStatus dominant;
  final bool triggeredByCriticalEvent;

  const IpsDominanceResult({
    required this.dominant,
    required this.triggeredByCriticalEvent,
  });
}

/// Seleziona il modulo dominante secondo la logica IBRIDA:
/// 1) Se esiste almeno un modulo in Evento Critico -> domina il critico con score più alto.
/// 2) Se nessun critico -> domina lo score più alto in logica preventiva.
/// In logica preventiva NON si può generare rosso strutturale (massimo giallo).
IpsDominanceResult selectDominantModule(List<IpsModuleStatus> statuses) {
  if (statuses.isEmpty) {
    throw ArgumentError('selectDominantModule: statuses is empty');
  }

  final critical = statuses.where((s) => s.isCriticalEvent).toList();
  if (critical.isNotEmpty) {
    critical.sort((a, b) => b.score.compareTo(a.score));
    return IpsDominanceResult(
      dominant: critical.first,
      triggeredByCriticalEvent: true,
    );
  }

  // Prevenzione: nessun evento critico
  final copy = List<IpsModuleStatus>.from(statuses);
  copy.sort((a, b) => b.score.compareTo(a.score));
  final top = copy.first;

  // In prevenzione, il dominante può avere score alto,
  // ma il sistema NON deve comunicare "rosso strutturale".
  // La trasformazione del level verrà gestita nel Core (non qui),
  // perché il Core calcola IpsLevel. Qui restiamo puri.
  return IpsDominanceResult(dominant: top, triggeredByCriticalEvent: false);
}

/// Helper: normalizza un level in logica preventiva.
/// Se non siamo in Evento Critico, red viene abbassato a yellow.
IpsLevel normalizeLevelForPrevention({
  required IpsLevel level,
  required bool triggeredByCriticalEvent,
}) {
  if (triggeredByCriticalEvent) return level;
  if (level == IpsLevel.red) return IpsLevel.yellow;
  return level;
}
