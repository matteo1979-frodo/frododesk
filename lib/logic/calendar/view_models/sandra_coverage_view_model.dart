import 'package:flutter/material.dart';

import '../../coverage_engine.dart';

class SandraCoverageViewModel {
  final CoverageSandraDecision decision;

  final bool manualMattina;
  final bool manualPranzo;
  final bool manualSera;

  final TimeOfDay mattinaStart;
  final TimeOfDay mattinaEnd;
  final TimeOfDay pranzoStart;
  final TimeOfDay pranzoEnd;
  final TimeOfDay seraStart;
  final TimeOfDay seraEnd;

  const SandraCoverageViewModel({
    required this.decision,
    required this.manualMattina,
    required this.manualPranzo,
    required this.manualSera,
    required this.mattinaStart,
    required this.mattinaEnd,
    required this.pranzoStart,
    required this.pranzoEnd,
    required this.seraStart,
    required this.seraEnd,
  });
}
