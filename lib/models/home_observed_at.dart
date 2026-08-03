class HomeObservedAt {
  final DateTime observedAt;

  const HomeObservedAt({required this.observedAt});

  DateTime get day =>
      DateTime(observedAt.year, observedAt.month, observedAt.day);

  int get minuteOfDay => observedAt.hour * 60 + observedAt.minute;

  int get year => observedAt.year;
}
