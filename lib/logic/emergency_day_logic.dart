// lib/logic/emergency_day_logic.dart
import 'package:flutter/foundation.dart';

import '../models/day_override.dart'; // OverrideStatus
import 'emergency_store.dart';

/// Tipi di evento emergenza (Centro di Controllo Alice)
enum EmergencyEventType {
  morningSchool, // vestizione + accompagnamento
  afternoonPickup, // ritiro + rientro
  homeReturnDelicate, // rientro/gestione casa delicata
}

/// Esito per singolo evento (✅/🟧/❌) + “non rilevante”
enum EmergencyEventOutcome {
  notRelevant, // evento non mostrato oggi
  coveredOk, // ✅ coperto bene (genitore operativo)
  coveredFragile, // 🟧 coperto ma fragile (solo Sandra o genitore malattia leggera)
  uncovered, // ❌ scoperto
}

/// Dettaglio evento pronto per UI
@immutable
class EmergencyEventResult {
  final EmergencyEventType type;
  final EmergencyEventOutcome outcome;

  /// Orario (minuti da mezzanotte) se applicabile (mattina/pomeriggio)
  final EmergencyTimeRange? range;

  /// Nota “umana” per UI (facoltativa)
  final String? note;

  const EmergencyEventResult({
    required this.type,
    required this.outcome,
    this.range,
    this.note,
  });

  String get emoji {
    switch (outcome) {
      case EmergencyEventOutcome.coveredOk:
        return '✅';
      case EmergencyEventOutcome.coveredFragile:
        return '🟧';
      case EmergencyEventOutcome.uncovered:
        return '❌';
      case EmergencyEventOutcome.notRelevant:
        return '—';
    }
  }
}

/// “Snapshot” logico della giornata in emergenza
@immutable
class EmergencyDayResult {
  /// Emerg. forzata (entrambi malattia a letto)
  final bool forcedEmergency;

  /// Emerg. attiva (forzata o toggle manuale)
  final bool emergencyEnabled;

  /// Eventi pronti da mostrare (già filtrati “solo se rilevanti”)
  final List<EmergencyEventResult> events;

  const EmergencyDayResult({
    required this.forcedEmergency,
    required this.emergencyEnabled,
    required this.events,
  });
}

/// Logica “Modalità Emergenza” (PRO) centrata su Alice.
/// CNC: modulo indipendente.
/// - Decide se emergenza è forzata (entrambi malattia a letto)
/// - Decide quali eventi sono rilevanti oggi (solo se rilevanti)
/// - Produce esiti separati per Mattina / Pomeriggio / Rientro delicato
///
/// IMPORTANTISSIMO:
/// Questo blocco NON calcola ancora i turni lavoro.
/// Per classificare copertura/fragilità usa input “semplici” che la UI (o un altro modulo)
/// può passare:
/// - per ogni evento: genitoreOperativo, genitoreFragile, sandraDisponibile.
///
/// Nel prossimo passo lo collegheremo ai calcoli reali (Step A + override) SENZA rompere nulla.
class EmergencyDayLogic {
  const EmergencyDayLogic();

  /// True se è un giorno “scuola standard” (lun–ven).
  /// (Step D futuro: vacanze/scuola realistica)
  bool isSchoolDay(DateTime day) {
    final wd = day.weekday; // 1=Mon ... 7=Sun
    return wd >= DateTime.monday && wd <= DateTime.friday;
  }

  /// True se entrambi i genitori sono in MalattiaALetto.
  bool isForcedEmergency({
    required OverrideStatus matteo,
    required OverrideStatus chiara,
  }) {
    return matteo == OverrideStatus.malattiaALetto &&
        chiara == OverrideStatus.malattiaALetto;
  }

  /// Regola outcome per un evento:
  /// - ✅ coveredOk: almeno un genitore “operativo”
  /// - 🟧 coveredFragile: coperto solo da Sandra o da genitore “fragile”
  /// - ❌ uncovered: nessuno copre
  EmergencyEventOutcome _classifyEvent({
    required bool parentOperational,
    required bool parentFragile,
    required bool sandraCovers,
  }) {
    if (parentOperational) return EmergencyEventOutcome.coveredOk;
    // nessun genitore operativo
    if (sandraCovers || parentFragile)
      return EmergencyEventOutcome.coveredFragile;
    return EmergencyEventOutcome.uncovered;
  }

  /// Costruisce il “centro controllo” per il giorno selezionato.
  ///
  /// Inputs:
  /// - day: giorno selezionato
  /// - settings: EmergencySettings dal tuo EmergencyStore
  /// - matteoStatus/chiaraStatus: override reali (Step B)
  ///
  /// - sandraMorning/sandraAfternoon: Sandra copre quell’evento oggi?
  ///   (per ora li passerai dalla UI; poi li automatizziamo)
  ///
  /// - parentOperationalMorning / parentOperationalAfternoon:
  ///   almeno un genitore è “operativo” in quell’evento?
  ///   (per ora lo passi tu; poi lo calcoliamo con Step A + override)
  ///
  /// - parentFragileMorning / parentFragileAfternoon:
  ///   copertura “debole” (es. genitore in malattia leggera ma presente)
  EmergencyDayResult buildDay({
    required DateTime day,
    required EmergencySettings settings,
    required OverrideStatus matteoStatus,
    required OverrideStatus chiaraStatus,

    // Sandra copre evento?
    required bool sandraMorning,
    required bool sandraAfternoon,

    // Genitori operativi evento?
    required bool parentOperationalMorning,
    required bool parentOperationalAfternoon,

    // Genitori fragili evento?
    required bool parentFragileMorning,
    required bool parentFragileAfternoon,
  }) {
    final k = emergencyDayKey(day);
    final forced = isForcedEmergency(
      matteo: matteoStatus,
      chiara: chiaraStatus,
    );
    final enabled = settings.effectiveEnabled(forced: forced);

    // Se emergenza non è attiva, non mostriamo nulla (la UI resterà in modalità normale).
    if (!enabled) {
      return EmergencyDayResult(
        forcedEmergency: forced,
        emergencyEnabled: false,
        events: const [],
      );
    }

    final List<EmergencyEventResult> out = [];

    final school = isSchoolDay(k);

    // --- MATTINA SCUOLA (solo se rilevante) ---
    final morningRelevant = school && settings.morningEnabled;
    if (morningRelevant) {
      final outcome = _classifyEvent(
        parentOperational: parentOperationalMorning,
        parentFragile: parentFragileMorning,
        sandraCovers: sandraMorning,
      );

      out.add(
        EmergencyEventResult(
          type: EmergencyEventType.morningSchool,
          outcome: outcome,
          range: settings.morningRange,
          note: outcome == EmergencyEventOutcome.uncovered
              ? 'Serve copertura per portare Alice a scuola.'
              : null,
        ),
      );
    }

    // --- POMERIGGIO / RITIRO (solo se rilevante) ---
    final afternoonRelevant = school && settings.afternoonEnabled;
    if (afternoonRelevant) {
      final outcome = _classifyEvent(
        parentOperational: parentOperationalAfternoon,
        parentFragile: parentFragileAfternoon,
        sandraCovers: sandraAfternoon,
      );

      out.add(
        EmergencyEventResult(
          type: EmergencyEventType.afternoonPickup,
          outcome: outcome,
          range: settings.afternoonRange,
          note: outcome == EmergencyEventOutcome.uncovered
              ? 'Serve copertura per ritiro e rientro da scuola.'
              : null,
        ),
      );
    }

    // --- RIENTRO DELICATO (solo se davvero rilevante) ---
    // Regola PRO: lo mostriamo solo se entrambi allettati (forced) o flag manuale.
    final delicateRelevant = forced || settings.homeReturnDelicate;
    if (delicateRelevant) {
      // Qui non è “copertura” oraria: è un rischio logistico.
      // Se forced => di default lo marchiamo 🟧 (fragile) perché è delicato.
      final outcome = forced
          ? EmergencyEventOutcome.coveredFragile
          : EmergencyEventOutcome.coveredFragile;

      out.add(
        EmergencyEventResult(
          type: EmergencyEventType.homeReturnDelicate,
          outcome: outcome,
          range: null,
          note: forced
              ? 'Entrambi allettati: rientro a casa delicato.'
              : 'Rientro a casa delicato (segnato manualmente).',
        ),
      );
    }

    return EmergencyDayResult(
      forcedEmergency: forced,
      emergencyEnabled: true,
      events: out,
    );
  }
}
