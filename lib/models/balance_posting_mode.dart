/// Declares whether recording an economic fact must also change the current
/// balance.
enum BalancePostingMode {
  affectsCurrentBalance,
  alreadyIncludedInCurrentBalance,
}

BalancePostingMode balancePostingModeFromJson(Object? value) {
  if (value == null) return BalancePostingMode.affectsCurrentBalance;
  if (value is! String) {
    throw const FormatException('balancePostingMode must be a string');
  }
  for (final mode in BalancePostingMode.values) {
    if (mode.name == value) return mode;
  }
  throw FormatException('Unknown balancePostingMode: $value');
}
