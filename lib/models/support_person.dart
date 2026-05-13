import 'package:flutter/material.dart';

class SupportTimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;

  const SupportTimeSlot({
    required this.start,
    required this.end,
  });
}

class SupportPerson {
  final String id;
  final String name;
  final bool enabled;

  // Compatibilità vecchia logica
  final TimeOfDay start;
  final TimeOfDay end;

  // Nuova logica: una persona può avere più fasce nello stesso giorno
  final List<SupportTimeSlot> slots;

  const SupportPerson({
    required this.id,
    required this.name,
    required this.enabled,
    required this.start,
    required this.end,
    this.slots = const [],
  });

  List<SupportTimeSlot> get effectiveSlots {
    if (slots.isNotEmpty) return slots;
    return [
      SupportTimeSlot(start: start, end: end),
    ];
  }

  SupportPerson copyWith({
    String? id,
    String? name,
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
    List<SupportTimeSlot>? slots,
  }) {
    return SupportPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
      slots: slots ?? this.slots,
    );
  }
}