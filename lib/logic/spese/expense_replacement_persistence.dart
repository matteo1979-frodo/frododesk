import 'dart:convert';

import '../../models/expense_replacement_intent.dart';
import '../persistence_store.dart';

typedef ExpenseReplacementLoad = Future<String?> Function(String key);
typedef ExpenseReplacementVerifiedSave =
    Future<PersistenceWriteVerification> Function(String key, String value);

class ExpenseReplacementPersistence {
  static const String storageKey = 'expense_replacement_intents_v1';
  static const int envelopeVersion = 1;

  final ExpenseReplacementLoad _load;
  final ExpenseReplacementVerifiedSave _saveVerified;

  ExpenseReplacementPersistence({
    ExpenseReplacementLoad? load,
    ExpenseReplacementVerifiedSave? saveVerified,
  }) : _load = load ?? PersistenceStore.loadString,
       _saveVerified = saveVerified ?? PersistenceStore.saveStringVerified;

  Future<List<ExpenseReplacementIntent>> load() async {
    final raw = await _load(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    late final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw FormatException(
        'Invalid expense replacement JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const FormatException(
        'Invalid expense replacement payload: root must be an object',
      );
    }
    final envelope = Map<String, dynamic>.from(decoded);
    if (envelope['version'] != envelopeVersion) {
      throw FormatException(
        'Unsupported expense replacement envelope version: ${envelope['version']}',
      );
    }
    final rawIntents = envelope['intents'];
    if (rawIntents is! List) {
      throw const FormatException(
        'Invalid expense replacement payload: intents must be a list',
      );
    }

    final intents = <ExpenseReplacementIntent>[];
    for (var index = 0; index < rawIntents.length; index++) {
      final rawIntent = rawIntents[index];
      if (rawIntent is! Map) {
        throw FormatException('Invalid expense replacement at index $index');
      }
      try {
        intents.add(
          ExpenseReplacementIntent.fromJson(
            Map<String, dynamic>.from(rawIntent),
          ),
        );
      } catch (error) {
        throw FormatException(
          'Invalid expense replacement at index $index: $error',
        );
      }
    }
    _validateUnique(intents);
    return List.unmodifiable(intents);
  }

  Future<ExpenseReplacementIntent?> findByReplacementId(String id) async {
    final intents = await load();
    return _singleOrNull(intents.where((intent) => intent.replacementId == id));
  }

  Future<ExpenseReplacementIntent?> findByOriginalExpenseId(String id) async {
    final intents = await load();
    return _singleOrNull(
      intents.where((intent) => intent.originalExpense.id == id),
    );
  }

  Future<bool> add(ExpenseReplacementIntent intent) async {
    final intents = await load();
    final sameReplacement = intents
        .where((item) => item.replacementId == intent.replacementId)
        .toList();
    if (sameReplacement.isNotEmpty) {
      if (_sameIntent(sameReplacement.single, intent)) return false;
      throw StateError(
        'Expense replacement id exists with incompatible content: '
        '${intent.replacementId}',
      );
    }
    final sameOriginal = intents
        .where((item) => item.originalExpense.id == intent.originalExpense.id)
        .toList();
    if (sameOriginal.isNotEmpty) {
      throw StateError(
        'Original expense already has a pending replacement: '
        '${intent.originalExpense.id}',
      );
    }
    await _write([...intents, intent]);
    return true;
  }

  Future<bool> remove(String replacementId) async {
    final intents = await load();
    final candidate = intents
        .where((intent) => intent.replacementId != replacementId)
        .toList();
    if (candidate.length == intents.length) return false;
    await _write(candidate);
    return true;
  }

  Future<void> _write(List<ExpenseReplacementIntent> intents) async {
    _validateUnique(intents);
    final serialized = jsonEncode({
      'version': envelopeVersion,
      'intents': intents.map((intent) => intent.toJson()).toList(),
    });
    late final PersistenceWriteVerification verification;
    try {
      verification = await _saveVerified(storageKey, serialized);
    } catch (error) {
      throw StateError('Expense replacement persistence failed: $error');
    }
    if (!verification.backendAccepted) {
      throw StateError(
        'Expense replacement persistence backend rejected write',
      );
    }
    if (verification.readBack == null) {
      throw StateError('Expense replacement persistence read-back is missing');
    }
    if (!verification.matches(serialized)) {
      throw StateError(
        'Expense replacement persistence read-back differs from written payload',
      );
    }
  }

  static void _validateUnique(List<ExpenseReplacementIntent> intents) {
    final replacementIds = <String>{};
    final originalIds = <String>{};
    for (final intent in intents) {
      if (!replacementIds.add(intent.replacementId)) {
        throw FormatException(
          'Duplicate expense replacement id: ${intent.replacementId}',
        );
      }
      if (!originalIds.add(intent.originalExpense.id)) {
        throw FormatException(
          'Duplicate pending replacement for original expense: '
          '${intent.originalExpense.id}',
        );
      }
    }
  }

  static ExpenseReplacementIntent? _singleOrNull(
    Iterable<ExpenseReplacementIntent> matches,
  ) {
    final values = matches.toList();
    return values.isEmpty ? null : values.single;
  }

  static bool _sameIntent(
    ExpenseReplacementIntent left,
    ExpenseReplacementIntent right,
  ) => jsonEncode(left.toJson()) == jsonEncode(right.toJson());
}
