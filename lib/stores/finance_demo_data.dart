import '../models/finance_balance.dart';
import '../models/finance_fund.dart';
import '../models/finance_recurring_item.dart';

final demoBalances = [
  FinanceBalance(
    personId: 'matteo',
    initialAmount: 2500,
    currentAmount: 2100,
    updatedAt: DateTime.now(),
  ),
  FinanceBalance(
    personId: 'chiara',
    initialAmount: 1800,
    currentAmount: 1650,
    updatedAt: DateTime.now(),
  ),
];

final demoFunds = [
  FinanceFund(
    id: 'emergency',
    name: 'Emergenze',
    description: 'Protezione imprevisti familiari',
    amount: 3000,
    protected: true,
  ),

  FinanceFund(
    id: 'car',
    name: 'Fondo Auto',
    description: 'Bollo, revisione, gomme e guasti',
    amount: 1200,
    protected: false,
  ),
];

final demoRecurringItems = [
  FinanceRecurringItem(
    id: 'salary_matteo',
    name: 'Stipendio Matteo',
    expectedAmount: 2100,
    nextDueDate: DateTime(DateTime.now().year, DateTime.now().month, 5),
    isIncome: true,
    recurringType: FinanceRecurringType.monthly,
    category: FinanceCategory.salary,
    requiresManualConfirmation: true,
    mandatory: true,
    pressureLevel: FinancePressureLevel.low,
    confirmed: false,
    variability: FinanceVariability.fixed,
    description: 'Entrata principale stipendio Matteo',
    paymentPriority: FinancePaymentPriority.high,
    protectionLevel: FinanceProtectionLevel.protected,
    stability: FinanceStability.stable,
    suspensionRisk: FinanceSuspensionRisk.low,
  ),
  FinanceRecurringItem(
    id: 'salary_chiara',
    name: 'Stipendio Chiara',
    expectedAmount: 1800,
    nextDueDate: DateTime(DateTime.now().year, DateTime.now().month, 5),
    isIncome: true,
    recurringType: FinanceRecurringType.monthly,
    category: FinanceCategory.salary,
    requiresManualConfirmation: true,
    mandatory: true,
    pressureLevel: FinancePressureLevel.low,
    confirmed: false,
    variability: FinanceVariability.fixed,
    description: 'Entrata principale stipendio Chiara',
    paymentPriority: FinancePaymentPriority.high,
    protectionLevel: FinanceProtectionLevel.protected,
    stability: FinanceStability.stable,
    suspensionRisk: FinanceSuspensionRisk.low,
  ),
  FinanceRecurringItem(
    id: 'netflix',
    name: 'Netflix',
    expectedAmount: 18,
    nextDueDate: DateTime.now(),
    isIncome: false,
    recurringType: FinanceRecurringType.monthly,
    category: FinanceCategory.entertainment,
    requiresManualConfirmation: false,
    mandatory: false,
    pressureLevel: FinancePressureLevel.low,
    confirmed: false,
    variability: FinanceVariability.fixed,
    description: 'Abbonamento streaming intrattenimento',
    paymentPriority: FinancePaymentPriority.low,
    protectionLevel: FinanceProtectionLevel.none,
    stability: FinanceStability.stable,
    suspensionRisk: FinanceSuspensionRisk.low,
  ),
];
