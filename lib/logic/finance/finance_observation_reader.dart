import '../../models/frodo_observation.dart';
import '../../stores/finance_store.dart';
import '../../core/frododesk_modules.dart';

class FinanceObservationReader {
  static List<FrodoObservation> analyze(FinanceStore financeStore) {
    final now = DateTime.now();
    final monthKey = '${now.year}_${now.month.toString().padLeft(2, '0')}';

    if (!financeStore.isUnderPressure()) {
      return [
        FrodoObservation(
          id: 'finance_pressure_stable_$monthKey',
          module: FrodoModules.finance,
          category: FrodoObservationCategory.finance,
          title: 'Situazione economica stabile',
          message:
              'La simulazione economica del mese non mostra pressione negativa.',
          priority: 40,
          level: FrodoObservationLevel.success,
          createdAt: now,
        ),
      ];
    }

    return [
      FrodoObservation(
        id: 'finance_pressure_warning_$monthKey',
        module: FrodoModules.finance,
        category: FrodoObservationCategory.finance,
        title: 'Pressione economica prevista',
        message: 'Le uscite previste superano le entrate previste del mese.',
        priority: 90,
        level: FrodoObservationLevel.attention,
        createdAt: now,
      ),
    ];
  }
}
