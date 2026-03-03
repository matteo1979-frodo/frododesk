// lib/logic/ips/ips_types.dart

/// Identificativo dei moduli IPS.
/// Enum semplice. Nessuna logica interna.
/// Le estensioni future verranno gestite esternamente.
enum IpsModuleId { coverage, finance, health, auto }

/// Livello derivato dallo score IPS.
/// Le soglie NON sono definite qui.
/// La derivazione avviene nel Core.
enum IpsLevel { green, yellow, red }

/// Interfaccia comune per i reasonCode dei moduli.
/// Ogni modulo definirà il proprio enum che implementa questa interfaccia.
/// Il Core lavora su questo tipo astratto.
abstract interface class ModuleReasonCode {
  /// Codice tecnico stabile.
  /// Utilizzabile per logging, persistenza futura e storico IPS.
  String code();
}
