import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frododesk/logic/composite_creation_intent_store.dart';
import 'package:frododesk/models/continuing_service_relationship.dart';
import 'package:frododesk/models/sim_service_details.dart';
import 'package:frododesk/screens/telefonia_screen.dart';
import 'package:frododesk/stores/continuing_service_relationship_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:frododesk/stores/sim_service_details_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('empty state exposes one clear Add SIM action', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Nessuna SIM configurata'), findsOneWidget);
    expect(find.text('Aggiungi SIM'), findsOneWidget);
  });

  testWidgets('Add SIM form exposes supported people by name and no shared', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiungi SIM'));
    await tester.pumpAndSettle();

    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Etichetta SIM'), findsOneWidget);
    expect(find.text('Prossimo rinnovo'), findsOneWidget);
    expect(find.text('La SIM'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Rinnovo e credito'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Matteo'), findsOneWidget);
    expect(find.text('Chiara'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.textContaining('shared'), findsNothing);
  });

  testWidgets('missing person blocks submit before starting an operation', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aggiungi SIM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crea SIM'));
    await tester.pump();

    expect(find.text('Seleziona una persona'), findsOneWidget);
    expect(harness.intentStore.intents, isEmpty);
    expect(harness.relationshipStore.items, isEmpty);
  });

  testWidgets(
    'selected person is propagated consistently and double submit is ignored',
    (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aggiungi SIM'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Provider'),
        'Test provider',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Etichetta SIM'),
        'Test SIM',
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matteo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Numero'),
        '3700000000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Offerta'),
        'Test offer',
      );
      await _chooseDefaultDate(tester, 'Data di attivazione');
      await _chooseDefaultDate(tester, 'Scadenza SIM');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Importo rinnovo'),
        '4,99',
      );
      await _chooseDefaultDate(tester, 'Prossimo rinnovo');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Credito SIM attuale'),
        '4,23',
      );
      await tester.ensureVisible(find.text('Crea SIM'));
      await tester.tap(find.text('Crea SIM'));
      await tester.tap(find.text('Crea SIM'));
      await tester.pumpAndSettle();

      expect(harness.intentStore.intents, hasLength(1));
      expect(harness.relationshipStore.items, hasLength(1));
      expect(harness.financeStore.balances, hasLength(1));
      expect(
        harness.financeStore.expectedExpenseAggregate.relationships,
        hasLength(1),
      );
      final service = harness.relationshipStore.items.single;
      final balance = harness.financeStore.balances.single;
      final expense =
          harness.financeStore.expectedExpenseAggregate.relationships.single;
      expect(service.personId, 'matteo');
      expect(balance.personId, service.personId);
      expect(expense.subject.name, service.personId);
      expect(expense.subject.name, isNot('shared'));
      expect(harness.financeStore.transactions, isEmpty);
    },
  );

  testWidgets('legacy relationship without person or SIM details still renders', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.relationshipStore.add(
      ContinuingServiceRelationship(
        relationshipId: 'legacy_service',
        provider: 'Legacy provider',
        label: 'Legacy line',
      ),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Legacy line'), findsOneWidget);
    expect(find.textContaining('Persona non associata'), findsOneWidget);
  });

  testWidgets('SIM card masks phone number and keeps safe edit identity', (
    tester,
  ) async {
    final harness = _Harness();
    final relationship = ContinuingServiceRelationship(
      relationshipId: 'service_1',
      provider: 'Provider',
      label: 'Personal line',
      personId: 'matteo',
    );
    await harness.relationshipStore.add(relationship);
    await harness.simStore.save(
      SimServiceDetails(
        relationshipId: relationship.relationshipId,
        phoneNumber: '3703042030',
        offerName: 'Mobile offer',
        activationDate: DateTime(2026, 6, 12),
        simExpirationDate: DateTime(2027, 10, 11),
      ),
    );
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.textContaining('******2030'), findsOneWidget);
    expect(find.textContaining('3703042030'), findsNothing);
    await tester.tap(find.byTooltip('Modifica'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Updated label');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(harness.relationshipStore.items.single.relationshipId, 'service_1');
    expect(harness.relationshipStore.items.single.personId, 'matteo');
    expect(harness.relationshipStore.items.single.label, 'Updated label');
  });
}

Future<void> _chooseDefaultDate(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

class _Harness {
  final relationshipStore = ContinuingServiceRelationshipStore();
  final simStore = SimServiceDetailsStore();
  final intentStore = CompositeCreationIntentStore();
  final financeStore = FinanceStore();

  Widget app() => MaterialApp(
    home: TelefoniaScreen(
      relationshipStore: relationshipStore,
      simDetailsStore: simStore,
      intentStore: intentStore,
      financeStore: financeStore,
    ),
  );
}
