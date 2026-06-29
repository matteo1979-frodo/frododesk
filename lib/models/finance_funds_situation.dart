import 'finance_fund.dart';

class FinanceFundsSituation {
  final double totalFunds;
  final double protectedAmount;
  final double availableAmount;

  final int activeFunds;
  final int emptyFunds;

  final int protectedFunds;
  final int unprotectedFunds;

  final List<FinanceFund> funds;

  const FinanceFundsSituation({
    required this.totalFunds,
    required this.protectedAmount,
    required this.availableAmount,
    required this.activeFunds,
    required this.emptyFunds,
    required this.protectedFunds,
    required this.unprotectedFunds,
    required this.funds,
  });
}
