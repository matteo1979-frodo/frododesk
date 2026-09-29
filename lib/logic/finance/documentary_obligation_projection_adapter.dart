import '../../models/documentary_obligation.dart';
import '../../models/future_outflow_presentation.dart';
import 'documentary_obligation_persistence.dart';

class DocumentaryObligationProjectionResult {
  final List<String> materializedCycleIdentities;
  final List<FutureOutflowPresentation> operationalInstallments;
  final List<FutureOutflowPresentation>
      materializedObligationsAwaitingChoice;
  final List<FutureOutflowPresentation> items;

  DocumentaryObligationProjectionResult({
    required Iterable<String> materializedCycleIdentities,
    required Iterable<FutureOutflowPresentation> operationalInstallments,
    required Iterable<FutureOutflowPresentation>
        materializedObligationsAwaitingChoice,
  }) : materializedCycleIdentities = List.unmodifiable(
         materializedCycleIdentities,
       ),
       operationalInstallments = List.unmodifiable(operationalInstallments),
       materializedObligationsAwaitingChoice = List.unmodifiable(
         materializedObligationsAwaitingChoice,
       ),
       items = List.unmodifiable([
         ...operationalInstallments,
         ...materializedObligationsAwaitingChoice,
       ]);
}

class DocumentaryObligationProjectionAdapter {
  const DocumentaryObligationProjectionAdapter();

  List<FutureOutflowPresentation> project(
    DocumentaryObligationAggregate aggregate,
  ) => projectWithAuthority(aggregate).items;

  DocumentaryObligationProjectionResult projectWithAuthority(
    DocumentaryObligationAggregate aggregate,
  ) {
    final materializedCycleIdentities = <String>[];
    final obligationByCycleIdentity = <String, String>{};
    final operationalInstallments = <FutureOutflowPresentation>[];
    final materializedObligationsAwaitingChoice =
        <FutureOutflowPresentation>[];
    for (final obligation in aggregate.obligations) {
      final relationshipId = obligation.relationshipId;
      final cycleSequence = obligation.cycleSequence;
      if (relationshipId != null && cycleSequence != null) {
        final identity = '$relationshipId#$cycleSequence';
        final existingObligationId = obligationByCycleIdentity[identity];
        if (existingObligationId != null &&
            existingObligationId != obligation.obligationId) {
          throw StateError(
            'Duplicate documentary cycle identity $identity: '
            '$existingObligationId, ${obligation.obligationId}',
          );
        }
        obligationByCycleIdentity[identity] = obligation.obligationId;
        materializedCycleIdentities.add(identity);
      }

      final selectedOption = obligation.selectedOption;
      if (selectedOption == null) {
        if (relationshipId != null && cycleSequence != null) {
          materializedObligationsAwaitingChoice.add(
            FutureOutflowPresentation(
              identity: 'documentary:${obligation.obligationId}:choice',
              authority: FutureOutflowAuthority.documentaryObligation,
              title: obligation.title,
              details: 'Scegli come pagare',
              amount: obligation.totalAmount,
              placementStart: null,
              placementEnd: null,
              placementPeriod: _expectedPeriodFor(
                aggregate,
                obligation,
              ),
              datePresentation:
                  FutureOutflowDatePresentation.documentaryChoiceRequired,
              requiresPlanning: false,
              provisional: false,
              requiresUserAction: true,
              overdue: false,
              obligationId: obligation.obligationId,
              relationshipId: relationshipId,
              cycleSequence: cycleSequence,
            ),
          );
        }
        continue;
      }

      for (final installment in obligation.operationalInstallments) {
        operationalInstallments.add(
          FutureOutflowPresentation(
            identity:
                'documentary:${obligation.obligationId}:${installment.installmentId}',
            authority: FutureOutflowAuthority.documentaryObligation,
            title: obligation.title,
            details: obligation.selectedOption!.label,
            amount: installment.amount,
            placementStart: installment.dueDate,
            placementEnd: installment.dueDate,
            datePresentation:
                FutureOutflowDatePresentation.documentaryDeadline,
            requiresPlanning: false,
            provisional: false,
            requiresUserAction: true,
            overdue: false,
            obligationId: obligation.obligationId,
            documentaryInstallmentId: installment.installmentId,
            relationshipId: obligation.relationshipId,
            cycleSequence: obligation.cycleSequence,
          ),
        );
      }
    }
    return DocumentaryObligationProjectionResult(
      materializedCycleIdentities: materializedCycleIdentities,
      operationalInstallments: operationalInstallments,
      materializedObligationsAwaitingChoice:
          materializedObligationsAwaitingChoice,
    );
  }

  ExpectedDocumentPeriod? _expectedPeriodFor(
    DocumentaryObligationAggregate aggregate,
    DocumentaryObligation obligation,
  ) {
    final identity = '${obligation.relationshipId}#${obligation.cycleSequence}';
    for (final expected in aggregate.expectedDocuments) {
      if (expected.identity == identity &&
          expected.materializedObligationId == obligation.obligationId) {
        return expected.expectedPeriod;
      }
    }
    return null;
  }
}
