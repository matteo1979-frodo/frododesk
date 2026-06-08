import '../logic/persistence_store.dart';
import '../models/real_expense.dart';

class ExpenseStore {
  static const String _storageKey = 'real_expenses_v1';

  final List<RealExpense> expenses = [];

  List<RealExpense> get all => List.unmodifiable(expenses);

  Future<void> load() async {
    final jsonList = await PersistenceStore.loadJsonList(_storageKey);

    expenses
      ..clear()
      ..addAll(jsonList.map(RealExpense.fromJson));
  }

  Future<void> save() async {
    final jsonList = expenses.map((expense) => expense.toJson()).toList();

    await PersistenceStore.saveJsonList(_storageKey, jsonList);
  }

  Future<void> addExpense(RealExpense expense) async {
    expenses.add(expense);
    await save();
  }
}