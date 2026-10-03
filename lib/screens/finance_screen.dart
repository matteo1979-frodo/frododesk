import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/finance_category_template.dart';
import '../models/finance_month_projection.dart';
import '../models/finance_recurring_item.dart';
import '../models/finance_forecast_presentation.dart';
import '../models/income_forecast_presentation.dart';
import '../models/financial_resilience.dart';
import '../models/finite_financial_plan.dart';
import '../models/projected_expense_cycle.dart';
import '../models/finite_financial_plan_installment_confirmation.dart';
import '../models/frodo_observation.dart';
import '../stores/finance_store.dart';
import '../stores/expense_store.dart';
import '../stores/cash_wallet_store.dart';
import '../widgets/finance/finance_info_card.dart';
import '../widgets/finance/finance_month_detail_dialog.dart';
import '../widgets/finance/finance_year_dashboard.dart';
import 'person_finance_screen.dart';
import '../core/frododesk_bootstrap.dart';
import '../engines/observation/observation_engine.dart';
import 'finance/finance_observations_page.dart';
import 'finance/finance_funds_page.dart';
import 'finance/finance_ledger_page.dart';
import '../logic/finance/finance_funds_coordinator.dart';
import '../logic/finance/finite_financial_plan_installment_confirmation_coordinator.dart';
import '../logic/finance/finance_ledger_presentation_coordinator.dart';
import '../logic/finance/finance_recurring_coordinator.dart';
import '../logic/finance/finance_forecast_reader.dart';
import '../logic/finance/income_forecast_reader.dart';
import '../logic/finance/finance_temporal_projection_reader.dart';
import '../logic/finance/household_resilience_reader.dart';
import '../models/finance_recurring_draft.dart';
import '../utils/euro_formatter.dart';
import 'income_page.dart';

class FinanceScreen extends StatefulWidget {
  final FinanceStore financeStore;
  final ExpenseStore expenseStore;
  final CashWalletStore cashWalletStore;
  final DateTime? forecastReferenceTime;

  const FinanceScreen({
    super.key,
    required this.financeStore,
    required this.expenseStore,
    required this.cashWalletStore,
    this.forecastReferenceTime,
  });

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
                    const SizedBox(height: 12),
                    _buildModernFinanceActions(),
                    const SizedBox(height: 18),
                    _buildIncomeExpenseSection(),
                    const SizedBox(height: 18),
                    _buildTimeSections(
                      pastItems: pastItems,
                      presentItems: presentItems,
                      futureItems: futureItems,
                    ),
                    const SizedBox(height: 18),
                    _buildFiniteFinancialPlansSection(),
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
      message =
          "Prossima scadenza: ${_formatDate(first.nextDueDate)} • ${first.name} • ${EuroFormatter.formatSigned(first.isIncome ? first.expectedAmount : -first.expectedAmount)}";
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
                        "Prossima scadenza: ${_formatDate(nextItems.first.nextDueDate)} • ${nextItems.first.name} • ${EuroFormatter.formatSigned(nextItems.first.isIncome ? nextItems.first.expectedAmount : -nextItems.first.expectedAmount)}",
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
            value: EuroFormatter.format(financeStore.totalBalance()),
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF43A047),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FinanceInfoCard(
            title: "Fondi",
            value: EuroFormatter.format(financeStore.totalFunds()),
            icon: Icons.savings_rounded,
            color: const Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FinanceInfoCard(
            title: "Disponibile mese",
            value: EuroFormatter.format(financeStore.availableThisMonth()),
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFFFB8C00),
          ),
        ),
      ],
    );
  }

  Widget _buildModernFinanceActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FinanceFundsPage(
                    coordinator: FinanceFundsCoordinator(
                      financeStore: financeStore,
                    ),
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.savings_rounded),
            label: const Text('Gestisci fondi'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FinanceLedgerPage(
                    coordinator: FinanceLedgerPresentationCoordinator(
                      financeStore: financeStore,
                      expenseStore: widget.expenseStore,
                      cashWalletStore: widget.cashWalletStore,
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('Movimenti della famiglia'),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseSection() {
    final referenceTime = widget.forecastReferenceTime ?? DateTime.now();
    final month = DateTime(referenceTime.year, referenceTime.month);
    final forecast = const FinanceForecastReader().read(
      expectedExpenses: financeStore.expectedExpenseAggregate,
      documentaryObligations: financeStore.documentaryObligationAggregate,
      finitePlans: financeStore.finiteFinancialPlans,
      referenceTime: referenceTime,
      projectionHorizon: ExpenseProjectionHorizon(
        start: month,
        end: DateTime(referenceTime.year + 1, 12, 31, 23, 59, 59, 999, 999),
      ),
    );
    final expenseItems = forecast.economicItemsForMonth(month).toList()
      ..sort((a, b) {
        final date = (a.economicStart ?? month).compareTo(
          b.economicStart ?? month,
        );
        return date != 0 ? date : a.identity.compareTo(b.identity);
      });
    final incomeForecast = const IncomeForecastReader().read(
      aggregate: financeStore.incomeAggregate,
      horizon: ExpenseProjectionHorizon(
        start: month,
        end: DateTime(referenceTime.year + 1, 12, 31, 23, 59, 59, 999, 999),
      ),
    );
    final incomeItems = incomeForecast.itemsForMonth(month);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _openIncomePage,
            child: _FinanceGlassCard(
              child: _buildIncomeForecastPreviewBlock(
                title: "Entrate previste",
                subtitle:
                    "${incomeItems.length} voci • ${EuroFormatter.format(incomeForecast.totalForMonth(month))}",
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF43A047),
                items: incomeItems,
                addLabel: "Aggiungi entrata",
                onAdd: () => _openIncomePage(startWithCreate: true),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _FinanceGlassCard(
            child: _buildForecastPreviewBlock(
              title: "Uscite previste",
              subtitle:
                  "${expenseItems.length} voci • ${EuroFormatter.format(forecast.economicOutflowForMonth(month))}",
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFE53935),
              items: expenseItems,
              addLabel: "Aggiungi uscita",
              onAdd: () => _showAddRecurringItemDialog(isIncome: false),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openIncomePage({bool startWithCreate = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncomePage(
          financeStore: financeStore,
          referenceTime: widget.forecastReferenceTime,
          startWithCreate: startWithCreate,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _buildIncomeForecastPreviewBlock({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<IncomeForecastPresentation> items,
    required String addLabel,
    required VoidCallback onAdd,
  }) => Column(
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
      if (items.isEmpty)
        _emptyMini('Nessuna voce inserita.')
      else
        ...items
            .take(4)
            .map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _formatDate(item.economicDate),
                  style: TextStyle(color: Colors.white.withOpacity(.62)),
                ),
                trailing: Text(
                  EuroFormatter.format(item.amount),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                onTap: _openIncomePage,
              ),
            ),
    ],
  );

  Widget _buildForecastPreviewBlock({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<FinanceForecastPresentation> items,
    required String addLabel,
    required VoidCallback onAdd,
  }) {
    final previewItems = items.take(4);
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
        if (items.isEmpty)
          _emptyMini("Nessuna voce inserita.")
        else
          ...previewItems.map(_forecastMiniTile),
      ],
    );
  }

  Widget _forecastMiniTile(FinanceForecastPresentation item) {
    final date = item.economicStart;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (date != null)
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            EuroFormatter.format(item.amount),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // Kept for the still-legacy time sections, but no longer an income source.
  // ignore: unused_element
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
                  "${pastItems.length} • ${EuroFormatter.format(financeStore.totalRecurringAmount(pastItems))}",
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
                  "${presentItems.length} • ${EuroFormatter.format(financeStore.totalRecurringAmount(presentItems))}",
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
                  "${futureItems.length} • ${EuroFormatter.format(financeStore.totalRecurringAmount(futureItems))}",
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

  Widget _buildFiniteFinancialPlansSection() {
    return _FinanceGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Piani finanziari',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('add-finite-financial-plan'),
                onPressed: _showAddFiniteFinancialPlanDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Aggiungi piano'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (financeStore.finiteFinancialPlans.isEmpty)
            _emptyMini('Nessun piano finanziario inserito.')
          else
            ...financeStore.finiteFinancialPlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildFiniteFinancialPlanCard(plan),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiniteFinancialPlanCard(FiniteFinancialPlan plan) {
    final installment = plan.nextInstallment;
    final accountName = financeStore.balances
        .where((balance) => balance.balanceId == plan.debitBalanceId)
        .map((balance) => balance.name)
        .firstOrNull;

    return Container(
      key: Key('finite-financial-plan-${plan.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          if (installment == null)
            const Text(
              'Completato',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            Text(
              'Rata ${installment.number} di ${plan.totalInstallments}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${EuroFormatter.format(installment.expectedAmount)} • ${_formatDate(installment.dueDate)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: Key('confirm-finite-plan-installment-${plan.id}'),
                onPressed: () => _showConfirmFinitePlanInstallmentDialog(
                  plan,
                  installment,
                  accountName ?? 'Conto non disponibile',
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text('Registra rata ${installment.number}'),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${_financeSubjectLabel(plan.subject)} • ${accountName ?? 'Nessun conto associato'}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmFinitePlanInstallmentDialog(
    FiniteFinancialPlan plan,
    FiniteFinancialPlanInstallment installment,
    String accountName,
  ) async {
    final amountController = TextEditingController(
      text: installment.expectedAmount.toStringAsFixed(2),
    );
    final descriptionController = TextEditingController();
    final feeController = TextEditingController();
    DateTime? economicDate;
    FinanceCategory? mainCategory;
    FinanceCategory? feeCategory;
    String? formError;
    var submitting = false;

    await _showFinanceDialog(
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF6D4C41),
      title: 'Registra rata ${installment.number}',
      subtitle: plan.name,
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          final fee = double.tryParse(
            feeController.text.trim().replaceAll(',', '.'),
          );

          Future<void> submit() async {
            if (submitting) return;
            final amount = double.tryParse(
              amountController.text.trim().replaceAll(',', '.'),
            );
            final description = descriptionController.text.trim();
            final feeText = feeController.text.trim();
            final effectiveFee = fee == null || fee == 0 ? null : fee;
            if (amount == null ||
                amount <= 0 ||
                economicDate == null ||
                description.isEmpty ||
                mainCategory == null ||
                (feeText.isNotEmpty && fee == null) ||
                (effectiveFee != null &&
                    (effectiveFee < 0 || feeCategory == null))) {
              refreshDialog(() {
                formError = effectiveFee != null && feeCategory == null
                    ? 'Seleziona la categoria della commissione.'
                    : 'Compila tutti i campi obbligatori con valori validi.';
              });
              return;
            }

            refreshDialog(() {
              submitting = true;
              formError = null;
            });
            try {
              final confirmation = FiniteFinancialPlanInstallmentConfirmation(
                planId: plan.id,
                installmentNumber: installment.number,
                debitBalanceId: plan.debitBalanceId ?? '',
                subject: plan.subject,
                mainAmount: amount,
                economicDate: economicDate!,
                description: description,
                mainCategory: _categoryLabel(mainCategory!),
                bankFee: effectiveFee,
                bankFeeCategory: effectiveFee == null
                    ? null
                    : _categoryLabel(feeCategory!),
              );
              final result =
                  await FiniteFinancialPlanInstallmentConfirmationCoordinator(
                    financeStore: financeStore,
                    expenseStore: widget.expenseStore,
                  ).confirm(confirmation);
              if (!context.mounted || !mounted) return;
              switch (result.status) {
                case FinitePlanInstallmentConfirmationStatus.completed:
                case FinitePlanInstallmentConfirmationStatus.alreadyComplete:
                  Navigator.of(context).pop();
                  setState(() {});
                case FinitePlanInstallmentConfirmationStatus.inconsistent:
                  refreshDialog(() {
                    submitting = false;
                    formError =
                        'I dati non sono coerenti: la rata non può essere registrata in sicurezza.';
                  });
                case FinitePlanInstallmentConfirmationStatus.failed:
                  refreshDialog(() {
                    submitting = false;
                    formError =
                        'Registrazione non completata. Verifica i dati e riprova.';
                  });
              }
            } catch (_) {
              if (!context.mounted) return;
              refreshDialog(() {
                submitting = false;
                formError =
                    'Registrazione non completata. Verifica i dati e riprova.';
              });
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Piano: ${plan.name}'),
              Text('Rata: ${installment.number} di ${plan.totalInstallments}'),
              Text('Conto: $accountName'),
              Text('Soggetto: ${_financeSubjectLabel(plan.subject)}'),
              Text(
                'Importo previsto: ${EuroFormatter.format(installment.expectedAmount)}',
              ),
              Text('Data pianificata: ${_formatDate(installment.dueDate)}'),
              const SizedBox(height: 16),
              TextField(
                key: const Key('finite-installment-amount'),
                controller: amountController,
                enabled: !submitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration('Importo reale rata'),
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('finite-installment-economic-date'),
                contentPadding: EdgeInsets.zero,
                enabled: !submitting,
                title: const Text('Data effettiva'),
                subtitle: Text(
                  economicDate == null
                      ? 'Seleziona la data'
                      : _formatDate(economicDate!),
                ),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: submitting
                    ? null
                    : () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: installment.dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100, 12, 31),
                        );
                        if (selected != null && context.mounted) {
                          refreshDialog(() => economicDate = selected);
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('finite-installment-description'),
                controller: descriptionController,
                enabled: !submitting,
                decoration: _inputDecoration('Causale / descrizione'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FinanceCategory>(
                key: const Key('finite-installment-main-category'),
                initialValue: mainCategory,
                decoration: _inputDecoration('Categoria rata'),
                items: FinanceCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(_categoryLabel(category)),
                      ),
                    )
                    .toList(),
                onChanged: submitting
                    ? null
                    : (value) => refreshDialog(() => mainCategory = value),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('finite-installment-fee'),
                controller: feeController,
                enabled: !submitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => refreshDialog(() {}),
                decoration: _inputDecoration(
                  'Commissione bancaria (facoltativa)',
                ),
              ),
              if (fee != null && fee > 0) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<FinanceCategory>(
                  key: const Key('finite-installment-fee-category'),
                  initialValue: feeCategory,
                  decoration: _inputDecoration('Categoria commissione'),
                  items: FinanceCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(_categoryLabel(category)),
                        ),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (value) => refreshDialog(() => feeCategory = value),
                ),
              ],
              if (formError != null) ...[
                const SizedBox(height: 12),
                Text(
                  formError!,
                  key: const Key('finite-installment-error'),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('confirm-finite-plan-installment'),
                  onPressed: submitting ? null : submit,
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(submitting ? 'Registrazione…' : 'Conferma'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddFiniteFinancialPlanDialog() async {
    final nameController = TextEditingController();
    final creditorController = TextEditingController();
    final totalController = TextEditingController();
    final amountController = TextEditingController();
    final completedController = TextEditingController(text: '0');
    var selectedSubject = FinanceSubject.shared;
    String? selectedBalanceId = financeStore.balances
        .where((balance) => balance.active)
        .map((balance) => balance.balanceId)
        .cast<String?>()
        .firstOrNull;
    DateTime? selectedDate;
    String? formError;

    await _showFinanceDialog(
      icon: Icons.event_note_rounded,
      color: const Color(0xFF6D4C41),
      title: 'Nuovo piano finanziario',
      subtitle: 'Piano rateale senza movimenti economici',
      child: StatefulBuilder(
        builder: (context, refreshDialog) {
          Future<void> save() async {
            final name = nameController.text.trim();
            final creditor = creditorController.text.trim();
            final total = int.tryParse(totalController.text.trim());
            final amount = double.tryParse(
              amountController.text.trim().replaceAll(',', '.'),
            );
            final completed = int.tryParse(completedController.text.trim());
            final activeBalanceIds = financeStore.balances
                .where((balance) => balance.active)
                .map((balance) => balance.balanceId)
                .toSet();

            if (name.isEmpty ||
                creditor.isEmpty ||
                total == null ||
                amount == null ||
                completed == null ||
                selectedDate == null ||
                selectedBalanceId == null ||
                !activeBalanceIds.contains(selectedBalanceId)) {
              refreshDialog(() {
                formError = 'Compila tutti i campi con valori validi.';
              });
              return;
            }

            try {
              final now = DateTime.now();
              final plan = FiniteFinancialPlan(
                id: 'finite_plan_${now.microsecondsSinceEpoch}',
                name: name,
                creditor: creditor,
                subject: selectedSubject,
                debitBalanceId: selectedBalanceId,
                totalInstallments: total,
                expectedInstallmentAmount: amount,
                firstInstallmentDate: selectedDate!,
                scheduledDayOfMonth: selectedDate!.day,
                completedInstallments: completed,
              );
              final saved = await financeStore.addFiniteFinancialPlan(plan);
              if (!saved) {
                throw StateError('Il piano esiste già.');
              }
              if (!mounted || !context.mounted) return;
              setState(() {});
              Navigator.of(context).pop();
            } catch (error) {
              if (!context.mounted) return;
              refreshDialog(() {
                formError = 'Impossibile salvare il piano: $error';
              });
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('finite-plan-name'),
                controller: nameController,
                decoration: _inputDecoration('Nome piano'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('finite-plan-creditor'),
                controller: creditorController,
                decoration: _inputDecoration('Creditore'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FinanceSubject>(
                key: const Key('finite-plan-subject'),
                initialValue: selectedSubject,
                decoration: _inputDecoration('Soggetto'),
                items: FinanceSubject.values
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(_financeSubjectLabel(subject)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  refreshDialog(() => selectedSubject = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('finite-plan-balance'),
                initialValue: selectedBalanceId,
                decoration: _inputDecoration('Conto di addebito'),
                items: financeStore.balances
                    .where((balance) => balance.active)
                    .map(
                      (balance) => DropdownMenuItem(
                        value: balance.balanceId,
                        child: Text(balance.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  refreshDialog(() => selectedBalanceId = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('finite-plan-total'),
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Numero totale rate'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('finite-plan-amount'),
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration('Importo previsto rata'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('finite-plan-first-date'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200),
                  );
                  if (picked != null) {
                    refreshDialog(() => selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(
                  selectedDate == null
                      ? 'Data prima rata'
                      : 'Data prima rata: ${_formatDate(selectedDate!)}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('finite-plan-completed'),
                controller: completedController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Rate già completate'),
              ),
              if (formError != null) ...[
                const SizedBox(height: 12),
                Text(
                  formError!,
                  key: const Key('finite-plan-error'),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('save-finite-financial-plan'),
                  onPressed: save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Salva piano'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _financeSubjectLabel(FinanceSubject subject) {
    switch (subject) {
      case FinanceSubject.matteo:
        return 'Matteo';
      case FinanceSubject.chiara:
        return 'Chiara';
      case FinanceSubject.alice:
        return 'Alice';
      case FinanceSubject.shared:
        return 'Condiviso';
    }
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
                      EuroFormatter.format(fund.amount),
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
            initialYear: widget.forecastReferenceTime?.year,
            projectionsForYear: _convergentYearProjections,
            resilienceForYear: _resilienceYear,
            onResilienceMonthTap: (assessment, color) async {
              await _showResilienceDetailDialog(assessment, color);
            },
            onMonthTap: (projection, color) async {
              await _showConvergentMonthDetailDialog(projection, color);
            },
          ),
        ],
      ),
    );
  }

  List<FinanceMonthProjection> _convergentYearProjections(int year) {
    final horizon = ExpenseProjectionHorizon(
      start: DateTime(year),
      end: DateTime(year, 12, 31, 23, 59, 59, 999, 999),
    );
    final incomes = const IncomeForecastReader().read(
      aggregate: financeStore.incomeAggregate,
      horizon: horizon,
    );
    final expenses = const FinanceForecastReader().read(
      expectedExpenses: financeStore.expectedExpenseAggregate,
      documentaryObligations: financeStore.documentaryObligationAggregate,
      finitePlans: financeStore.finiteFinancialPlans,
      referenceTime: widget.forecastReferenceTime ?? DateTime.now(),
      projectionHorizon: horizon,
    );
    return const FinanceTemporalProjectionReader().readYear(
      year: year,
      incomes: incomes,
      expenses: expenses,
    );
  }

  List<ResilienceAssessment> _resilienceYear(int year) {
    final reference = widget.forecastReferenceTime ?? DateTime.now();
    final horizon = ExpenseProjectionHorizon(
      start: DateTime(year),
      end: DateTime(year, 12, 31, 23, 59, 59, 999, 999),
    );
    final incomes = const IncomeForecastReader().read(
      aggregate: financeStore.incomeAggregate,
      horizon: horizon,
    );
    final expenses = const FinanceForecastReader().read(
      expectedExpenses: financeStore.expectedExpenseAggregate,
      documentaryObligations: financeStore.documentaryObligationAggregate,
      finitePlans: financeStore.finiteFinancialPlans,
      referenceTime: reference,
      projectionHorizon: horizon,
    );
    return const HouseholdResilienceReader().readYear(
      year: year,
      referenceTime: reference,
      financeStore: financeStore,
      cashWalletStore: widget.cashWalletStore,
      incomes: incomes,
      expenses: expenses,
      activeRealExpenseEconomicFactIds: widget.expenseStore.all
          .map((item) => item.economicFactId)
          .whereType<String>(),
    );
  }

  Future<void> _showResilienceDetailDialog(
    ResilienceAssessment assessment,
    Color color,
  ) async {
    await _showFinanceDialog(
      icon: Icons.health_and_safety_outlined,
      color: color,
      title: DateFormat('MMMM yyyy', 'it_IT').format(assessment.month),
      subtitle: assessment.phase == ResiliencePhase.realized
          ? 'Realtà osservata'
          : 'Sostenibilità secondo le informazioni disponibili',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Entrate', EuroFormatter.format(assessment.inflow)),
          _detailRow('Uscite', EuroFormatter.format(assessment.outflow)),
          if (assessment.phase == ResiliencePhase.realized) ...[
            const SizedBox(height: 12),
            const Text(
              'Fatti economici',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            if (assessment.items.isEmpty)
              const Text('Nessun fatto economico registrato per il mese.'),
            ...assessment.items.map(_resilienceItemTile),
          ],
          if (assessment.phase != ResiliencePhase.realized) ...[
            _detailRow(
              'Liquidità prevista a fine mese',
              EuroFormatter.format(assessment.projectedClosingLiquidity),
            ),
            _detailRow(
              'Minimo previsto',
              EuroFormatter.format(assessment.minimumProjectedLiquidity),
            ),
          ],
          const SizedBox(height: 12),
          ...assessment.explanations.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(text),
            ),
          ),
          if (assessment.alternatives.isNotEmpty) ...[
            const Divider(),
            const Text(
              'Alternative conosciute',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            ...assessment.alternatives.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.explanation),
                subtitle: item.requiresApproval
                    ? const Text('Richiede consenso o verifica')
                    : null,
              ),
            ),
          ],
          if (assessment.people.isNotEmpty) ...[
            const Divider(),
            const Text(
              'Persone',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            ...assessment.people.map(_personResilienceTile),
          ],
          if (assessment.coverage.partial) ...[
            const Divider(),
            Text(
              assessment.coverageTitle,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(assessment.coverageExplanation),
          ],
        ],
      ),
    );
  }

  Widget _resilienceItemTile(ResilienceLineItem item) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(item.label),
    subtitle: Text(
      [
        if (item.date != null) DateFormat('dd/MM/yyyy').format(item.date!),
        if (item.ownerId != null) _displayOwner(item.ownerId!),
        if (item.balanceLabel != null) item.balanceLabel!,
      ].join(' • '),
    ),
    trailing: Text(
      EuroFormatter.formatSigned(
        item.direction == FinancialEventDirection.income
            ? item.amount
            : -item.amount,
      ),
      style: TextStyle(
        color: item.direction == FinancialEventDirection.income
            ? const Color(0xFF43A047)
            : const Color(0xFFE53935),
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _personResilienceTile(PersonResilienceDetail detail) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(_displayOwner(detail.ownerId)),
    subtitle: Text(
      'Liquidità ${EuroFormatter.format(detail.liquidity)} • '
      'Entrate ${EuroFormatter.format(detail.inflow)} • '
      'Uscite ${EuroFormatter.format(detail.outflow)}',
    ),
    children: [
      ...detail.resources.map(
        (resource) => ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 12),
          title: Text(resource.label),
          trailing: Text(EuroFormatter.format(resource.amount)),
        ),
      ),
      ...detail.items.map(_resilienceItemTile),
    ],
  );

  String _displayOwner(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  Future<void> _showConvergentMonthDetailDialog(
    FinanceMonthProjection projection,
    Color color,
  ) async {
    final month = DateTime(projection.month.year, projection.month.month);
    final horizon = ExpenseProjectionHorizon(
      start: month,
      end: DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999, 999),
    );
    final incomes = const IncomeForecastReader()
        .read(aggregate: financeStore.incomeAggregate, horizon: horizon)
        .itemsForMonth(month);
    final expenses = const FinanceForecastReader()
        .read(
          expectedExpenses: financeStore.expectedExpenseAggregate,
          documentaryObligations: financeStore.documentaryObligationAggregate,
          finitePlans: financeStore.finiteFinancialPlans,
          referenceTime: widget.forecastReferenceTime ?? DateTime.now(),
          projectionHorizon: horizon,
        )
        .economicItemsForMonth(month);
    await _showFinanceDialog(
      icon: Icons.calendar_month_rounded,
      color: color,
      title: DateFormat('MMMM yyyy', 'it_IT').format(month),
      subtitle: 'Dettaglio economico del mese',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entrate ${EuroFormatter.format(projection.expectedIncome)} • Uscite ${EuroFormatter.format(projection.expectedExpenses)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          const Text(
            'Entrate',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (incomes.isEmpty)
            const ListTile(
              title: Text('Nessuna entrata economicamente collocata'),
            ),
          ...incomes.map(
            (item) => ListTile(
              title: Text(item.label),
              subtitle: Text(_formatDate(item.economicDate)),
              trailing: Text(EuroFormatter.format(item.amount)),
            ),
          ),
          const Divider(),
          const Text(
            'Uscite',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (expenses.isEmpty)
            const ListTile(
              title: Text('Nessuna uscita economicamente collocata'),
            ),
          ...expenses.map(
            (item) => ListTile(
              title: Text(item.label),
              subtitle: Text(
                item.economicStart == null
                    ? 'Data economica non disponibile'
                    : _formatDate(item.economicStart!),
              ),
              trailing: Text(EuroFormatter.format(item.amount)),
            ),
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

  // ignore: unused_element
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

  // ignore: unused_element
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
                  .where((item) => item.isIncome == isIncome && !item.confirmed)
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
              EuroFormatter.formatSigned(
                item.isIncome ? item.expectedAmount : -item.expectedAmount,
              ),
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
            EuroFormatter.formatSigned(
              item.isIncome ? item.expectedAmount : -item.expectedAmount,
            ),
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
            EuroFormatter.format(item.expectedAmount),
          ),
          if (item.realAmount != null)
            _detailRow("Importo reale", EuroFormatter.format(item.realAmount!)),
          _detailRow("Ricorrenza", _recurringTypeLabel(item.recurringType)),
          _detailRow("Proprietario", _ownerLabel(item.paymentOwner)),
          _detailRow("Metodo", _paymentMethodLabel(item.paymentMethod)),
          _detailRow("Categoria", _categoryLabel(item.category)),
          _detailRow("Stato", item.confirmed ? "Confermato" : "Da confermare"),
          _detailRow(
            "Obbligatorietà",
            item.mandatory ? "Obbligatoria" : "Flessibile",
          ),
          _detailRow("Priorità", item.paymentPriority.name),
          _detailRow("Variabilità", item.variability.name),
          _detailRow("Protezione", item.protectionLevel.name),
          _detailRow("Stabilità", item.stability.name),
          _detailRow("Rischio sospensione", item.suspensionRisk.name),
          if (item.splits.isNotEmpty)
            _detailRow(
              "Ripartizione",
              item.splits
                  .map(
                    (split) =>
                        '${split.personId}: ${EuroFormatter.format(split.amount)}',
                  )
                  .join(' · '),
            ),
          _detailRow(
            "Comportamento",
            [
              if (item.behaviorProfile.timeSensitive) 'sensibile al tempo',
              if (item.behaviorProfile.canBeDelayed) 'rinviabile',
              if (item.behaviorProfile.canBeSplit) 'divisibile',
              if (item.behaviorProfile.canBeReduced) 'riducibile',
            ].join(' · '),
          ),
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

    FinanceSmartTemplateType selectedTemplate = isIncome
        ? FinanceSmartTemplateType.salary
        : FinanceSmartTemplateType.generic;
    bool useCustomSplit = existing?.splits.isNotEmpty ?? false;
    double splitPercentage(String personId) {
      if (existing == null || existing.expectedAmount == 0) return 50;
      final matches = existing.splits.where(
        (split) => split.personId == personId,
      );
      if (matches.isEmpty) return 50;
      return matches.first.amount / existing.expectedAmount * 100;
    }

    final matteoPercentageController = TextEditingController(
      text: splitPercentage('matteo').toStringAsFixed(0),
    );
    final chiaraPercentageController = TextEditingController(
      text: splitPercentage('chiara').toStringAsFixed(0),
    );
    bool mandatory = existing?.mandatory ?? !isIncome;
    FinancePaymentPriority selectedPriority =
        existing?.paymentPriority ?? FinancePaymentPriority.normal;
    FinanceVariability selectedVariability =
        existing?.variability ?? FinanceVariability.variable;
    FinanceProtectionLevel selectedProtection =
        existing?.protectionLevel ?? FinanceProtectionLevel.none;
    FinanceStability selectedStability =
        existing?.stability ?? FinanceStability.stable;
    FinanceSuspensionRisk selectedSuspensionRisk =
        existing?.suspensionRisk ?? FinanceSuspensionRisk.low;
    var behavior = existing?.behaviorProfile ?? const FinanceBehaviorProfile();

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
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Opzioni avanzate'),
                subtitle: const Text('Template, ripartizione e rischio'),
                children: [
                  DropdownButtonFormField<FinanceSmartTemplateType>(
                    initialValue: selectedTemplate,
                    decoration: _inputDecoration('Smart template'),
                    items: financeSmartTemplates.map((template) {
                      return DropdownMenuItem(
                        value: template.type,
                        child: Text(template.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final defaults = FinanceRecurringCoordinator(
                        financeStore: financeStore,
                      ).defaultsFor(value);
                      refreshDialog(() {
                        selectedTemplate = value;
                        selectedPaymentMethod = defaults.paymentMethod;
                        selectedCategory = defaults.category;
                        behavior = defaults.behaviorProfile;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ripartizione personalizzata'),
                    value: useCustomSplit,
                    onChanged: (value) =>
                        refreshDialog(() => useCustomSplit = value),
                  ),
                  if (useCustomSplit)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: matteoPercentageController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Matteo %'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: chiaraPercentageController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Chiara %'),
                          ),
                        ),
                      ],
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Obbligatoria'),
                    value: mandatory,
                    onChanged: (value) =>
                        refreshDialog(() => mandatory = value),
                  ),
                  DropdownButtonFormField<FinancePaymentPriority>(
                    initialValue: selectedPriority,
                    decoration: _inputDecoration('Priorità'),
                    items: FinancePaymentPriority.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refreshDialog(
                      () => selectedPriority = value ?? selectedPriority,
                    ),
                  ),
                  DropdownButtonFormField<FinanceVariability>(
                    initialValue: selectedVariability,
                    decoration: _inputDecoration('Variabilità'),
                    items: FinanceVariability.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refreshDialog(
                      () => selectedVariability = value ?? selectedVariability,
                    ),
                  ),
                  DropdownButtonFormField<FinanceProtectionLevel>(
                    initialValue: selectedProtection,
                    decoration: _inputDecoration('Protezione'),
                    items: FinanceProtectionLevel.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refreshDialog(
                      () => selectedProtection = value ?? selectedProtection,
                    ),
                  ),
                  DropdownButtonFormField<FinanceStability>(
                    initialValue: selectedStability,
                    decoration: _inputDecoration('Stabilità'),
                    items: FinanceStability.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refreshDialog(
                      () => selectedStability = value ?? selectedStability,
                    ),
                  ),
                  DropdownButtonFormField<FinanceSuspensionRisk>(
                    initialValue: selectedSuspensionRisk,
                    decoration: _inputDecoration('Rischio sospensione'),
                    items: FinanceSuspensionRisk.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => refreshDialog(
                      () => selectedSuspensionRisk =
                          value ?? selectedSuspensionRisk,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sensibile al tempo'),
                    value: behavior.timeSensitive,
                    onChanged: (value) => refreshDialog(
                      () => behavior = behavior.copyWith(timeSensitive: value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Può essere rinviata'),
                    value: behavior.canBeDelayed,
                    onChanged: (value) => refreshDialog(
                      () => behavior = behavior.copyWith(canBeDelayed: value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Può essere suddivisa'),
                    value: behavior.canBeSplit,
                    onChanged: (value) => refreshDialog(
                      () => behavior = behavior.copyWith(canBeSplit: value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Può essere ridotta'),
                    value: behavior.canBeReduced,
                    onChanged: (value) => refreshDialog(
                      () => behavior = behavior.copyWith(canBeReduced: value),
                    ),
                  ),
                ],
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

                    final customInterval =
                        selectedRecurringType == FinanceRecurringType.custom
                        ? int.tryParse(customIntervalController.text.trim()) ??
                              1
                        : null;

                    final draft = FinanceRecurringDraft(
                      existing: existing,
                      name: name,
                      description: descriptionController.text.trim(),
                      expectedAmount: amount,
                      nextDueDate: selectedDate,
                      isIncome: isIncome,
                      recurringType: selectedRecurringType,
                      customInterval: customInterval,
                      category: selectedCategory,
                      paymentOwner: selectedOwner,
                      subject: selectedSubject,
                      balanceId: selectedBalanceId,
                      paymentMethod: selectedPaymentMethod,
                      templateType: selectedTemplate,
                      matteoPercentage: useCustomSplit
                          ? double.tryParse(matteoPercentageController.text)
                          : null,
                      chiaraPercentage: useCustomSplit
                          ? double.tryParse(chiaraPercentageController.text)
                          : null,
                      mandatory: mandatory,
                      paymentPriority: selectedPriority,
                      variability: selectedVariability,
                      protectionLevel: selectedProtection,
                      stability: selectedStability,
                      suspensionRisk: selectedSuspensionRisk,
                      behaviorProfile: behavior,
                    );

                    final coordinator = FinanceRecurringCoordinator(
                      financeStore: financeStore,
                    );
                    final validationError = coordinator.validate(draft);
                    if (validationError != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(validationError)));
                      return;
                    }
                    await coordinator.save(draft);

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
              EuroFormatter.format(amount),
              style: TextStyle(
                color: Colors.white.withOpacity(0.88),
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Previsione fine mese: ${EuroFormatter.format(availableThisMonth)}",
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
