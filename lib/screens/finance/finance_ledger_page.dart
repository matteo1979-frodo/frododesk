import 'package:flutter/material.dart';

import '../../logic/finance/finance_ledger_presentation_coordinator.dart';
import '../../models/economic_event.dart';
import '../../models/ledger_event_view_model.dart';
import '../../models/ledger_presentation_data.dart';
import '../../utils/euro_formatter.dart';

enum FinanceLedgerNatureFilter { all, income, outflow, internalTransfer }

class FinanceLedgerPage extends StatefulWidget {
  final FinanceLedgerPresentationCoordinator coordinator;

  const FinanceLedgerPage({super.key, required this.coordinator});

  @override
  State<FinanceLedgerPage> createState() => _FinanceLedgerPageState();
}

class _FinanceLedgerPageState extends State<FinanceLedgerPage> {
  final DateTime observedAt = DateTime.now();
  String query = '';
  FinanceLedgerNatureFilter type = FinanceLedgerNatureFilter.all;

  @override
  Widget build(BuildContext context) {
    final data = widget.coordinator.build(
      observedAt: observedAt,
      query: query,
      selectedFilterIds: _selectedFilterIds(type),
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
          DropdownButton<FinanceLedgerNatureFilter>(
            value: type,
            items: FinanceLedgerNatureFilter.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_typeLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => type = value ?? type),
          ),
          const SizedBox(height: 12),
          if (data.state == LedgerPresentationState.archiveEmpty)
            const Card(
              child: ListTile(title: Text('Nessun movimento disponibile')),
            )
          else if (data.state == LedgerPresentationState.noResults)
            const Card(child: ListTile(title: Text('Nessun movimento trovato')))
          else
            ...data.entries.map(_entryCard),
        ],
      ),
    );
  }

  Widget _entryCard(LedgerEventViewModel entry) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => _showDetail(entry),
      leading: CircleAvatar(child: Icon(_icon(entry))),
      title: Text(
        entry.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          [
            if (entry.subtitle.isNotEmpty) entry.subtitle,
            _dateLabel(entry.occurredAt),
          ].join('\n'),
        ),
      ),
      trailing: Text(
        _amountLabel(entry),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      isThreeLine: entry.subtitle.isNotEmpty,
    ),
  );

  Future<void> _showDetail(LedgerEventViewModel entry) {
    final origins = _counterpartyLabels(entry, LedgerCounterpartyRole.origin);
    final destinations = _counterpartyLabels(
      entry,
      LedgerCounterpartyRole.destination,
    );
    final recurring = entry.transactionOrigins.contains(
      EconomicTransactionOrigin.recurringItem,
    );
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Importo', EuroFormatter.format(entry.amount)),
              _detailRow('Data', _dateLabel(entry.occurredAt)),
              if (origins.isNotEmpty) _detailRow('Da', origins),
              if (destinations.isNotEmpty) _detailRow('A', destinations),
              if (entry.personLabel?.isNotEmpty ?? false)
                _detailRow('Persona', entry.personLabel!),
              if (entry.category != null)
                _detailRow('Categoria', entry.category!.label),
              if (recurring) _detailRow('Ricorrenza', 'Ricorrente'),
              for (final note in entry.notes) _detailRow('Nota', note),
              for (final badge in entry.badges.where(
                (badge) => badge.tone == LedgerBadgeTone.warning,
              ))
                _detailRow('Stato', badge.label),
            ],
          ),
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

  Set<String> _selectedFilterIds(FinanceLedgerNatureFilter value) =>
      switch (value) {
        FinanceLedgerNatureFilter.all => const {},
        FinanceLedgerNatureFilter.income => const {'nature:income'},
        FinanceLedgerNatureFilter.outflow => const {'nature:outflow'},
        FinanceLedgerNatureFilter.internalTransfer => const {
          'nature:internalTransfer',
        },
      };

  String _typeLabel(FinanceLedgerNatureFilter value) => switch (value) {
    FinanceLedgerNatureFilter.all => 'Tutti i tipi',
    FinanceLedgerNatureFilter.income => 'Entrate',
    FinanceLedgerNatureFilter.outflow => 'Uscite',
    FinanceLedgerNatureFilter.internalTransfer => 'Trasferimenti',
  };

  IconData _icon(LedgerEventViewModel entry) => switch (entry.nature) {
    EconomicNature.income => Icons.south_west,
    EconomicNature.outflow => Icons.north_east,
    EconomicNature.internalTransfer => Icons.swap_horiz_rounded,
  };

  String _amountLabel(LedgerEventViewModel entry) =>
      switch (entry.economicSign) {
        LedgerEconomicSign.positive => EuroFormatter.formatSigned(entry.amount),
        LedgerEconomicSign.negative => EuroFormatter.formatSigned(
          -entry.amount,
        ),
        LedgerEconomicSign.neutral => EuroFormatter.format(entry.amount),
      };

  String _counterpartyLabels(
    LedgerEventViewModel entry,
    LedgerCounterpartyRole role,
  ) => entry.counterparties
      .where((counterparty) => counterparty.role == role)
      .map((counterparty) => counterparty.label)
      .join(', ');

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
