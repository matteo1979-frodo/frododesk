import 'dart:collection';

import '../../models/economic_event.dart';
import '../../models/economic_operation_metadata.dart';
import '../../models/expense_replacement_metadata.dart';

/// Raised only after structural correlation has been established through an
/// equal, non-null [EconomicEvent.economicFactId].
class EconomicEventMergeConflict implements Exception {
  final String economicFactId;
  final String field;
  final List<Object> values;

  EconomicEventMergeConflict({
    required this.economicFactId,
    required this.field,
    required Iterable<Object> values,
  }) : values = List<Object>.unmodifiable(values);

  @override
  String toString() =>
      'EconomicEventMergeConflict($economicFactId, $field, $values)';
}

/// Correlates events exclusively by structural economic-fact identity.
///
/// No event content participates in deciding whether two records represent
/// the same fact. Content is inspected only after correlation, to merge the
/// complementary representations or expose an incompatible group.
class EconomicEventCorrelator {
  const EconomicEventCorrelator();

  UnmodifiableListView<EconomicEvent> correlate(List<EconomicEvent> events) {
    final standalone = <EconomicEvent>[];
    final groups = <String, List<EconomicEvent>>{};

    for (final event in events) {
      final factId = event.economicFactId;
      if (factId == null) {
        standalone.add(event);
      } else {
        groups.putIfAbsent(factId, () => <EconomicEvent>[]).add(event);
      }
    }

    final result = <EconomicEvent>[
      ...standalone,
      ...groups.entries.map((entry) => _merge(entry.key, entry.value)),
    ]..sort((left, right) => _stableKey(left).compareTo(_stableKey(right)));
    return UnmodifiableListView(result);
  }

  EconomicEvent _merge(String factId, List<EconomicEvent> events) {
    final ordered = List<EconomicEvent>.of(events)
      ..sort(_compareSourceFidelity);
    final amount = _singleRequired(
      factId,
      'amount',
      ordered.map((event) => event.amount),
    );
    final nature = _mergeNature(factId, ordered.map((event) => event.nature));
    final category = _singleOptional(
      factId,
      'category',
      ordered.map((event) => event.category),
      (left, right) => left.id == right.id,
    );
    final personId = _singleOptional(
      factId,
      'personId',
      ordered.map((event) => event.personId),
      (left, right) => left == right,
    );
    final operationMetadata = _singleOptional(
      factId,
      'operationMetadata',
      ordered.map((event) => event.operationMetadata),
      _sameOperationMetadata,
    );
    final expenseReplacementMetadata = _singleOptional(
      factId,
      'expenseReplacementMetadata',
      ordered.map((event) => event.expenseReplacementMetadata),
      _sameExpenseReplacementMetadata,
    );

    return EconomicEvent(
      id: 'economic_fact:$factId',
      economicFactId: factId,
      operationMetadata: operationMetadata,
      expenseReplacementMetadata: expenseReplacementMetadata,
      observedAt: ordered
          .map((event) => event.observedAt)
          .reduce((left, right) => left.isAfter(right) ? left : right),
      occurredAt: ordered.first.occurredAt,
      origins: _mergeEndpoints(
        factId,
        'origins',
        ordered.map((event) => event.origins),
      ),
      destinations: _mergeEndpoints(
        factId,
        'destinations',
        ordered.map((event) => event.destinations),
      ),
      category: category,
      personId: personId,
      description: _mostInformativeDescription(
        ordered.map((event) => event.description),
      ),
      amount: amount,
      nature: nature,
      sourceLinks: _mergeSourceLinks(
        ordered.expand((event) => event.sourceLinks),
      ),
      relatedEventIds: _sortedUnique(
        ordered.expand((event) => event.relatedEventIds),
      ),
      notes: _sortedUnique(ordered.expand((event) => event.notes)),
      transactionOrigins: _sortedUniqueOrigins(
        ordered.expand((event) => event.transactionOrigins),
      ),
      recurringItemIds: _sortedUnique(
        ordered.expand((event) => event.recurringItemIds),
      ),
    );
  }

  List<EconomicEndpoint> _mergeEndpoints(
    String factId,
    String role,
    Iterable<Iterable<EconomicEndpoint>> representations,
  ) {
    final byIdentity = <String, EconomicEndpoint>{};
    final groups = representations.map(List<EconomicEndpoint>.of).toList();
    final hasConcreteRepresentation = groups.any(
      (group) => group.any(_isConcreteEndpoint),
    );
    for (final group in groups) {
      final groupHasConcrete = group.any(_isConcreteEndpoint);
      for (final endpoint in group) {
        if (hasConcreteRepresentation &&
            !groupHasConcrete &&
            !_isConcreteEndpoint(endpoint)) {
          continue;
        }
        final key = _endpointIdentity(endpoint);
        final current = byIdentity[key];
        byIdentity[key] = current == null
            ? endpoint
            : _mergeEndpoint(factId, role, current, endpoint);
      }
    }

    final values = byIdentity.values.toList();
    values.sort(
      (left, right) => _endpointKey(left).compareTo(_endpointKey(right)),
    );
    return values;
  }

  bool _isConcreteEndpoint(EconomicEndpoint endpoint) =>
      endpoint.referenceId?.trim().isNotEmpty ?? false;

  String _endpointIdentity(EconomicEndpoint endpoint) {
    if (_isConcreteEndpoint(endpoint)) {
      return 'concrete|${endpoint.kind.name}|${endpoint.referenceId}';
    }
    return [
      'generic',
      endpoint.kind.name,
      endpoint.referenceId ?? '',
      endpoint.personId ?? '',
      endpoint.amount.toString(),
    ].join('|');
  }

  EconomicEndpoint _mergeEndpoint(
    String factId,
    String role,
    EconomicEndpoint left,
    EconomicEndpoint right,
  ) {
    if (!_isConcreteEndpoint(left) || !_isConcreteEndpoint(right)) {
      return _isMoreInformative(right.label, left.label) ? right : left;
    }
    if (left.amount != right.amount) {
      final values = [left.amount, right.amount]..sort();
      throw EconomicEventMergeConflict(
        economicFactId: factId,
        field: '$role.amount',
        values: values,
      );
    }
    final personId = _mergeEndpointPersonId(
      factId,
      role,
      left.personId,
      right.personId,
    );
    final label = _isMoreInformative(right.label, left.label)
        ? right.label
        : left.label;
    return EconomicEndpoint(
      kind: left.kind,
      referenceId: left.referenceId,
      label: label,
      personId: personId,
      amount: left.amount,
    );
  }

  String? _mergeEndpointPersonId(
    String factId,
    String role,
    String? left,
    String? right,
  ) {
    if (left == null) return right;
    if (right == null || left == right) return left;
    final values = [left, right]..sort();
    throw EconomicEventMergeConflict(
      economicFactId: factId,
      field: '$role.personId',
      values: values,
    );
  }

  List<EconomicSourceLink> _mergeSourceLinks(
    Iterable<EconomicSourceLink> input,
  ) {
    final byIdentity = <String, EconomicSourceLink>{};
    for (final link in input) {
      byIdentity['${link.kind.name}|${link.recordId}'] = link;
    }
    final result = byIdentity.values.toList()
      ..sort((left, right) => _sourceKey(left).compareTo(_sourceKey(right)));
    return result;
  }

  EconomicNature _mergeNature(String factId, Iterable<EconomicNature> values) {
    final unique = values.toSet();
    if (unique.length == 1) return unique.single;
    if (unique.contains(EconomicNature.income) &&
        unique.contains(EconomicNature.outflow)) {
      throw EconomicEventMergeConflict(
        economicFactId: factId,
        field: 'nature',
        values: unique.map((value) => value.name),
      );
    }
    // A transfer-aware representation is more informative than a legacy leg
    // exposed as a generic inflow/outflow.
    if (unique.contains(EconomicNature.internalTransfer)) {
      return EconomicNature.internalTransfer;
    }
    throw EconomicEventMergeConflict(
      economicFactId: factId,
      field: 'nature',
      values: unique.map((value) => value.name),
    );
  }

  T _singleRequired<T>(String factId, String field, Iterable<T> input) {
    final values = input.toSet();
    if (values.length != 1) {
      throw EconomicEventMergeConflict(
        economicFactId: factId,
        field: field,
        values: values.cast<Object>(),
      );
    }
    return values.single;
  }

  T? _singleOptional<T>(
    String factId,
    String field,
    Iterable<T?> input,
    bool Function(T left, T right) equals,
  ) {
    final values = input.whereType<T>().toList();
    if (values.isEmpty) return null;
    final first = values.first;
    if (values.skip(1).any((value) => !equals(first, value))) {
      throw EconomicEventMergeConflict(
        economicFactId: factId,
        field: field,
        values: values.cast<Object>(),
      );
    }
    return first;
  }

  bool _sameOperationMetadata(
    EconomicOperationMetadata left,
    EconomicOperationMetadata right,
  ) =>
      left.operationId == right.operationId &&
      left.role == right.role &&
      left.context == right.context &&
      left.accessoryCostType == right.accessoryCostType;

  String _mostInformativeDescription(Iterable<String> values) {
    final candidates = values.map((value) => value.trim()).toSet().toList()
      ..sort((left, right) {
        final length = right.length.compareTo(left.length);
        return length != 0 ? length : left.compareTo(right);
      });
    return candidates.first;
  }

  List<String> _sortedUnique(Iterable<String> values) =>
      values.toSet().toList()..sort();

  bool _sameExpenseReplacementMetadata(
    ExpenseReplacementMetadata left,
    ExpenseReplacementMetadata right,
  ) =>
      left.originalEconomicFactId == right.originalEconomicFactId &&
      left.replacementEconomicFactId == right.replacementEconomicFactId &&
      left.role == right.role;

  List<EconomicTransactionOrigin> _sortedUniqueOrigins(
    Iterable<EconomicTransactionOrigin> values,
  ) => values.toSet().toList()..sort((left, right) => left.index - right.index);

  int _compareSourceFidelity(EconomicEvent left, EconomicEvent right) {
    final rank = _sourceFidelity(left).compareTo(_sourceFidelity(right));
    return rank != 0 ? rank : left.id.compareTo(right.id);
  }

  int _sourceFidelity(EconomicEvent event) {
    final kinds = event.sourceLinks.map((link) => link.kind).toSet();
    if (kinds.contains(EconomicSourceKind.realExpense)) return 0;
    if (kinds.contains(EconomicSourceKind.financeAssetMovement)) return 1;
    if (kinds.contains(EconomicSourceKind.financeTransaction)) return 2;
    return 3;
  }

  bool _isMoreInformative(String candidate, String current) =>
      candidate.trim().length > current.trim().length ||
      (candidate.trim().length == current.trim().length &&
          candidate.compareTo(current) < 0);

  String _stableKey(EconomicEvent event) =>
      event.economicFactId == null ? '1|${event.id}' : '0|${event.id}';

  String _endpointKey(EconomicEndpoint endpoint) => [
    endpoint.kind.name,
    endpoint.referenceId ?? '',
    endpoint.personId ?? '',
    endpoint.amount.toString(),
    endpoint.label,
  ].join('|');

  String _sourceKey(EconomicSourceLink link) =>
      '${link.kind.name}|${link.recordId}';
}
