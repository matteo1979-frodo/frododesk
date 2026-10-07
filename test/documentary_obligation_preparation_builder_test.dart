import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/builders/documentary_obligation_preparation_builder.dart';
import 'package:frododesk/models/documentary_obligation.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/manual_payment_preference.dart';

void main() {
  group('DocumentaryObligationPreparationBuilder', () {
    test(
      'exposes complete stable knowledge without mutating its authority',
      () {
        final relationship = _relationship();
        final before = relationship.toJson();

        final preparation = const DocumentaryObligationPreparationBuilder()
            .build(relationship: relationship);

        expect(preparation.relationship, same(relationship));
        expect(preparation.relationshipId, 'relationship-generic');
        expect(preparation.service, 'Servizio ricorrente');
        expect(preparation.provider, 'Fornitore generico');
        expect(preparation.subject, FinanceSubject.chiara);
        expect(preparation.periodicity.type, FinanceRecurringType.monthly);
        expect(
          preparation.paymentConfiguration.method,
          FinancePaymentMethod.rid,
        );
        expect(preparation.paymentConfiguration.expectedBalanceId, 'balance-1');
        expect(
          preparation.paymentExecutionMode,
          PaymentExecutionMode.automatic,
        );
        expect(
          preparation.manualPaymentPreference?.preferredStartDayOfMonth,
          5,
        );
        expect(preparation.identifiers.single.identity, 'contract:C-001');
        expect(
          preparation.identifiers.single.provenance,
          'documento originale',
        );
        expect(preparation.commercialTerm?.effectiveFrom, DateTime(2026, 2, 1));
        expect(
          preparation.commercialTerm?.commercialEnd,
          DateTime(2027, 1, 31),
        );
        expect(preparation.suggestedDocumentHolder, FinanceSubject.chiara);
        expect(preparation.expectedDocumentCycle, isNull);
        expect(relationship.toJson(), before);
      },
    );

    test('keeps an expected cycle explicitly separate from document facts', () {
      final relationship = _relationship();
      final expected = ExpectedDocumentCycle(
        relationshipId: relationship.relationshipId,
        cycleSequence: 2,
        expectedPeriod: ExpectedDocumentPeriod(year: 2026, month: 4),
      );

      final preparation = const DocumentaryObligationPreparationBuilder().build(
        relationship: relationship,
        expectedDocumentCycle: expected,
      );

      expect(preparation.expectedDocumentCycle, same(expected));
      expect(preparation.expectedDocumentCycle?.expectedPeriod.month, 4);
    });

    test('rejects forecast knowledge owned by another relationship', () {
      expect(
        () => const DocumentaryObligationPreparationBuilder().build(
          relationship: _relationship(),
          expectedDocumentCycle: ExpectedDocumentCycle(
            relationshipId: 'other',
            cycleSequence: 2,
            expectedPeriod: ExpectedDocumentPeriod(year: 2026, month: 4),
          ),
        ),
        throwsArgumentError,
      );
    });

    for (final provider in ['Fornitore acqua', 'Ente assicurativo']) {
      test('is provider-agnostic for $provider', () {
        final relationship = _relationship(provider: provider);

        final preparation = const DocumentaryObligationPreparationBuilder()
            .build(relationship: relationship);

        expect(preparation.provider, provider);
        expect(preparation.suggestedDocumentHolder, relationship.subject);
      });
    }
  });
}

ExpenseRelationship _relationship({String provider = 'Fornitore generico'}) =>
    ExpenseRelationship(
      relationshipId: 'relationship-generic',
      service: 'Servizio ricorrente',
      provider: provider,
      subject: FinanceSubject.chiara,
      status: ExpenseRelationshipStatus.active,
      periodicity: ExpenseRelationshipPeriodicity(
        type: FinanceRecurringType.monthly,
      ),
      paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.rid,
        expectedBalanceId: 'balance-1',
      ),
      paymentExecutionMode: PaymentExecutionMode.automatic,
      manualPaymentPreference: ManualPaymentPreference(
        preferredStartDayOfMonth: 5,
      ),
      identifiers: [
        ExpenseRelationshipIdentifier(
          namespace: 'contract',
          value: 'C-001',
          provenance: 'documento originale',
        ),
      ],
      commercialTerm: ExpenseRelationshipCommercialTerm(
        effectiveFrom: DateTime(2026, 2, 1),
        commercialEnd: DateTime(2027, 1, 31),
      ),
    );
