import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../logic/persistence_store.dart';
import '../models/real_expense.dart';

enum VerifiedExpenseAddStatus { added, alreadyCoherent, conflict, writerFailed }

enum VerifiedExpenseReplacementStatus {
  replaced,
  alreadyCoherent,
  conflict,
  writerFailed,
}

class VerifiedExpenseAddResult {
  final VerifiedExpenseAddStatus status;
  final List<String> errors;

  VerifiedExpenseAddResult._(this.status, {Iterable<String> errors = const []})
    : errors = List.unmodifiable(errors);

  factory VerifiedExpenseAddResult.added() =>
      VerifiedExpenseAddResult._(VerifiedExpenseAddStatus.added);

  factory VerifiedExpenseAddResult.alreadyCoherent() =>
      VerifiedExpenseAddResult._(VerifiedExpenseAddStatus.alreadyCoherent);

  factory VerifiedExpenseAddResult.conflict(Iterable<String> errors) =>
      VerifiedExpenseAddResult._(
        VerifiedExpenseAddStatus.conflict,
        errors: errors,
      );

  factory VerifiedExpenseAddResult.writerFailed(Iterable<String> errors) =>
      VerifiedExpenseAddResult._(
        VerifiedExpenseAddStatus.writerFailed,
        errors: errors,
      );

  bool get isSuccess =>
      status == VerifiedExpenseAddStatus.added ||
      status == VerifiedExpenseAddStatus.alreadyCoherent;
}

class VerifiedExpenseReplacementResult {
  final VerifiedExpenseReplacementStatus status;
  final List<String> errors;

  VerifiedExpenseReplacementResult._(
    this.status, {
    Iterable<String> errors = const [],
  }) : errors = List.unmodifiable(errors);

  factory VerifiedExpenseReplacementResult.replaced() =>
      VerifiedExpenseReplacementResult._(
        VerifiedExpenseReplacementStatus.replaced,
      );

  factory VerifiedExpenseReplacementResult.alreadyCoherent() =>
      VerifiedExpenseReplacementResult._(
        VerifiedExpenseReplacementStatus.alreadyCoherent,
      );

  factory VerifiedExpenseReplacementResult.conflict(Iterable<String> errors) =>
      VerifiedExpenseReplacementResult._(
        VerifiedExpenseReplacementStatus.conflict,
        errors: errors,
      );

  factory VerifiedExpenseReplacementResult.writerFailed(
    Iterable<String> errors,
  ) => VerifiedExpenseReplacementResult._(
    VerifiedExpenseReplacementStatus.writerFailed,
    errors: errors,
  );

  bool get isSuccess =>
      status == VerifiedExpenseReplacementStatus.replaced ||
      status == VerifiedExpenseReplacementStatus.alreadyCoherent;
}

typedef ExpenseVerifiedSave =
    Future<PersistenceWriteVerification> Function(String key, String value);

class ExpenseStore extends ChangeNotifier {
  static const String _storageKey = 'real_expenses_v1';

  final ExpenseVerifiedSave _saveVerified;
  final List<RealExpense> _expenses = [];

  ExpenseStore({ExpenseVerifiedSave? saveVerified})
    : _saveVerified = saveVerified ?? PersistenceStore.saveStringVerified;

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

  Future<VerifiedExpenseAddResult> addExpenseVerified(
    RealExpense expense,
  ) async {
    final idMatches = _expenses.where((item) => item.id == expense.id).toList();
    final factMatches = expense.economicFactId == null
        ? const <RealExpense>[]
        : _expenses
              .where((item) => item.economicFactId == expense.economicFactId)
              .toList();
    final identityMatches = <RealExpense>{...idMatches, ...factMatches};

    if (idMatches.length > 1 ||
        factMatches.length > 1 ||
        identityMatches.length > 1) {
      return VerifiedExpenseAddResult.conflict(const [
        'Duplicate expense identity already exists',
      ]);
    }

    if (identityMatches.isNotEmpty) {
      final existing = identityMatches.single;
      if (existing.id != expense.id ||
          existing.economicFactId != expense.economicFactId) {
        return VerifiedExpenseAddResult.conflict(const [
          'Expense identity conflicts with an existing record',
        ]);
      }
      return _sameExpense(existing, expense)
          ? VerifiedExpenseAddResult.alreadyCoherent()
          : VerifiedExpenseAddResult.conflict(const [
              'Expense identity exists with incompatible content',
            ]);
    }

    final candidate = List<RealExpense>.of(_expenses)..add(expense);
    final serialized = jsonEncode(
      candidate.map((item) => item.toJson()).toList(),
    );
    late final PersistenceWriteVerification verification;
    try {
      verification = await _saveVerified(_storageKey, serialized);
    } catch (error) {
      return VerifiedExpenseAddResult.writerFailed([
        'Expense persistence failed: $error',
      ]);
    }
    if (!verification.backendAccepted) {
      return VerifiedExpenseAddResult.writerFailed(const [
        'Expense persistence backend rejected the write',
      ]);
    }
    if (verification.readBack == null) {
      return VerifiedExpenseAddResult.writerFailed(const [
        'Expense persistence read-back is missing',
      ]);
    }
    if (!verification.matches(serialized)) {
      return VerifiedExpenseAddResult.writerFailed(const [
        'Expense persistence read-back differs from written payload',
      ]);
    }

    _expenses
      ..clear()
      ..addAll(candidate);
    notifyListeners();
    return VerifiedExpenseAddResult.added();
  }

  Future<VerifiedExpenseReplacementResult> replaceExpenseVerified({
    required RealExpense original,
    required RealExpense replacement,
  }) async {
    final originalMatches = _expenses
        .where(
          (item) =>
              item.id == original.id ||
              (original.economicFactId != null &&
                  item.economicFactId == original.economicFactId),
        )
        .toList();
    final replacementMatches = _expenses
        .where(
          (item) =>
              item.id == replacement.id ||
              (replacement.economicFactId != null &&
                  item.economicFactId == replacement.economicFactId),
        )
        .toList();

    if (originalMatches.length > 1 || replacementMatches.length > 1) {
      return VerifiedExpenseReplacementResult.conflict(const [
        'Duplicate expense identity exists',
      ]);
    }
    if (originalMatches.isNotEmpty &&
        !_sameExpense(originalMatches.single, original)) {
      return VerifiedExpenseReplacementResult.conflict(const [
        'Original expense differs from the expected snapshot',
      ]);
    }
    if (replacementMatches.isNotEmpty &&
        !_sameExpense(replacementMatches.single, replacement)) {
      return VerifiedExpenseReplacementResult.conflict(const [
        'Replacement expense identity exists with incompatible content',
      ]);
    }
    if (originalMatches.isEmpty && replacementMatches.isNotEmpty) {
      return VerifiedExpenseReplacementResult.alreadyCoherent();
    }
    if (originalMatches.isEmpty || replacementMatches.isNotEmpty) {
      return VerifiedExpenseReplacementResult.conflict(const [
        'Expense replacement state is not recoverable',
      ]);
    }

    final candidate = List<RealExpense>.of(_expenses);
    final index = candidate.indexOf(originalMatches.single);
    candidate[index] = replacement;
    final serialized = jsonEncode(
      candidate.map((item) => item.toJson()).toList(),
    );
    late final PersistenceWriteVerification verification;
    try {
      verification = await _saveVerified(_storageKey, serialized);
    } catch (error) {
      return VerifiedExpenseReplacementResult.writerFailed([
        'Expense persistence failed: $error',
      ]);
    }
    if (!verification.backendAccepted) {
      return VerifiedExpenseReplacementResult.writerFailed(const [
        'Expense persistence backend rejected the replacement',
      ]);
    }
    if (verification.readBack == null) {
      return VerifiedExpenseReplacementResult.writerFailed(const [
        'Expense replacement read-back is missing',
      ]);
    }
    if (!verification.matches(serialized)) {
      return VerifiedExpenseReplacementResult.writerFailed(const [
        'Expense replacement read-back differs from written payload',
      ]);
    }

    _expenses
      ..clear()
      ..addAll(candidate);
    notifyListeners();
    return VerifiedExpenseReplacementResult.replaced();
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

  static bool _sameExpense(RealExpense left, RealExpense right) =>
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
      jsonEncode(left.operationMetadata?.toJson()) ==
          jsonEncode(right.operationMetadata?.toJson());
}
