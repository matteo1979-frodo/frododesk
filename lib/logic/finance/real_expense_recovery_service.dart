import 'dart:convert';

import '../../models/economic_operation_metadata.dart';
import '../../models/finance_transaction.dart';
import '../../models/finance_balance.dart';
import '../../models/finite_financial_plan.dart';
import '../../models/real_expense.dart';
import '../../stores/expense_store.dart';
import 'finance_portfolio_v3_contract.dart';

class RealExpenseRecoveryCandidate {
  final RealExpense expense;
  final String producer;
  final String reason;

  const RealExpenseRecoveryCandidate({
    required this.expense,
    required this.producer,
    required this.reason,
  });
}

class RealExpenseRecoveryPreview {
  final List<RealExpense> existing;
  final List<RealExpenseRecoveryCandidate> candidates;
  final List<RealExpense> finalExpenses;
  final List<String> errors;
  final bool expenseStoreLoaded;
  final bool noEconomicFactCollision;
  final bool excludedReviewAbsent;
  final bool financeUnchanged;
  final bool balancesUnchanged;
  final int expectedExisting;
  final int expectedRecover;
  final int expectedFinal;

  RealExpenseRecoveryPreview({
    required Iterable<RealExpense> existing,
    required Iterable<RealExpenseRecoveryCandidate> candidates,
    required Iterable<RealExpense> finalExpenses,
    required Iterable<String> errors,
    required this.expenseStoreLoaded,
    required this.noEconomicFactCollision,
    required this.excludedReviewAbsent,
    required this.financeUnchanged,
    required this.balancesUnchanged,
    this.expectedExisting = 1,
    this.expectedRecover = 12,
    this.expectedFinal = 13,
  }) : existing = List.unmodifiable(existing),
       candidates = List.unmodifiable(candidates),
       finalExpenses = List.unmodifiable(finalExpenses),
       errors = List.unmodifiable(errors);

  bool get _commonReady =>
      errors.isEmpty &&
      expenseStoreLoaded &&
      noEconomicFactCollision &&
      excludedReviewAbsent &&
      financeUnchanged &&
      balancesUnchanged;

  bool get alreadyRecovered =>
      _commonReady &&
      existing.length == expectedFinal &&
      candidates.isEmpty &&
      finalExpenses.length == expectedFinal;

  bool get ready =>
      _commonReady &&
      ((existing.length == expectedExisting &&
              candidates.length == expectedRecover &&
              finalExpenses.length == expectedFinal) ||
          alreadyRecovered);
}

class RealExpenseRecoveryService {
  final ExpenseStore expenseStore;

  const RealExpenseRecoveryService({required this.expenseStore});

  RealExpenseRecoveryPreview preview({
    required FinancePortfolioV3 portfolio,
    required List<FiniteFinancialPlan> finitePlans,
  }) {
    final financeBefore = jsonEncode(FinancePortfolioV3Contract.build(portfolio));
    final balancesBefore = jsonEncode(
      portfolio.balances.map((item) => item.toJson()).toList(),
    );
    final existing = expenseStore.all;
    final errors = <String>[];
    final candidates = <RealExpenseRecoveryCandidate>[];
    final balances = {for (final item in portfolio.balances) item.balanceId: item};
    final plans = {for (final item in finitePlans) item.id: item};
    final existingByFact = <String, RealExpense>{};
    var noCollision = true;
    for (final expense in existing) {
      final factId = expense.economicFactId;
      if (factId == null ||
          factId.isEmpty ||
          existingByFact.containsKey(factId)) {
        noCollision = false;
        continue;
      }
      existingByFact[factId] = expense;
    }

    final candidatesByFact = <String, List<RealExpenseRecoveryCandidate>>{};
    for (final transaction in portfolio.transactions) {
      final candidate = _candidateFor(
        transaction,
        portfolio.transactions,
        balances,
        plans,
      );
      if (candidate == null) continue;
      final factId = candidate.expense.economicFactId;
      if (factId == null || factId.isEmpty) {
        noCollision = false;
        continue;
      }
      candidatesByFact.putIfAbsent(factId, () => []).add(candidate);
    }
    for (final factCandidates in candidatesByFact.values) {
      if (factCandidates.length != 1) {
        noCollision = false;
        continue;
      }
      final candidate = factCandidates.single;
      final factId = candidate.expense.economicFactId!;
      final materialized = existingByFact[factId];
      if (materialized != null) {
        if (!_sameExpense(materialized, candidate.expense)) {
          noCollision = false;
        }
        continue;
      }
      candidates.add(candidate);
    }

    final finalExpenses = [
      ...existing,
      ...candidates.map((item) => item.expense),
    ];
    final finalFacts = <String>{};
    for (final expense in finalExpenses) {
      final factId = expense.economicFactId;
      if (factId == null || !finalFacts.add(factId)) noCollision = false;
    }
    if (!expenseStore.isLoaded) errors.add('ExpenseStore is not loaded');
    if (!noCollision) errors.add('Economic fact identity collision');

    final financeAfter = jsonEncode(FinancePortfolioV3Contract.build(portfolio));
    final balancesAfter = jsonEncode(
      portfolio.balances.map((item) => item.toJson()).toList(),
    );
    return RealExpenseRecoveryPreview(
      existing: existing,
      candidates: candidates,
      finalExpenses: finalExpenses,
      errors: errors,
      expenseStoreLoaded: expenseStore.isLoaded,
      noEconomicFactCollision: noCollision,
      excludedReviewAbsent: candidates.every(
        (item) =>
            item.producer == 'composite' ||
            item.producer == 'expense replacement' ||
            item.producer.startsWith('finite plan'),
      ),
      financeUnchanged: financeBefore == financeAfter,
      balancesUnchanged: balancesBefore == balancesAfter,
    );
  }

  Future<VerifiedExpenseRecoveryResult> recover(
    RealExpenseRecoveryPreview preview,
  ) async {
    if (!preview.ready) {
      return VerifiedExpenseRecoveryResult(
        VerifiedExpenseRecoveryStatus.conflict,
        ['Recovery preview invariants failed', ...preview.errors],
      );
    }
    return expenseStore.commitRecoveryCandidateVerified(
      expectedCurrent: preview.existing,
      candidate: preview.finalExpenses,
    );
  }

  RealExpenseRecoveryCandidate? _candidateFor(
    FinanceTransaction transaction,
    List<FinanceTransaction> allTransactions,
    Map<String, FinanceBalance> balances,
    Map<String, FiniteFinancialPlan> plans,
  ) {
    if (transaction.type != FinanceTransactionType.expense ||
        transaction.isIncome ||
        transaction.origin != FinanceTransactionOrigin.manual) {
      return null;
    }
    final balance = balances[transaction.balanceId];
    final category = transaction.notes;
    final factId = transaction.economicFactId;
    if (balance == null ||
        category == null ||
        category.trim().isEmpty ||
        factId == null) {
      return null;
    }

    final metadata = transaction.operationMetadata;
    if (metadata != null &&
        transaction.id.startsWith('finance_transaction:composite:') &&
        _compositeIdentityMatches(transaction)) {
      return RealExpenseRecoveryCandidate(
        expense: _expense(
          transaction,
          balance.name,
          'real_expense:composite:${_encoded(factId)}',
        ),
        producer: 'composite',
        reason: 'Composite identity, metadata and Finance fact are complete.',
      );
    }

    final finite = _finiteIdentity(factId);
    if (finite != null) {
      final plan = plans[finite.planId];
      final installment = plan?.installment(finite.installmentNumber);
      final expectedTransactionId =
          'finance_transaction:finite_plan_installment:'
          '${finite.encodedPlanId}:${finite.installmentNumber}:${finite.role}';
      final coherentPlan = plan != null &&
          installment != null &&
          plan.debitBalanceId == transaction.balanceId &&
          plan.subject == transaction.subject &&
          (finite.role == 'fee' || installment.expectedAmount == transaction.amount);
      final pairedMain = finite.role != 'fee' ||
          allTransactions.any(
            (item) =>
                item.economicFactId ==
                'economic_fact:finite_plan_installment:'
                    '${finite.encodedPlanId}:${finite.installmentNumber}:main',
          );
      if (coherentPlan && transaction.id == expectedTransactionId && pairedMain) {
        return RealExpenseRecoveryCandidate(
          expense: _expense(
            transaction,
            balance.name,
            'real_expense:finite_plan_installment:'
                '${finite.encodedPlanId}:${finite.installmentNumber}:${finite.role}',
          ),
          producer: 'finite plan ${finite.role}',
          reason: 'Finite-plan identity matches persisted plan and installment.',
        );
      }
      return null;
    }

    const factPrefix = 'economic_fact_spese_';
    if (!factId.startsWith(factPrefix)) return null;
    final commandId = factId.substring(factPrefix.length);
    if (!commandId.startsWith('expense_replacement_') ||
        !commandId.endsWith('_replacement') ||
        transaction.id != 'real_expense_spese_${_encoded(factId)}') {
      return null;
    }
    return RealExpenseRecoveryCandidate(
      expense: _expense(transaction, balance.name, commandId),
      producer: 'expense replacement',
      reason: 'Replacement command and Finance identities are deterministic.',
    );
  }

  bool _compositeIdentityMatches(FinanceTransaction transaction) =>
      transaction.id ==
      'finance_transaction:composite:${_encoded(transaction.economicFactId!)}';

  RealExpense _expense(
    FinanceTransaction transaction,
    String balanceName,
    String id,
  ) => RealExpense(
    id: id,
    balanceId: transaction.balanceId,
    balanceName: balanceName,
    amount: transaction.amount,
    description: transaction.description,
    category: transaction.notes!,
    date: transaction.date,
    subject: transaction.subject,
    economicFactId: transaction.economicFactId,
    operationMetadata: transaction.operationMetadata,
    balancePostingMode: transaction.balancePostingMode,
  );

  String _encoded(String value) => base64Url.encode(utf8.encode(value));

  bool _sameExpense(RealExpense left, RealExpense right) =>
      jsonEncode(left.toJson()) == jsonEncode(right.toJson());

  _FiniteIdentity? _finiteIdentity(String factId) {
    final match = RegExp(
      r'^economic_fact:finite_plan_installment:([^:]+):(\d+):(main|fee)$',
    ).firstMatch(factId);
    if (match == null) return null;
    try {
      final encodedPlanId = match.group(1)!;
      final planId = utf8.decode(base64Url.decode(encodedPlanId));
      final installmentNumber = int.parse(match.group(2)!);
      if (installmentNumber <= 0) return null;
      return _FiniteIdentity(
        encodedPlanId: encodedPlanId,
        planId: planId,
        installmentNumber: installmentNumber,
        role: match.group(3)!,
      );
    } catch (_) {
      return null;
    }
  }
}

class _FiniteIdentity {
  final String encodedPlanId;
  final String planId;
  final int installmentNumber;
  final String role;

  const _FiniteIdentity({
    required this.encodedPlanId,
    required this.planId,
    required this.installmentNumber,
    required this.role,
  });
}
