import 'real_expense.dart';
import 'spese_command.dart';

class SpeseMutationPlan {
  final SpeseCommand command;
  final RealExpense? expenseToCreate;
  final String? expenseIdToRemove;

  const SpeseMutationPlan({
    required this.command,
    this.expenseToCreate,
    this.expenseIdToRemove,
  });

  bool get createsExpense => expenseToCreate != null;
  bool get removesExpense => expenseIdToRemove != null;
}
