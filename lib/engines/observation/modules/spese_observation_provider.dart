import '../../../models/frodo_observation.dart';
import '../../../models/real_expense.dart';
import '../../../logic/spese/spese_month_reader.dart';
import '../observation_provider.dart';
import '../../../core/frododesk_modules.dart';

class SpeseObservationProvider implements ObservationProvider {
  final List<RealExpense> allExpenses;

  const SpeseObservationProvider({required this.allExpenses});

  @override
  String get module => FrodoModules.spese;

  @override
  List<FrodoObservation> generate() {
    final now = DateTime.now();

    final currentMonthExpenses = allExpenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();

    final previousMonth = DateTime(now.year, now.month - 1, 1);

    final previousMonthExpenses = allExpenses.where((expense) {
      return expense.date.year == previousMonth.year &&
          expense.date.month == previousMonth.month;
    }).toList();

    return SpeseMonthReader.analyze(
      currentMonthExpenses: currentMonthExpenses,
      previousMonthExpenses: previousMonthExpenses,
    );
  }
}
