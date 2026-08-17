import 'package:flutter/material.dart';

import '../../logic/finance/finance_ledger_coordinator.dart';
import '../../models/finance_asset_movement.dart';
import '../../models/finance_ledger_view_data.dart';

class FinanceLedgerPage extends StatefulWidget {
  final FinanceLedgerCoordinator coordinator;

  const FinanceLedgerPage({super.key, required this.coordinator});

  @override
  State<FinanceLedgerPage> createState() => _FinanceLedgerPageState();
}

class _FinanceLedgerPageState extends State<FinanceLedgerPage> {
  String query = '';
  FinanceLedgerTypeFilter type = FinanceLedgerTypeFilter.all;
  FinanceLedgerOriginFilter origin = FinanceLedgerOriginFilter.all;

  @override
  Widget build(BuildContext context) {
    final viewData = widget.coordinator.build(
      query: query,
      type: type,
      origin: origin,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Movimenti della famiglia')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Cerca descrizione, conto, fondo o note',
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              DropdownButton<FinanceLedgerTypeFilter>(
                value: type,
                items: FinanceLedgerTypeFilter.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_typeLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => type = value ?? type),
              ),
              DropdownButton<FinanceLedgerOriginFilter>(
                value: origin,
                items: FinanceLedgerOriginFilter.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_originLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => origin = value ?? origin),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...viewData.fundOperations.map(_fundOperationCard),
          ...viewData.entries.map(_entryCard),
          if (viewData.entries.isEmpty && viewData.fundOperations.isEmpty)
            const Card(
              child: ListTile(title: Text('Nessun movimento trovato')),
            ),
        ],
      ),
    );
  }

  Widget _fundOperationCard(FinanceFundOperationViewData operation) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _fundOperationColor(
                  operation.movement.kind,
                ).withValues(alpha: 0.16),
                child: Icon(
                  _fundOperationIcon(operation.movement.kind),
                  color: _fundOperationColor(operation.movement.kind),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operation.typeLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      operation.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_dateLabel(operation.movement.occurredAt)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '€${operation.amount.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (operation.origins.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Da', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            ...operation.origins.map(_partyRow),
          ],
          if (operation.destinations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('A', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            ...operation.destinations.map(_partyRow),
          ],
        ],
      ),
    ),
  );

  Widget _partyRow(FinanceLedgerPartyViewData party) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        const Icon(Icons.arrow_right, size: 18),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            party.ownerName == null
                ? _displayName(party.name)
                : '${_displayName(party.name)} · ${party.ownerName}',
          ),
        ),
        Text('€${party.amount.toStringAsFixed(2)}'),
      ],
    ),
  );

  Widget _entryCard(FinanceLedgerEntryViewData entry) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => _showDetail(entry),
      leading: CircleAvatar(
        child: Icon(
          entry.transaction.isIncome ? Icons.south_west : Icons.north_east,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.typeLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            entry.description,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          '${entry.accountRoleLabel}: ${entry.balanceName} · ${entry.ownerName}\n'
          '${_dateLabel(entry.transaction.date)}',
        ),
      ),
      trailing: Text(
        '${entry.transaction.isIncome ? '+' : '-'}€${entry.transaction.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      isThreeLine: true,
    ),
  );

  Future<void> _showDetail(FinanceLedgerEntryViewData entry) {
    final transaction = entry.transaction;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Tipo', entry.typeLabel),
            _detailRow(entry.accountRoleLabel, entry.balanceName),
            _detailRow('Proprietario', entry.ownerName),
            _detailRow('Data', _dateLabel(transaction.date)),
            _detailRow('Importo', '€${transaction.amount.toStringAsFixed(2)}'),
            if (transaction.notes?.isNotEmpty ?? false)
              Text('Note: ${transaction.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  String _typeLabel(FinanceLedgerTypeFilter value) => switch (value) {
    FinanceLedgerTypeFilter.all => 'Tutti i tipi',
    FinanceLedgerTypeFilter.income => 'Entrate',
    FinanceLedgerTypeFilter.expense => 'Uscite',
    FinanceLedgerTypeFilter.transfer => 'Trasferimenti',
  };

  String _originLabel(FinanceLedgerOriginFilter value) => switch (value) {
    FinanceLedgerOriginFilter.all => 'Tutte le origini',
    FinanceLedgerOriginFilter.recurringItem => 'Ricorrenze',
    FinanceLedgerOriginFilter.manual => 'Manuali',
    FinanceLedgerOriginFilter.fund => 'Fondi',
    FinanceLedgerOriginFilter.adjustment => 'Rettifiche',
  };

  IconData _fundOperationIcon(FinanceAssetMovementKind kind) => switch (kind) {
    FinanceAssetMovementKind.fundOpening => Icons.flag_outlined,
    FinanceAssetMovementKind.fundAllocation => Icons.south_east_rounded,
    FinanceAssetMovementKind.fundRelease => Icons.north_west_rounded,
    FinanceAssetMovementKind.fundExpense => Icons.receipt_long_outlined,
    FinanceAssetMovementKind.fundTransferOut ||
    FinanceAssetMovementKind.fundTransferIn => Icons.swap_horiz_rounded,
    FinanceAssetMovementKind.legacyOpening => Icons.history_rounded,
    FinanceAssetMovementKind.legacyUnclassified => Icons.help_outline_rounded,
  };

  Color _fundOperationColor(FinanceAssetMovementKind kind) => switch (kind) {
    FinanceAssetMovementKind.fundOpening ||
    FinanceAssetMovementKind.fundAllocation => const Color(0xFF43A047),
    FinanceAssetMovementKind.fundRelease ||
    FinanceAssetMovementKind.fundTransferOut ||
    FinanceAssetMovementKind.fundTransferIn => const Color(0xFF1976D2),
    FinanceAssetMovementKind.fundExpense => const Color(0xFFE53935),
    FinanceAssetMovementKind.legacyOpening ||
    FinanceAssetMovementKind.legacyUnclassified => const Color(0xFF78909C),
  };

  String _displayName(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
