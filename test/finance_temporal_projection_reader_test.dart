import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/logic/finance/finance_temporal_projection_reader.dart';
import 'package:frododesk/models/documentary_obligation.dart';
import 'package:frododesk/models/finance_forecast_presentation.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/future_outflow_presentation.dart';
import 'package:frododesk/models/income.dart';
import 'package:frododesk/models/income_forecast_presentation.dart';

void main() {
  test('pressure uses modern income and only economically placed outflows', () {
    final incomes = IncomeForecastOverview([
      IncomeForecastPresentation(
        identity: 'income:modern',
        relationshipId: 'relationship:modern',
        occurrenceId: null,
        cycleSequence: 1,
        label: 'Entrata moderna',
        amount: 1000,
        economicDate: DateTime(2027, 3, 27),
        subject: FinanceSubject.matteo,
        destinationBalanceId: 'bank',
        provenance: IncomeProvenance.recurringRelationship,
        knowledge: IncomeKnowledge.predicted,
        evidenceEconomicFactIds: const [],
        projected: true,
      ),
    ]);
    final expenses = FinanceForecastOverview([
      _expense('TIM', 4.99, DateTime(2027, 3, 10)),
      _expense('INPS', 386, DateTime(2027, 3, 16)),
      _documentOnly('TARI', 173),
      _documentOnly('SORIT', 46.32),
    ]);
    final march = const FinanceTemporalProjectionReader().readYear(
      year: 2027,
      incomes: incomes,
      expenses: expenses,
    )[2];
    expect(march.expectedIncome, 1000);
    expect(march.expectedExpenses, closeTo(390.99, 0.001));
    expect(march.expectedMargin, closeTo(609.01, 0.001));
    expect(march.pressureItemCount, 2);
  });

  test(
    'existing Respira Attenzione Soffre margin thresholds stay unchanged',
    () {
      final emptyExpenses = FinanceForecastOverview(const []);
      final projections = const FinanceTemporalProjectionReader().readYear(
        year: 2027,
        incomes: IncomeForecastOverview([_income(1, 300), _income(2, 200)]),
        expenses: emptyExpenses,
      );
      expect(projections[0].expectedMargin, 300);
      expect(projections[1].expectedMargin, 200);
      expect(projections[2].expectedMargin, 0);
    },
  );
}

IncomeForecastPresentation _income(int month, double amount) =>
    IncomeForecastPresentation(
      identity: 'income:$month',
      relationshipId: 'relationship:$month',
      occurrenceId: null,
      cycleSequence: 1,
      label: 'Entrata',
      amount: amount,
      economicDate: DateTime(2027, month, 1),
      subject: FinanceSubject.shared,
      destinationBalanceId: null,
      provenance: IncomeProvenance.recurringRelationship,
      knowledge: IncomeKnowledge.predicted,
      evidenceEconomicFactIds: const [],
      projected: true,
    );

FinanceForecastPresentation _expense(
  String label,
  double amount,
  DateTime date,
) => FinanceForecastPresentation(
  identity: 'expense:$label',
  label: label,
  amount: amount,
  subject: FinanceSubject.shared,
  temporalKnowledge: FinanceForecastTemporalKnowledge.economicDateKnown,
  economicStart: date,
  economicEnd: date,
  economicPeriod: null,
  documentaryPeriod: null,
  certainty: FinanceForecastCertainty.known,
  provisional: false,
  authority: FutureOutflowAuthority.expectedExpense,
  provenance: FutureOutflowDatePresentation.plannedEconomicImpact,
  relationshipId: null,
  cycleSequence: null,
  occurrenceId: null,
  obligationId: null,
  documentaryInstallmentId: null,
  planId: null,
  installmentNumber: null,
  economicFactId: null,
  requiresUserAction: false,
  requiresPlanning: false,
);

FinanceForecastPresentation _documentOnly(String label, double amount) =>
    FinanceForecastPresentation(
      identity: 'document:$label',
      label: label,
      amount: amount,
      subject: FinanceSubject.shared,
      temporalKnowledge: FinanceForecastTemporalKnowledge.documentPeriodOnly,
      economicStart: null,
      economicEnd: null,
      economicPeriod: null,
      documentaryPeriod: ExpectedDocumentPeriod(year: 2027, month: 3),
      certainty: FinanceForecastCertainty.known,
      provisional: false,
      authority: FutureOutflowAuthority.documentaryObligation,
      provenance: FutureOutflowDatePresentation.expectedDocumentPeriod,
      relationshipId: null,
      cycleSequence: null,
      occurrenceId: null,
      obligationId: label,
      documentaryInstallmentId: null,
      planId: null,
      installmentNumber: null,
      economicFactId: null,
      requiresUserAction: true,
      requiresPlanning: true,
    );
