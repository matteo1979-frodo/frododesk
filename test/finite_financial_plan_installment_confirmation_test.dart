import 'package:flutter_test/flutter_test.dart';

import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finite_financial_plan.dart';
import 'package:frododesk/models/finite_financial_plan_installment_confirmation.dart';

void main() {
  group('FiniteFinancialPlanInstallmentConfirmation', () {
    test('represents the real INPS installment and distinct bank fee', () {
      final confirmation = _confirmation();

      expect(confirmation.planId, 'finite_plan_inps');
      expect(confirmation.installmentNumber, 3);
      expect(confirmation.mainAmount, 386);
      expect(confirmation.bankFee, 1);
      expect(confirmation.totalAccountOutflow, 387);
      expect(confirmation.economicDate, DateTime(2026, 9, 16));
      expect(confirmation.hasBankFee, isTrue);
      expect(confirmation.feeEconomicFactId, isNotNull);
      expect(
        confirmation.mainEconomicFactId,
        isNot(confirmation.feeEconomicFactId),
      );
    });

    test('identities are stable for semantically identical confirmations', () {
      final first = _confirmation();
      final second = _confirmation();

      expect(first.installmentIdentity, second.installmentIdentity);
      expect(first.mainEconomicFactId, second.mainEconomicFactId);
      expect(first.feeEconomicFactId, second.feeEconomicFactId);
    });

    test('different installments and plans have distinct identities', () {
      final installmentThree = _confirmation();
      final installmentFour = _confirmation(installmentNumber: 4);
      final otherPlan = _confirmation(planId: 'finite_plan_other');

      expect(
        installmentThree.installmentIdentity,
        isNot(installmentFour.installmentIdentity),
      );
      expect(
        installmentThree.mainEconomicFactId,
        isNot(installmentFour.mainEconomicFactId),
      );
      expect(
        installmentThree.installmentIdentity,
        isNot(otherPlan.installmentIdentity),
      );
    });

    test('economic values and descriptions do not influence identity', () {
      final baseline = _confirmation();
      final changed = _confirmation(
        mainAmount: 400,
        description: 'Descrizione differente',
        economicDate: DateTime(2026, 9, 20),
      );

      expect(changed.installmentIdentity, baseline.installmentIdentity);
      expect(changed.mainEconomicFactId, baseline.mainEconomicFactId);
      expect(changed.feeEconomicFactId, baseline.feeEconomicFactId);
    });

    test('null and zero bank fees produce no fee identity', () {
      final absent = _confirmation(bankFee: null, bankFeeCategory: null);
      final zero = _confirmation(bankFee: 0, bankFeeCategory: null);

      expect(absent.hasBankFee, isFalse);
      expect(absent.feeEconomicFactId, isNull);
      expect(absent.totalAccountOutflow, 386);
      expect(zero.hasBankFee, isFalse);
      expect(zero.bankFee, isNull);
      expect(zero.feeEconomicFactId, isNull);
      expect(zero.totalAccountOutflow, 386);
    });

    test('positive bank fee requires a category and exposes an identity', () {
      final confirmation = _confirmation();

      expect(confirmation.hasBankFee, isTrue);
      expect(confirmation.bankFeeCategory, 'Commissioni bancarie');
      expect(confirmation.feeEconomicFactId, isNotNull);
      expect(() => _confirmation(bankFeeCategory: ''), throwsArgumentError);
    });

    test('rejects invalid structural and monetary input', () {
      expect(() => _confirmation(planId: ' '), throwsArgumentError);
      expect(() => _confirmation(installmentNumber: 0), throwsArgumentError);
      expect(() => _confirmation(debitBalanceId: ' '), throwsArgumentError);
      expect(() => _confirmation(mainAmount: 0), throwsArgumentError);
      expect(() => _confirmation(mainAmount: -1), throwsArgumentError);
      expect(() => _confirmation(bankFee: -1), throwsArgumentError);
      expect(() => _confirmation(description: ' '), throwsArgumentError);
      expect(() => _confirmation(mainCategory: ' '), throwsArgumentError);
      expect(
        () => _confirmation(economicDate: DateTime(2019, 12, 31)),
        throwsArgumentError,
      );
      expect(
        () => _confirmation(economicDate: DateTime(2101)),
        throwsArgumentError,
      );
    });

    test('identity is independent from wall-clock time', () {
      final first = _confirmation(economicDate: DateTime(2026, 9, 16));
      final second = _confirmation(economicDate: DateTime(2099, 12, 31));

      expect(first.installmentIdentity, second.installmentIdentity);
      expect(first.mainEconomicFactId, second.mainEconomicFactId);
      expect(first.feeEconomicFactId, second.feeEconomicFactId);
    });

    test('constructing a confirmation cannot advance its finite plan', () {
      final plan = FiniteFinancialPlan(
        id: 'finite_plan_inps',
        name: 'INPS',
        subject: FinanceSubject.matteo,
        debitBalanceId: 'balance_banca_imola',
        totalInstallments: 12,
        expectedInstallmentAmount: 386,
        firstInstallmentDate: DateTime(2026, 7, 15),
        completedInstallments: 2,
      );

      _confirmation();

      expect(plan.completedInstallments, 2);
      expect(plan.nextInstallmentNumber, 3);
    });
  });
}

FiniteFinancialPlanInstallmentConfirmation _confirmation({
  String planId = 'finite_plan_inps',
  int installmentNumber = 3,
  String debitBalanceId = 'balance_banca_imola',
  double mainAmount = 386,
  DateTime? economicDate,
  String description =
      'pagamento pratica legale TFR 30-23 05 45 93, Giovannini, rata terza',
  String mainCategory = 'Pratiche legali',
  double? bankFee = 1,
  String? bankFeeCategory = 'Commissioni bancarie',
}) => FiniteFinancialPlanInstallmentConfirmation(
  planId: planId,
  installmentNumber: installmentNumber,
  debitBalanceId: debitBalanceId,
  subject: FinanceSubject.matteo,
  mainAmount: mainAmount,
  economicDate: economicDate ?? DateTime(2026, 9, 16),
  description: description,
  mainCategory: mainCategory,
  bankFee: bankFee,
  bankFeeCategory: bankFeeCategory,
);
