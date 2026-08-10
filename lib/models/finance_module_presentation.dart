enum FinanceModuleState { stable, pressure }

class FinanceModulePresentation {
  final String subtitle;
  final String badgeText;
  final FinanceModuleState state;

  const FinanceModulePresentation({
    required this.subtitle,
    required this.badgeText,
    required this.state,
  });
}
