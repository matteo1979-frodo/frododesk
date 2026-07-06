class PlannerReasonData {
  final String itemId;
  final String itemName;
  final String? itemDescription;

  final double? amount;
  final DateTime? dueDate;

  final String? ownerId;
  final String? ownerLabel;

  final String? balanceId;
  final String? balanceName;
  final String? balanceOwnerId;
  final String? balanceOwnerLabel;

  final double? balanceBefore;
  final double? balanceAfter;
  final double? balanceThreshold;

  final String? paymentMethodName;

  const PlannerReasonData({
    required this.itemId,
    required this.itemName,
    this.itemDescription,
    this.amount,
    this.dueDate,
    this.ownerId,
    this.ownerLabel,
    this.balanceId,
    this.balanceName,
    this.balanceOwnerId,
    this.balanceOwnerLabel,
    this.balanceBefore,
    this.balanceAfter,
    this.balanceThreshold,
    this.paymentMethodName,
  });
}
