import 'finance_recurring_item.dart';

enum FiniteFinancialPlanFrequency { monthly }

enum FiniteFinancialPlanStatus { active, completed }

class FiniteFinancialPlanInstallment {
  final int number;
  final DateTime dueDate;
  final double expectedAmount;

  const FiniteFinancialPlanInstallment({
    required this.number,
    required this.dueDate,
    required this.expectedAmount,
  });
}

/// Pure domain contract for a finite future financial commitment.
///
/// This model describes a schedule only. It does not create transactions,
/// expenses, ledger events, or balance mutations.
class FiniteFinancialPlan {
  final String id;
  final String name;
  final String description;
  final FinanceSubject subject;
  final String? creditor;
  final String? debitBalanceId;
  final int totalInstallments;
  final FiniteFinancialPlanFrequency frequency;
  final double expectedInstallmentAmount;
  final Map<int, double> installmentAmountOverrides;
  final DateTime firstInstallmentDate;
  final int scheduledDayOfMonth;
  final int completedInstallments;

  FiniteFinancialPlan._({
    required this.id,
    required this.name,
    required this.description,
    required this.subject,
    required this.creditor,
    required this.debitBalanceId,
    required this.totalInstallments,
    required this.frequency,
    required this.expectedInstallmentAmount,
    required this.installmentAmountOverrides,
    required this.firstInstallmentDate,
    required this.scheduledDayOfMonth,
    required this.completedInstallments,
  });

  factory FiniteFinancialPlan({
    required String id,
    required String name,
    String description = '',
    FinanceSubject subject = FinanceSubject.shared,
    String? creditor,
    String? debitBalanceId,
    required int totalInstallments,
    FiniteFinancialPlanFrequency frequency =
        FiniteFinancialPlanFrequency.monthly,
    required double expectedInstallmentAmount,
    Map<int, double> installmentAmountOverrides = const {},
    required DateTime firstInstallmentDate,
    int? scheduledDayOfMonth,
    int completedInstallments = 0,
  }) {
    final normalizedFirstDate = DateTime(
      firstInstallmentDate.year,
      firstInstallmentDate.month,
      firstInstallmentDate.day,
    );
    final contractualDay = scheduledDayOfMonth ?? normalizedFirstDate.day;

    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty');
    }
    if (totalInstallments <= 0) {
      throw ArgumentError.value(
        totalInstallments,
        'totalInstallments',
        'Must be greater than zero',
      );
    }
    if (!expectedInstallmentAmount.isFinite || expectedInstallmentAmount <= 0) {
      throw ArgumentError.value(
        expectedInstallmentAmount,
        'expectedInstallmentAmount',
        'Must be finite and greater than zero',
      );
    }
    for (final entry in installmentAmountOverrides.entries) {
      if (entry.key < 1 || entry.key > totalInstallments) {
        throw ArgumentError.value(
          entry.key,
          'installmentAmountOverrides',
          'Installment number must be between 1 and totalInstallments',
        );
      }
      if (!entry.value.isFinite || entry.value <= 0) {
        throw ArgumentError.value(
          entry.value,
          'installmentAmountOverrides',
          'Override amount must be finite and greater than zero',
        );
      }
    }
    if (contractualDay < 1 || contractualDay > 31) {
      throw ArgumentError.value(
        contractualDay,
        'scheduledDayOfMonth',
        'Must be between 1 and 31',
      );
    }
    if (completedInstallments < 0 ||
        completedInstallments > totalInstallments) {
      throw ArgumentError.value(
        completedInstallments,
        'completedInstallments',
        'Must be between zero and totalInstallments',
      );
    }

    final expectedFirstDate = _monthlyDate(
      normalizedFirstDate.year,
      normalizedFirstDate.month,
      contractualDay,
    );
    if (normalizedFirstDate != expectedFirstDate) {
      throw ArgumentError.value(
        firstInstallmentDate,
        'firstInstallmentDate',
        'Must match the contractual day or the last day of its month',
      );
    }

    return FiniteFinancialPlan._(
      id: id,
      name: name,
      description: description,
      subject: subject,
      creditor: creditor,
      debitBalanceId: debitBalanceId,
      totalInstallments: totalInstallments,
      frequency: frequency,
      expectedInstallmentAmount: expectedInstallmentAmount,
      installmentAmountOverrides: Map.unmodifiable(
        installmentAmountOverrides,
      ),
      firstInstallmentDate: normalizedFirstDate,
      scheduledDayOfMonth: contractualDay,
      completedInstallments: completedInstallments,
    );
  }

  int get remainingInstallments => totalInstallments - completedInstallments;

  int get installmentsAfterNext =>
      remainingInstallments == 0 ? 0 : remainingInstallments - 1;

  bool get isCompleted => completedInstallments == totalInstallments;

  FiniteFinancialPlanStatus get status => isCompleted
      ? FiniteFinancialPlanStatus.completed
      : FiniteFinancialPlanStatus.active;

  int? get nextInstallmentNumber =>
      isCompleted ? null : completedInstallments + 1;

  FiniteFinancialPlanInstallment? get nextInstallment {
    final number = nextInstallmentNumber;
    return number == null ? null : installment(number);
  }

  FiniteFinancialPlanInstallment get lastInstallment =>
      installment(totalInstallments)!;

  List<FiniteFinancialPlanInstallment> get remainingSchedule => [
    for (
      var number = completedInstallments + 1;
      number <= totalInstallments;
      number++
    )
      installment(number)!,
  ];

  FiniteFinancialPlanInstallment? installment(int number) {
    if (number < 1 || number > totalInstallments) return null;

    final monthIndex = firstInstallmentDate.month + number - 1;
    return FiniteFinancialPlanInstallment(
      number: number,
      dueDate: _monthlyDate(
        firstInstallmentDate.year,
        monthIndex,
        scheduledDayOfMonth,
      ),
      expectedAmount: amountForInstallment(number),
    );
  }

  double amountForInstallment(int installmentNumber) {
    if (installmentNumber < 1 || installmentNumber > totalInstallments) {
      throw ArgumentError.value(
        installmentNumber,
        'installmentNumber',
        'Must be between 1 and totalInstallments',
      );
    }
    return installmentAmountOverrides[installmentNumber] ??
        expectedInstallmentAmount;
  }

  double get expectedTotalAmount {
    var total = 0.0;
    for (var number = 1; number <= totalInstallments; number++) {
      total += amountForInstallment(number);
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'subject': subject.name,
    'creditor': creditor,
    'debitBalanceId': debitBalanceId,
    'totalInstallments': totalInstallments,
    'frequency': frequency.name,
    'expectedInstallmentAmount': expectedInstallmentAmount,
    'installmentAmountOverrides': [
      for (final entry in installmentAmountOverrides.entries)
        {'installmentNumber': entry.key, 'amount': entry.value},
    ],
    'firstInstallmentDate': firstInstallmentDate.toIso8601String(),
    'scheduledDayOfMonth': scheduledDayOfMonth,
    'completedInstallments': completedInstallments,
  };

  factory FiniteFinancialPlan.fromJson(Map<String, dynamic> json) {
    final firstInstallmentDate = DateTime.parse(
      json['firstInstallmentDate'] as String,
    );
    final frequencyName = json['frequency'] as String? ?? 'monthly';
    final frequency = FiniteFinancialPlanFrequency.values
        .where((value) => value.name == frequencyName)
        .firstOrNull;
    if (frequency == null) {
      throw ArgumentError.value(
        frequencyName,
        'frequency',
        'Unsupported finite plan frequency',
      );
    }

    return FiniteFinancialPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      subject: FinanceSubject.values.firstWhere(
        (value) => value.name == (json['subject'] as String? ?? 'shared'),
      ),
      creditor: json['creditor'] as String?,
      debitBalanceId: json['debitBalanceId'] as String?,
      totalInstallments: json['totalInstallments'] as int,
      frequency: frequency,
      expectedInstallmentAmount: (json['expectedInstallmentAmount'] as num)
          .toDouble(),
      installmentAmountOverrides: json.containsKey(
        'installmentAmountOverrides',
      )
          ? _decodeInstallmentAmountOverrides(
              json['installmentAmountOverrides'],
            )
          : const {},
      firstInstallmentDate: firstInstallmentDate,
      scheduledDayOfMonth:
          json['scheduledDayOfMonth'] as int? ?? firstInstallmentDate.day,
      completedInstallments: json['completedInstallments'] as int? ?? 0,
    );
  }

  static Map<int, double> _decodeInstallmentAmountOverrides(dynamic raw) {
    if (raw is! List) {
      throw ArgumentError.value(
        raw,
        'installmentAmountOverrides',
        'Must be a list',
      );
    }

    final result = <int, double>{};
    for (var index = 0; index < raw.length; index++) {
      final item = raw[index];
      if (item is! Map) {
        throw ArgumentError.value(
          item,
          'installmentAmountOverrides[$index]',
          'Must be an object',
        );
      }
      final entry = Map<String, dynamic>.from(item);
      final installmentNumber = entry['installmentNumber'];
      final amount = entry['amount'];
      if (installmentNumber is! int) {
        throw ArgumentError.value(
          installmentNumber,
          'installmentAmountOverrides[$index].installmentNumber',
          'Must be an integer',
        );
      }
      if (amount is! num) {
        throw ArgumentError.value(
          amount,
          'installmentAmountOverrides[$index].amount',
          'Must be a number',
        );
      }
      if (result.containsKey(installmentNumber)) {
        throw ArgumentError.value(
          installmentNumber,
          'installmentAmountOverrides[$index].installmentNumber',
          'Duplicate installment number',
        );
      }
      result[installmentNumber] = amount.toDouble();
    }
    return result;
  }

  static DateTime _monthlyDate(int year, int month, int preferredDay) {
    final monthStart = DateTime(year, month, 1);
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final day = preferredDay <= lastDay ? preferredDay : lastDay;
    return DateTime(monthStart.year, monthStart.month, day);
  }
}
