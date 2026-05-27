enum FinancePaymentMethod { manual, bankTransfer, rid, card, cash }

enum FinanceSmartTemplateType {
  subscription,
  utilityBill,
  mortgage,
  rent,
  insurance,
  salary,
  school,
  car,
  health,
  generic,
}

class FinanceCategoryTemplate {
  final FinanceSmartTemplateType type;
  final String label;
  final FinancePaymentMethod defaultPaymentMethod;

  const FinanceCategoryTemplate({
    required this.type,
    required this.label,
    required this.defaultPaymentMethod,
  });
}

const financeSmartTemplates = [
  FinanceCategoryTemplate(
    type: FinanceSmartTemplateType.subscription,
    label: 'Abbonamento',
    defaultPaymentMethod: FinancePaymentMethod.rid,
  ),

  FinanceCategoryTemplate(
    type: FinanceSmartTemplateType.utilityBill,
    label: 'Bolletta',
    defaultPaymentMethod: FinancePaymentMethod.rid,
  ),

  FinanceCategoryTemplate(
    type: FinanceSmartTemplateType.salary,
    label: 'Stipendio',
    defaultPaymentMethod: FinancePaymentMethod.bankTransfer,
  ),

  FinanceCategoryTemplate(
    type: FinanceSmartTemplateType.insurance,
    label: 'Assicurazione',
    defaultPaymentMethod: FinancePaymentMethod.bankTransfer,
  ),

  FinanceCategoryTemplate(
    type: FinanceSmartTemplateType.car,
    label: 'Auto',
    defaultPaymentMethod: FinancePaymentMethod.card,
  ),

  FinanceCategoryTemplate(
    type: FinanceSmartTemplateType.school,
    label: 'Scuola',
    defaultPaymentMethod: FinancePaymentMethod.bankTransfer,
  ),

  FinanceCategoryTemplate(
    type: FinanceSmartTemplateType.health,
    label: 'Salute',
    defaultPaymentMethod: FinancePaymentMethod.card,
  ),

  FinanceCategoryTemplate(
    type: FinanceSmartTemplateType.generic,
    label: 'Generico',
    defaultPaymentMethod: FinancePaymentMethod.manual,
  ),
];
