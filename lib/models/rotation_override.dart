import 'package:flutter/foundation.dart';
import 'turn_override.dart';

enum RotationStartPoint { mattina, notte, pomeriggio }

@immutable
class RotationOverride {
  final TurnPersonId person;
  final DateTime startDate;
  final RotationStartPoint startPoint;

  const RotationOverride({
    required this.person,
    required this.startDate,
    required this.startPoint,
  });
}
