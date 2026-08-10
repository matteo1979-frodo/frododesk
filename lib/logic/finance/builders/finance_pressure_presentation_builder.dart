import '../../../models/finance_pressure_presentation.dart';

class FinancePressurePresentationBuilder {
  const FinancePressurePresentationBuilder();

  FinancePressurePresentation build(double economicPressureScore) {
    if (economicPressureScore < 500) {
      return const FinancePressurePresentation(
        title: 'Pressione economica bassa',
        description: 'Situazione stabile e sostenibile.',
        state: FinancePressureState.low,
        color: 0xFF66BB6A,
      );
    }
    if (economicPressureScore < 1500) {
      return const FinancePressurePresentation(
        title: 'Pressione economica media',
        description: 'Le uscite iniziano a pesare.',
        state: FinancePressureState.medium,
        color: 0xFFFFB300,
      );
    }
    if (economicPressureScore < 3000) {
      return const FinancePressurePresentation(
        title: 'Pressione economica alta',
        description: 'Serve attenzione sulle prossime spese.',
        state: FinancePressureState.high,
        color: 0xFFE57373,
      );
    }
    return const FinancePressurePresentation(
      title: 'Pressione economica critica',
      description: 'La situazione economica è sotto forte pressione.',
      state: FinancePressureState.critical,
      color: 0xFFD32F2F,
    );
  }
}
