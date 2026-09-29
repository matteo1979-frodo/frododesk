import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/documentary_obligation_coordinator.dart';
import 'package:frododesk/logic/finance/documentary_obligation_persistence.dart';
import 'package:frododesk/logic/finance/documentary_obligation_projection_adapter.dart';
import 'package:frododesk/logic/finance/expected_expense_reader.dart';
import 'package:frododesk/logic/finance/expected_expense_persistence.dart';
import 'package:frododesk/logic/finance/expense_relationship_projection_adapter.dart';
import 'package:frododesk/logic/finance/future_expense_reader.dart';
import 'package:frododesk/logic/finance/future_outflow_presentation_composer.dart';
import 'package:frododesk/logic/persistence_store.dart';
import 'package:frododesk/models/composite_economic_operation.dart';
import 'package:frododesk/models/documentary_obligation.dart';
import 'package:frododesk/models/economic_operation_metadata.dart';
import 'package:frododesk/models/expense_relationship.dart';
import 'package:frododesk/models/expected_expense_occurrence.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_category_template.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/future_expense_projection.dart';
import 'package:frododesk/models/future_outflow_presentation.dart';
import 'package:frododesk/models/projected_expense_cycle.dart';
import 'package:frododesk/models/real_expense.dart';
import 'package:frododesk/stores/expense_store.dart';
import 'package:frododesk/stores/finance_store.dart';
import 'package:frododesk/screens/documentary_obligations_page.dart';

void main() {
  group('DocumentaryObligation', () {
    test('JSON round-trip preserves optional documentary knowledge', () {
      final source = _tari();
      final restored = DocumentaryObligation.fromJson(source.toJson());
      expect(restored.toJson(), source.toJson());
      expect(restored.documentHolder, FinanceSubject.chiara);
      expect(restored.receivedAt, isNull);
    });

    test('legacy aggregate without obligations loads empty', () async {
      final persistence = DocumentaryObligationPersistence(load: (_) async => null);
      expect((await persistence.load()).obligations, isEmpty);
    });

    test('legacy aggregate without expected documents remains compatible', () async {
      final persistence = DocumentaryObligationPersistence(
        load: (_) async => '{"version":1,"obligations":[]}',
      );
      final restored = await persistence.load();
      expect(restored.expectedDocuments, isEmpty);
    });

    test('expected document cycle carries a month but no economic amount', () {
      final expected = ExpectedDocumentCycle(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
        expectedPeriod: ExpectedDocumentPeriod(year: 2027, month: 3),
      );
      expect(expected.identity, 'annual-tax#2');
      expect(expected.toJson(), isNot(contains('amount')));
      expect(expected.toJson(), isNot(contains('dueDate')));
    });

    test('single option is implicit and produces one operational deadline', () {
      final value = _sorit();
      expect(value.effectiveSelectedOptionId, 'single');
      expect(value.operationalInstallments.single.amount, 46.32);
    });

    test('only selected TARI option produces operational installments', () {
      final value = _tari().selectOption('single');
      expect(value.operationalInstallments, hasLength(1));
      expect(value.operationalInstallments.single.amount, 173);
      expect(value.operationalInstallments.single.dueDate, DateTime(2026, 6, 30));
      expect(value.isLate(installmentId: 'single-1', paidAt: DateTime(2026, 4, 7)), isFalse);
      expect(value.options.singleWhere((item) => item.optionId == 'installments').installments.map((item) => item.amount), [58, 58, 57]);
    });

    test('installment option has three distinct deadlines summing obligation', () {
      final value = _tari().selectOption('installments');
      expect(value.operationalInstallments, hasLength(3));
      expect(value.operationalInstallments.fold<double>(0, (sum, item) => sum + item.amount), 173);
      expect(value.operationalInstallments.map((item) => item.dueDate), [DateTime(2026, 3, 31), DateTime(2026, 6, 30), DateTime(2026, 9, 30)]);
    });

    test('different second selection conflicts while retry is stable', () {
      final selected = _tari().selectOption('single');
      expect(selected.selectOption('single').selectedOptionId, 'single');
      expect(() => selected.selectOption('installments'), throwsStateError);
    });

    test('pending contingency has no amount and no projected outflow', () {
      final value = _tari();
      expect(value.contingencies.single.status, DocumentaryContingencyStatus.pending);
      final projected = const DocumentaryObligationProjectionAdapter().project(DocumentaryObligationAggregate(obligations: [value]));
      expect(projected, isEmpty);
    });

    test('legacy contingency status decodes without rewriting persistence', () async {
      var writes = 0;
      final source = _tari().toJson();
      final raw = jsonEncode({
        'version': 1,
        'obligations': [source],
        'expectedDocuments': const [],
      });
      final persistence = DocumentaryObligationPersistence(
        load: (_) async => raw,
        save: (_, value) async {
          writes++;
          return PersistenceWriteVerification(
            backendAccepted: true,
            readBack: value,
          );
        },
      );

      final restored = await persistence.load();

      expect(restored.obligations.single.contingencies.single.status,
          DocumentaryContingencyStatus.pending);
      expect(writes, 0);
    });

    test('not-due contingency stays closed and creates no outflow', () {
      final source = _tari();
      final closed = source.replaceContingency(source.contingencies.single.copyWith(status: DocumentaryContingencyStatus.notDue));
      expect(closed.contingencies.single.status, DocumentaryContingencyStatus.notDue);
      expect(const DocumentaryObligationProjectionAdapter().project(DocumentaryObligationAggregate(obligations: [closed])), isEmpty);
    });

    test('projection contains selected option only and does not double count', () {
      final value = _tari().selectOption('single');
      final projected = const DocumentaryObligationProjectionAdapter().project(DocumentaryObligationAggregate(obligations: [value]));
      expect(projected, hasLength(1));
      expect(projected.single.amount, 173);
      expect(projected.single.identity, 'documentary:tari-2026:single-1');
    });

    test('documentary installment takes precedence over projected cycle', () {
      final obligation = DocumentaryObligation.fromJson({
        ..._tari().selectOption('single').toJson(),
        'relationshipId': 'annual-tax',
        'cycleSequence': 1,
      });
      final documentary = const DocumentaryObligationProjectionAdapter().project(
        DocumentaryObligationAggregate(obligations: [obligation]),
      );
      final projected = ProjectedExpenseCycle(
        identity: const ExpenseCycleIdentity(
          relationshipId: 'annual-tax',
          cycleSequence: 1,
        ),
        cycleAnchor: DateTime(2026, 6, 30),
        sourceOccurrenceId: 'source',
        service: 'Tributo',
        provider: 'Ente',
        expectedAmount: 170,
        expectedSubject: FinanceSubject.matteo,
        expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.manual,
        ),
        paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
        provisional: true,
      );
      final overview = const FutureOutflowPresentationComposer().compose(
        expectedExpenses: const [],
        projectedCycles: [projected],
        finitePlans: const [],
        referenceTime: DateTime(2026, 1, 1),
        documentaryInstallments: documentary,
      );
      final items = [
        ...overview.pastMonths,
        ...overview.currentMonth,
        for (final month in overview.futureMonths) ...month.items,
        ...overview.unplaced,
      ];
      expect(items, hasLength(1));
      expect(items.single.amount, 173);
    });

    for (final realAmount in [160.0, 190.0]) {
      test('real document $realAmount suppresses a 173 estimate by cycle identity', () {
        final projected = ProjectedExpenseCycle(
          identity: const ExpenseCycleIdentity(
            relationshipId: 'annual-tax',
            cycleSequence: 2,
          ),
          expectedPeriod: ExpectedDocumentPeriod(year: 2027, month: 3),
          sourceOccurrenceId: 'documentary_annual-tax_2',
          service: 'TARI',
          provider: 'Comune',
          expectedAmount: 173,
          expectedSubject: FinanceSubject.matteo,
          expectedPaymentConfiguration:
              ExpenseRelationshipPaymentConfiguration(
                method: FinancePaymentMethod.manual,
              ),
          paymentExecutionMode: PaymentExecutionMode.unknown,
          provisional: true,
        );
        final documentary = FutureOutflowPresentation(
          identity: 'documentary:tari-2027:single',
          authority: FutureOutflowAuthority.documentaryObligation,
          title: 'TARI 2027',
          details: '',
          amount: realAmount,
          placementStart: DateTime(2027, 6, 30),
          placementEnd: DateTime(2027, 6, 30),
          datePresentation:
              FutureOutflowDatePresentation.documentaryDeadline,
          requiresPlanning: false,
          provisional: false,
          requiresUserAction: true,
          overdue: false,
          relationshipId: 'annual-tax',
          cycleSequence: 2,
        );

        final overview = const FutureOutflowPresentationComposer().compose(
          expectedExpenses: const [],
          projectedCycles: [projected],
          finitePlans: const [],
          referenceTime: DateTime(2027),
          documentaryInstallments: [documentary],
        );
        final items = [
          ...overview.pastMonths,
          ...overview.currentMonth,
          for (final month in overview.futureMonths) ...month.items,
          ...overview.unplaced,
        ];
        expect(items, hasLength(1));
        expect(items.single.amount, realAmount);
      });
    }

    group('permanent documentary precedence', () {
      for (final realAmount in [173.0, 181.0]) {
        test(
          'materialized document $realAmount suppresses the seed by cycle identity',
          () {
            final aggregate = _materializedDocumentaryAggregate(
              amount: realAmount,
            );
            final sourceJson = aggregate.toJson();
            final documentary =
                const DocumentaryObligationProjectionAdapter()
                    .projectWithAuthority(aggregate);

            final overview =
                const FutureOutflowPresentationComposer().compose(
                  expectedExpenses: [_documentarySeed()],
                  projectedCycles: [_documentaryProjectedCycle(sequence: 2)],
                  finitePlans: const [],
                  referenceTime: DateTime(2027, 1, 1),
                  documentaryInstallments: documentary.items,
                  materializedDocumentaryCycleIds:
                      documentary.materializedCycleIdentities,
                );
            final items = _futureOutflowItems(overview);

            expect(documentary.materializedCycleIdentities, [
              'annual-tax#2',
            ]);
            expect(documentary.operationalInstallments, isEmpty);
            expect(
              documentary.materializedObligationsAwaitingChoice,
              hasLength(1),
            );
            expect(items, hasLength(1));
            expect(items.single.authority,
                FutureOutflowAuthority.documentaryObligation);
            expect(items.single.amount, realAmount);
            expect(items.single.datePresentation,
                FutureOutflowDatePresentation.documentaryChoiceRequired);
            expect(items.single.details, 'Scegli come pagare');
            expect(items.single.requiresUserAction, isTrue);
            expect(aggregate.toJson(), sourceJson);
          },
        );
      }

      test('selected option exposes only installments without total duplication',
          () {
        final aggregate = _materializedDocumentaryAggregate(
          amount: 173,
          selected: true,
        );
        final documentary = const DocumentaryObligationProjectionAdapter()
            .projectWithAuthority(aggregate);
        final overview = const FutureOutflowPresentationComposer().compose(
          expectedExpenses: [_documentarySeed()],
          projectedCycles: [_documentaryProjectedCycle(sequence: 2)],
          finitePlans: const [],
          referenceTime: DateTime(2027, 1, 1),
          documentaryInstallments: documentary.items,
          materializedDocumentaryCycleIds:
              documentary.materializedCycleIdentities,
        );
        final items = _futureOutflowItems(overview);

        expect(documentary.operationalInstallments, hasLength(1));
        expect(documentary.materializedObligationsAwaitingChoice, isEmpty);
        expect(items, hasLength(1));
        expect(items.single.identity, 'documentary:tari-2027:single-1');
        expect(items.single.amount, 173);
        expect(
          items.where((item) =>
              item.datePresentation ==
              FutureOutflowDatePresentation.documentaryChoiceRequired),
          isEmpty,
        );
      });

      test('fulfilled document keeps authority and seed never returns', () {
        final aggregate = _materializedDocumentaryAggregate(
          amount: 173,
          selected: true,
          fulfilled: true,
        );
        final documentary = const DocumentaryObligationProjectionAdapter()
            .projectWithAuthority(aggregate);
        final overview = const FutureOutflowPresentationComposer().compose(
          expectedExpenses: [_documentarySeed()],
          projectedCycles: [_documentaryProjectedCycle(sequence: 2)],
          finitePlans: const [],
          referenceTime: DateTime(2027, 1, 1),
          documentaryInstallments: documentary.items,
          materializedDocumentaryCycleIds:
              documentary.materializedCycleIdentities,
        );

        expect(documentary.items, isEmpty);
        expect(documentary.materializedCycleIdentities, ['annual-tax#2']);
        expect(_futureOutflowItems(overview), isEmpty);
      });

      test('duplicate documentary cycle identity fails explicitly', () {
        final first = _materializedDocumentaryAggregate(amount: 173)
            .obligations
            .single;
        final duplicate = DocumentaryObligation.fromJson({
          ...first.toJson(),
          'obligationId': 'tari-2027-duplicate',
        });
        final aggregate = DocumentaryObligationAggregate(
          obligations: [first, duplicate],
        );
        final before = aggregate.obligations
            .map((obligation) => obligation.toJson())
            .toList();

        expect(
          () => const DocumentaryObligationProjectionAdapter()
              .projectWithAuthority(aggregate),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('annual-tax#2'),
            ),
          ),
        );
        expect(
          aggregate.obligations.map((obligation) => obligation.toJson()),
          before,
        );
      });

      test('different cycle sequences and relationships remain valid', () {
        final first = _materializedDocumentaryAggregate(amount: 173)
            .obligations
            .single;
        final nextCycle = DocumentaryObligation.fromJson({
          ...first.toJson(),
          'obligationId': 'tari-2028',
          'cycleSequence': 3,
        });
        final otherRelationship = DocumentaryObligation.fromJson({
          ...first.toJson(),
          'obligationId': 'other-2027',
          'relationshipId': 'other-tax',
        });

        final result = const DocumentaryObligationProjectionAdapter()
            .projectWithAuthority(
          DocumentaryObligationAggregate(
            obligations: [first, nextCycle, otherRelationship],
          ),
        );

        expect(
          result.materializedCycleIdentities,
          ['annual-tax#2', 'annual-tax#3', 'other-tax#2'],
        );
      });

      test('reload preserves complete fulfilled documentary precedence',
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
        final source = _materializedDocumentaryAggregate(
          amount: 181,
          selected: true,
          fulfilled: true,
        );
        await persistence.write(source);
        final restored = await persistence.load();
        final adapter = const DocumentaryObligationProjectionAdapter();

        final before = adapter.projectWithAuthority(source);
        final after = adapter.projectWithAuthority(restored);
        final composer = const FutureOutflowPresentationComposer();
        final expectedExpenses = [
          _documentarySeed(sequence: 2),
          _documentarySeed(identity: 'next-seed', sequence: 3),
        ];
        final projectedCycles = [
          _documentaryProjectedCycle(sequence: 2),
          _documentaryProjectedCycle(sequence: 3),
        ];
        final beforeOverview = composer.compose(
          expectedExpenses: expectedExpenses,
          projectedCycles: projectedCycles,
          finitePlans: const [],
          referenceTime: DateTime(2027, 1, 1),
          documentaryInstallments: before.items,
          materializedDocumentaryCycleIds:
              before.materializedCycleIdentities,
        );
        final afterOverview = composer.compose(
          expectedExpenses: expectedExpenses,
          projectedCycles: projectedCycles,
          finitePlans: const [],
          referenceTime: DateTime(2027, 1, 1),
          documentaryInstallments: after.items,
          materializedDocumentaryCycleIds:
              after.materializedCycleIdentities,
        );
        final beforeItems = _futureOutflowItems(beforeOverview);
        final afterItems = _futureOutflowItems(afterOverview);

        expect(after.materializedCycleIdentities,
            before.materializedCycleIdentities);
        expect(before.items, isEmpty);
        expect(after.items, isEmpty);
        expect(
          afterItems.map(_futureOutflowSignature),
          beforeItems.map(_futureOutflowSignature),
        );
        expect(afterItems.map((item) => item.identity), contains('next-seed'));
        expect(
          afterItems.map((item) => item.identity),
          isNot(contains('documentary_annual-tax_2')),
        );
        expect(
          afterItems.map((item) => item.identity),
          isNot(contains('documentary:tari-2027:choice')),
        );
      });

      test('materialized 2027 cycle does not suppress projected 2028 cycle', () {
        final aggregate = _materializedDocumentaryAggregate(amount: 173);
        final documentary = const DocumentaryObligationProjectionAdapter()
            .projectWithAuthority(aggregate);
        final overview = const FutureOutflowPresentationComposer().compose(
          expectedExpenses: [_documentarySeed()],
          projectedCycles: [
            _documentaryProjectedCycle(sequence: 2),
            _documentaryProjectedCycle(sequence: 3),
          ],
          finitePlans: const [],
          referenceTime: DateTime(2027, 1, 1),
          documentaryInstallments: documentary.items,
          materializedDocumentaryCycleIds:
              documentary.materializedCycleIdentities,
        );
        final items = _futureOutflowItems(overview);

        expect(items, hasLength(2));
        expect(
          items.map((item) => item.identity),
          containsAll([
            'documentary:tari-2027:choice',
            'annual-tax#3',
          ]),
        );
      });

      test('backfilled seed is suppressed only by its structural cycle identity',
          () {
        final aggregate = _materializedDocumentaryAggregate(amount: 173);
        final documentary = const DocumentaryObligationProjectionAdapter()
            .projectWithAuthority(aggregate);
        final overview = const FutureOutflowPresentationComposer().compose(
          expectedExpenses: [
            _documentarySeed(identity: 'backfilled-seed', sequence: 2),
            _documentarySeed(identity: 'next-seed', sequence: 3),
          ],
          projectedCycles: const [],
          finitePlans: const [],
          referenceTime: DateTime(2027, 1, 1),
          documentaryInstallments: documentary.items,
          materializedDocumentaryCycleIds:
              documentary.materializedCycleIdentities,
        );
        final items = _futureOutflowItems(overview);

        expect(items.map((item) => item.identity), isNot(contains('backfilled-seed')));
        expect(items.map((item) => item.identity), contains('next-seed'));
      });

      test('projection precedence does not mutate economic stores', () async {
        final balance = FinanceBalance(
          personId: 'person_matteo',
          balanceId: 'bank',
          name: 'Conto',
          initialAmount: 1000,
          currentAmount: 1000,
          updatedAt: DateTime(2027, 1, 1),
          balanceType: FinanceBalanceType.bankAccount,
          operational: true,
          active: true,
          reservedAmount: 0,
          warningThreshold: 0,
          persistentStressDays: 0,
          recoveryDays: 0,
        );
        final transaction = FinanceTransaction(
          id: 'transaction-existing',
          balanceId: balance.balanceId,
          amount: 10,
          date: DateTime(2026, 12, 1),
          isIncome: false,
          subject: FinanceSubject.matteo,
          description: 'Esistente',
          type: FinanceTransactionType.expense,
          origin: FinanceTransactionOrigin.manual,
          economicFactId: 'fact-existing',
        );
        final realExpense = RealExpense(
          id: 'expense-existing',
          balanceId: balance.balanceId,
          balanceName: balance.name,
          amount: 10,
          description: 'Esistente',
          category: 'Altro',
          date: DateTime(2026, 12, 1),
          subject: FinanceSubject.matteo,
          economicFactId: 'fact-existing',
        );
        final financeStore = FinanceStore(
          initialBalances: [balance],
          initialTransactions: [transaction],
        );
        final expenseStore = ExpenseStore(
          load: (_) async => jsonEncode([realExpense.toJson()]),
        );
        await expenseStore.load();
        var financeNotifications = 0;
        var expenseNotifications = 0;
        financeStore.addListener(() => financeNotifications++);
        expenseStore.addListener(() => expenseNotifications++);
        final balanceBefore = financeStore.balances.single.toJson();
        final transactionBefore = financeStore.transactions.single.toJson();
        final expenseBefore = expenseStore.all.single.toJson();

        final aggregate = _materializedDocumentaryAggregate(amount: 181);
        final documentary = const DocumentaryObligationProjectionAdapter()
            .projectWithAuthority(aggregate);
        const FutureOutflowPresentationComposer().compose(
          expectedExpenses: [_documentarySeed()],
          projectedCycles: [_documentaryProjectedCycle(sequence: 2)],
          finitePlans: const [],
          referenceTime: DateTime(2027, 1, 1),
          documentaryInstallments: documentary.items,
          materializedDocumentaryCycleIds:
              documentary.materializedCycleIdentities,
        );

        expect(financeStore.balances.single.toJson(), balanceBefore);
        expect(financeStore.transactions.single.toJson(), transactionBefore);
        expect(expenseStore.all.single.toJson(), expenseBefore);
        expect(financeNotifications, 0);
        expect(expenseNotifications, 0);
      });
    });

    test('verified persistence reload preserves selected option and contingency', () async {
      String? stored;
      final persistence = DocumentaryObligationPersistence(
        load: (_) async => stored,
        save: (_, value) async { stored = value; return PersistenceWriteVerification(backendAccepted: true, readBack: value); },
      );
      final candidate = DocumentaryObligationAggregate(obligations: [_tari().selectOption('single')]);
      await persistence.write(candidate);
      final restored = await persistence.load();
      expect(restored.obligations.single.toJson(), candidate.obligations.single.toJson());
    });

    test('coordinator selection and not-due closure are idempotent', () async {
      String? stored;
      final persistence = DocumentaryObligationPersistence(
        load: (_) async => stored,
        save: (_, value) async { stored = value; return PersistenceWriteVerification(backendAccepted: true, readBack: value); },
      );
      final finance = FinanceStore(documentaryObligationPersistence: persistence, initialDocumentaryObligationAggregate: DocumentaryObligationAggregate(obligations: [_tari()]));
      final coordinator = DocumentaryObligationCoordinator(financeStore: finance);
      expect(await coordinator.selectOption(obligationId: 'tari-2026', optionId: 'single'), DocumentaryObligationOutcome.applied);
      expect(await coordinator.selectOption(obligationId: 'tari-2026', optionId: 'single'), DocumentaryObligationOutcome.unchanged);
      expect(await coordinator.closeContingencyNotDue(obligationId: 'tari-2026', contingencyId: 'balance'), DocumentaryObligationOutcome.applied);
      expect(await coordinator.closeContingencyNotDue(obligationId: 'tari-2026', contingencyId: 'balance'), DocumentaryObligationOutcome.unchanged);
    });

    test('recurring document creates continuity and next amount-free expectation idempotently', () async {
      String? expectedStored;
      String? documentaryStored;
      final relationship = ExpenseRelationship(
        relationshipId: 'annual-service',
        service: 'Pagamento annuale',
        provider: 'Ente generico',
        subject: FinanceSubject.matteo,
        status: ExpenseRelationshipStatus.active,
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.yearly,
        ),
        paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.manual,
        ),
      );
      final obligation = DocumentaryObligation.fromJson({
        ..._sorit().toJson(),
        'relationshipId': relationship.relationshipId,
        'cycleSequence': 1,
      });
      final next = ExpectedDocumentCycle(
        relationshipId: relationship.relationshipId,
        cycleSequence: 2,
        expectedPeriod: ExpectedDocumentPeriod(year: 2027, month: 3),
      );
      final finance = FinanceStore(
        expectedExpensePersistence: ExpectedExpensePersistence(
          load: (_) async => expectedStored,
          save: (_, value) async {
            expectedStored = value;
            return PersistenceWriteVerification(backendAccepted: true, readBack: value);
          },
        ),
        documentaryObligationPersistence: DocumentaryObligationPersistence(
          load: (_) async => documentaryStored,
          save: (_, value) async {
            documentaryStored = value;
            return PersistenceWriteVerification(backendAccepted: true, readBack: value);
          },
        ),
      );
      final coordinator = DocumentaryObligationCoordinator(financeStore: finance);
      expect(
        await coordinator.registerRecurringDocument(
          obligation: obligation,
          relationship: relationship,
          nextExpectedDocument: next,
        ),
        DocumentaryObligationOutcome.applied,
      );
      expect(
        await coordinator.registerRecurringDocument(
          obligation: obligation,
          relationship: relationship,
          nextExpectedDocument: next,
        ),
        DocumentaryObligationOutcome.unchanged,
      );
      expect(finance.expectedExpenseAggregate.relationships.single.relationshipId, 'annual-service');
      final seed = finance.expectedExpenseAggregate.occurrences.single;
      expect(seed.relationshipId, next.relationshipId);
      expect(seed.cycleSequence, next.cycleSequence);
      expect(seed.expectedPeriod!.year, 2027);
      expect(seed.expectedPeriod!.month, 3);
      expect(seed.expectedAmount, obligation.totalAmount);
      expect(seed.provisional, isTrue);
      expect(seed.sourceDocumentaryObligationId, obligation.obligationId);
      expect(seed.evidenceEconomicFactIds, isEmpty);
      expect(seed.expectedDueDate, isNull);
      expect(seed.expectedPaymentWindow, isNull);
      expect(seed.plannedEconomicImpact, isNull);
      expect(seed.paymentExecutionMode, PaymentExecutionMode.unknown);
      expect(finance.expectedExpenseAggregate.occurrences, hasLength(1));
      expect(finance.documentaryObligationAggregate.expectedDocuments.single.toJson(), isNot(contains('amount')));
    });

    test('fulfilled installment is removed from operational projection and retry is stable', () async {
      String? stored;
      final persistence = DocumentaryObligationPersistence(
        load: (_) async => stored,
        save: (_, value) async {
          stored = value;
          return PersistenceWriteVerification(backendAccepted: true, readBack: value);
        },
      );
      final finance = FinanceStore(
        documentaryObligationPersistence: persistence,
        initialDocumentaryObligationAggregate: DocumentaryObligationAggregate(
          obligations: [_tari().selectOption('single')],
        ),
      );
      final coordinator = DocumentaryObligationCoordinator(financeStore: finance);
      expect(
        await coordinator.markInstallmentFulfilled(
          obligationId: 'tari-2026',
          installmentId: 'single-1',
          economicFactId: 'tari-payment-2026',
        ),
        DocumentaryObligationOutcome.applied,
      );
      expect(
        await coordinator.markInstallmentFulfilled(
          obligationId: 'tari-2026',
          installmentId: 'single-1',
          economicFactId: 'tari-payment-2026',
        ),
        DocumentaryObligationOutcome.unchanged,
      );
      expect(finance.documentaryObligationAggregate.obligations.single.operationalInstallments, isEmpty);
      expect(
        const DocumentaryObligationProjectionAdapter().project(
          finance.documentaryObligationAggregate,
        ),
        isEmpty,
      );
      expect(
        (await persistence.load())
            .obligations
            .single
            .selectedOption!
            .installments
            .single
            .fulfilledEconomicFactId,
        'tari-payment-2026',
      );
    });

    test('contingency materialization is recoverable and does not duplicate occurrence', () async {
      String? expectedStored;
      String? documentaryStored;
      final expectedPersistence = ExpectedExpensePersistence(
        load: (_) async => expectedStored,
        save: (_, value) async {
          expectedStored = value;
          return PersistenceWriteVerification(backendAccepted: true, readBack: value);
        },
      );
      final documentaryPersistence = DocumentaryObligationPersistence(
        load: (_) async => documentaryStored,
        save: (_, value) async {
          documentaryStored = value;
          return PersistenceWriteVerification(backendAccepted: true, readBack: value);
        },
      );
      final relationship = ExpenseRelationship(
        relationshipId: 'tari-relationship',
        service: 'Tributo locale',
        provider: 'Ente',
        subject: FinanceSubject.matteo,
        status: ExpenseRelationshipStatus.active,
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.yearly,
        ),
        paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.manual,
        ),
        paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
      );
      final obligation = DocumentaryObligation.fromJson({
        ..._tari().toJson(),
        'relationshipId': relationship.relationshipId,
      });
      final finance = FinanceStore(
        expectedExpensePersistence: expectedPersistence,
        documentaryObligationPersistence: documentaryPersistence,
        initialExpectedExpenseAggregate: ExpectedExpenseAggregate(
          relationships: [relationship],
          occurrences: [
            ExpectedExpenseOccurrence(
              occurrenceId: 'annual-cycle-1',
              relationshipId: relationship.relationshipId,
              cycleSequence: 1,
              cycleAnchor: DateTime(2026, 3, 1),
              status: ExpectedExpenseOccurrenceStatus.resolved,
              expectedDueDate: DateTime(2026, 3, 31),
              expectedDueDateSource: ExpectedExpenseDateSource.explicit,
              expectedAmount: 173,
              estimationMethod: ExpenseEstimationMethod.manualEstimate,
              confidence: ExpenseEstimateConfidence.high,
              provisional: false,
              expectedPaymentConfiguration: relationship.paymentConfiguration,
              paymentExecutionMode: relationship.paymentExecutionMode,
              expectedSubject: relationship.subject,
              resolvedEconomicFactId: 'paid-cycle-1',
            ),
          ],
        ),
        initialDocumentaryObligationAggregate: DocumentaryObligationAggregate(
          obligations: [obligation],
        ),
      );
      final occurrence = ExpectedExpenseOccurrence(
        occurrenceId: 'tari-balance-2026',
        relationshipId: relationship.relationshipId,
        status: ExpectedExpenseOccurrenceStatus.pending,
        knowledgeState: ExpectedExpenseKnowledgeState.knownUnpaid,
        knowledgeSource: ExpectedExpenseKnowledgeSource.userConfirmed,
        expectedDueDate: DateTime(2026, 11, 30),
        expectedDueDateSource: ExpectedExpenseDateSource.explicit,
        expectedDueDateCertainty: ExpectedExpenseDateCertainty.known,
        expectedAmount: 25,
        estimationMethod: ExpenseEstimationMethod.manualEstimate,
        confidence: ExpenseEstimateConfidence.high,
        provisional: false,
        expectedPaymentConfiguration: relationship.paymentConfiguration,
        paymentExecutionMode: relationship.paymentExecutionMode,
        expectedSubject: relationship.subject,
        participatesInCycleProjection: false,
      );
      final coordinator = DocumentaryObligationCoordinator(financeStore: finance);
      expect(
        await coordinator.materializeContingency(
          obligationId: obligation.obligationId,
          contingencyId: 'balance',
          occurrence: occurrence,
        ),
        DocumentaryObligationOutcome.applied,
      );
      expect(
        await coordinator.materializeContingency(
          obligationId: obligation.obligationId,
          contingencyId: 'balance',
          occurrence: occurrence,
        ),
        DocumentaryObligationOutcome.unchanged,
      );
      expect(finance.expectedExpenseAggregate.occurrences, hasLength(2));
      expect(
        finance.documentaryObligationAggregate.obligations.single.contingencies.single.status,
        DocumentaryContingencyStatus.materialized,
      );
      final projected = const ExpenseRelationshipProjectionAdapter().project(
        aggregate: finance.expectedExpenseAggregate,
        horizon: ExpenseProjectionHorizon(
          start: DateTime(2027, 1, 1),
          end: DateTime(2027, 12, 31),
        ),
      );
      expect(projected, hasLength(1));
      expect(projected.single.identity.value, 'tari-relationship#2');
    });

    test('SORIT metadata separates holder from payer and groups accessory', () {
      final operation = CompositeEconomicOperation(
        operationId: 'sorit-2026',
        context: OperationContext.utilityBill,
        mainEconomicFactId: 'sorit-main',
        mainAmount: 46.32,
        documentaryObligationId: 'sorit-obligation',
        documentHolder: FinanceSubject.chiara,
        accessories: const [(economicFactId: 'sorit-fee', amount: 1.50, accessoryCostType: AccessoryCostType.bankCommission)],
      );
      expect(operation.totalAmount, 47.82);
      expect(operation.main.operationMetadata.documentHolder, FinanceSubject.chiara);
      expect(operation.accessories.single.operationMetadata.operationId, operation.main.operationMetadata.operationId);
      expect(operation.accessories.single.operationMetadata.role, OperationRole.accessory);
    });

    testWidgets(
      'payment action forwards the selected unfulfilled installment',
      (tester) async {
        final obligation = _tari().selectOption('installments');
        final finance = FinanceStore(
          initialDocumentaryObligationAggregate:
              DocumentaryObligationAggregate(obligations: [obligation]),
        );
        DocumentaryObligation? launchedObligation;
        DocumentaryInstallment? launchedInstallment;

        await tester.pumpWidget(
          MaterialApp(
            home: DocumentaryObligationsPage(
              financeStore: finance,
              onRegisterPayment: (context, value, installment) async {
                launchedObligation = value;
                launchedInstallment = installment;
              },
            ),
          ),
        );
        await tester.tap(find.text('Acconto comunale 2026'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Registra pagamento').first);
        await tester.pumpAndSettle();

        expect(launchedObligation?.obligationId, 'tari-2026');
        expect(launchedInstallment?.installmentId, 'rate-1');
        expect(launchedInstallment?.amount, 58);
        expect(
          finance.documentaryObligationAggregate.obligations.single
              .operationalInstallments,
          hasLength(3),
        );
      },
    );

    testWidgets('recurrence starts with neutral subject and calendar fields', (
      tester,
    ) async {
      final finance = _uiFinanceStore();
      await _openDocumentaryEditor(tester, finance);
      await tester.tap(find.byKey(const ValueKey('documentary-repeats')));
      await tester.pumpAndSettle();

      expect(find.text('Scegli la persona'), findsOneWidget);
      expect(find.text('Scegli la frequenza'), findsOneWidget);
      expect(find.text('Scegli il mese'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('documentary-expected-year')),
            )
            .controller
            ?.text,
        isEmpty,
      );
    });

    testWidgets('new recurrence requires an explicit economic subject', (
      tester,
    ) async {
      final finance = _uiFinanceStore();
      await _openDocumentaryEditor(tester, finance);
      await _fillRecurringDocument(
        tester,
        subject: null,
        recurrenceLabel: 'Ogni mese',
      );

      await tester.tap(find.byKey(const ValueKey('documentary-save')));
      await tester.pumpAndSettle();

      expect(find.text('Scegli la persona'), findsWidgets);
      expect(finance.expectedExpenseAggregate.relationships, isEmpty);
      expect(find.text('Nuova bolletta o pagamento'), findsOneWidget);
    });

    for (final entry in const [
      (label: 'Ogni mese', type: FinanceRecurringType.monthly, months: null),
      (label: 'Ogni 2 mesi', type: FinanceRecurringType.custom, months: 2),
      (label: 'Ogni 3 mesi', type: FinanceRecurringType.custom, months: 3),
      (label: 'Ogni 4 mesi', type: FinanceRecurringType.custom, months: 4),
      (label: 'Ogni 6 mesi', type: FinanceRecurringType.custom, months: 6),
      (label: 'Ogni anno', type: FinanceRecurringType.yearly, months: null),
    ]) {
      testWidgets('${entry.label} maps to the existing recurrence domain', (
        tester,
      ) async {
        final finance = _uiFinanceStore();
        await _openDocumentaryEditor(tester, finance);
        await _fillRecurringDocument(
          tester,
          subject: FinanceSubject.chiara,
          recurrenceLabel: entry.label,
        );

        await tester.tap(find.byKey(const ValueKey('documentary-save')));
        await tester.pumpAndSettle();

        final periodicity =
            finance.expectedExpenseAggregate.relationships.single.periodicity;
        expect(periodicity.type, entry.type);
        expect(periodicity.customInterval, entry.months);
        expect(
          periodicity.customIntervalUnit,
          entry.months == null ? isNull : 'months',
        );
        expect(
          finance.expectedExpenseAggregate.relationships.single.subject,
          FinanceSubject.chiara,
        );
      });
    }

    testWidgets('custom positive month interval is persisted without coercion', (
      tester,
    ) async {
      final finance = _uiFinanceStore();
      await _openDocumentaryEditor(tester, finance);
      await _fillRecurringDocument(
        tester,
        subject: FinanceSubject.alice,
        recurrenceLabel: 'Personalizzata…',
        customMonths: '5',
      );

      await tester.tap(find.byKey(const ValueKey('documentary-save')));
      await tester.pumpAndSettle();

      final relationship =
          finance.expectedExpenseAggregate.relationships.single;
      expect(relationship.periodicity.type, FinanceRecurringType.custom);
      expect(relationship.periodicity.customInterval, 5);
      expect(relationship.periodicity.customIntervalUnit, 'months');
      expect(relationship.subject, FinanceSubject.alice);
    });

    for (final invalid in const ['0', '-2', 'non valido']) {
      testWidgets('custom interval rejects "$invalid"', (tester) async {
        final finance = _uiFinanceStore();
        await _openDocumentaryEditor(tester, finance);
        await _fillRecurringDocument(
          tester,
          subject: FinanceSubject.matteo,
          recurrenceLabel: 'Personalizzata…',
          customMonths: invalid,
        );

        await tester.tap(find.byKey(const ValueKey('documentary-save')));
        await tester.pumpAndSettle();

        expect(
          find.text('Inserisci un numero di mesi maggiore di zero'),
          findsWidgets,
        );
        expect(finance.expectedExpenseAggregate.relationships, isEmpty);
      });
    }

    testWidgets('existing custom recurrence is shown without losing its value', (
      tester,
    ) async {
      final relationship = ExpenseRelationship(
        relationshipId: 'existing-custom',
        service: 'Servizio esistente',
        provider: 'Fornitore',
        subject: FinanceSubject.chiara,
        status: ExpenseRelationshipStatus.active,
        periodicity: ExpenseRelationshipPeriodicity(
          type: FinanceRecurringType.custom,
          customInterval: 5,
          customIntervalUnit: 'months',
        ),
        paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
          method: FinancePaymentMethod.manual,
        ),
      );
      final finance = _uiFinanceStore(
        aggregate: ExpectedExpenseAggregate(relationships: [relationship]),
      );
      await _openDocumentaryEditor(tester, finance);

      await tester.tap(find.text('È collegata a una spesa già ricorrente? (opzionale)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Servizio esistente · Fornitore').last);
      await tester.pumpAndSettle();

      expect(find.text('Ogni 5 mesi'), findsOneWidget);
      final subject = tester.widget<DropdownButtonFormField<FinanceSubject>>(
        find.byType(DropdownButtonFormField<FinanceSubject>),
      );
      expect(subject.initialValue, FinanceSubject.chiara);
      expect(finance.expectedExpenseAggregate.relationships.single.toJson(), relationship.toJson());
    });
  });
}

FinanceStore _uiFinanceStore({ExpectedExpenseAggregate? aggregate}) {
  String? expectedStored;
  String? documentaryStored;
  return FinanceStore(
    initialExpectedExpenseAggregate: aggregate,
    expectedExpensePersistence: ExpectedExpensePersistence(
      load: (_) async => expectedStored,
      save: (_, value) async {
        expectedStored = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    ),
    documentaryObligationPersistence: DocumentaryObligationPersistence(
      load: (_) async => documentaryStored,
      save: (_, value) async {
        documentaryStored = value;
        return PersistenceWriteVerification(
          backendAccepted: true,
          readBack: value,
        );
      },
    ),
  );
}

Future<void> _openDocumentaryEditor(
  WidgetTester tester,
  FinanceStore finance,
) async {
  await tester.pumpWidget(
    MaterialApp(home: DocumentaryObligationsPage(financeStore: finance)),
  );
  await tester.tap(find.text('Aggiungi'));
  await tester.pumpAndSettle();
}

Future<void> _fillRecurringDocument(
  WidgetTester tester, {
  required FinanceSubject? subject,
  required String recurrenceLabel,
  String? customMonths,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('documentary-title')),
    'Documento ricorrente',
  );
  await tester.enterText(
    find.byKey(const ValueKey('documentary-amount')),
    '10',
  );
  await tester.tap(find.byKey(const ValueKey('documentary-repeats')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('documentary-provider')),
    'Fornitore',
  );
  if (subject != null) {
    await tester.tap(find.text('Di chi è normalmente la spesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(subject.name[0].toUpperCase() + subject.name.substring(1)).last);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const ValueKey('documentary-recurrence')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(recurrenceLabel).last);
  await tester.pumpAndSettle();
  if (customMonths != null) {
    await tester.enterText(
      find.byKey(const ValueKey('documentary-custom-months')),
      customMonths,
    );
  }
  await tester.tap(find.byKey(const ValueKey('documentary-expected-month')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Marzo').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('documentary-expected-year')),
    '2027',
  );
}

DocumentaryObligationAggregate _materializedDocumentaryAggregate({
  required double amount,
  bool selected = false,
  bool fulfilled = false,
}) {
  var obligation = DocumentaryObligation(
    obligationId: 'tari-2027',
    title: 'TARI 2027',
    totalAmount: amount,
    documentHolder: FinanceSubject.matteo,
    relationshipId: 'annual-tax',
    cycleSequence: 2,
    options: [
      DocumentaryFulfillmentOption(
        optionId: 'single',
        label: 'Rata unica',
        installments: [
          DocumentaryInstallment(
            installmentId: 'single-1',
            amount: amount,
            dueDate: DateTime(2027, 6, 30),
          ),
        ],
      ),
      DocumentaryFulfillmentOption(
        optionId: 'installments',
        label: 'Due rate',
        installments: [
          DocumentaryInstallment(
            installmentId: 'rate-1',
            amount: amount / 2,
            dueDate: DateTime(2027, 6, 30),
          ),
          DocumentaryInstallment(
            installmentId: 'rate-2',
            amount: amount - amount / 2,
            dueDate: DateTime(2027, 9, 30),
          ),
        ],
      ),
    ],
  );
  if (selected || fulfilled) {
    obligation = obligation.selectOption('single');
  }
  if (fulfilled) {
    obligation = obligation.replaceSelectedInstallment(
      obligation.operationalInstallments.single.fulfill('fact-tari-2027'),
    );
  }
  return DocumentaryObligationAggregate(
    obligations: [obligation],
    expectedDocuments: [
      ExpectedDocumentCycle(
        relationshipId: 'annual-tax',
        cycleSequence: 2,
        expectedPeriod: ExpectedDocumentPeriod(year: 2027, month: 3),
      ).materialize(obligation.obligationId),
    ],
  );
}

FutureExpenseProjection _documentarySeed({
  String identity = 'documentary_annual-tax_2',
  int sequence = 2,
}) {
  final relationship = ExpenseRelationship(
    relationshipId: 'annual-tax',
    service: 'TARI',
    provider: 'Comune',
    subject: FinanceSubject.matteo,
    status: ExpenseRelationshipStatus.active,
    periodicity: ExpenseRelationshipPeriodicity(
      type: FinanceRecurringType.yearly,
    ),
    paymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
    ),
  );
  final occurrence = ExpectedExpenseOccurrence(
    occurrenceId: identity,
    relationshipId: relationship.relationshipId,
    cycleSequence: sequence,
    expectedPeriod: ExpectedDocumentPeriod(
      year: 2026 + sequence - 1,
      month: 3,
    ),
    status: ExpectedExpenseOccurrenceStatus.pending,
    expectedAmount: 173,
    estimationMethod: ExpenseEstimationMethod.documentaryObligation,
    sourceDocumentaryObligationId: 'tari-2026',
    confidence: ExpenseEstimateConfidence.medium,
    provisional: true,
    expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
      method: FinancePaymentMethod.manual,
    ),
    paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
    expectedSubject: FinanceSubject.matteo,
  );
  final projections = const ExpectedExpenseReader().read(
    ExpectedExpenseAggregate(
      relationships: [relationship],
      occurrences: [occurrence],
    ),
  );
  return const FutureExpenseReader()
      .read(projections: projections, referenceTime: DateTime(2027, 1, 1))
      .single;
}

ProjectedExpenseCycle _documentaryProjectedCycle({required int sequence}) =>
    ProjectedExpenseCycle(
      identity: ExpenseCycleIdentity(
        relationshipId: 'annual-tax',
        cycleSequence: sequence,
      ),
      expectedPeriod: ExpectedDocumentPeriod(
        year: 2026 + sequence - 1,
        month: 3,
      ),
      sourceOccurrenceId: 'documentary_annual-tax_2',
      service: 'TARI',
      provider: 'Comune',
      expectedAmount: 173,
      expectedSubject: FinanceSubject.matteo,
      expectedPaymentConfiguration: ExpenseRelationshipPaymentConfiguration(
        method: FinancePaymentMethod.manual,
      ),
      paymentExecutionMode: PaymentExecutionMode.requiresUserAction,
      provisional: true,
    );

List<FutureOutflowPresentation> _futureOutflowItems(
  FutureOutflowOverview overview,
) => [
  ...overview.pastMonths,
  ...overview.currentMonth,
  ...overview.futureMonths.expand((month) => month.items),
  ...overview.unplaced,
];

String _futureOutflowSignature(FutureOutflowPresentation item) =>
    '${item.identity}|${item.authority.name}|${item.amount}|'
    '${item.placementStart?.toIso8601String()}|'
    '${item.placementPeriod?.year}-${item.placementPeriod?.month}|'
    '${item.datePresentation.name}|${item.requiresUserAction}';

DocumentaryObligation _sorit() => DocumentaryObligation(
  obligationId: 'sorit-2026', title: 'Avviso bonifica 2026', totalAmount: 46.32,
  documentHolder: FinanceSubject.chiara, documentReference: 'avviso documentale',
  options: [DocumentaryFulfillmentOption(optionId: 'single', label: 'Rata unica', installments: [DocumentaryInstallment(installmentId: 'single-1', amount: 46.32, dueDate: DateTime(2026, 3, 31))])],
);

DocumentaryObligation _tari() => DocumentaryObligation(
  obligationId: 'tari-2026', title: 'Acconto comunale 2026', totalAmount: 173,
  documentHolder: FinanceSubject.chiara,
  options: [
    DocumentaryFulfillmentOption(optionId: 'single', label: 'Rata unica', installments: [DocumentaryInstallment(installmentId: 'single-1', amount: 173, dueDate: DateTime(2026, 6, 30))]),
    DocumentaryFulfillmentOption(optionId: 'installments', label: 'Tre rate', installments: [
      DocumentaryInstallment(installmentId: 'rate-1', amount: 58, dueDate: DateTime(2026, 3, 31)),
      DocumentaryInstallment(installmentId: 'rate-2', amount: 58, dueDate: DateTime(2026, 6, 30)),
      DocumentaryInstallment(installmentId: 'rate-3', amount: 57, dueDate: DateTime(2026, 9, 30)),
    ]),
  ],
  contingencies: [DocumentaryContingency(contingencyId: 'balance', description: 'Conguaglio eventuale', anticipatedDueDate: DateTime(2026, 11, 30))],
);
