class EconomicFactIdGenerator {
  final String Function() _next;

  const EconomicFactIdGenerator.from(this._next);

  factory EconomicFactIdGenerator.timestamped({DateTime Function()? clock}) {
    final effectiveClock = clock ?? DateTime.now;
    var sequence = 0;
    return EconomicFactIdGenerator.from(
      () =>
          'economic_fact_${effectiveClock().microsecondsSinceEpoch}_${sequence++}',
    );
  }

  String next() => _next();
}
