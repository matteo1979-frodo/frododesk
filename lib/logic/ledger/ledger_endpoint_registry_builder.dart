import '../../models/cash_wallet.dart';
import '../../models/finance_balance.dart';
import '../../models/finance_fund.dart';
import '../../models/finance_person.dart';
import '../../models/ledger_resolved_endpoint.dart';

class LedgerEndpointRegistryBuilder {
  const LedgerEndpointRegistryBuilder();

  LedgerEndpointRegistry build({
    required Iterable<FinanceBalance> accounts,
    required Iterable<FinanceFund> funds,
    required Iterable<CashWallet> wallets,
    required Iterable<FinancePerson> people,
  }) {
    final personRecords = _people(people);
    return LedgerEndpointRegistry(
      accounts: _endpoints(
        kind: 'account',
        values: accounts.map(
          (account) => LedgerEndpointRecord(
            id: account.balanceId,
            label: account.name,
            personId: account.personId,
          ),
        ),
      ),
      funds: _endpoints(
        kind: 'fund',
        values: funds.map(
          (fund) => LedgerEndpointRecord(id: fund.id, label: fund.name),
        ),
      ),
      cashWallets: _endpoints(
        kind: 'cash wallet',
        values: wallets.map(
          (wallet) => LedgerEndpointRecord(
            id: wallet.id,
            label: wallet.name,
            personId: wallet.personId,
          ),
        ),
      ),
      people: personRecords,
    );
  }

  Map<String, LedgerPersonRecord> _people(Iterable<FinancePerson> values) {
    final records = <String, LedgerPersonRecord>{};
    for (final person in values) {
      final candidate = LedgerPersonRecord(id: person.id, label: person.name);
      final existing = records[candidate.id];
      if (existing != null && existing.label != candidate.label) {
        throw StateError('Conflicting person referenceId: ${candidate.id}');
      }
      records[candidate.id] = candidate;
    }
    return _sorted(records);
  }

  Map<String, LedgerEndpointRecord> _endpoints({
    required String kind,
    required Iterable<LedgerEndpointRecord> values,
  }) {
    final records = <String, LedgerEndpointRecord>{};
    for (final candidate in values) {
      final existing = records[candidate.id];
      if (existing != null &&
          (existing.label != candidate.label ||
              existing.personId != candidate.personId)) {
        throw StateError('Conflicting $kind referenceId: ${candidate.id}');
      }
      records[candidate.id] = candidate;
    }
    return _sorted(records);
  }

  Map<String, T> _sorted<T>(Map<String, T> records) {
    final keys = records.keys.toList()..sort();
    return {for (final key in keys) key: records[key] as T};
  }
}
