import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/documentary_obligation_coordinator.dart';
import 'package:frododesk/logic/finance/documentary_obligation_persistence.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/documentary_obligation.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test(
    'verified fulfillment replacement updates, retries and rejects third id',
    () async {
      String? stored;
      final persistence = DocumentaryObligationPersistence(
        load: (_) async => stored,
        save: (_, value) async {
          stored = value;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      );
      var obligation = DocumentaryObligation(
        obligationId: 'obligation',
        title: 'Documento',
        totalAmount: 100,
        options: [
          DocumentaryFulfillmentOption(
            optionId: 'single',
            label: 'Unica',
            installments: [
              DocumentaryInstallment(
                installmentId: 'installment',
                amount: 100,
                dueDate: DateTime(2026, 9, 30),
              ),
            ],
          ),
        ],
      ).selectOption('single');
      obligation = obligation.replaceSelectedInstallment(
        obligation.operationalInstallments.single.fulfill('old-main'),
      );
      final finance = FinanceStore(
        documentaryObligationPersistence: persistence,
        initialDocumentaryObligationAggregate: DocumentaryObligationAggregate(
          obligations: [obligation],
        ),
      );
      final coordinator = DocumentaryObligationCoordinator(
        financeStore: finance,
      );
      FinanceTransaction replacement(String id) => FinanceTransaction(
        id: 'transaction-$id',
        balanceId: 'balance',
        amount: 100,
        date: DateTime(2026, 10, 1),
        isIncome: false,
        subject: FinanceSubject.matteo,
        description: 'Corretto',
        type: FinanceTransactionType.expense,
        origin: FinanceTransactionOrigin.adjustment,
        economicFactId: id,
        operationMetadata: EconomicOperationMetadata(
          operationId: 'operation',
          role: OperationRole.main,
          context: OperationContext.utilityBill,
          documentaryObligationId: 'obligation',
        ),
      );

      expect(
        await coordinator.replaceInstallmentFulfillmentVerified(
          obligationId: 'obligation',
          installmentId: 'installment',
          expectedOldEconomicFactId: 'old-main',
          replacementMain: replacement('new-main'),
          operationId: 'operation',
        ),
        DocumentaryObligationOutcome.applied,
      );
      expect(
        await coordinator.replaceInstallmentFulfillmentVerified(
          obligationId: 'obligation',
          installmentId: 'installment',
          expectedOldEconomicFactId: 'old-main',
          replacementMain: replacement('new-main'),
          operationId: 'operation',
        ),
        DocumentaryObligationOutcome.unchanged,
      );
      expect(
        await coordinator.replaceInstallmentFulfillmentVerified(
          obligationId: 'obligation',
          installmentId: 'installment',
          expectedOldEconomicFactId: 'old-main',
          replacementMain: replacement('third-main'),
          operationId: 'operation',
        ),
        DocumentaryObligationOutcome.conflict,
      );
    },
  );
}
