enum CompositeCreationIntentStatus { pending, completed, conflict }

enum CompositeCreationStepStatus { pending, completed }

class CompositeCreationStep {
  final String stepId;
  final String componentId;
  final CompositeCreationStepStatus status;

  CompositeCreationStep({
    required String stepId,
    required String componentId,
    this.status = CompositeCreationStepStatus.pending,
  })  : stepId = _required(stepId, 'stepId'),
        componentId = _required(componentId, 'componentId');

  CompositeCreationStep copyWith({CompositeCreationStepStatus? status}) =>
      CompositeCreationStep(stepId: stepId, componentId: componentId, status: status ?? this.status);

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'componentId': componentId,
        'status': status.name,
      };

  factory CompositeCreationStep.fromJson(Map<String, dynamic> json) =>
      CompositeCreationStep(
        stepId: _jsonText(json, 'stepId'),
        componentId: _jsonText(json, 'componentId'),
        status: CompositeCreationStepStatus.values.firstWhere(
          (value) => value.name == (json['status'] ?? 'pending'),
        ),
      );
}

class CompositeCreationIntent {
  final String operationId;
  final CompositeCreationIntentStatus status;
  final List<CompositeCreationStep> steps;
  final Map<String, dynamic> payload;

  CompositeCreationIntent({
    required String operationId,
    required Iterable<CompositeCreationStep> steps,
    Map<String, dynamic> payload = const {},
    this.status = CompositeCreationIntentStatus.pending,
  })  : operationId = _required(operationId, 'operationId'),
        steps = List.unmodifiable(steps),
        payload = Map.unmodifiable(Map<String, dynamic>.from(payload)) {
    if (this.steps.isEmpty) throw ArgumentError.value(steps, 'steps', 'Must not be empty');
    final ids = this.steps.map((step) => step.stepId).toSet();
    if (ids.length != this.steps.length) throw ArgumentError.value(steps, 'steps', 'Step IDs must be unique');
  }

  bool get allStepsCompleted => steps.every((step) => step.status == CompositeCreationStepStatus.completed);

  CompositeCreationIntent complete() {
    if (status == CompositeCreationIntentStatus.conflict) {
      throw StateError('A conflicting intent requires explicit resolution');
    }
    if (!allStepsCompleted) throw StateError('Cannot complete an intent with pending steps');
    return _copy(status: CompositeCreationIntentStatus.completed);
  }

  CompositeCreationIntent markStepCompleted(String stepId) {
    if (status != CompositeCreationIntentStatus.pending) return this;
    final index = steps.indexWhere((step) => step.stepId == stepId);
    if (index < 0) throw StateError('Unknown step: $stepId');
    final next = [...steps]..[index] = steps[index].copyWith(status: CompositeCreationStepStatus.completed);
    return _copy(steps: next);
  }

  CompositeCreationIntent markConflict() {
    if (status == CompositeCreationIntentStatus.completed) {
      throw StateError('A completed intent cannot become conflict');
    }
    return _copy(status: CompositeCreationIntentStatus.conflict);
  }

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'status': status.name,
        'steps': steps.map((step) => step.toJson()).toList(),
        'payload': payload,
      };

  factory CompositeCreationIntent.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    final rawPayload = json['payload'];
    if (rawSteps is! List || rawPayload is! Map) {
      throw const FormatException('steps and payload must be present');
    }
    return CompositeCreationIntent(
      operationId: _jsonText(json, 'operationId'),
      status: CompositeCreationIntentStatus.values.firstWhere(
        (value) => value.name == (json['status'] ?? 'pending'),
      ),
      steps: rawSteps.map((item) => CompositeCreationStep.fromJson(Map<String, dynamic>.from(item as Map))),
      payload: Map<String, dynamic>.from(rawPayload),
    );
  }

  CompositeCreationIntent _copy({CompositeCreationIntentStatus? status, Iterable<CompositeCreationStep>? steps}) =>
      CompositeCreationIntent(operationId: operationId, status: status ?? this.status, steps: steps ?? this.steps, payload: payload);
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field, 'Must not be empty');
  return normalized;
}

String _jsonText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string');
  return value;
}
