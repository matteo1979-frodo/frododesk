import '../../models/finance_account_linked_item.dart';
import '../../models/finance_asset_movement.dart';
import '../../models/finance_balance.dart';
import '../../models/finance_fund.dart';
import '../../models/finance_transaction.dart';
import '../../models/fund_transaction.dart';

class FinancePortfolioV3 {
  final List<FinanceBalance> balances;
  final List<FinanceFund> funds;
  final List<FinanceAssetMovement> assetMovements;
  final List<FinanceTransaction> transactions;
  final List<FundTransaction> fundTransactions;
  final List<FinanceAccountLinkedItem> linkedItems;

  FinancePortfolioV3({
    required Iterable<FinanceBalance> balances,
    required Iterable<FinanceFund> funds,
    required Iterable<FinanceAssetMovement> assetMovements,
    required Iterable<FinanceTransaction> transactions,
    required Iterable<FundTransaction> fundTransactions,
    required Iterable<FinanceAccountLinkedItem> linkedItems,
  }) : balances = List.unmodifiable(balances),
       funds = List.unmodifiable(funds),
       assetMovements = List.unmodifiable(assetMovements),
       transactions = List.unmodifiable(transactions),
       fundTransactions = List.unmodifiable(fundTransactions),
       linkedItems = List.unmodifiable(linkedItems);
}

class FinancePortfolioV3ParseResult {
  final FinancePortfolioV3? value;
  final List<String> errors;

  FinancePortfolioV3ParseResult({
    required this.value,
    required Iterable<String> errors,
  }) : errors = List.unmodifiable(errors);

  bool get isSuccess => value != null && errors.isEmpty;
}

class FinancePortfolioV3ValidationResult {
  final List<String> errors;

  FinancePortfolioV3ValidationResult(Iterable<String> errors)
    : errors = List.unmodifiable(errors);

  bool get isValid => errors.isEmpty;
}

class FinancePortfolioV3Contract {
  static const int version = 3;

  static Map<String, dynamic> build(FinancePortfolioV3 portfolio) {
    return {
      'version': version,
      'balances': portfolio.balances.map((item) => item.toJson()).toList(),
      'funds': portfolio.funds.map((item) => item.toJson()).toList(),
      'assetMovements': portfolio.assetMovements
          .map((item) => item.toJson())
          .toList(),
      'transactions': portfolio.transactions
          .map((item) => item.toJson())
          .toList(),
      'fundTransactions': portfolio.fundTransactions
          .map((item) => item.toJson())
          .toList(),
      'linkedItems': portfolio.linkedItems
          .map((item) => item.toJson())
          .toList(),
    };
  }

  static FinancePortfolioV3ParseResult parse(Map<String, dynamic> json) {
    final errors = <String>[];
    if (!json.containsKey('version')) {
      errors.add('Missing required field: version');
    } else if (json['version'] != version) {
      errors.add('Unsupported portfolio version: ${json['version']}');
    }

    final balances = _parseList(
      json: json,
      field: 'balances',
      decode: FinanceBalance.fromJson,
      errors: errors,
    );
    final funds = _parseList(
      json: json,
      field: 'funds',
      decode: FinanceFund.fromJson,
      errors: errors,
    );
    final assetMovements = _parseList(
      json: json,
      field: 'assetMovements',
      decode: FinanceAssetMovement.fromJson,
      errors: errors,
    );
    final transactions = _parseList(
      json: json,
      field: 'transactions',
      decode: FinanceTransaction.fromJson,
      errors: errors,
    );
    final fundTransactions = _parseList(
      json: json,
      field: 'fundTransactions',
      decode: FundTransaction.fromJson,
      errors: errors,
    );
    final linkedItems = _parseList(
      json: json,
      field: 'linkedItems',
      decode: FinanceAccountLinkedItem.fromJson,
      errors: errors,
    );

    if (errors.isNotEmpty) {
      return FinancePortfolioV3ParseResult(value: null, errors: errors);
    }

    final value = FinancePortfolioV3(
      balances: balances,
      funds: funds,
      assetMovements: assetMovements,
      transactions: transactions,
      fundTransactions: fundTransactions,
      linkedItems: linkedItems,
    );
    final validation = FinancePortfolioV3Validator.validate(value);
    return FinancePortfolioV3ParseResult(
      value: value,
      errors: validation.errors,
    );
  }

  static List<T> _parseList<T>({
    required Map<String, dynamic> json,
    required String field,
    required T Function(Map<String, dynamic>) decode,
    required List<String> errors,
  }) {
    final raw = json[field];
    if (raw is! List) {
      errors.add('Invalid required list: $field');
      return const [];
    }

    final values = <T>[];
    for (var index = 0; index < raw.length; index++) {
      final element = raw[index];
      if (element is! Map) {
        errors.add('Invalid $field element at index $index');
        continue;
      }
      try {
        values.add(decode(Map<String, dynamic>.from(element)));
      } catch (error) {
        errors.add('Invalid $field element at index $index: $error');
      }
    }
    return values;
  }
}

class FinancePortfolioV3Validator {
  static FinancePortfolioV3ValidationResult validate(
    FinancePortfolioV3 portfolio,
  ) {
    final errors = <String>[];
    final balancesById = <String, FinanceBalance>{};
    final duplicateBalanceIds = <String>{};

    for (final balance in portfolio.balances) {
      if (balancesById.containsKey(balance.balanceId)) {
        duplicateBalanceIds.add(balance.balanceId);
      } else {
        balancesById[balance.balanceId] = balance;
      }
    }
    for (final id in duplicateBalanceIds.toList()..sort()) {
      errors.add('Duplicate balanceId: $id');
    }

    final linkedItemIds = <String>{};
    final duplicateLinkedItemIds = <String>{};
    for (final item in portfolio.linkedItems) {
      if (!linkedItemIds.add(item.id)) {
        duplicateLinkedItemIds.add(item.id);
      }
    }
    for (final id in duplicateLinkedItemIds.toList()..sort()) {
      errors.add('Duplicate linkedItem.id: $id');
    }

    for (final item in portfolio.linkedItems) {
      if (!balancesById.containsKey(item.balanceId)) {
        errors.add(
          'Linked item ${item.id} references missing parent balance: '
          '${item.balanceId}',
        );
      }

      final autonomousId = item.autonomousBalanceId;
      if (autonomousId == null) {
        continue;
      }
      if (autonomousId == item.balanceId) {
        errors.add(
          'Linked item ${item.id} uses the parent balance as autonomous balance',
        );
      }

      final autonomousBalance = balancesById[autonomousId];
      if (autonomousBalance == null) {
        errors.add(
          'Linked item ${item.id} references missing autonomous balance: '
          '$autonomousId',
        );
      } else if (autonomousBalance.balanceType !=
          FinanceBalanceType.prepaidCard) {
        errors.add(
          'Linked item ${item.id} autonomous balance is not prepaidCard: '
          '$autonomousId',
        );
      }
    }

    return FinancePortfolioV3ValidationResult(errors);
  }
}
