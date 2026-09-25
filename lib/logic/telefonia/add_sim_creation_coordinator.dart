import 'dart:convert';

import '../../models/composite_creation_intent.dart';
import '../../models/continuing_service_relationship.dart';
import '../../models/expense_relationship.dart';
import '../../models/expected_expense_occurrence.dart';
import '../../models/finance_balance.dart';
import '../../models/sim_service_details.dart';
import '../../stores/continuing_service_relationship_store.dart';
import '../../stores/finance_store.dart';
import '../../stores/sim_service_details_store.dart';
import '../composite_creation_intent_store.dart';
import '../finance/expected_expense_registration_coordinator.dart';

enum AddSimCreationOutcome { completed, conflict }

enum _ComponentState { missing, equivalent, conflict }

/// Recoverable application coordinator for the cross-domain "Add SIM" flow.
///
/// The persisted domain reality always wins over the progress marker. Every
/// retry classifies the real component before deciding whether it must be
/// created, acknowledged as equivalent, or marked as a conflict.
class AddSimCreationCoordinator {
  static const operationKind = 'addSimV1';
  static const serviceStepId = 'serviceRelationship';
  static const balanceStepId = 'creditBalance';
  static const expenseStepId = 'expectedExpense';
  static const simStepId = 'simDetails';

  final CompositeCreationIntentStore intentStore;
  final ContinuingServiceRelationshipStore relationshipStore;
  final SimServiceDetailsStore simDetailsStore;
  final FinanceStore financeStore;

  const AddSimCreationCoordinator({
    required this.intentStore,
    required this.relationshipStore,
    required this.simDetailsStore,
    required this.financeStore,
  });

  CompositeCreationIntent buildIntent({
    required String operationId,
    required ContinuingServiceRelationship serviceRelationship,
    required SimServiceDetails simDetails,
    required ExpenseRelationship expenseRelationship,
    required ExpectedExpenseOccurrence firstOccurrence,
    required FinanceBalance creditBalance,
  }) {
    final personId = serviceRelationship.personId;
    if (personId == null || personId.trim().isEmpty) {
      throw ArgumentError(
        'Integrated Add SIM requires an associated person',
      );
    }
    final expectedSubject = financeStore.subjectForPersonIdIfSupported(
      personId,
    );
    if (expectedSubject == null) {
      throw ArgumentError('Unsupported Finance person: $personId');
    }
    if (creditBalance.personId != personId ||
        expenseRelationship.subject != expectedSubject ||
        firstOccurrence.expectedSubject != expectedSubject) {
      throw ArgumentError(
        'Service, SIM credit and expected expense must use the same person',
      );
    }
    if (simDetails.relationshipId != serviceRelationship.relationshipId) {
      throw ArgumentError('SIM details must reference the service relationship');
    }
    if (simDetails.expenseRelationshipId !=
        expenseRelationship.relationshipId) {
      throw ArgumentError('SIM details must reference the expense relationship');
    }
    if (simDetails.creditBalanceId != creditBalance.balanceId) {
      throw ArgumentError('SIM details must reference the credit balance');
    }
    if (firstOccurrence.relationshipId !=
        expenseRelationship.relationshipId) {
      throw ArgumentError('Occurrence must reference the expense relationship');
    }
    if (expenseRelationship.provider != serviceRelationship.provider) {
      throw ArgumentError(
        'Service and expense relationship providers must match',
      );
    }
    if (expenseRelationship.paymentConfiguration.expectedBalanceId !=
        creditBalance.balanceId) {
      throw ArgumentError('Expected expense must reference the credit balance');
    }
    if (creditBalance.balanceType != FinanceBalanceType.prepaidCard) {
      throw ArgumentError('SIM credit must use a prepaid-card balance');
    }
    final expenseErrors =
        ExpectedExpenseRegistrationCoordinator.validateManualFirstOccurrence(
          relationship: expenseRelationship,
          occurrence: firstOccurrence,
        );
    if (expenseErrors.isNotEmpty) {
      throw ArgumentError(
        'Invalid initial expected expense: ${expenseErrors.join('; ')}',
      );
    }

    return CompositeCreationIntent(
      operationId: operationId,
      steps: [
        CompositeCreationStep(
          stepId: serviceStepId,
          componentId: serviceRelationship.relationshipId,
        ),
        CompositeCreationStep(
          stepId: balanceStepId,
          componentId: creditBalance.balanceId,
        ),
        CompositeCreationStep(
          stepId: expenseStepId,
          componentId: expenseRelationship.relationshipId,
        ),
        CompositeCreationStep(
          stepId: simStepId,
          componentId: simDetails.relationshipId,
        ),
      ],
      payload: {
        'kind': operationKind,
        'serviceRelationship': serviceRelationship.toJson(),
        'simDetails': simDetails.toJson(),
        'expenseRelationship': expenseRelationship.toJson(),
        'firstOccurrence': firstOccurrence.toJson(),
        'creditBalance': creditBalance.toJson(),
      },
    );
  }

  Future<AddSimCreationOutcome> start(
    CompositeCreationIntent requested,
  ) async {
    await intentStore.load();
    final existing = intentStore.find(requested.operationId);
    if (existing == null) {
      await intentStore.save(requested);
    } else if (!_samePayload(existing, requested)) {
      if (existing.status == CompositeCreationIntentStatus.completed) {
        throw StateError('A completed operationId cannot be reused');
      }
      await intentStore.save(existing.markConflict());
      return AddSimCreationOutcome.conflict;
    }
    return recover(requested.operationId);
  }

  Future<List<AddSimCreationOutcome>> recoverPending() async {
    await intentStore.load();
    final operationIds = intentStore.intents
        .where(
          (intent) =>
              intent.status == CompositeCreationIntentStatus.pending &&
              intent.payload['kind'] == operationKind,
        )
        .map((intent) => intent.operationId)
        .toList();
    final outcomes = <AddSimCreationOutcome>[];
    for (final operationId in operationIds) {
      outcomes.add(await recover(operationId));
    }
    return outcomes;
  }

  Future<AddSimCreationOutcome> recover(String operationId) async {
    var intent = intentStore.find(operationId);
    if (intent == null) {
      await intentStore.load();
      intent = intentStore.find(operationId);
    }
    if (intent == null || intent.payload['kind'] != operationKind) {
      throw StateError('Add SIM intent not found: $operationId');
    }
    if (intent.status == CompositeCreationIntentStatus.conflict) {
      return AddSimCreationOutcome.conflict;
    }
    if (intent.status == CompositeCreationIntentStatus.completed) {
      return AddSimCreationOutcome.completed;
    }

    await relationshipStore.load();
    await simDetailsStore.load();
    final desired = _DesiredAddSim.fromPayload(intent.payload);
    if (!_validRecoveredIntent(intent, desired)) {
      final conflicted = intent.markConflict();
      await intentStore.save(conflicted);
      return AddSimCreationOutcome.conflict;
    }

    intent = await _satisfy(
      intent: intent,
      stepId: serviceStepId,
      classify: () => _classifyService(desired.serviceRelationship),
      create: () async {
        await relationshipStore.add(desired.serviceRelationship);
        await relationshipStore.load();
      },
    );
    if (intent.status == CompositeCreationIntentStatus.conflict) {
      return AddSimCreationOutcome.conflict;
    }

    intent = await _satisfy(
      intent: intent,
      stepId: balanceStepId,
      classify: () => _classifyBalance(desired.creditBalance),
      create: () async {
        await financeStore.addBalance(desired.creditBalance);
      },
    );
    if (intent.status == CompositeCreationIntentStatus.conflict) {
      return AddSimCreationOutcome.conflict;
    }

    intent = await _satisfy(
      intent: intent,
      stepId: expenseStepId,
      classify: () => _classifyExpense(desired),
      create: () => _createExpectedExpense(desired),
    );
    if (intent.status == CompositeCreationIntentStatus.conflict) {
      return AddSimCreationOutcome.conflict;
    }

    intent = await _satisfy(
      intent: intent,
      stepId: simStepId,
      classify: () => _classifySim(desired.simDetails),
      create: () async {
        await simDetailsStore.save(desired.simDetails);
        await simDetailsStore.load();
      },
    );
    if (intent.status == CompositeCreationIntentStatus.conflict) {
      return AddSimCreationOutcome.conflict;
    }

    if (!_allEquivalent(desired)) {
      final conflicted = intent.markConflict();
      await intentStore.save(conflicted);
      return AddSimCreationOutcome.conflict;
    }
    final completed = intent.complete();
    await intentStore.save(completed);
    return AddSimCreationOutcome.completed;
  }

  Future<CompositeCreationIntent> _satisfy({
    required CompositeCreationIntent intent,
    required String stepId,
    required _ComponentState Function() classify,
    required Future<void> Function() create,
  }) async {
    var state = classify();
    if (state == _ComponentState.conflict) {
      final conflicted = intent.markConflict();
      await intentStore.save(conflicted);
      return conflicted;
    }
    if (state == _ComponentState.missing) {
      await create();
      state = classify();
    }
    if (state != _ComponentState.equivalent) {
      final conflicted = intent.markConflict();
      await intentStore.save(conflicted);
      return conflicted;
    }
    final progressed = intent.markStepCompleted(stepId);
    await intentStore.save(progressed);
    return progressed;
  }

  _ComponentState _classifyService(ContinuingServiceRelationship desired) {
    final matches = relationshipStore.items
        .where((item) => item.relationshipId == desired.relationshipId)
        .toList();
    if (matches.isEmpty) return _ComponentState.missing;
    if (matches.length > 1) return _ComponentState.conflict;
    final actual = matches.single;
    return actual.provider == desired.provider &&
            actual.label == desired.label &&
            actual.personId == desired.personId &&
            actual.active == desired.active
        ? _ComponentState.equivalent
        : _ComponentState.conflict;
  }

  _ComponentState _classifyBalance(FinanceBalance desired) {
    final matches = financeStore.balances
        .where((item) => item.balanceId == desired.balanceId)
        .toList();
    if (matches.isEmpty) return _ComponentState.missing;
    if (matches.length > 1) return _ComponentState.conflict;
    final actual = matches.single;
    return actual.balanceId == desired.balanceId &&
            actual.personId == desired.personId &&
            actual.name == desired.name &&
            actual.initialAmount == desired.initialAmount &&
            actual.balanceType == desired.balanceType
        ? _ComponentState.equivalent
        : _ComponentState.conflict;
  }

  _ComponentState _classifyExpense(_DesiredAddSim desired) {
    final state = ExpectedExpenseRegistrationCoordinator(
      financeStore: financeStore,
    ).classifyManualEstimate(
      relationship: desired.expenseRelationship,
      occurrence: desired.firstOccurrence,
    );
    return switch (state) {
      ExpectedExpenseManualRegistrationState.missing =>
        _ComponentState.missing,
      ExpectedExpenseManualRegistrationState.equivalent =>
        _ComponentState.equivalent,
      ExpectedExpenseManualRegistrationState.conflict =>
        _ComponentState.conflict,
    };
  }

  _ComponentState _classifySim(SimServiceDetails desired) {
    final actual = simDetailsStore.findByRelationshipId(desired.relationshipId);
    if (actual == null) return _ComponentState.missing;
    return _sameJson(actual.toJson(), desired.toJson())
        ? _ComponentState.equivalent
        : _ComponentState.conflict;
  }

  Future<void> _createExpectedExpense(_DesiredAddSim desired) async {
    await ExpectedExpenseRegistrationCoordinator(
      financeStore: financeStore,
    ).registerManualEstimate(
      relationship: desired.expenseRelationship,
      occurrence: desired.firstOccurrence,
    );
  }

  bool _allEquivalent(_DesiredAddSim desired) =>
      _classifyService(desired.serviceRelationship) ==
          _ComponentState.equivalent &&
      _classifyBalance(desired.creditBalance) == _ComponentState.equivalent &&
      _classifyExpense(desired) == _ComponentState.equivalent &&
      _classifySim(desired.simDetails) == _ComponentState.equivalent;

  bool _samePayload(
    CompositeCreationIntent left,
    CompositeCreationIntent right,
  ) =>
      jsonEncode(left.payload) == jsonEncode(right.payload) &&
      jsonEncode(
            left.steps
                .map((item) => [item.stepId, item.componentId])
                .toList(),
          ) ==
          jsonEncode(
            right.steps
                .map((item) => [item.stepId, item.componentId])
                .toList(),
          );

  bool _validRecoveredIntent(
    CompositeCreationIntent intent,
    _DesiredAddSim desired,
  ) {
    final components = {
      for (final step in intent.steps) step.stepId: step.componentId,
    };
    return components.length == 4 &&
        components[serviceStepId] ==
            desired.serviceRelationship.relationshipId &&
        components[balanceStepId] == desired.creditBalance.balanceId &&
        components[expenseStepId] ==
            desired.expenseRelationship.relationshipId &&
        components[simStepId] == desired.simDetails.relationshipId &&
        desired.simDetails.relationshipId ==
            desired.serviceRelationship.relationshipId &&
        desired.simDetails.creditBalanceId ==
            desired.creditBalance.balanceId &&
        desired.simDetails.expenseRelationshipId ==
            desired.expenseRelationship.relationshipId &&
        desired.expenseRelationship.provider ==
            desired.serviceRelationship.provider &&
        desired.firstOccurrence.relationshipId ==
            desired.expenseRelationship.relationshipId &&
        desired.expenseRelationship.paymentConfiguration.expectedBalanceId ==
            desired.creditBalance.balanceId &&
        desired.creditBalance.balanceType == FinanceBalanceType.prepaidCard &&
        _hasCoherentPerson(desired) &&
        ExpectedExpenseRegistrationCoordinator.validateManualFirstOccurrence(
          relationship: desired.expenseRelationship,
          occurrence: desired.firstOccurrence,
        ).isEmpty;
  }

  bool _sameJson(Map<String, dynamic> left, Map<String, dynamic> right) =>
      jsonEncode(left) == jsonEncode(right);

  bool _hasCoherentPerson(_DesiredAddSim desired) {
    final personId = desired.serviceRelationship.personId;
    if (personId == null) return false;
    final subject = financeStore.subjectForPersonIdIfSupported(personId);
    return subject != null &&
        desired.creditBalance.personId == personId &&
        desired.expenseRelationship.subject == subject &&
        desired.firstOccurrence.expectedSubject == subject;
  }
}

class _DesiredAddSim {
  final ContinuingServiceRelationship serviceRelationship;
  final SimServiceDetails simDetails;
  final ExpenseRelationship expenseRelationship;
  final ExpectedExpenseOccurrence firstOccurrence;
  final FinanceBalance creditBalance;

  const _DesiredAddSim({
    required this.serviceRelationship,
    required this.simDetails,
    required this.expenseRelationship,
    required this.firstOccurrence,
    required this.creditBalance,
  });

  factory _DesiredAddSim.fromPayload(Map<String, dynamic> payload) =>
      _DesiredAddSim(
        serviceRelationship: ContinuingServiceRelationship.fromJson(
          _map(payload, 'serviceRelationship'),
        ),
        simDetails: SimServiceDetails.fromJson(_map(payload, 'simDetails')),
        expenseRelationship: ExpenseRelationship.fromJson(
          _map(payload, 'expenseRelationship'),
        ),
        firstOccurrence: ExpectedExpenseOccurrence.fromJson(
          _map(payload, 'firstOccurrence'),
        ),
        creditBalance: FinanceBalance.fromJson(_map(payload, 'creditBalance')),
      );

  static Map<String, dynamic> _map(
    Map<String, dynamic> payload,
    String key,
  ) {
    final value = payload[key];
    if (value is! Map) throw FormatException('$key must be an object');
    return Map<String, dynamic>.from(value);
  }
}
