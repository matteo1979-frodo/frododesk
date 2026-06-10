class RealExpense {
  final String id;
  final String balanceId;
  final String balanceName;
  final double amount;
  final String description;

  /// Categoria scelta dall'utente
  /// (Scuola, Sandra, Ferramenta, Bar...)
  final String category;

  final DateTime date;
  final bool nonTrackedCash;

  /// True quando questo movimento rappresenta un prelievo contanti
  /// dal conto verso un portafoglio.
  final bool isCashWithdrawal;

  /// Id del portafoglio collegato al prelievo contanti.
  /// Esempio: wallet_matteo, wallet_chiara.
  final String? cashWalletId;

  const RealExpense({
    required this.id,
    required this.balanceId,
    required this.balanceName,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.nonTrackedCash = false,
    this.isCashWithdrawal = false,
    this.cashWalletId,
  });

  String get displayAmount => "€${amount.toStringAsFixed(2)}";

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'balanceId': balanceId,
      'balanceName': balanceName,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'nonTrackedCash': nonTrackedCash,
      'isCashWithdrawal': isCashWithdrawal,
      'cashWalletId': cashWalletId,
    };
  }

  factory RealExpense.fromJson(Map<String, dynamic> json) {
    return RealExpense(
      id: json['id'] as String? ?? '',
      balanceId: json['balanceId'] as String? ?? '',
      balanceName: json['balanceName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Senza categoria',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      nonTrackedCash: json['nonTrackedCash'] as bool? ?? false,
      isCashWithdrawal: json['isCashWithdrawal'] as bool? ?? false,
      cashWalletId: json['cashWalletId'] as String?,
    );
  }
}
