import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/screens/person_finance_screen.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  for (final personName in ['Matteo', 'Chiara']) {
    testWidgets('PersonFinanceScreen shows a readable AppBar for $personName', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PersonFinanceScreen(
                        financeStore: FinanceStore(),
                        personId: personName.toLowerCase(),
                        personName: personName,
                      ),
                    ),
                  );
                },
                child: const Text('Apri conti'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apri conti'));
      await tester.pumpAndSettle();

      expect(find.text('Conti $personName'), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.foregroundColor, Colors.white);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Apri conti'), findsOneWidget);
      expect(find.text('Conti $personName'), findsNothing);
    });
  }
}
