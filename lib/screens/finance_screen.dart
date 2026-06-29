import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/finance_category_template.dart';
import '../models/finance_month_projection.dart';
import '../models/finance_recurring_item.dart';
import '../models/frodo_observation.dart';
import '../stores/finance_store.dart';
import '../widgets/finance/finance_info_card.dart';
import '../widgets/finance/finance_month_detail_dialog.dart';
import '../widgets/finance/finance_year_dashboard.dart';
import 'person_finance_screen.dart';
import '../core/frododesk_bootstrap.dart';
import '../engines/observation/observation_engine.dart';
import 'finance/finance_observations_page.dart';

class FinanceScreen extends StatefulWidget {
  final FinanceStore financeStore;

  const FinanceScreen({super.key, required this.financeStore});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  FinanceStore get financeStore => widget.financeStore;

  @override
  Widget build(BuildContext context) {
    final pastItems = financeStore.pastRecurringItems();
    final presentItems = financeStore.presentRecurringItems();
    final futureItems = financeStore.futureRecurringItems();

    FrodoDeskBootstrap.initialize(
      expenses: const [],
      financeStore: financeStore,
    );

    final financeObservations = ObservationEngine.collectForModule('finance');

    return Scaffold(
      backgroundColor: const Color(0xFF0F1D12),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text("Finanze"),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.22)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    _buildFrodoControlCard(financeObservations),
                    const SizedBox(height: 18),
                    _buildMainNumbers(),
                    const SizedBox(height: 18),
                    _buildIncomeExpenseSection(),
                    const SizedBox(height: 18),
                    _buildTimeSections(
                      pastItems: pastItems,
                      presentItems: presentItems,
                      futureItems: futureItems,
                    ),
                    const SizedBox(height: 18),
                    _buildPeopleSection(context),
                    const SizedBox(height: 18),
                    _buildFundsSection(),
                    const SizedBox(height: 18),
                    _buildTemporalPressureSection(),
                    const SizedBox(height: 18),
                    _buildPressureFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrodoControlCard(List<FrodoObservation> financeObservations) {
    final nextItems = [
      ...financeStore.presentRecurringItems(),
      ...financeStore.futureRecurringItems(),
    ]..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    String message = "Nessuna criticità evidente nei prossimi giorni.";
    final firstObservation = financeObservations.isNotEmpty
        ? financeObservations.first
        : null;

    if (firstObservation != null) {
      message = firstObservation.message;
    }

    if (firstObservation == null && nextItems.isNotEmpty) {
      final first = nextItems.first;
      final sign = first.isIncome ? "+" : "-";

      message =
          "Prossima scadenza: ${_formatDate(first.nextDueDate)} • ${first.name} • $sign€${first.expectedAmount.toStringAsFixed(0)}";
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FinanceObservationsPage()),
        );
      },
      child: _FinanceGlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFB08D57).withOpacity(0.20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFFD54F),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Centro controllo economico",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (nextItems.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        "Prossima scadenza: ${_formatDate(nextItems.first.nextDueDate)} • ${nextItems.first.name} • ${nextItems.first.isIncome ? "+" : "-"}€${nextItems.first.expectedAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainNumbers() {
    return Row(
      children: [
        Expanded(
          child: FinanceInfoCard(
            title: "Saldo totale",
            value: "€${financeStore.totalBalance().toStringAsFixed(0)}",
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF43A047),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FinanceInfoCard(
            title: "Fondi",
            value: "€${financeStore.totalFunds().toStringAsFixed(0)}",
            icon: Icons.savings_rounded,
            color: const Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FinanceInfoCard(
            title: "Disponibile mese",
            value: "€${financeStore.availableThisMonth().toStringAsFixed(0)}",
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFFFB8C00),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseSection() {
    final incomeItems =
        financeStore.recurringItems.where((item) => item.isIncome).toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    final expenseItems =
        financeStore.recurringItems.where((item) => !item.isIncome).toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FinanceGlassCard(
            child: _buildRecurringPreviewBlock(
              title: "Entrate previste",
              subtitle:
                  "${incomeItems.length} voci • €${financeStore.totalRecurringAmount(incomeItems).toStringAsFixed(0)}",
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF43A047),
              items: incomeItems,
              addLabel: "Aggiungi entrata",
              onAdd: () => _showAddRecurringItemDialog(isIncome: true),
              onOpenAll: () => _showRecurringListDialog(
                title: "Entrate previste",
                isIncome: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _FinanceGlassCard(
            child: _buildRecurringPreviewBlock(
              title: "Uscite previste",
              subtitle:
                  "${expenseItems.length} voci • €${financeStore.totalRecurringAmount(expenseItems).toStringAsFixed(0)}",
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFE53935),
              items: expenseItems,
              addLabel: "Aggiungi uscita",
              onAdd: () => _showAddRecurringItemDialog(isIncome: false),
              onOpenAll: () => _showRecurringListDialog(
                title: "Uscite previste",
                isIncome: false,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringPreviewBlock({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<FinanceRecurringItem> items,
    required String addLabel,
    required VoidCallback onAdd,
    required VoidCallback onOpenAll,
  }) {
    final previewItems = items.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.66),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(addLabel),
          ),
        ),
        const SizedBox(height: 16),
        if (previewItems.isEmpty)
          _emptyMini("Nessuna voce inserita.")
        else
          ...previewItems.map(
            (item) => _recurringMiniTile(
              item,
              onTap: () => _showRecurringDetailDialog(item),
            ),
          ),
        if (items.length > 4) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenAll,
              icon: const Icon(Icons.open_in_full_rounded),
              label: const Text("Vedi tutte"),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSections({
    required List<FinanceRecurringItem> pastItems,
    required List<FinanceRecurringItem> presentItems,
    required List<FinanceRecurringItem> futureItems,
  }) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showTimeListDialog(
              title: "Passato economico",
              subtitle: "Ricorrenze già confermate",
              items: pastItems,
              color: const Color(0xFF8D6E63),
              icon: Icons.history_rounded,
            ),
            child: FinanceInfoCard(
              title: "Storico",
              value:
                  "${pastItems.length} • €${financeStore.totalRecurringAmount(pastItems).toStringAsFixed(0)}",
              icon: Icons.history_rounded,
              color: const Color(0xFF8D6E63),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showTimeListDialog(
              title: "Da confermare",
              subtitle: "Da confermare oggi o scadute",
              items: presentItems,
              color: const Color(0xFFE53935),
              icon: Icons.today_rounded,
            ),
            child: FinanceInfoCard(
              title: "Presente",
              value:
                  "${presentItems.length} • €${financeStore.totalRecurringAmount(presentItems).toStringAsFixed(0)}",
              icon: Icons.today_rounded,
              color: const Color(0xFFE53935),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showTimeListDialog(
              title: "Futuro economico",
              subtitle: "Prossime scadenze previste",
              items: futureItems,
              color: const Color(0xFF1E88E5),
              icon: Icons.event_available_rounded,
            ),
            child: FinanceInfoCard(
              title: "Prossime",
              value:
                  "${futureItems.length} • €${financeStore.totalRecurringAmount(futureItems).toStringAsFixed(0)}",
              icon: Icons.event_available_rounded,
              color: const Color(0xFF1E88E5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeopleSection(BuildContext context) {
    return _FinanceGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Conti per persona",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PersonBalanceCard(
                  name: "Matteo",
                  amount: financeStore.balanceForPerson("matteo"),
                  availableThisMonth: financeStore.availableThisMonthForOwner(
                    FinancePaymentOwner.matteo,
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonFinanceScreen(
                          financeStore: financeStore,
                          personId: "matteo",
                          personName: "Matteo",
                        ),
                      ),
                    );

                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PersonBalanceCard(
                  name: "Chiara",
                  amount: financeStore.balanceForPerson("chiara"),
                  availableThisMonth: financeStore.availableThisMonthForOwner(
                    FinancePaymentOwner.chiara,
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonFinanceScreen(
                          financeStore: financeStore,
                          personId: "chiara",
                          personName: "Chiara",
                        ),
                      ),
                    );

                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundsSection() {
    return _FinanceGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fondi",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (financeStore.funds.isEmpty)
            Text(
              "Nessun fondo inserito.",
              style: TextStyle(color: Colors.white.withOpacity(0.70)),
            )
          else
            ...financeStore.funds.map(
              (fund) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fund.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      "€${fund.amount.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTemporalPressureSection() {
    return _FinanceGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pressione temporale",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          FinanceYearDashboard(
            financeStore: financeStore,
            onMonthTap: (projection, color) async {
              await _showMonthDetailDialog(projection, color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPressureFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: financeStore.isUnderPressure()
            ? const Color(0xFFE53935).withOpacity(0.14)
            : const Color(0xFF43A047).withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        financeStore.isUnderPressure()
            ? "Il sistema rileva pressione economica."
            : "Situazione economica stabile.",
        style: TextStyle(
          color: Colors.white.withOpacity(0.84),
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _showMonthDetailDialog(
    FinanceMonthProjection projection,
    Color color,
  ) async {
    final monthItems = financeStore.itemsForProjectionMonth(projection.month)
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    final monthIncomeItems = monthItems.where((item) => item.isIncome).toList();
    final monthExpenseItems = monthItems
        .where((item) => !item.isIncome)
        .toList();

    await _showFinanceDialog(
      icon: Icons.calendar_month_rounded,
      color: color,
      title: DateFormat('MMMM yyyy', 'it_IT').format(projection.month),
      subtitle: "Dettaglio economico del mese",
      child: FinanceMonthDetailDialog(
        financeStore: financeStore,
        projection: projection,
        monthIncomeItems: monthIncomeItems,
        monthExpenseItems: monthExpenseItems,
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _showRecurringListDialog({
    required String title,
    required bool isIncome,
  }) async {
    await _showFinanceDialog(
      icon: isIncome
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      color: isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935),
      title: title,
      subtitle: isIncome
          ? "Entrate economiche previste"
          : "Uscite economiche previste",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          final items =
              financeStore.recurringItems
                  .where((item) => item.isIncome == isIncome)
                  .toList()
                ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _showAddRecurringItemDialog(isIncome: isIncome);
                    refreshDialog(() {});
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    isIncome ? "Aggiungi entrata" : "Aggiungi uscita",
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                _dialogEmpty(
                  icon: Icons.inbox_rounded,
                  title: "Nessuna voce",
                  subtitle: "Puoi aggiungerla dal pulsante qui sopra.",
                )
              else
                ...items.map(
                  (item) => _recurringActionTile(
                    item,
                    onChanged: () {
                      refreshDialog(() {});
                      if (mounted) setState(() {});
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showTimeListDialog({
    required String title,
    required String subtitle,
    required List<FinanceRecurringItem> items,
    required Color color,
    required IconData icon,
  }) async {
    await _showFinanceDialog(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          final currentItems = List<FinanceRecurringItem>.from(items)
            ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

          return currentItems.isEmpty
              ? _dialogEmpty(
                  icon: icon,
                  title: "Nessuna voce",
                  subtitle: "Non ci sono elementi in questa sezione.",
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: currentItems.map((item) {
                    return _recurringActionTile(
                      item,
                      onChanged: () {
                        refreshDialog(() {});
                        if (mounted) setState(() {});
                      },
                    );
                  }).toList(),
                );
        },
      ),
    );
  }

  Widget _recurringMiniTile(
    FinanceRecurringItem item, {
    required VoidCallback onTap,
  }) {
    final color = item.isIncome
        ? const Color(0xFF43A047)
        : const Color(0xFFE53935);
    final sign = item.isIncome ? "+" : "-";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          children: [
            Icon(
              item.isIncome
                  ? Icons.add_circle_rounded
                  : Icons.remove_circle_rounded,
              color: color,
              size: 19,
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 72,
              child: Text(
                _formatDate(item.nextDueDate),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              "$sign€${item.expectedAmount.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recurringActionTile(
    FinanceRecurringItem item, {
    required VoidCallback onChanged,
  }) {
    final color = item.isIncome
        ? const Color(0xFF43A047)
        : const Color(0xFFE53935);
    final sign = item.isIncome ? "+" : "-";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.42)),
      ),
      child: Row(
        children: [
          Icon(
            item.isIncome
                ? Icons.add_circle_rounded
                : Icons.remove_circle_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(
              _formatDate(item.nextDueDate),
              style: TextStyle(
                color: Colors.black.withOpacity(0.58),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _showRecurringDetailDialog(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${_recurringTypeLabel(item.recurringType)} • ${_ownerLabel(item.paymentOwner)} • ${_paymentMethodLabel(item.paymentMethod)}",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.56),
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            "$sign€${item.expectedAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "confirm") {
                await _showConfirmRecurringDialog(item);
              } else if (value == "edit") {
                await _showEditRecurringItemDialog(item);
              } else if (value == "delete") {
                await financeStore.removeRecurringItem(item.id);
              }

              onChanged();
            },
            itemBuilder: (context) => [
              if (!item.confirmed)
                const PopupMenuItem(value: "confirm", child: Text("Conferma")),
              const PopupMenuItem(value: "edit", child: Text("Modifica")),
              const PopupMenuItem(value: "delete", child: Text("Elimina")),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showRecurringDetailDialog(FinanceRecurringItem item) async {
    await _showFinanceDialog(
      icon: item.isIncome
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      color: item.isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935),
      title: item.name,
      subtitle: item.isIncome ? "Entrata prevista" : "Uscita prevista",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow("Data", _formatDate(item.nextDueDate)),
          _detailRow(
            "Importo previsto",
            "€${item.expectedAmount.toStringAsFixed(2)}",
          ),
          if (item.realAmount != null)
            _detailRow(
              "Importo reale",
              "€${item.realAmount!.toStringAsFixed(2)}",
            ),
          _detailRow("Ricorrenza", _recurringTypeLabel(item.recurringType)),
          _detailRow("Proprietario", _ownerLabel(item.paymentOwner)),
          _detailRow("Metodo", _paymentMethodLabel(item.paymentMethod)),
          _detailRow("Categoria", _categoryLabel(item.category)),
          _detailRow("Stato", item.confirmed ? "Confermato" : "Da confermare"),
          if (item.description.trim().isNotEmpty)
            _detailRow("Note", item.description),
          const SizedBox(height: 14),
          if (!item.confirmed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _showConfirmRecurringDialog(item);
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text("Conferma"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black.withOpacity(0.52),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmRecurringDialog(FinanceRecurringItem item) async {
    final amountController = TextEditingController(
      text: item.expectedAmount.toStringAsFixed(2),
    );

    await _showFinanceDialog(
      icon: Icons.check_circle_rounded,
      color: item.isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935),
      title: "Conferma ${item.isIncome ? "entrata" : "uscita"}",
      subtitle: item.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Importo reale",
              hintText: item.expectedAmount.toStringAsFixed(2),
              filled: true,
              fillColor: Colors.white.withOpacity(0.82),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final raw = amountController.text.trim().replaceAll(',', '.');
                final amount = double.tryParse(raw);

                if (amount == null) return;

                await financeStore.confirmRecurringItem(
                  item.id,
                  realAmount: amount,
                );

                if (mounted) {
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text("Conferma e aggiorna saldo"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRecurringItemDialog({required bool isIncome}) async {
    await _showRecurringItemFormDialog(isIncome: isIncome);
  }

  Future<void> _showEditRecurringItemDialog(FinanceRecurringItem item) async {
    await _showRecurringItemFormDialog(isIncome: item.isIncome, existing: item);
  }

  Future<void> _showRecurringItemFormDialog({
    required bool isIncome,
    FinanceRecurringItem? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? "");
    final descriptionController = TextEditingController(
      text: existing?.description ?? "",
    );
    final amountController = TextEditingController(
      text: existing?.expectedAmount.toStringAsFixed(2) ?? "",
    );
    final customIntervalController = TextEditingController(
      text: existing?.customInterval?.toString() ?? "1",
    );

    DateTime selectedDate = existing?.nextDueDate ?? DateTime.now();

    FinanceRecurringType selectedRecurringType =
        existing?.recurringType ?? FinanceRecurringType.monthly;

    FinancePaymentOwner selectedOwner =
        existing?.paymentOwner ?? FinancePaymentOwner.shared;

    FinanceSubject selectedSubject = existing?.subject ?? FinanceSubject.shared;

    FinancePaymentMethod selectedPaymentMethod =
        existing?.paymentMethod ?? FinancePaymentMethod.manual;

    FinanceCategory selectedCategory =
        existing?.category ??
        (isIncome ? FinanceCategory.salary : FinanceCategory.generic);

    String? selectedBalanceId = existing?.balanceId;

    if (selectedBalanceId == null && financeStore.balances.isNotEmpty) {
      selectedBalanceId = financeStore.balances
          .where((b) => b.active)
          .map((b) => b.balanceId)
          .cast<String?>()
          .firstOrNull;
    }

    await _showFinanceDialog(
      icon: isIncome
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      color: isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935),
      title: existing == null
          ? (isIncome ? "Nuova entrata" : "Nuova uscita")
          : "Modifica voce",
      subtitle: isIncome
          ? "Entrata economica prevista"
          : "Uscita economica prevista",
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedBalanceId,
                decoration: _inputDecoration("Conto collegato"),
                items: financeStore.balances.where((b) => b.active).map((
                  balance,
                ) {
                  return DropdownMenuItem(
                    value: balance.balanceId,
                    child: Text(balance.name),
                  );
                }).toList(),
                onChanged: (value) {
                  refreshDialog(() {
                    selectedBalanceId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: _inputDecoration(
                  isIncome ? "Nome entrata" : "Nome uscita",
                  hint: isIncome
                      ? "Es. Stipendio Matteo"
                      : "Es. Hera, IMU, assicurazione",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  "Importo previsto",
                  hint: "Es. 50.00",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: _inputDecoration("Descrizione / note"),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (picked == null) return;

                  refreshDialog(() {
                    selectedDate = picked;
                  });
                },
                child: FinanceInfoCard(
                  title: isIncome
                      ? "Data entrata prevista"
                      : "Data scadenza prevista",
                  value: _formatDate(selectedDate),
                  icon: Icons.event_rounded,
                  color: const Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FinanceRecurringType>(
                value: selectedRecurringType,
                decoration: _inputDecoration("Tipo ricorrenza"),
                items: const [
                  DropdownMenuItem(
                    value: FinanceRecurringType.monthly,
                    child: Text("Mensile"),
                  ),
                  DropdownMenuItem(
                    value: FinanceRecurringType.yearly,
                    child: Text("Annuale"),
                  ),
                  DropdownMenuItem(
                    value: FinanceRecurringType.oneShot,
                    child: Text("Una volta"),
                  ),
                  DropdownMenuItem(
                    value: FinanceRecurringType.custom,
                    child: Text("Personalizzata"),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  refreshDialog(() {
                    selectedRecurringType = value;
                  });
                },
              ),
              if (selectedRecurringType == FinanceRecurringType.custom) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: customIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    "Ogni quanti mesi?",
                    hint: "Es. 2",
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<FinancePaymentOwner>(
                value: selectedOwner,
                decoration: _inputDecoration("Chi paga / riceve"),
                items: const [
                  DropdownMenuItem(
                    value: FinancePaymentOwner.matteo,
                    child: Text("Matteo"),
                  ),
                  DropdownMenuItem(
                    value: FinancePaymentOwner.chiara,
                    child: Text("Chiara"),
                  ),
                  DropdownMenuItem(
                    value: FinancePaymentOwner.shared,
                    child: Text("Condiviso"),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  refreshDialog(() {
                    selectedOwner = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<FinanceSubject>(
                value: selectedSubject,
                decoration: _inputDecoration("Di chi è"),
                items: const [
                  DropdownMenuItem(
                    value: FinanceSubject.matteo,
                    child: Text("Matteo"),
                  ),
                  DropdownMenuItem(
                    value: FinanceSubject.chiara,
                    child: Text("Chiara"),
                  ),
                  DropdownMenuItem(
                    value: FinanceSubject.alice,
                    child: Text("Alice"),
                  ),
                  DropdownMenuItem(
                    value: FinanceSubject.shared,
                    child: Text("Condiviso"),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  refreshDialog(() {
                    selectedSubject = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FinancePaymentMethod>(
                value: selectedPaymentMethod,
                decoration: _inputDecoration("Metodo pagamento"),
                items: const [
                  DropdownMenuItem(
                    value: FinancePaymentMethod.manual,
                    child: Text("Manuale"),
                  ),
                  DropdownMenuItem(
                    value: FinancePaymentMethod.rid,
                    child: Text("RID bancario"),
                  ),
                  DropdownMenuItem(
                    value: FinancePaymentMethod.bankTransfer,
                    child: Text("Bonifico"),
                  ),
                  DropdownMenuItem(
                    value: FinancePaymentMethod.card,
                    child: Text("Carta"),
                  ),
                  DropdownMenuItem(
                    value: FinancePaymentMethod.cash,
                    child: Text("Contanti"),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  refreshDialog(() {
                    selectedPaymentMethod = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FinanceCategory>(
                value: selectedCategory,
                decoration: _inputDecoration("Categoria"),
                items: FinanceCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_categoryLabel(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  refreshDialog(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final rawAmount = amountController.text.trim().replaceAll(
                      ',',
                      '.',
                    );
                    final amount = double.tryParse(rawAmount);

                    if (name.isEmpty || amount == null) return;

                    final now = DateTime.now();

                    final customInterval =
                        selectedRecurringType == FinanceRecurringType.custom
                        ? int.tryParse(customIntervalController.text.trim()) ??
                              1
                        : null;

                    final item = FinanceRecurringItem(
                      id:
                          existing?.id ??
                          'recurring_${now.microsecondsSinceEpoch}',
                      name: name,
                      description: descriptionController.text.trim(),
                      expectedAmount: amount,
                      nextDueDate: selectedDate,
                      isIncome: isIncome,
                      recurringType: selectedRecurringType,
                      customInterval: customInterval,
                      customIntervalUnit:
                          selectedRecurringType == FinanceRecurringType.custom
                          ? 'months'
                          : null,
                      category: selectedCategory,
                      requiresManualConfirmation: true,
                      mandatory: !isIncome,
                      pressureLevel: isIncome
                          ? FinancePressureLevel.low
                          : FinancePressureLevel.medium,
                      confirmed: existing?.confirmed ?? false,
                      realAmount: existing?.realAmount,
                      variability: FinanceVariability.variable,
                      paymentPriority: isIncome
                          ? FinancePaymentPriority.normal
                          : FinancePaymentPriority.high,
                      protectionLevel: FinanceProtectionLevel.none,
                      paymentOwner: selectedOwner,
                      subject: selectedSubject,
                      balanceId: selectedBalanceId,
                      paymentMethod: selectedPaymentMethod,
                      stability: FinanceStability.stable,
                      suspensionRisk: FinanceSuspensionRisk.low,
                      originType: FinanceOriginType.manual,
                      splits: existing?.splits ?? const [],
                      behaviorProfile:
                          existing?.behaviorProfile ??
                          FinanceBehaviorProfile(
                            predictable: true,
                            lifeGenerated: false,
                            timeSensitive: !isIncome,
                            canBeDelayed: !isIncome,
                            canBeSplit: !isIncome,
                            canBeReduced: false,
                            affectsResilience: true,
                            affectsOperationalOxygen: true,
                            rigidityScore: isIncome ? 0.2 : 0.6,
                            maneuverabilityScore: isIncome ? 0.8 : 0.4,
                            recoveryImpactScore: 0.5,
                          ),
                    );

                    if (existing == null) {
                      await financeStore.addRecurringItem(item);
                    } else {
                      await financeStore.updateRecurringItem(item);
                    }

                    if (mounted) {
                      setState(() {});
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(existing == null ? "Salva" : "Aggiorna"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.82),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF8D6E63), width: 2),
      ),
    );
  }

  Future<void> _showFinanceDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget child,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 780, maxHeight: 820),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.86),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black.withOpacity(0.88),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.25,
                                  color: Colors.black.withOpacity(0.60),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: "Chiudi",
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Colors.black.withOpacity(0.40)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.56),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMini(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.70),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return "$day/$month/$year";
  }

  String _recurringTypeLabel(FinanceRecurringType type) {
    switch (type) {
      case FinanceRecurringType.monthly:
        return "Mensile";
      case FinanceRecurringType.yearly:
        return "Annuale";
      case FinanceRecurringType.oneShot:
        return "Una volta";
      case FinanceRecurringType.custom:
        return "Personalizzata";
    }
  }

  String _ownerLabel(FinancePaymentOwner owner) {
    switch (owner) {
      case FinancePaymentOwner.matteo:
        return "Matteo";
      case FinancePaymentOwner.chiara:
        return "Chiara";
      case FinancePaymentOwner.shared:
        return "Condiviso";
    }
  }

  String _paymentMethodLabel(FinancePaymentMethod method) {
    switch (method) {
      case FinancePaymentMethod.manual:
        return "Manuale";
      case FinancePaymentMethod.rid:
        return "RID";
      case FinancePaymentMethod.bankTransfer:
        return "Bonifico";
      case FinancePaymentMethod.card:
        return "Carta";
      case FinancePaymentMethod.cash:
        return "Contanti";
    }
  }

  String _categoryLabel(FinanceCategory category) {
    switch (category) {
      case FinanceCategory.salary:
        return "Stipendio";
      case FinanceCategory.entertainment:
        return "Intrattenimento";
      case FinanceCategory.house:
        return "Casa";
      case FinanceCategory.auto:
        return "Auto";
      case FinanceCategory.school:
        return "Scuola";
      case FinanceCategory.health:
        return "Salute";
      case FinanceCategory.generic:
        return "Generica";
    }
  }
}

class _FinanceGlassCard extends StatelessWidget {
  final Widget child;

  const _FinanceGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PersonBalanceCard extends StatelessWidget {
  final String name;
  final double amount;
  final double availableThisMonth;
  final VoidCallback onTap;

  const _PersonBalanceCard({
    required this.name,
    required this.amount,
    required this.availableThisMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "€${amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Previsione fine mese: €${availableThisMonth.toStringAsFixed(0)}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Apri conti",
              style: TextStyle(
                color: Colors.white.withOpacity(0.60),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
