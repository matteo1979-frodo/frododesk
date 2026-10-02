import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_lifecycle_loader.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test('runs the current finance lifecycle then refreshes Home', () async {
    final operations = <String>[];
    final store = _RecordingFinanceStore(operations);
    final loader = FinanceLifecycleLoader(
      financeStore: store,
      refresh: () => operations.add('refresh'),
    );

    await loader.load();

    expect(operations, [
      'loadInitialRealData',
      'loadSavedFiniteFinancialPlans',
      'loadSavedExpectedExpenses',
      'loadSavedDocumentaryObligations',
      'loadSavedIncomes',
      'saveBalances',
      'saveFunds',
      'saveRecurringItems',
      'saveSnapshot',
      'refresh',
    ]);
    expect(store.snapshotDate, isNotNull);
  });
}

class _RecordingFinanceStore extends FinanceStore {
  final List<String> operations;
  DateTime? snapshotDate;

  _RecordingFinanceStore(this.operations);

  @override
  Future<void> loadInitialRealData() async {
    operations.add('loadInitialRealData');
  }

  @override
  Future<void> loadSavedFiniteFinancialPlans() async {
    operations.add('loadSavedFiniteFinancialPlans');
  }

  @override
  Future<void> loadSavedExpectedExpenses() async {
    operations.add('loadSavedExpectedExpenses');
  }

  @override
  Future<void> loadSavedDocumentaryObligations() async {
    operations.add('loadSavedDocumentaryObligations');
  }

  @override
  Future<void> loadSavedIncomes() async {
    operations.add('loadSavedIncomes');
  }

  @override
  Future<void> saveBalances() async {
    operations.add('saveBalances');
  }

  @override
  Future<void> saveFunds() async {
    operations.add('saveFunds');
  }

  @override
  Future<void> saveRecurringItems() async {
    operations.add('saveRecurringItems');
  }

  @override
  Future<void> saveSnapshot(DateTime date) async {
    operations.add('saveSnapshot');
    snapshotDate = date;
  }
}
