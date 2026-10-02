import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/household_resilience_reader.dart';
import 'package:frododesk/models/finance_balance.dart';
import 'package:frododesk/models/finance_forecast_presentation.dart';
import 'package:frododesk/models/finance_fund.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finance_transaction.dart';
import 'package:frododesk/models/financial_resilience.dart';
import 'package:frododesk/models/future_outflow_presentation.dart';
import 'package:frododesk/models/income_forecast_presentation.dart';
import 'package:frododesk/stores/cash_wallet_store.dart';
import 'package:frododesk/stores/finance_store.dart';

void main() {
  test(
    'adapter combines balances, funds, modern forecast and actual facts',
    () {
      final store = FinanceStore(
        initialBalances: [_balance()],
        initialFunds: const [
          FinanceFund(
            id: 'fund',
            name: 'Fondo',
            description: '',
            amount: 200,
            protected: true,
            category: FinanceFundCategory.generic,
          ),
        ],
        initialTransactions: [
          FinanceTransaction(
            id: 'actual',
            balanceId: 'main',
            amount: 45,
            date: DateTime(2026, 4, 7),
            isIncome: false,
            subject: FinanceSubject.matteo,
            description: 'Fatto reale',
            type: FinanceTransactionType.expense,
            origin: FinanceTransactionOrigin.manual,
            economicFactId: 'fact:actual',
          ),
        ],
      );
      final assessments = const HouseholdResilienceReader().readYear(
        year: 2026,
        referenceTime: DateTime(2026, 10, 3),
        financeStore: store,
        cashWalletStore: CashWalletStore(),
        incomes: IncomeForecastOverview(const []),
        expenses: FinanceForecastOverview([_outflow()]),
      );

      expect(assessments[3].phase, ResiliencePhase.realized);
      expect(assessments[3].outflow, 45);
      expect(assessments[9].openingLiquidity, 10200);
      expect(assessments[9].outflow, 390.99);
      expect(assessments[9].status, ResilienceStatus.breathes);
      expect(assessments[9].coverage.partial, isTrue);
    },
  );
}

FinanceBalance _balance() => FinanceBalance(
  personId: 'matteo',
  balanceId: 'main',
  name: 'Conto',
  initialAmount: 10000,
  currentAmount: 10000,
  updatedAt: DateTime(2026, 10, 3),
  balanceType: FinanceBalanceType.bankAccount,
  operational: true,
  active: true,
  reservedAmount: 0,
  warningThreshold: 0,
  persistentStressDays: 0,
  recoveryDays: 0,
);

FinanceForecastPresentation _outflow() => FinanceForecastPresentation(
  identity: 'outflow:october',
  label: 'Uscite moderne',
  amount: 390.99,
  subject: FinanceSubject.matteo,
  balanceId: 'main',
  temporalKnowledge: FinanceForecastTemporalKnowledge.economicDateKnown,
  economicStart: DateTime(2026, 10, 12),
  economicEnd: DateTime(2026, 10, 12),
  economicPeriod: null,
  documentaryPeriod: null,
  certainty: FinanceForecastCertainty.known,
  provisional: false,
  authority: FutureOutflowAuthority.expectedExpense,
  provenance: FutureOutflowDatePresentation.plannedEconomicImpact,
  relationshipId: 'expense:modern',
  cycleSequence: 1,
  occurrenceId: 'occurrence:modern',
  obligationId: null,
  documentaryInstallmentId: null,
  planId: null,
  installmentNumber: null,
  economicFactId: null,
  requiresUserAction: false,
  requiresPlanning: false,
);
