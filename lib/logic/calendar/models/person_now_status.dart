class PersonNowStatus {
  final bool busyNow;
  final String label;
  final String turnLabel;

  const PersonNowStatus({
    required this.busyNow,
    required this.label,
    this.turnLabel = '',
  });
}
