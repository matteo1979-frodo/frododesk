import 'package:flutter/foundation.dart';

import '../logic/persistence_store.dart';
import '../models/real_expense.dart';

class ExpenseStore extends ChangeNotifier {
  static const String _storageKey = 'real_expenses_v1';

  final List<RealExpense> _expenses = [];

  List<RealExpense> get all => List.unmodifiable(_expenses);

  Future<void> load() async {
    final jsonList = await PersistenceStore.loadJsonList(_storageKey);

    _expenses
      ..clear()
      ..addAll(jsonList.map(RealExpense.fromJson));
    notifyListeners();
  }

  Future<void> save() async {
    final jsonList = _expenses.map((expense) => expense.toJson()).toList();

    await PersistenceStore.saveJsonList(_storageKey, jsonList);
  }

  Future<void> addExpense(RealExpense expense) async {
    _expenses.add(expense);
    await save();
    notifyListeners();
  }

  Future<void> removeExpense(String expenseId) async {
    _expenses.removeWhere((expense) => expense.id == expenseId);
    await save();
    notifyListeners();
  }

  RealExpense? findById(String expenseId) {
    try {
      return _expenses.firstWhere((expense) => expense.id == expenseId);
    } catch (_) {
      return null;
    }
  }
}
