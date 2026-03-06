import '../models/day_override.dart';
import 'override_store.dart';
import 'coverage_engine.dart';
import 'ferie_period_store.dart';

/// Adapter certificato: usa CoverageEngine + OverrideStore (+ flags per giorno)
/// per calcolare rischio su orizzonte (es. 30 giorni).
class CoverageAdapter {
  final OverrideStore overrideStore;
  final CoverageEngine engine;
  final FeriePeriodStore ferieStore;

  /// Sandra globale per giorno (legacy: unico toggle)
  final bool Function(DateTime day) sandraDisponibileForDay;

  /// Uscita 13 per giorno
  final bool Function(DateTime day) uscita13ForDay;

  CoverageAdapter({
    required this.overrideStore,
    required this.engine,
    required this.ferieStore,
    required this.sandraDisponibileForDay,
    required this.uscita13ForDay,
  });

  /// Ritorna le stringhe-buco per un giorno (metodo di comodo)
  List<String> gapsForDay(DateTime day) {
    final d0 = DateTime(day.year, day.month, day.day);
    final DayOverrides ov = overrideStore.getForDay(d0);

    final bool uscita13 = uscita13ForDay(d0);
    final bool sandraOn = sandraDisponibileForDay(d0);

    return engine.gapsForDay(
      day: d0,
      uscita13: uscita13,
      sandraAvailable: sandraOn,
      overrides: ov,
      ferieStore: ferieStore,
    );
  }

  /// Rischio su 30 giorni:
  /// - 25 se c'è un buco OGGI
  /// - 20 se c'è un buco entro 30 giorni
  /// - 0 se nessun buco
  int riskScore30Days({DateTime? startDay}) {
    final DateTime base = startDay ?? DateTime.now();
    final DateTime start = DateTime(base.year, base.month, base.day);

    final todayGaps = gapsForDay(start);
    if (todayGaps.isNotEmpty) return 25;

    for (int i = 1; i < 30; i++) {
      final d = start.add(Duration(days: i));
      final g = gapsForDay(d);
      if (g.isNotEmpty) return 20;
    }

    return 0;
  }
}