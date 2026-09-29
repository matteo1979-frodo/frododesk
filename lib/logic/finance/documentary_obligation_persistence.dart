import 'dart:collection';
import 'dart:convert';

import '../../models/documentary_obligation.dart';
import '../persistence_store.dart';

class DocumentaryObligationAggregate {
  final UnmodifiableListView<DocumentaryObligation> obligations;
  final UnmodifiableListView<ExpectedDocumentCycle> expectedDocuments;
  DocumentaryObligationAggregate({
    Iterable<DocumentaryObligation> obligations = const [],
    Iterable<ExpectedDocumentCycle> expectedDocuments = const [],
  }) : obligations = UnmodifiableListView(List.of(obligations)),
       expectedDocuments = UnmodifiableListView(List.of(expectedDocuments));
  factory DocumentaryObligationAggregate.empty() => DocumentaryObligationAggregate();
}

class DocumentaryObligationPersistence {
  static const storageKey = 'finance_documentary_obligations_v1';
  static const version = 1;
  final Future<String?> Function(String) _load;
  final Future<PersistenceWriteVerification> Function(String, String) _save;
  DocumentaryObligationPersistence({Future<String?> Function(String)? load, Future<PersistenceWriteVerification> Function(String, String)? save})
      : _load = load ?? PersistenceStore.loadString, _save = save ?? PersistenceStore.saveStringVerified;
  Future<DocumentaryObligationAggregate> load() async {
    final raw = await _load(storageKey); if (raw == null || raw.isEmpty) return DocumentaryObligationAggregate.empty();
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['version'] != version || decoded['obligations'] is! List) throw const FormatException('Invalid documentary obligations payload');
    final values = (decoded['obligations'] as List).map((item) => DocumentaryObligation.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    final rawExpected = decoded['expectedDocuments'] ?? const [];
    if (rawExpected is! List) throw const FormatException('expectedDocuments must be a list');
    final expected = rawExpected.map((item) => ExpectedDocumentCycle.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    _validate(values, expected); return DocumentaryObligationAggregate(obligations: values, expectedDocuments: expected);
  }
  Future<void> write(DocumentaryObligationAggregate candidate) async {
    _validate(candidate.obligations, candidate.expectedDocuments);
    final value = jsonEncode({'version': version, 'obligations': candidate.obligations.map((item) => item.toJson()).toList(), 'expectedDocuments': candidate.expectedDocuments.map((item) => item.toJson()).toList()});
    final result = await _save(storageKey, value);
    if (!result.backendAccepted || result.readBack == null || !result.matches(value)) throw StateError('Documentary obligations verified write failed');
  }
  void _validate(Iterable<DocumentaryObligation> values, Iterable<ExpectedDocumentCycle> expected) {
    final ids = values.map((item) => item.obligationId).toList();
    if (ids.toSet().length != ids.length) throw const FormatException('Duplicate documentary obligationId');
    final cycles = expected.map((item) => item.identity).toList();
    if (cycles.toSet().length != cycles.length) throw const FormatException('Duplicate expected document cycle');
  }
}
