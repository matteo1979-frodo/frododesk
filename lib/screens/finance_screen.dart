import 'package:flutter/material.dart';

import '../stores/finance_store.dart';
import '../widgets/finance/finance_info_card.dart';
import '../widgets/finance/finance_year_dashboard.dart';
import 'person_finance_screen.dart';

class FinanceScreen extends StatelessWidget {
  final FinanceStore financeStore;

  const FinanceScreen({super.key, required this.financeStore});

  @override
  Widget build(BuildContext context) {
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
                    _buildFrodoControlCard(),
                    const SizedBox(height: 18),
                    _buildMainNumbers(),
                    const SizedBox(height: 18),
                    _buildPeopleSection(context),
                    const SizedBox(height: 18),
                    _buildFundsSection(),
                    const SizedBox(height: 18),
                    _buildTemporalPressureSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrodoControlCard() {
    final nextItems = financeStore.futureRecurringItems();

    String message = "Nessuna criticità evidente nei prossimi giorni.";

    if (nextItems.isNotEmpty) {
      final first = nextItems.first;
      message =
          "Prossima scadenza: ${first.name} • €${first.expectedAmount.toStringAsFixed(0)}";
    }

    return _FinanceGlassCard(
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
                Text(
                  "Nota: FrodoDesk non è collegato alla banca. I saldi sono affidabili solo se aggiorni movimenti e spese reali.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonFinanceScreen(
                          financeStore: financeStore,
                          personId: "matteo",
                          personName: "Matteo",
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PersonBalanceCard(
                  name: "Chiara",
                  amount: financeStore.balanceForPerson("chiara"),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PersonFinanceScreen(
                          financeStore: financeStore,
                          personId: "chiara",
                          personName: "Chiara",
                        ),
                      ),
                    );
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
          const SizedBox(height: 12),
          FinanceYearDashboard(
            financeStore: financeStore,
            onMonthTap: (projection, color) async {},
          ),
        ],
      ),
    );
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
  final VoidCallback onTap;

  const _PersonBalanceCard({
    required this.name,
    required this.amount,
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
              "Apri conti",
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
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
