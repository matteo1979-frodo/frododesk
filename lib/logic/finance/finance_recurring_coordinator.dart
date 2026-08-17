import '../../models/finance_category_template.dart';
import '../../models/finance_recurring_draft.dart';
import '../../models/finance_recurring_item.dart';
import '../../stores/finance_store.dart';
import 'builders/finance_recurring_item_builder.dart';

class FinanceRecurringCoordinator {
  final FinanceStore financeStore;
  final FinanceRecurringItemBuilder itemBuilder;
  final DateTime Function() clock;

  FinanceRecurringCoordinator({
    required this.financeStore,
    this.itemBuilder = const FinanceRecurringItemBuilder(),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  FinanceTemplateDefaults defaultsFor(FinanceSmartTemplateType type) {
    return itemBuilder.defaultsFor(type);
  }

  String? validate(FinanceRecurringDraft draft) => itemBuilder.validate(draft);

  Future<FinanceRecurringItem> save(FinanceRecurringDraft draft) async {
    final item = itemBuilder.build(draft, clock());
    if (draft.existing == null) {
      await financeStore.addRecurringItem(item);
    } else {
      await financeStore.updateRecurringItem(item);
    }
    return item;
  }
}
