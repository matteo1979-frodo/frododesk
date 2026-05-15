class FinanceFund {
  final String id;
  final String name;
  final String description;
  final double amount;
  final bool protected;

  const FinanceFund({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.protected,
  });
}
