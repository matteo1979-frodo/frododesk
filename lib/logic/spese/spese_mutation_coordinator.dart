import '../../models/real_expense.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/spese_command.dart';
import '../../models/spese_mutation_plan.dart';
import '../../stores/cash_wallet_store.dart';
import '../../stores/expense_store.dart';
import '../../stores/finance_store.dart';

class SpeseMutationCoordinator {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;

  const SpeseMutationCoordinator({
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
  });

  SpeseMutationPlan prepare(SpeseCommand command) {
    if (command.action == SpeseCommandAction.create) {
      return SpeseMutationPlan(
        command: command,
        expenseToCreate: _expenseFrom(command),
      );
    }

    final targetId = command.targetRecordId;
    if (targetId == null || expenseStore.findById(targetId) == null) {
      throw StateError('Movimento da modificare o eliminare non trovato.');
    }
    return SpeseMutationPlan(command: command, expenseIdToRemove: targetId);
  }

  Future<void> execute(SpeseCommand command) => commit(prepare(command));

  Future<void> commit(SpeseMutationPlan plan) async {
    final command = plan.command;
    if (plan.createsExpense) {
      await _commitCreation(command, plan.expenseToCreate!);
      return;
    }
    if (plan.removesExpense) {
      await _commitRemoval(command, plan.expenseIdToRemove!);
      return;
    }
    throw StateError('Piano di mutazione Spese vuoto.');
  }

  Future<void> _commitCreation(
    SpeseCommand command,
    RealExpense expense,
  ) async {
    final economicFactId = _economicFactId(command);
    switch (command.kind) {
      case SpeseCommandKind.expense:
        await financeStore.registerRealExpense(
          balanceId: command.origin.referenceId!,
          amount: command.amount,
          description: command.description,
          notes: command.category,
          economicFactId: economicFactId,
        );
      case SpeseCommandKind.extraIncome:
        await financeStore.registerExtraIncome(
          balanceId: command.destination.referenceId!,
          amount: command.amount,
          description: command.description,
          economicFactId: economicFactId,
        );
      case SpeseCommandKind.cashWithdrawal:
        await financeStore.registerRealExpense(
          balanceId: command.origin.referenceId!,
          amount: command.amount,
          description: command.description,
          notes: command.destination.label,
          economicFactId: economicFactId,
        );
        await cashWalletStore.addCash(
          walletId: command.destination.referenceId!,
          amount: command.amount,
        );
    }
    await expenseStore.addExpense(expense);
  }

  Future<void> _commitRemoval(SpeseCommand command, String expenseId) async {
    switch (command.kind) {
      case SpeseCommandKind.extraIncome:
        await financeStore.removeExtraIncome(
          balanceId: command.destination.referenceId!,
          amount: command.amount,
          description: command.description,
        );
      case SpeseCommandKind.expense:
        await financeStore.restoreRealExpense(
          balanceId: command.origin.referenceId!,
          amount: command.amount,
          description: command.description,
        );
      case SpeseCommandKind.cashWithdrawal:
        await financeStore.restoreRealExpense(
          balanceId: command.origin.referenceId!,
          amount: command.amount,
          description: command.description,
        );
        await cashWalletStore.removeCash(
          walletId: command.destination.referenceId!,
          amount: command.amount,
        );
    }
    await expenseStore.removeExpense(expenseId);
  }

  RealExpense _expenseFrom(SpeseCommand command) {
    return RealExpense(
      id: command.id,
      economicFactId: _economicFactId(command),
      balanceId: command.kind == SpeseCommandKind.extraIncome
          ? command.destination.referenceId!
          : command.origin.referenceId!,
      balanceName: command.kind == SpeseCommandKind.extraIncome
          ? command.destination.label
          : command.origin.label,
      amount: command.amount,
      description: command.description,
      category: command.category,
      date: command.occurredAt,
      isCashWithdrawal: command.kind == SpeseCommandKind.cashWithdrawal,
      cashWalletId: command.kind == SpeseCommandKind.cashWithdrawal
          ? command.destination.referenceId
          : null,
      isIncome: command.kind == SpeseCommandKind.extraIncome,
      subject: FinanceSubject.values.firstWhere(
        (subject) => subject.name == command.personId,
        orElse: () => FinanceSubject.shared,
      ),
    );
  }

  String _economicFactId(SpeseCommand command) =>
      'economic_fact_spese_${command.id}';
}
