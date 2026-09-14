import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/screens/account_detail_screen.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  final accounts = <({String name, FinanceBalanceType type})>[
    (name: 'Banca di Imola', type: FinanceBalanceType.bankAccount),
    (name: 'Findomestic', type: FinanceBalanceType.bankAccount),
    (name: 'Prepagata Banca di Imola', type: FinanceBalanceType.prepaidCard),
  ];

  for (final account in accounts) {
    testWidgets(
      'AccountDetailScreen shows a readable AppBar for ${account.name}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final balance = FinanceBalance(
          personId: 'matteo',
          balanceId: 'balance_${account.name}',
          name: account.name,
          initialAmount: 0,
          currentAmount: 0,
          updatedAt: DateTime(2026),
          balanceType: account.type,
          operational: true,
          active: true,
          reservedAmount: 0,
          warningThreshold: 0,
          persistentStressDays: 0,
          recoveryDays: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountDetailScreen(
                          financeStore: FinanceStore(
                            initialBalances: [balance],
                          ),
                          balance: balance,
                        ),
                      ),
                    );
                  },
                  child: const Text('Apri dettaglio'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Apri dettaglio'));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text(account.name),
          ),
          findsOneWidget,
        );
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.foregroundColor, Colors.white);
        expect(find.byType(BackButton), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.text('Apri dettaglio'), findsOneWidget);
        expect(find.text(account.name), findsNothing);
      },
    );
  }
}
