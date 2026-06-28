import '../engines/observation/observation_registry.dart';
import '../engines/observation/modules/spese_observation_provider.dart';
import '../engines/observation/modules/finance_observation_provider.dart';
import '../models/real_expense.dart';
import '../stores/finance_store.dart';

class FrodoDeskBootstrap {
  static void initialize({
    required List<RealExpense> expenses,
    required FinanceStore financeStore,
  }) {
    ObservationRegistry.clear();

    ObservationRegistry.register(
      SpeseObservationProvider(allExpenses: expenses),
    );

    ObservationRegistry.register(
      FinanceObservationProvider(financeStore: financeStore),
    );
  }
}
