import 'dart:convert';

import '../../models/composite_correction_intent.dart';
import '../persistence_store.dart';

typedef CompositeCorrectionLoad = Future<String?> Function(String key);
typedef CompositeCorrectionSave =
    Future<PersistenceWriteVerification> Function(String key, String value);

class CompositeCorrectionIntentPersistence {
  static const storageKey = 'composite_correction_intents_v1';
  static const envelopeVersion = 1;
  final CompositeCorrectionLoad _load;
  final CompositeCorrectionSave _save;

  CompositeCorrectionIntentPersistence({
    CompositeCorrectionLoad? load,
    CompositeCorrectionSave? save,
  }) : _load = load ?? PersistenceStore.loadString,
       _save = save ?? PersistenceStore.saveStringVerified;

  Future<List<CompositeCorrectionIntent>> load() async {
    final raw = await _load(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map ||
        decoded['version'] != envelopeVersion ||
        decoded['intents'] is! List) {
      throw const FormatException(
        'Invalid composite correction intent envelope',
      );
    }
    final values = (decoded['intents'] as List)
        .map(
          (item) => CompositeCorrectionIntent.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    _validate(values);
    return List.unmodifiable(values);
  }

  Future<CompositeCorrectionIntent?> findByOperationId(
    String operationId,
  ) async {
    final matches = (await load())
        .where((item) => item.operationId == operationId)
        .toList();
    return matches.isEmpty ? null : matches.single;
  }

  Future<void> put(CompositeCorrectionIntent intent) async {
    final values = await load();
    final matches = values
        .where((item) => item.correctionId == intent.correctionId)
        .toList();
    if (matches.isNotEmpty &&
        matches.single.operationId != intent.operationId) {
      throw StateError('Correction identity belongs to another operation');
    }
    final candidate = [
      for (final item in values)
        if (item.correctionId != intent.correctionId) item,
      intent,
    ];
    await _write(candidate);
  }

  Future<void> remove(String correctionId) async {
    final values = await load();
    await _write(
      values.where((item) => item.correctionId != correctionId).toList(),
    );
  }

  Future<void> _write(List<CompositeCorrectionIntent> values) async {
    _validate(values);
    final serialized = jsonEncode({
      'version': envelopeVersion,
      'intents': values.map((item) => item.toJson()).toList(),
    });
    final result = await _save(storageKey, serialized);
    if (!result.backendAccepted ||
        result.readBack == null ||
        !result.matches(serialized)) {
      throw StateError('Composite correction intent verified write failed');
    }
  }

  static void _validate(List<CompositeCorrectionIntent> values) {
    if (values.map((item) => item.correctionId).toSet().length !=
            values.length ||
        values.map((item) => item.operationId).toSet().length !=
            values.length) {
      throw const FormatException(
        'Duplicate composite correction intent identity',
      );
    }
  }
}
