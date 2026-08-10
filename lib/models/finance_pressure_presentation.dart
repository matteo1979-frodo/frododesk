enum FinancePressureState { low, medium, high, critical }

class FinancePressurePresentation {
  final String title;
  final String description;
  final FinancePressureState state;
  final int color;

  const FinancePressurePresentation({
    required this.title,
    required this.description,
    required this.state,
    required this.color,
  });
}
