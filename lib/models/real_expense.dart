import 'economic_operation_metadata.dart';
import 'finance_recurring_item.dart';
import 'balance_posting_mode.dart';
import 'composite_correction_metadata.dart';

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

  final bool isIncome;
  final FinanceSubject subject;

  /// Id del portafoglio collegato al prelievo contanti.
  /// Esempio: wallet_matteo, wallet_chiara.
  final String? cashWalletId;
  final String? economicFactId;
  final EconomicOperationMetadata? operationMetadata;
  final BalancePostingMode balancePostingMode;
  final CompositeCorrectionMetadata? compositeCorrectionMetadata;

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
    this.isIncome = false,
    this.subject = FinanceSubject.shared,
    this.cashWalletId,
    this.economicFactId,
    this.operationMetadata,
    this.balancePostingMode = BalancePostingMode.affectsCurrentBalance,
    this.compositeCorrectionMetadata,
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
      'isIncome': isIncome,
      'subject': subject.name,
      'economicFactId': economicFactId,
      'operationMetadata': operationMetadata?.toJson(),
      'balancePostingMode': balancePostingMode.name,
      if (compositeCorrectionMetadata != null)
        'compositeCorrectionMetadata': compositeCorrectionMetadata!.toJson(),
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
      isIncome: json['isIncome'] as bool? ?? false,
      subject: json['subject'] == null
          ? FinanceSubject.shared
          : FinanceSubject.values.firstWhere((e) => e.name == json['subject']),
      economicFactId: json['economicFactId'] as String?,
      operationMetadata: json['operationMetadata'] == null
          ? null
          : EconomicOperationMetadata.fromJson(
              Map<String, dynamic>.from(json['operationMetadata'] as Map),
            ),
      balancePostingMode: balancePostingModeFromJson(
        json['balancePostingMode'],
      ),
      compositeCorrectionMetadata: json['compositeCorrectionMetadata'] == null
          ? null
          : CompositeCorrectionMetadata.fromJson(
              Map<String, dynamic>.from(
                json['compositeCorrectionMetadata'] as Map,
              ),
            ),
    );
  }
}
