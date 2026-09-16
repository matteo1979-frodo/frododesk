import 'dart:convert';

import '../../models/real_expense.dart';
import '../../models/finance_recurring_item.dart';
import '../../models/finance_transaction.dart';
import '../../models/economic_event.dart';
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
        await _commitOrdinaryExpenseCreation(command, expense, economicFactId);
        return;
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
        if (command.destination.kind == EconomicEndpointKind.cash) {
          await cashWalletStore.addCash(
            walletId: command.destination.referenceId!,
            amount: command.amount,
          );
        }
    }
    await expenseStore.addExpense(expense);
  }

  Future<void> _commitOrdinaryExpenseCreation(
    SpeseCommand command,
    RealExpense expense,
    String economicFactId,
  ) async {
    final expectedTransaction = _ordinaryExpenseTransaction(
      command,
      economicFactId,
    );
    var financeMatch = _classifyFinanceTransaction(expectedTransaction);
    final expenseMatch = _classifyExpense(expense);

    if (financeMatch == _RecordMatch.conflicting ||
        expenseMatch == _RecordMatch.conflicting ||
        (financeMatch == _RecordMatch.absent &&
            expenseMatch == _RecordMatch.coherent)) {
      throw StateError('Stato Spese ordinario incompatibile.');
    }
    if (financeMatch == _RecordMatch.coherent &&
        expenseMatch == _RecordMatch.coherent) {
      return;
    }

    if (financeMatch == _RecordMatch.absent) {
      await financeStore.registerRealExpense(
        balanceId: command.origin.referenceId!,
        amount: command.amount,
        description: command.description,
        notes: command.category,
        economicFactId: economicFactId,
        occurredAt: command.occurredAt,
        transactionId: expectedTransaction.id,
      );
      financeMatch = _classifyFinanceTransaction(expectedTransaction);
      if (financeMatch != _RecordMatch.coherent) {
        throw StateError('Persistenza Finance della Spesa non verificabile.');
      }
    }

    final addition = await expenseStore.addExpenseVerified(expense);
    if (!addition.isSuccess) {
      throw StateError(
        addition.errors.isEmpty
            ? 'Persistenza Expense della Spesa fallita.'
            : addition.errors.join('; '),
      );
    }
  }

  FinanceTransaction _ordinaryExpenseTransaction(
    SpeseCommand command,
    String economicFactId,
  ) => FinanceTransaction(
    id: _ordinaryExpenseTransactionId(economicFactId),
    balanceId: command.origin.referenceId!,
    amount: command.amount,
    date: command.occurredAt,
    isIncome: false,
    subject: _subject(command.personId),
    description: command.description,
    type: FinanceTransactionType.expense,
    origin: FinanceTransactionOrigin.manual,
    notes: command.category,
    economicFactId: economicFactId,
  );

  String _ordinaryExpenseTransactionId(String economicFactId) =>
      'real_expense_spese_${base64Url.encode(utf8.encode(economicFactId))}';

  _RecordMatch _classifyFinanceTransaction(FinanceTransaction expected) {
    final matches = financeStore.transactions
        .where(
          (item) =>
              item.id == expected.id ||
              item.economicFactId == expected.economicFactId,
        )
        .toList();
    if (matches.isEmpty) return _RecordMatch.absent;
    if (matches.length != 1 || !_sameTransaction(matches.single, expected)) {
      return _RecordMatch.conflicting;
    }
    return _RecordMatch.coherent;
  }

  _RecordMatch _classifyExpense(RealExpense expected) {
    final matches = expenseStore.all
        .where(
          (item) =>
              item.id == expected.id ||
              item.economicFactId == expected.economicFactId,
        )
        .toList();
    if (matches.isEmpty) return _RecordMatch.absent;
    if (matches.length != 1 || !_sameExpense(matches.single, expected)) {
      return _RecordMatch.conflicting;
    }
    return _RecordMatch.coherent;
  }

  bool _sameTransaction(FinanceTransaction left, FinanceTransaction right) =>
      left.id == right.id &&
      left.balanceId == right.balanceId &&
      left.amount == right.amount &&
      left.date == right.date &&
      left.isIncome == right.isIncome &&
      left.subject == right.subject &&
      left.description == right.description &&
      left.type == right.type &&
      left.origin == right.origin &&
      left.notes == right.notes &&
      left.economicFactId == right.economicFactId &&
      left.operationMetadata == null;

  bool _sameExpense(RealExpense left, RealExpense right) =>
      left.id == right.id &&
      left.balanceId == right.balanceId &&
      left.balanceName == right.balanceName &&
      left.amount == right.amount &&
      left.description == right.description &&
      left.category == right.category &&
      left.date == right.date &&
      left.nonTrackedCash == right.nonTrackedCash &&
      left.isCashWithdrawal == right.isCashWithdrawal &&
      left.isIncome == right.isIncome &&
      left.subject == right.subject &&
      left.cashWalletId == right.cashWalletId &&
      left.economicFactId == right.economicFactId &&
      left.operationMetadata == right.operationMetadata;

  FinanceSubject _subject(String? personId) => FinanceSubject.values.firstWhere(
    (subject) => subject.name == personId,
    orElse: () => FinanceSubject.shared,
  );

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
        if (command.destination.kind == EconomicEndpointKind.cash) {
          await cashWalletStore.removeCash(
            walletId: command.destination.referenceId!,
            amount: command.amount,
          );
        }
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
      nonTrackedCash:
          command.kind == SpeseCommandKind.cashWithdrawal &&
          command.destination.kind == EconomicEndpointKind.external,
      cashWalletId: command.kind == SpeseCommandKind.cashWithdrawal
          ? command.destination.kind == EconomicEndpointKind.cash
                ? command.destination.referenceId
                : null
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

enum _RecordMatch { absent, coherent, conflicting }
