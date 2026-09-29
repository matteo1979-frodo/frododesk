import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/screens/account_detail_screen.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  testWidgets('account movements present composite accessories semantically', (
    tester,
  ) async {
    final balance = _balance();
    await tester.pumpWidget(
      MaterialApp(
        home: AccountDetailScreen(
          financeStore: FinanceStore(
            initialBalances: [balance],
            initialTransactions: [
              _transaction(id: 'normal', description: 'Movimento normale'),
              _transaction(
                id: 'main',
                description: 'TARI 2026',
                metadata: EconomicOperationMetadata(
                  operationId: 'tari-operation',
                  role: OperationRole.main,
                  context: OperationContext.utilityBill,
                ),
              ),
              _transaction(
                id: 'bank',
                description: 'TARI 2026',
                metadata: EconomicOperationMetadata(
                  operationId: 'tari-operation',
                  role: OperationRole.accessory,
                  context: OperationContext.utilityBill,
                  accessoryCostType: AccessoryCostType.bankCommission,
                ),
              ),
              _transaction(
                id: 'postal',
                description: 'Bolletta acqua Hera',
                metadata: EconomicOperationMetadata(
                  operationId: 'hera-operation',
                  role: OperationRole.accessory,
                  context: OperationContext.utilityBill,
                  accessoryCostType:
                      AccessoryCostType.postalAcceptanceCharge,
                ),
              ),
            ],
          ),
          balance: balance,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Movimento normale'), findsOneWidget);
    expect(find.text('TARI 2026'), findsNWidgets(2));
    expect(find.text('Commissione bancaria'), findsOneWidget);
    expect(find.text('Costo accettazione postale'), findsOneWidget);
    expect(find.text('Bolletta acqua Hera'), findsOneWidget);
  });

  testWidgets('all movements dialog uses a dark readable surface', (
    tester,
  ) async {
    final balance = _balance();
    await tester.pumpWidget(
      MaterialApp(
        home: AccountDetailScreen(
          financeStore: FinanceStore(
            initialBalances: [balance],
            initialTransactions: [
              for (var index = 0; index < 6; index++)
                _transaction(
                  id: 'movement-$index',
                  description: 'Movimento $index',
                ),
            ],
          ),
          balance: balance,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Vedi tutti'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.backgroundColor, const Color(0xFF142219));
    final title = dialog.title! as Text;
    expect(title.style?.color, Colors.white);
    final movement = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Movimento 0'),
    );
    expect(movement, findsOneWidget);
    expect(tester.widget<Text>(movement).style?.color, Colors.white);
  });
}

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'account',
  name: 'Banca di prova',
  initialAmount: 100,
  currentAmount: 100,
  updatedAt: DateTime(2026, 9, 28),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceTransaction _transaction({
  required String id,
  required String description,
  EconomicOperationMetadata? metadata,
}) => FinanceTransaction(
  id: id,
  balanceId: 'account',
  amount: 1,
  date: DateTime(2026, 9, 28),
  isIncome: false,
  subject: FinanceSubject.matteo,
  description: description,
  type: FinanceTransactionType.expense,
  origin: FinanceTransactionOrigin.manual,
  economicFactId: 'fact-$id',
  operationMetadata: metadata,
);
