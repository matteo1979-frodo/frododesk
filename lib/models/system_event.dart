// lib/models/system_event.dart
import 'package:flutter/foundation.dart';

/// Tipi di evento che alimenteranno IPS e la Home "Controllo".
/// (In futuro: bollette/scadenze/salute ecc. si aggiungono qui, senza toccare il resto.)
enum SystemEventType {
  overrideChanged, // Step B: cambiato stato/permesso/malattia ecc.
  coverageGapDetected, // Step A/B: rilevato buco di copertura (con orari)
  emergencyToggled, // Modalità Emergenza attivata/disattivata
}

/// Severità evento (serve per IPS e indicatori sintetici).
enum SystemEventSeverity {
  info, // log neutro
  warning, // criticità moderata (copertura debole, rischio)
  critical, // criticità alta (buco vero, emergenza)
}

/// Evento di sistema: forma unica, serializzabile.
/// Niente riferimenti UI. Solo dominio.
@immutable
class SystemEvent {
  final String id; // unico (generato lato store)
  final DateTime createdAt; // timestamp reale evento
  final DateTime day; // giorno "chiave" (00:00) a cui l'evento appartiene

  final SystemEventType type;
  final SystemEventSeverity severity;

  /// Testo umano breve (es. "Buco 07:30–08:40", "Matteo: Malattia a letto")
  final String title;

  /// Dati liberi ma controllati (es: {"fromMin":450,"toMin":520,"who":"Matteo"})
  final Map<String, dynamic> payload;

  const SystemEvent({
    required this.id,
    required this.createdAt,
    required this.day,
    required this.type,
    required this.severity,
    required this.title,
    required this.payload,
  });

  /// Helper: normalizza una data a chiave giorno (00:00)
  static DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'day': day.toIso8601String(),
    'type': type.name,
    'severity': severity.name,
    'title': title,
    'payload': payload,
  };

  static SystemEvent fromJson(Map<String, dynamic> json) {
    return SystemEvent(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      day: DateTime.parse(json['day'] as String),
      type: SystemEventType.values.firstWhere((e) => e.name == json['type']),
      severity: SystemEventSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      title: json['title'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}
