import 'package:flutter/material.dart';

enum RealEventType { generic, visit, trip, appointment, personal, school, work }

@immutable
class RealEvent {
  final String id;

  /// Giorno iniziale dell'evento
  final DateTime startDate;

  /// Giorno finale dell'evento
  final DateTime endDate;

  final String title;

  /// Orario iniziale opzionale
  final TimeOfDay? startTime;

  /// Orario finale opzionale
  final TimeOfDay? endTime;

  /// Tipo evento
  final RealEventType type;

  /// Luogo opzionale
  final String? location;

  /// Persona coinvolta legacy.
  /// Mantenerla per compatibilità con il codice esistente.
  final String? personKey;

  /// Persone coinvolte nell'evento.
  /// Nuova struttura per eventi multi-partecipante.
  final List<String> participantKeys;

  /// Note opzionali
  final String? notes;

  const RealEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.title,
    this.startTime,
    this.endTime,
    this.type = RealEventType.generic,
    this.location,
    this.personKey,
    this.participantKeys = const [],
    this.notes,
  });

  /// Compatibilità temporanea con il codice vecchio:
  /// dove prima esisteva solo "day", usiamo startDate.
  DateTime get day => startDate;

  bool get isMultiDay => !_isSameDate(startDate, endDate);

  bool get hasTimeRange => startTime != null && endTime != null;

  /// Persone effettive dell'evento.
  /// Se participantKeys è vuoto, usa personKey come fallback legacy.
  List<String> get effectiveParticipantKeys {
    if (participantKeys.isNotEmpty) {
      return List.unmodifiable(participantKeys);
    }

    if (personKey != null && personKey!.trim().isNotEmpty) {
      return List.unmodifiable([personKey!.trim()]);
    }

    return const [];
  }

  bool involvesPerson(String key) {
    return effectiveParticipantKeys.contains(key);
  }

  RealEvent copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? title,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    RealEventType? type,
    String? location,
    String? personKey,
    List<String>? participantKeys,
    String? notes,
  }) {
    return RealEvent(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      location: location ?? this.location,
      personKey: personKey ?? this.personKey,
      participantKeys: participantKeys ?? this.participantKeys,
      notes: notes ?? this.notes,
    );
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
