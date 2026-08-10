import '../../models/home_finance_view_data.dart';
import '../../models/home_observed_at.dart';
import '../../stores/finance_store.dart';
import 'builders/finance_module_presentation_builder.dart';
import 'builders/finance_pressure_presentation_builder.dart';
import 'builders/finance_summary_builder.dart';

class HomeFinanceCoordinator {
  final FinanceStore financeStore;
  final FinanceSummaryBuilder summaryBuilder;
  final FinancePressurePresentationBuilder pressurePresentationBuilder;
  final FinanceModulePresentationBuilder modulePresentationBuilder;

  const HomeFinanceCoordinator({
    required this.financeStore,
    this.summaryBuilder = const FinanceSummaryBuilder(),
    this.pressurePresentationBuilder =
        const FinancePressurePresentationBuilder(),
    this.modulePresentationBuilder = const FinanceModulePresentationBuilder(),
  });

  HomeFinanceViewData build({required HomeObservedAt observedAt}) {
    final snapshot = summaryBuilder.build(
      financeStore: financeStore,
      observedAt: observedAt,
    );
    final pressurePresentation = pressurePresentationBuilder.build(
      snapshot.economicPressureScore,
    );
    final modulePresentation = modulePresentationBuilder.build(snapshot);

    return HomeFinanceViewData(
      pressurePresentation: pressurePresentation,
      modulePresentation: modulePresentation,
    );
  }
}
