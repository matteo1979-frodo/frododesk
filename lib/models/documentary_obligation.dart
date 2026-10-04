import 'dart:collection';

import 'finance_recurring_item.dart';

enum DocumentaryContingencyStatus { pending, materialized, notDue }

enum ExpectedDocumentCycleStatus { expected, materialized }

enum DocumentaryCompetencePeriodSemantic { competence, service, other }

class DocumentaryCompetencePeriod {
  final DateTime startDate;
  final DateTime endDate;
  final DocumentaryCompetencePeriodSemantic semantic;

  DocumentaryCompetencePeriod({
    required this.startDate,
    required this.endDate,
    this.semantic = DocumentaryCompetencePeriodSemantic.competence,
  }) {
    if (endDate.isBefore(startDate)) {
      throw ArgumentError.value(
        endDate,
        'endDate',
        'Must not precede startDate',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'semantic': semantic.name,
  };

  factory DocumentaryCompetencePeriod.fromJson(Map<String, dynamic> json) =>
      DocumentaryCompetencePeriod(
        startDate: _date(json, 'startDate'),
        endDate: _date(json, 'endDate'),
        semantic: _enum(
          json['semantic'],
          DocumentaryCompetencePeriodSemantic.values,
          DocumentaryCompetencePeriodSemantic.competence,
        ),
      );
}

enum DocumentaryReferenceType { invoiceNumber, other }

class DocumentaryEconomicComponent {
  final String componentId;
  final String label;
  final String classificationCode;
  final double amount;

  DocumentaryEconomicComponent({
    required String componentId,
    required String label,
    required String classificationCode,
    required this.amount,
  }) : componentId = _required(componentId, 'componentId'),
       label = _required(label, 'label'),
       classificationCode = _required(
         classificationCode,
         'classificationCode',
       ) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }
  }

  Map<String, dynamic> toJson() => {
    'componentId': componentId,
    'label': label,
    'classificationCode': classificationCode,
    'amount': amount,
  };

  factory DocumentaryEconomicComponent.fromJson(Map<String, dynamic> json) =>
      DocumentaryEconomicComponent(
        componentId: _string(json, 'componentId'),
        label: _string(json, 'label'),
        classificationCode: _string(json, 'classificationCode'),
        amount: _number(json, 'amount'),
      );
}

class ExpectedDocumentPeriod {
  final int year;
  final int month;

  ExpectedDocumentPeriod({required this.year, required this.month}) {
    if (year <= 0 || month < 1 || month > 12) {
      throw ArgumentError('Invalid expected document period');
    }
  }

  Map<String, dynamic> toJson() => {'year': year, 'month': month};

  factory ExpectedDocumentPeriod.fromJson(Map<String, dynamic> json) {
    final year = json['year'];
    final month = json['month'];
    if (year is! int || month is! int || month < 1 || month > 12) {
      throw const FormatException('Invalid expected document period');
    }
    return ExpectedDocumentPeriod(year: year, month: month);
  }
}

/// Non-economic knowledge that a document is expected for one relationship
/// cycle. It deliberately carries neither an amount nor a payment due date.
class ExpectedDocumentCycle {
  final String relationshipId;
  final int cycleSequence;
  final ExpectedDocumentPeriod expectedPeriod;
  final ExpectedDocumentCycleStatus status;
  final String? materializedObligationId;

  ExpectedDocumentCycle({
    required String relationshipId,
    required this.cycleSequence,
    required this.expectedPeriod,
    this.status = ExpectedDocumentCycleStatus.expected,
    String? materializedObligationId,
  }) : relationshipId = _required(relationshipId, 'relationshipId'),
       materializedObligationId = _optional(
         materializedObligationId,
         'materializedObligationId',
       ) {
    if (cycleSequence <= 0) {
      throw ArgumentError.value(cycleSequence, 'cycleSequence');
    }
    if ((status == ExpectedDocumentCycleStatus.materialized) !=
        (this.materializedObligationId != null)) {
      throw ArgumentError(
        'Only a materialized expected document has an obligationId',
      );
    }
  }

  String get identity => '$relationshipId#$cycleSequence';

  ExpectedDocumentCycle materialize(String obligationId) {
    final id = _required(obligationId, 'obligationId');
    if (materializedObligationId != null && materializedObligationId != id) {
      throw StateError('Expected document already materialized differently');
    }
    return ExpectedDocumentCycle(
      relationshipId: relationshipId,
      cycleSequence: cycleSequence,
      expectedPeriod: expectedPeriod,
      status: ExpectedDocumentCycleStatus.materialized,
      materializedObligationId: id,
    );
  }

  Map<String, dynamic> toJson() => {
    'relationshipId': relationshipId,
    'cycleSequence': cycleSequence,
    'expectedPeriod': expectedPeriod.toJson(),
    'status': status.name,
    'materializedObligationId': materializedObligationId,
  };

  factory ExpectedDocumentCycle.fromJson(Map<String, dynamic> json) {
    final period = json['expectedPeriod'];
    if (period is! Map) {
      throw const FormatException('expectedPeriod must be an object');
    }
    return ExpectedDocumentCycle(
      relationshipId: _string(json, 'relationshipId'),
      cycleSequence: json['cycleSequence'] as int,
      expectedPeriod: ExpectedDocumentPeriod.fromJson(
        Map<String, dynamic>.from(period),
      ),
      status: _enum(
        json['status'],
        ExpectedDocumentCycleStatus.values,
        ExpectedDocumentCycleStatus.expected,
      ),
      materializedObligationId: json['materializedObligationId'] as String?,
    );
  }
}

class DocumentaryInstallment {
  final String installmentId;
  final double amount;
  final DateTime dueDate;
  final String? fulfilledEconomicFactId;
  DocumentaryInstallment({
    required String installmentId,
    required this.amount,
    required this.dueDate,
    String? fulfilledEconomicFactId,
  }) : installmentId = _required(installmentId, 'installmentId'),
       fulfilledEconomicFactId = _optional(
         fulfilledEconomicFactId,
         'fulfilledEconomicFactId',
       ) {
    if (!amount.isFinite || amount <= 0)
      throw ArgumentError.value(amount, 'amount');
  }
  bool get isFulfilled => fulfilledEconomicFactId != null;
  DocumentaryInstallment fulfill(String economicFactId) {
    final id = _required(economicFactId, 'economicFactId');
    if (fulfilledEconomicFactId != null && fulfilledEconomicFactId != id)
      throw StateError(
        'Installment is already fulfilled by another economic fact',
      );
    return DocumentaryInstallment(
      installmentId: installmentId,
      amount: amount,
      dueDate: dueDate,
      fulfilledEconomicFactId: id,
    );
  }

  Map<String, dynamic> toJson() => {
    'installmentId': installmentId,
    'amount': amount,
    'dueDate': dueDate.toIso8601String(),
    if (fulfilledEconomicFactId != null)
      'fulfilledEconomicFactId': fulfilledEconomicFactId,
  };
  factory DocumentaryInstallment.fromJson(Map<String, dynamic> json) =>
      DocumentaryInstallment(
        installmentId: _string(json, 'installmentId'),
        amount: _number(json, 'amount'),
        dueDate: _date(json, 'dueDate'),
        fulfilledEconomicFactId: json['fulfilledEconomicFactId'] as String?,
      );
}

class DocumentaryFulfillmentOption {
  final String optionId;
  final String label;
  final UnmodifiableListView<DocumentaryInstallment> installments;
  DocumentaryFulfillmentOption({
    required String optionId,
    required String label,
    required Iterable<DocumentaryInstallment> installments,
  }) : optionId = _required(optionId, 'optionId'),
       label = _required(label, 'label'),
       installments = UnmodifiableListView(List.of(installments)) {
    if (this.installments.isEmpty)
      throw ArgumentError.value(
        installments,
        'installments',
        'Must not be empty',
      );
    _unique(
      this.installments.map((item) => item.installmentId),
      'installmentId',
    );
  }
  double get totalAmount =>
      installments.fold(0, (total, item) => total + item.amount);
  DocumentaryFulfillmentOption replaceInstallment(
    DocumentaryInstallment candidate,
  ) {
    final index = installments.indexWhere(
      (item) => item.installmentId == candidate.installmentId,
    );
    if (index < 0) throw StateError('Installment not found');
    final updated = installments.toList()..[index] = candidate;
    return DocumentaryFulfillmentOption(
      optionId: optionId,
      label: label,
      installments: updated,
    );
  }

  Map<String, dynamic> toJson() => {
    'optionId': optionId,
    'label': label,
    'installments': installments.map((item) => item.toJson()).toList(),
  };
  factory DocumentaryFulfillmentOption.fromJson(Map<String, dynamic> json) {
    final raw = json['installments'];
    if (raw is! List)
      throw const FormatException('installments must be a list');
    return DocumentaryFulfillmentOption(
      optionId: _string(json, 'optionId'),
      label: _string(json, 'label'),
      installments: raw.map(
        (item) => DocumentaryInstallment.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      ),
    );
  }
}

class DocumentaryContingency {
  final String contingencyId;
  final String description;
  final DateTime? anticipatedDueDate;
  final DocumentaryContingencyStatus status;
  final String? materializedOccurrenceId;
  DocumentaryContingency({
    required String contingencyId,
    required String description,
    this.anticipatedDueDate,
    this.status = DocumentaryContingencyStatus.pending,
    String? materializedOccurrenceId,
  }) : contingencyId = _required(contingencyId, 'contingencyId'),
       description = _required(description, 'description'),
       materializedOccurrenceId = _optional(
         materializedOccurrenceId,
         'materializedOccurrenceId',
       ) {
    if ((status == DocumentaryContingencyStatus.materialized) !=
        (this.materializedOccurrenceId != null)) {
      throw ArgumentError(
        'Only a materialized contingency has a materializedOccurrenceId',
      );
    }
  }
  DocumentaryContingency copyWith({
    required DocumentaryContingencyStatus status,
    String? materializedOccurrenceId,
  }) => DocumentaryContingency(
    contingencyId: contingencyId,
    description: description,
    anticipatedDueDate: anticipatedDueDate,
    status: status,
    materializedOccurrenceId: materializedOccurrenceId,
  );
  Map<String, dynamic> toJson() => {
    'contingencyId': contingencyId,
    'description': description,
    'anticipatedDueDate': anticipatedDueDate?.toIso8601String(),
    'status': status.name,
    'materializedOccurrenceId': materializedOccurrenceId,
  };
  factory DocumentaryContingency.fromJson(Map<String, dynamic> json) =>
      DocumentaryContingency(
        contingencyId: _string(json, 'contingencyId'),
        description: _string(json, 'description'),
        anticipatedDueDate: _optionalDate(json, 'anticipatedDueDate'),
        status: _enum(
          json['status'],
          DocumentaryContingencyStatus.values,
          DocumentaryContingencyStatus.pending,
        ),
        materializedOccurrenceId: json['materializedOccurrenceId'] as String?,
      );
}

/// Documentary knowledge for one concrete obligation/cycle. It is not an
/// economic fact; only the selected option can yield operational deadlines.
class DocumentaryObligation {
  final String obligationId;
  final String title;
  final double totalAmount;
  final FinanceSubject? documentHolder;
  final String? documentReference;
  final DocumentaryReferenceType? documentReferenceType;
  final DateTime? issuedAt;
  final DateTime? receivedAt;
  final DocumentaryCompetencePeriod? competencePeriod;
  final UnmodifiableListView<DocumentaryEconomicComponent> components;
  final String? relationshipId;
  final int? cycleSequence;
  final UnmodifiableListView<DocumentaryFulfillmentOption> options;
  final String? selectedOptionId;
  final UnmodifiableListView<DocumentaryContingency> contingencies;

  DocumentaryObligation({
    required String obligationId,
    required String title,
    required this.totalAmount,
    this.documentHolder,
    String? documentReference,
    this.documentReferenceType,
    this.issuedAt,
    this.receivedAt,
    this.competencePeriod,
    Iterable<DocumentaryEconomicComponent> components = const [],
    String? relationshipId,
    this.cycleSequence,
    Iterable<DocumentaryFulfillmentOption> options = const [],
    String? selectedOptionId,
    Iterable<DocumentaryContingency> contingencies = const [],
  }) : obligationId = _required(obligationId, 'obligationId'),
       title = _required(title, 'title'),
       documentReference = _optional(documentReference, 'documentReference'),
       relationshipId = _optional(relationshipId, 'relationshipId'),
       components = UnmodifiableListView(List.of(components)),
       options = UnmodifiableListView(List.of(options)),
       selectedOptionId = _optional(selectedOptionId, 'selectedOptionId'),
       contingencies = UnmodifiableListView(List.of(contingencies)) {
    if (!totalAmount.isFinite || totalAmount <= 0)
      throw ArgumentError.value(totalAmount, 'totalAmount');
    if (cycleSequence != null && this.relationshipId == null)
      throw ArgumentError('A cycleSequence requires relationshipId');
    if (cycleSequence != null && cycleSequence! <= 0)
      throw ArgumentError.value(cycleSequence, 'cycleSequence');
    if (receivedAt != null &&
        issuedAt != null &&
        receivedAt!.isBefore(issuedAt!))
      throw ArgumentError.value(receivedAt, 'receivedAt');
    if (this.documentReference == null && documentReferenceType != null)
      throw ArgumentError('A reference type requires a document reference');
    _unique(this.components.map((item) => item.componentId), 'componentId');
    if (this.components.isNotEmpty &&
        (this.components.fold<double>(0, (sum, item) => sum + item.amount) -
                    totalAmount)
                .abs() >
            0.005) {
      throw ArgumentError.value(
        this.components,
        'components',
        'Component total must equal document total',
      );
    }
    _unique(this.options.map((item) => item.optionId), 'optionId');
    _unique(
      this.contingencies.map((item) => item.contingencyId),
      'contingencyId',
    );
    for (final option in this.options) {
      if ((option.totalAmount - totalAmount).abs() > 0.005)
        throw ArgumentError.value(
          option.totalAmount,
          'options',
          'Option total must equal obligation total',
        );
    }
    if (this.selectedOptionId != null &&
        !this.options.any((item) => item.optionId == this.selectedOptionId))
      throw ArgumentError.value(selectedOptionId, 'selectedOptionId');
  }

  String? get effectiveSelectedOptionId =>
      selectedOptionId ??
      (options.length == 1 ? options.single.optionId : null);
  DocumentaryFulfillmentOption? get selectedOption {
    final id = effectiveSelectedOptionId;
    return id == null
        ? null
        : options.firstWhere((item) => item.optionId == id);
  }

  UnmodifiableListView<DocumentaryInstallment> get operationalInstallments =>
      UnmodifiableListView(
        (selectedOption?.installments ?? const <DocumentaryInstallment>[])
            .where((item) => !item.isFulfilled),
      );
  bool isLate({required String installmentId, required DateTime paidAt}) =>
      paidAt.isAfter(
        selectedOption!.installments
            .firstWhere((item) => item.installmentId == installmentId)
            .dueDate,
      );

  DocumentaryObligation selectOption(String optionId) {
    final id = _required(optionId, 'optionId');
    if (!options.any((item) => item.optionId == id))
      throw ArgumentError.value(optionId, 'optionId');
    if (selectedOptionId != null && selectedOptionId != id)
      throw StateError('A different fulfillment option is already selected');
    return _copy(selectedOptionId: id);
  }

  DocumentaryObligation replaceContingency(DocumentaryContingency candidate) {
    final index = contingencies.indexWhere(
      (item) => item.contingencyId == candidate.contingencyId,
    );
    if (index < 0) throw StateError('Contingency not found');
    final updated = contingencies.toList()..[index] = candidate;
    return _copy(contingencies: updated);
  }

  DocumentaryObligation replaceSelectedInstallment(
    DocumentaryInstallment candidate,
  ) {
    final option = selectedOption;
    if (option == null) throw StateError('No fulfillment option is selected');
    final updated = options
        .map(
          (item) => item.optionId == option.optionId
              ? item.replaceInstallment(candidate)
              : item,
        )
        .toList();
    return _copy(options: updated);
  }

  DocumentaryObligation _copy({
    String? selectedOptionId,
    Iterable<DocumentaryFulfillmentOption>? options,
    Iterable<DocumentaryContingency>? contingencies,
  }) => DocumentaryObligation(
    obligationId: obligationId,
    title: title,
    totalAmount: totalAmount,
    documentHolder: documentHolder,
    documentReference: documentReference,
    documentReferenceType: documentReferenceType,
    issuedAt: issuedAt,
    receivedAt: receivedAt,
    competencePeriod: competencePeriod,
    components: components,
    relationshipId: relationshipId,
    cycleSequence: cycleSequence,
    options: options ?? this.options,
    selectedOptionId: selectedOptionId ?? this.selectedOptionId,
    contingencies: contingencies ?? this.contingencies,
  );
  Map<String, dynamic> toJson() => {
    'obligationId': obligationId,
    'title': title,
    'totalAmount': totalAmount,
    'documentHolder': documentHolder?.name,
    'documentReference': documentReference,
    'documentReferenceType': documentReferenceType?.name,
    'issuedAt': issuedAt?.toIso8601String(),
    'receivedAt': receivedAt?.toIso8601String(),
    'competencePeriod': competencePeriod?.toJson(),
    'components': components.map((item) => item.toJson()).toList(),
    'relationshipId': relationshipId,
    'cycleSequence': cycleSequence,
    'options': options.map((item) => item.toJson()).toList(),
    'selectedOptionId': selectedOptionId,
    'contingencies': contingencies.map((item) => item.toJson()).toList(),
  };
  factory DocumentaryObligation.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] ?? const [];
    final rawContingencies = json['contingencies'] ?? const [];
    final rawComponents = json['components'] ?? const [];
    if (rawOptions is! List ||
        rawContingencies is! List ||
        rawComponents is! List)
      throw const FormatException(
        'options, contingencies and components must be lists',
      );
    final rawCompetence = json['competencePeriod'];
    if (rawCompetence != null && rawCompetence is! Map)
      throw const FormatException('competencePeriod must be an object or null');
    final holder = json['documentHolder'];
    return DocumentaryObligation(
      obligationId: _string(json, 'obligationId'),
      title: _string(json, 'title'),
      totalAmount: _number(json, 'totalAmount'),
      documentHolder: holder == null
          ? null
          : FinanceSubject.values.firstWhere(
              (item) => item.name == holder,
              orElse: () =>
                  throw FormatException('Unknown documentHolder: $holder'),
            ),
      documentReference: json['documentReference'] as String?,
      documentReferenceType: json['documentReferenceType'] == null
          ? null
          : _enum(
              json['documentReferenceType'],
              DocumentaryReferenceType.values,
              DocumentaryReferenceType.other,
            ),
      issuedAt: _optionalDate(json, 'issuedAt'),
      receivedAt: _optionalDate(json, 'receivedAt'),
      competencePeriod: rawCompetence == null
          ? null
          : DocumentaryCompetencePeriod.fromJson(
              Map<String, dynamic>.from(rawCompetence),
            ),
      components: rawComponents.map(
        (item) => DocumentaryEconomicComponent.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      ),
      relationshipId: json['relationshipId'] as String?,
      cycleSequence: json['cycleSequence'] as int?,
      options: rawOptions.map(
        (item) => DocumentaryFulfillmentOption.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      ),
      selectedOptionId: json['selectedOptionId'] as String?,
      contingencies: rawContingencies.map(
        (item) => DocumentaryContingency.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      ),
    );
  }
}

String _required(String value, String field) {
  final result = value.trim();
  if (result.isEmpty) throw ArgumentError.value(value, field);
  return result;
}

String? _optional(String? value, String field) =>
    value == null ? null : _required(value, field);
String _string(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a string');
  return value;
}

double _number(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! num) throw FormatException('$field must be a number');
  return value.toDouble();
}

DateTime _date(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a date string');
  return DateTime.parse(value);
}

DateTime? _optionalDate(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String)
    throw FormatException('$field must be a date string or null');
  return DateTime.parse(value);
}

T _enum<T extends Enum>(Object? raw, List<T> values, T fallback) {
  if (raw == null) return fallback;
  if (raw is! String) throw const FormatException('enum must be a string');
  return values.firstWhere(
    (item) => item.name == raw,
    orElse: () => throw FormatException('Unknown enum: $raw'),
  );
}

void _unique(Iterable<String> values, String field) {
  final list = values.toList();
  if (list.toSet().length != list.length)
    throw ArgumentError.value(list, field, 'Must be unique');
}
