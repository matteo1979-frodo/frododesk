import '../../../models/frodo_observation.dart';
import '../../../stores/finance_store.dart';
import '../observation_provider.dart';
import '../../../logic/finance/finance_observation_reader.dart';
import '../../../core/frododesk_modules.dart';

class FinanceObservationProvider implements ObservationProvider {
  final FinanceStore financeStore;

  const FinanceObservationProvider({required this.financeStore});

  @override
  String get module => FrodoModules.finance;

  @override
  List<FrodoObservation> generate() {
    return FinanceObservationReader.analyze(financeStore);
  }
}
