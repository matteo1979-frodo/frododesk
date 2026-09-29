import '../../models/documentary_obligation.dart';
import '../../models/future_outflow_presentation.dart';
import 'documentary_obligation_persistence.dart';

class DocumentaryObligationProjectionAdapter {
  const DocumentaryObligationProjectionAdapter();

  List<FutureOutflowPresentation> project(
    DocumentaryObligationAggregate aggregate,
  ) => List.unmodifiable([
    for (final obligation in aggregate.obligations)
      for (final installment in obligation.operationalInstallments)
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
  ]);
}
