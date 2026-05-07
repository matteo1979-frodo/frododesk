import 'package:flutter/material.dart';

import '../logic/alice_events/alice_event_behavior.dart';

enum AliceSpecialEventCategory { school, sport, health, activity, other }

class AliceSpecialEvent {
  final String id;
  final String label;
  final AliceSpecialEventCategory category;
  final AliceEventBehavior behavior;

  /// Adulto associato all'evento accompagnato.
  ///
  /// Esempi:
  /// - matteo
  /// - chiara
  /// - sandra
  /// - supporto
  final String? accompanyingAdultKey;

  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final String note;
  final bool enabled;

  const AliceSpecialEvent({
    required this.id,
    required this.label,
    required this.category,
    this.behavior = AliceEventBehavior.logistic,
    this.accompanyingAdultKey,
    required this.date,
    required this.start,
    required this.end,
    this.note = '',
    this.enabled = true,
  });

  AliceSpecialEvent copyWith({
    String? id,
    String? label,
    AliceSpecialEventCategory? category,
    AliceEventBehavior? behavior,
    String? accompanyingAdultKey,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    String? note,
    bool? enabled,
  }) {
    return AliceSpecialEvent(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      behavior: behavior ?? this.behavior,
      accompanyingAdultKey: accompanyingAdultKey ?? this.accompanyingAdultKey,
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      note: note ?? this.note,
      enabled: enabled ?? this.enabled,
    );
  }
}
