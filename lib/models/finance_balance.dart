class FinanceBalance {
  final String personId;
  final double initialAmount;
  final double currentAmount;
  final DateTime updatedAt;

  const FinanceBalance({
    required this.personId,
    required this.initialAmount,
    required this.currentAmount,
    required this.updatedAt,
  });
}
