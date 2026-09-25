import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frododesk/logic/composite_creation_intent_store.dart';
import 'package:frododesk/models/composite_creation_intent.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  CompositeCreationIntent intent() => CompositeCreationIntent(
        operationId: 'op_1',
        steps: const [
          CompositeCreationStep(stepId: 'a', componentId: 'component_a'),
          CompositeCreationStep(stepId: 'b', componentId: 'component_b'),
        ],
        payload: const {'kind': 'future'},
      );

  test('round trips and supports pending progress', () {
    final pending = intent();
    final restored = CompositeCreationIntent.fromJson(pending.toJson());
    expect(restored.operationId, 'op_1');
    expect(restored.status, CompositeCreationIntentStatus.pending);
    expect(restored.markStepCompleted('a').steps.first.status, CompositeCreationStepStatus.completed);
  });

  test('equivalent reality can complete without recreating step A', () {
    final progressed = intent().markStepCompleted('a');
    final completed = progressed.markStepCompleted('b').complete();
    expect(completed.status, CompositeCreationIntentStatus.completed);
    expect(completed.steps, everyElement(isA<CompositeCreationStep>()));
  });

  test('missing remains pending and incompatible reality becomes conflict', () {
    final pending = intent().markStepCompleted('a');
    expect(pending.status, CompositeCreationIntentStatus.pending);
    expect(pending.markConflict().status, CompositeCreationIntentStatus.conflict);
  });

  test('completed and conflict cannot regress automatically', () {
    final completed = intent().markStepCompleted('a').markStepCompleted('b').complete();
    expect(() => completed.markStepCompleted('a'), returnsNormally);
    expect(() => completed.markConflict(), throwsStateError);
    expect(() => intent().markConflict().complete(), throwsStateError);
  });

  test('persists and reloads payload/progress', () async {
    final store = CompositeCreationIntentStore();
    await store.save(intent().markStepCompleted('a'));
    final reloaded = CompositeCreationIntentStore();
    await reloaded.load();
    expect(reloaded.find('op_1')!.steps.first.status, CompositeCreationStepStatus.completed);
    expect(reloaded.find('op_1')!.payload['kind'], 'future');
  });
}
