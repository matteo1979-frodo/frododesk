import 'package:flutter_test/flutter_test.dart';
import 'package:frododesk/models/finance_recurring_item.dart';
import 'package:frododesk/models/finite_financial_plan.dart';

void main() {
  group('FiniteFinancialPlan', () {
    test('represents and bounds a twelve-installment plan', () {
      final plan = _plan();

      expect(plan.nextInstallmentNumber, 1);
      expect(plan.remainingInstallments, 12);
      expect(plan.remainingSchedule, hasLength(12));
      expect(plan.lastInstallment.number, 12);
      expect(plan.lastInstallment.dueDate, DateTime(2027, 12, 15));
      expect(plan.installment(13), isNull);
      expect(plan.status, FiniteFinancialPlanStatus.active);
    });

    test('represents an already-started plan at installment three', () {
      final plan = _plan(completedInstallments: 2);

      expect(plan.nextInstallmentNumber, 3);
      expect(plan.nextInstallment!.number, 3);
      expect(plan.nextInstallment!.dueDate, DateTime(2027, 3, 15));
      expect(plan.remainingInstallments, 10);
      expect(plan.installmentsAfterNext, 9);
      expect(plan.remainingSchedule.first.number, 3);
      expect(plan.remainingSchedule.last.number, 12);
    });

    test('progression is domain-only and creates no economic records', () {
      final plan = _plan(completedInstallments: 2);
      final json = plan.toJson();

      expect(json, isNot(contains('transactions')));
      expect(json, isNot(contains('realExpenses')));
      expect(json, isNot(contains('economicEvents')));
      expect(json, isNot(contains('economicFactId')));
    });

    test('a completed plan has no next or remaining installment', () {
      final plan = _plan(completedInstallments: 12);

      expect(plan.isCompleted, isTrue);
      expect(plan.status, FiniteFinancialPlanStatus.completed);
      expect(plan.nextInstallmentNumber, isNull);
      expect(plan.nextInstallment, isNull);
      expect(plan.remainingInstallments, 0);
      expect(plan.remainingSchedule, isEmpty);
    });

    test('monthly schedule keeps an ordinary contractual day', () {
      final plan = _plan(
        firstInstallmentDate: DateTime(2027, 1, 15),
        scheduledDayOfMonth: 15,
      );

      expect(plan.installment(2)!.dueDate, DateTime(2027, 2, 15));
      expect(plan.installment(3)!.dueDate, DateTime(2027, 3, 15));
    });

    test('day 31 clamps to month end and returns to 31 when available', () {
      final plan = _plan(
        firstInstallmentDate: DateTime(2027, 1, 31),
        scheduledDayOfMonth: 31,
      );

      expect(plan.installment(2)!.dueDate, DateTime(2027, 2, 28));
      expect(plan.installment(3)!.dueDate, DateTime(2027, 3, 31));
      expect(plan.installment(4)!.dueDate, DateTime(2027, 4, 30));
    });

    test('day 31 uses February 29 in a leap year', () {
      final plan = _plan(
        firstInstallmentDate: DateTime(2028, 1, 31),
        scheduledDayOfMonth: 31,
      );

      expect(plan.installment(2)!.dueDate, DateTime(2028, 2, 29));
      expect(plan.installment(3)!.dueDate, DateTime(2028, 3, 31));
    });

    test('day 29 clamps in non-leap February and returns to 29', () {
      final plan = _plan(
        firstInstallmentDate: DateTime(2027, 1, 29),
        scheduledDayOfMonth: 29,
      );

      expect(plan.installment(2)!.dueDate, DateTime(2027, 2, 28));
      expect(plan.installment(3)!.dueDate, DateTime(2027, 3, 29));
    });

    test('day 30 clamps in non-leap February and returns to 30', () {
      final plan = _plan(
        firstInstallmentDate: DateTime(2027, 1, 30),
        scheduledDayOfMonth: 30,
      );

      expect(plan.installment(2)!.dueDate, DateTime(2027, 2, 28));
      expect(plan.installment(3)!.dueDate, DateTime(2027, 3, 30));
    });

    test('December to January preserves the contractual day', () {
      final plan = _plan(
        firstInstallmentDate: DateTime(2027, 12, 15),
        scheduledDayOfMonth: 15,
      );

      expect(plan.installment(1)!.dueDate, DateTime(2027, 12, 15));
      expect(plan.installment(2)!.dueDate, DateTime(2028, 1, 15));
    });

    test('multi-year schedule preserves installment numbers and dates', () {
      final plan = _plan(
        totalInstallments: 26,
        firstInstallmentDate: DateTime(2027, 11, 30),
        scheduledDayOfMonth: 30,
      );

      expect(plan.installment(3)!.number, 3);
      expect(plan.installment(3)!.dueDate, DateTime(2028, 1, 30));
      expect(plan.installment(15)!.number, 15);
      expect(plan.installment(15)!.dueDate, DateTime(2029, 1, 30));
      expect(plan.installment(26)!.number, 26);
      expect(plan.installment(26)!.dueDate, DateTime(2029, 12, 30));
    });

    test('a February start can retain a contractual day 31', () {
      final plan = _plan(
        firstInstallmentDate: DateTime(2027, 2, 28),
        scheduledDayOfMonth: 31,
      );

      expect(plan.installment(1)!.dueDate, DateTime(2027, 2, 28));
      expect(plan.installment(2)!.dueDate, DateTime(2027, 3, 31));
    });

    test('round-trips every persisted field', () {
      final plan = _plan(completedInstallments: 2);
      final restored = FiniteFinancialPlan.fromJson(plan.toJson());

      expect(restored.toJson(), plan.toJson());
      expect(restored.nextInstallmentNumber, 3);
      expect(restored.remainingInstallments, 10);
      expect(restored.lastInstallment.dueDate, plan.lastInstallment.dueDate);
    });

    test('reads backward-compatible optional defaults', () {
      final json = _plan().toJson()
        ..remove('description')
        ..remove('subject')
        ..remove('frequency')
        ..remove('scheduledDayOfMonth')
        ..remove('completedInstallments');

      final restored = FiniteFinancialPlan.fromJson(json);

      expect(restored.description, isEmpty);
      expect(restored.subject, FinanceSubject.shared);
      expect(restored.frequency, FiniteFinancialPlanFrequency.monthly);
      expect(restored.scheduledDayOfMonth, 15);
      expect(restored.completedInstallments, 0);
    });

    test('rejects invalid plan inputs', () {
      expect(() => _plan(totalInstallments: 0), throwsArgumentError);
      expect(
        () => _plan(totalInstallments: 12, completedInstallments: 13),
        throwsArgumentError,
      );
      expect(() => _plan(expectedInstallmentAmount: 0), throwsArgumentError);
      expect(
        () => _plan(expectedInstallmentAmount: double.nan),
        throwsArgumentError,
      );
      expect(
        () => _plan(
          firstInstallmentDate: DateTime(2027, 2, 27),
          scheduledDayOfMonth: 31,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an unsupported serialized frequency', () {
      final json = _plan().toJson()..['frequency'] = 'weekly';

      expect(() => FiniteFinancialPlan.fromJson(json), throwsArgumentError);
    });
  });
}

FiniteFinancialPlan _plan({
  int totalInstallments = 12,
  int completedInstallments = 0,
  double expectedInstallmentAmount = 386,
  DateTime? firstInstallmentDate,
  int scheduledDayOfMonth = 15,
}) => FiniteFinancialPlan(
  id: 'plan_inps',
  name: 'Rateizzazione INPS',
  description: 'Piano finito',
  subject: FinanceSubject.matteo,
  creditor: 'INPS',
  debitBalanceId: 'balance_banca',
  totalInstallments: totalInstallments,
  expectedInstallmentAmount: expectedInstallmentAmount,
  firstInstallmentDate: firstInstallmentDate ?? DateTime(2027, 1, 15),
  scheduledDayOfMonth: scheduledDayOfMonth,
  completedInstallments: completedInstallments,
);
