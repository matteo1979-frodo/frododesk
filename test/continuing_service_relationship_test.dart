import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/continuing_service_relationship.dart';

void main() {
  test('same provider and label can have distinct stable identities', () {
    final first = ContinuingServiceRelationship(
      relationshipId: 'service_1',
      provider: 'Provider',
      label: 'Service',
    );
    final second = ContinuingServiceRelationship(
      relationshipId: 'service_2',
      provider: 'Provider',
      label: 'Service',
    );

    expect(first.relationshipId, isNot(second.relationshipId));
    expect(first.provider, second.provider);
    expect(first.label, second.label);
  });

  test('person association is optional', () {
    final relationship = ContinuingServiceRelationship(
      relationshipId: 'service_1',
      provider: 'Provider',
      label: 'Shared service',
    );

    expect(relationship.personId, isNull);
  });

  test('active state and copyWith are preserved and changeable', () {
    final inactive = ContinuingServiceRelationship(
      relationshipId: 'service_1',
      provider: 'Provider',
      label: 'Service',
      personId: 'matteo',
      active: false,
    );
    final active = inactive.copyWith(active: true);

    expect(inactive.active, isFalse);
    expect(active.active, isTrue);
    expect(active.relationshipId, inactive.relationshipId);
    expect(active.personId, inactive.personId);
  });

  test('JSON round-trip preserves identity and fields', () {
    final original = ContinuingServiceRelationship(
      relationshipId: 'service_1',
      provider: 'Provider',
      label: 'Service',
      personId: 'chiara',
      active: false,
    );

    final restored = ContinuingServiceRelationship.fromJson(original.toJson());

    expect(restored.toJson(), original.toJson());
  });

  test('exists without economic entities', () {
    final relationship = ContinuingServiceRelationship(
      relationshipId: 'service_1',
      provider: 'Provider',
      label: 'Service',
    );

    expect(relationship, isA<ContinuingServiceRelationship>());
  });

  test('copyWith can explicitly clear the optional person', () {
    final relationship = ContinuingServiceRelationship(
      relationshipId: 'service_1',
      provider: 'Provider',
      label: 'Service',
      personId: 'matteo',
    );

    expect(relationship.copyWith(personId: null).personId, isNull);
  });
}
