import '../../../models/documentary_obligation.dart';
import '../../../models/expense_relationship.dart';
import '../../../models/finance_recurring_item.dart';
import '../../../models/manual_payment_preference.dart';

/// Read-only knowledge used to prepare a new documentary obligation.
///
/// Stable values remain owned by [relationship]. A document holder is only a
/// correctable suggestion, while [expectedDocumentCycle] remains forecast
/// knowledge and is never promoted to a document fact by this object.
class DocumentaryObligationPreparation {
  final ExpenseRelationship relationship;
  final ExpectedDocumentCycle? expectedDocumentCycle;

  const DocumentaryObligationPreparation({
    required this.relationship,
    this.expectedDocumentCycle,
  });

  String get relationshipId => relationship.relationshipId;
  String get service => relationship.service;
  String get provider => relationship.provider;
  FinanceSubject get subject => relationship.subject;
  ExpenseRelationshipStatus get status => relationship.status;
  ExpenseRelationshipPeriodicity get periodicity => relationship.periodicity;
  ExpenseRelationshipCycleLabelPolicy get cycleLabelPolicy =>
      relationship.cycleLabelPolicy;
  ExpenseRelationshipPaymentConfiguration get paymentConfiguration =>
      relationship.paymentConfiguration;
  PaymentExecutionMode get paymentExecutionMode =>
      relationship.paymentExecutionMode;
  ManualPaymentPreference? get manualPaymentPreference =>
      relationship.manualPaymentPreference;
  List<ExpenseRelationshipIdentifier> get identifiers =>
      List.unmodifiable(relationship.identifiers);
  ExpenseRelationshipCommercialTerm? get commercialTerm =>
      relationship.commercialTerm;

  FinanceSubject get suggestedDocumentHolder => relationship.subject;
}

class DocumentaryObligationPreparationBuilder {
  const DocumentaryObligationPreparationBuilder();

  DocumentaryObligationPreparation build({
    required ExpenseRelationship relationship,
    ExpectedDocumentCycle? expectedDocumentCycle,
  }) {
    if (expectedDocumentCycle != null &&
        expectedDocumentCycle.relationshipId != relationship.relationshipId) {
      throw ArgumentError.value(
        expectedDocumentCycle.relationshipId,
        'expectedDocumentCycle',
        'Must belong to the selected relationship',
      );
    }
    return DocumentaryObligationPreparation(
      relationship: relationship,
      expectedDocumentCycle: expectedDocumentCycle,
    );
  }
}
