import 'package:flutter/material.dart';

class SupportPerson {
  final String id;
  final String name;
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  const SupportPerson({
    required this.id,
    required this.name,
    required this.enabled,
    required this.start,
    required this.end,
  });

  SupportPerson copyWith({
    String? id,
    String? name,
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return SupportPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
