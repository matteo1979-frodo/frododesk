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

enum VerifiedExpenseRecoveryStatus {
  committed,
  alreadyCoherent,
  conflict,
  writerFailed,
}

class VerifiedExpenseRecoveryResult {
  final VerifiedExpenseRecoveryStatus status;
  final List<String> errors;

  VerifiedExpenseRecoveryResult(this.status, [Iterable<String> errors = const []])
    : errors = List.unmodifiable(errors);

  bool get isSuccess =>
      status == VerifiedExpenseRecoveryStatus.committed ||
      status == VerifiedExpenseRecoveryStatus.alreadyCoherent;
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
typedef ExpenseLoad = Future<String?> Function(String key);

class ExpenseStore extends ChangeNotifier {
  static const String _storageKey = 'real_expenses_v1';

  final ExpenseLoad _load;
  final ExpenseVerifiedSave _saveVerified;
  final List<RealExpense> _expenses = [];
  bool _isLoaded = false;

  ExpenseStore({ExpenseLoad? load, ExpenseVerifiedSave? saveVerified})
    : _load = load ?? PersistenceStore.loadString,
      _saveVerified = saveVerified ?? PersistenceStore.saveStringVerified;

  List<RealExpense> get all => List.unmodifiable(_expenses);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _isLoaded = false;
    final raw = await _load(_storageKey);
    final List<dynamic> decoded;
    if (raw == null || raw.isEmpty) {
      decoded = const [];
    } else {
      final value = jsonDecode(raw);
      if (value is! List) {
        throw const FormatException(
          'Invalid real expenses payload: root must be a list',
        );
      }
      decoded = value;
    }
    final candidate = <RealExpense>[];
    for (var index = 0; index < decoded.length; index++) {
      final item = decoded[index];
      if (item is! Map) {
        throw FormatException('Invalid real expense at index $index');
      }
      candidate.add(RealExpense.fromJson(Map<String, dynamic>.from(item)));
    }

    _expenses
      ..clear()
      ..addAll(candidate);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    _requireLoaded();
    final jsonList = _expenses.map((expense) => expense.toJson()).toList();

    await PersistenceStore.saveJsonList(_storageKey, jsonList);
  }

  Future<void> addExpense(RealExpense expense) async {
    _requireLoaded();
    _expenses.add(expense);
    await save();
    notifyListeners();
  }

  Future<VerifiedExpenseAddResult> addExpenseVerified(
    RealExpense expense,
  ) async {
    _requireLoaded();
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
    _requireLoaded();
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
    _requireLoaded();
    _expenses.removeWhere((expense) => expense.id == expenseId);
    await save();
    notifyListeners();
  }

  Future<VerifiedExpenseRecoveryResult> commitRecoveryCandidateVerified({
    required List<RealExpense> expectedCurrent,
    required List<RealExpense> candidate,
  }) async {
    _requireLoaded();
    final expectedSerialized = _serialize(expectedCurrent);
    if (_serialize(_expenses) != expectedSerialized) {
      return VerifiedExpenseRecoveryResult(
        VerifiedExpenseRecoveryStatus.conflict,
        const ['ExpenseStore memory differs from the recovery preview'],
      );
    }
    final identities = <String>{};
    for (final expense in candidate) {
      final factId = expense.economicFactId;
      if (factId == null || factId.isEmpty || !identities.add(factId)) {
        return VerifiedExpenseRecoveryResult(
          VerifiedExpenseRecoveryStatus.conflict,
          const ['Recovery candidate has missing or duplicate economicFactId'],
        );
      }
    }
    final candidateSerialized = _serialize(candidate);
    if (candidateSerialized == expectedSerialized) {
      return VerifiedExpenseRecoveryResult(
        VerifiedExpenseRecoveryStatus.alreadyCoherent,
      );
    }

    try {
      final persistedRaw = await _load(_storageKey);
      final persisted = _decodeExpenses(persistedRaw);
      if (_serialize(persisted) != expectedSerialized) {
        return VerifiedExpenseRecoveryResult(
          VerifiedExpenseRecoveryStatus.conflict,
          const ['Persisted expenses differ from the recovery preview'],
        );
      }
      final verification = await _saveVerified(
        _storageKey,
        candidateSerialized,
      );
      if (!verification.backendAccepted ||
          verification.readBack == null ||
          !verification.matches(candidateSerialized)) {
        return VerifiedExpenseRecoveryResult(
          VerifiedExpenseRecoveryStatus.writerFailed,
          const ['Expense recovery verified write failed'],
        );
      }
    } catch (error) {
      return VerifiedExpenseRecoveryResult(
        VerifiedExpenseRecoveryStatus.writerFailed,
        ['Expense recovery persistence failed: $error'],
      );
    }

    _expenses
      ..clear()
      ..addAll(candidate);
    notifyListeners();
    return VerifiedExpenseRecoveryResult(
      VerifiedExpenseRecoveryStatus.committed,
    );
  }

  RealExpense? findById(String expenseId) {
    try {
      return _expenses.firstWhere((expense) => expense.id == expenseId);
    } catch (_) {
      return null;
    }
  }

  void _requireLoaded() {
    if (!_isLoaded) {
      throw StateError(
        'ExpenseStore must be loaded successfully before mutations',
      );
    }
  }

  static String _serialize(Iterable<RealExpense> expenses) =>
      jsonEncode(expenses.map((item) => item.toJson()).toList());

  static List<RealExpense> _decodeExpenses(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Invalid real expenses persistence root');
    }
    return decoded
        .map(
          (item) => RealExpense.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
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
      left.balancePostingMode == right.balancePostingMode &&
      jsonEncode(left.operationMetadata?.toJson()) ==
          jsonEncode(right.operationMetadata?.toJson());
}
