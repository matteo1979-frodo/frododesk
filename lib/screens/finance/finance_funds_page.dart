import 'package:flutter/material.dart';

import '../../logic/finance/finance_funds_coordinator.dart';
import '../../models/finance_fund.dart';
import '../../models/finance_funds_view_data.dart';
import '../../models/finance_asset_movement.dart';
import '../../widgets/shared/frodo_person_avatar.dart';

class FinanceFundsPage extends StatefulWidget {
  final FinanceFundsCoordinator coordinator;

  const FinanceFundsPage({super.key, required this.coordinator});

  @override
  State<FinanceFundsPage> createState() => _FinanceFundsPageState();
}

class _FinanceFundsPageState extends State<FinanceFundsPage> {
  @override
  Widget build(BuildContext context) {
    final viewData = widget.coordinator.build();
    final activeFunds = viewData.funds
        .where((item) => item.fund.status == FinanceFundStatus.active)
        .length;
    final closedFunds = viewData.funds.length - activeFunds;
    final pageTheme = Theme.of(context).copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFF6F4EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF263228),
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.82),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6D8B74), width: 2),
        ),
      ),
    );
    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1D12),
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.08),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Fondi famiglia',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.28)),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      _summaryCard(
                        total: viewData.totalAmount,
                        funds: viewData.funds.length,
                        active: activeFunds,
                        closed: closedFunds,
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final heading = const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I tuoi fondi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.35,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Obiettivi, riserve e protezioni della famiglia',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                          final action = FilledButton.icon(
                            onPressed: () => _editFund(),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD54F),
                              foregroundColor: const Color(0xFF243126),
                              elevation: 8,
                              shadowColor: Colors.black54,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.38),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 21,
                                vertical: 16,
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 22),
                            label: const Text(
                              'Nuovo fondo',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                          if (constraints.maxWidth < 430) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                heading,
                                const SizedBox(height: 12),
                                action,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: heading),
                              const SizedBox(width: 16),
                              action,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (viewData.funds.isEmpty)
                        _emptyFundsCard()
                      else
                        ...viewData.funds.map(
                          (item) => _fundCard(
                            item,
                            viewData.sources,
                            viewData.funds.map((entry) => entry.fund).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required double total,
    required int funds,
    required int active,
    required int closed,
  }) => Container(
    padding: const EdgeInsets.all(22),
    decoration: _glassDecoration(radius: 26),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;
        final totalBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: Color(0xFF90CAF9),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Patrimonio nei fondi',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _money(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ],
        );
        final metrics = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _summaryMetric('$funds', 'Totali', Icons.folder_outlined),
            _summaryMetric('$active', 'Attivi', Icons.check_circle_outline),
            _summaryMetric('$closed', 'Chiusi', Icons.archive_outlined),
          ],
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [totalBlock, const SizedBox(height: 20), metrics],
              )
            : Row(
                children: [
                  Expanded(child: totalBlock),
                  const SizedBox(width: 24),
                  metrics,
                ],
              );
      },
    ),
  );

  Widget _summaryMetric(String value, String label, IconData icon) => Container(
    width: 96,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _emptyFundsCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
    decoration: _glassDecoration(radius: 22),
    child: const Column(
      children: [
        Icon(Icons.savings_outlined, color: Colors.white54, size: 38),
        SizedBox(height: 12),
        Text(
          'Nessun fondo inserito',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Crea il primo fondo per separare una riserva o un obiettivo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.3),
        ),
      ],
    ),
  );

  Widget _fundCard(
    FinanceFundViewData item,
    List<FinanceFundSourceViewData> sources,
    List<FinanceFund> funds,
  ) {
    final fund = item.fund;
    final categoryColor = _categoryColor(fund.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: _glassDecoration(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.white.withValues(alpha: 0.06),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
          minTileHeight: 0,
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          title: LayoutBuilder(
            builder: (context, constraints) {
              final balanceWidth = (constraints.maxWidth * 0.26)
                  .clamp(72.0, 132.0)
                  .toDouble();
              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _fundCategoryIcon(fund.category, categoryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _displayFundName(fund.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _fundBalance(fund.amount, width: balanceWidth),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _fundIdentity(fund, categoryColor, showName: false),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _fundCategoryIcon(fund.category, categoryColor),
                  const SizedBox(width: 12),
                  Expanded(child: _fundIdentity(fund, categoryColor)),
                  const SizedBox(width: 12),
                  _fundBalance(fund.amount, width: balanceWidth),
                ],
              );
            },
          ),
          children: [
            Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
            if (fund.status == FinanceFundStatus.active)
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 18),
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _moveMoney(fund),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF90CAF9),
                        foregroundColor: const Color(0xFF102532),
                      ),
                      icon: const Icon(Icons.swap_vert_rounded),
                      label: const Text(
                        'Sposta denaro',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Modifica fondo',
                      onPressed: () => _editFund(existing: fund),
                      color: Colors.white70,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Chiudi fondo',
                      onPressed: () => _closeFund(fund),
                      color: const Color(0xFFEF9A9A),
                      icon: const Icon(Icons.archive_outlined),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CRONOLOGIA DEL FONDO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (item.assetMovements.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Nessuna operazione registrata',
                  style: TextStyle(color: Colors.white60),
                ),
              )
            else
              ...item.assetMovements.map(
                (movement) => _movementStory(
                  movement,
                  fund: fund,
                  sources: sources,
                  funds: funds,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _movementStory(
    FinanceAssetMovement movement, {
    required FinanceFund fund,
    required List<FinanceFundSourceViewData> sources,
    required List<FinanceFund> funds,
  }) {
    final fundDelta = movement.legs
        .where(
          (leg) =>
              leg.type == FinanceAssetLegType.fund &&
              leg.referenceId == fund.id,
        )
        .fold<double>(0, (sum, leg) => sum + leg.delta);
    final origins = movement.legs
        .where((leg) => leg.delta < 0)
        .map((leg) => _legLabel(leg, funds: funds, sources: sources))
        .join(' + ');
    final destinations = movement.legs
        .where((leg) => leg.delta > 0)
        .map((leg) => _legLabel(leg, funds: funds, sources: sources))
        .join(' + ');
    final color = _movementColor(movement.kind);
    final isInternal =
        movement.kind == FinanceAssetMovementKind.fundAllocation ||
        movement.kind == FinanceAssetMovementKind.fundRelease ||
        movement.kind == FinanceAssetMovementKind.fundTransferOut ||
        movement.kind == FinanceAssetMovementKind.fundTransferIn;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_movementIcon(movement.kind), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    Text(
                      _movementLabel(movement.kind),
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.65,
                      ),
                    ),
                    if (isInternal) _badge('INTERNO', const Color(0xFF90CAF9)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$origins  →  $destinations',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                if (movement.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    movement.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  _dateLabel(movement.occurredAt),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${fundDelta > 0
                ? '+'
                : fundDelta < 0
                ? '−'
                : ''}${_money(fundDelta.abs())}',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fundCategoryIcon(FinanceFundCategory category, Color color) =>
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Icon(_categoryIcon(category), color: color, size: 22),
      );

  Widget _fundIdentity(
    FinanceFund fund,
    Color categoryColor, {
    bool showName = true,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (showName) ...[
        Text(
          _displayFundName(fund.name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
      ],
      Wrap(
        spacing: 5,
        runSpacing: 4,
        children: [
          _badge(_categoryLabel(fund.category), categoryColor),
          _badge(
            fund.status == FinanceFundStatus.active ? 'ATTIVO' : 'CHIUSO',
            fund.status == FinanceFundStatus.active
                ? const Color(0xFF66BB6A)
                : const Color(0xFFB0BEC5),
          ),
          if (fund.protected)
            _badge(
              'PROTETTO',
              const Color(0xFFFFD54F),
              icon: Icons.shield_outlined,
            ),
        ],
      ),
      if (fund.description.trim().isNotEmpty) ...[
        const SizedBox(height: 5),
        Text(
          fund.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12.5,
            height: 1.25,
          ),
        ),
      ],
      if ((fund.status == FinanceFundStatus.closed && fund.closedAt != null) ||
          (fund.status == FinanceFundStatus.active &&
              fund.openedAt != null)) ...[
        const SizedBox(height: 5),
        Text(
          fund.status == FinanceFundStatus.closed && fund.closedAt != null
              ? 'Chiuso il ${_dateLabel(fund.closedAt!)}'
              : 'Aperto il ${_dateLabel(fund.openedAt!)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ],
  );

  Widget _fundBalance(double amount, {required double width}) => SizedBox(
    width: width,
    height: 46,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Align(
              alignment: Alignment.topRight,
              child: Text(
                'SALDO',
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.65,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                width: double.infinity,
                height: 20,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _money(amount),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _badge(String label, Color color, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ),
  );

  BoxDecoration _glassDecoration({required double radius}) => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );

  String _legLabel(
    FinanceAssetLeg leg, {
    required List<FinanceFund> funds,
    required List<FinanceFundSourceViewData> sources,
  }) {
    switch (leg.type) {
      case FinanceAssetLegType.balance:
        final source = sources
            .where((item) => item.balanceId == leg.referenceId)
            .firstOrNull;
        return source == null
            ? 'Conto della famiglia'
            : '${source.name} · ${source.ownerName}';
      case FinanceAssetLegType.fund:
        final involvedFund = funds
            .where((item) => item.id == leg.referenceId)
            .firstOrNull;
        return involvedFund == null
            ? 'Fondo della famiglia'
            : _displayFundName(involvedFund.name);
      case FinanceAssetLegType.openingBalance:
        return 'Saldo già esistente';
      case FinanceAssetLegType.expense:
        return 'Spesa sostenuta';
      case FinanceAssetLegType.legacyCounterpart:
        return 'Provenienza precedente';
    }
  }

  IconData _categoryIcon(FinanceFundCategory value) => switch (value) {
    FinanceFundCategory.emergency => Icons.health_and_safety_outlined,
    FinanceFundCategory.auto => Icons.directions_car_outlined,
    FinanceFundCategory.home => Icons.home_outlined,
    FinanceFundCategory.health => Icons.favorite_outline,
    FinanceFundCategory.school => Icons.school_outlined,
    FinanceFundCategory.generic => Icons.savings_outlined,
  };

  Color _categoryColor(FinanceFundCategory value) => switch (value) {
    FinanceFundCategory.emergency => const Color(0xFFFFB74D),
    FinanceFundCategory.auto => const Color(0xFF90CAF9),
    FinanceFundCategory.home => const Color(0xFFA1887F),
    FinanceFundCategory.health => const Color(0xFFEF9A9A),
    FinanceFundCategory.school => const Color(0xFFCE93D8),
    FinanceFundCategory.generic => const Color(0xFF80CBC4),
  };

  String _movementLabel(FinanceAssetMovementKind kind) => switch (kind) {
    FinanceAssetMovementKind.fundOpening => 'APERTURA',
    FinanceAssetMovementKind.fundAllocation => 'TRASFERIMENTO AL FONDO',
    FinanceAssetMovementKind.fundRelease => 'PRELIEVO DAL FONDO',
    FinanceAssetMovementKind.fundExpense => 'SPESA DAL FONDO',
    FinanceAssetMovementKind.fundTransferOut => 'TRASFERIMENTO IN USCITA',
    FinanceAssetMovementKind.fundTransferIn => 'TRASFERIMENTO IN ENTRATA',
    FinanceAssetMovementKind.legacyOpening => 'SALDO INIZIALE',
    FinanceAssetMovementKind.legacyUnclassified => 'OPERAZIONE PRECEDENTE',
  };

  IconData _movementIcon(FinanceAssetMovementKind kind) => switch (kind) {
    FinanceAssetMovementKind.fundOpening => Icons.flag_outlined,
    FinanceAssetMovementKind.fundAllocation => Icons.south_east_rounded,
    FinanceAssetMovementKind.fundRelease => Icons.north_west_rounded,
    FinanceAssetMovementKind.fundExpense => Icons.receipt_long_outlined,
    FinanceAssetMovementKind.fundTransferOut => Icons.swap_horiz_rounded,
    FinanceAssetMovementKind.fundTransferIn => Icons.swap_horiz_rounded,
    FinanceAssetMovementKind.legacyOpening => Icons.history_rounded,
    FinanceAssetMovementKind.legacyUnclassified => Icons.help_outline_rounded,
  };

  Color _movementColor(FinanceAssetMovementKind kind) => switch (kind) {
    FinanceAssetMovementKind.fundOpening ||
    FinanceAssetMovementKind.fundAllocation => const Color(0xFF81C784),
    FinanceAssetMovementKind.fundRelease => const Color(0xFF90CAF9),
    FinanceAssetMovementKind.fundExpense => const Color(0xFFEF9A9A),
    FinanceAssetMovementKind.fundTransferOut ||
    FinanceAssetMovementKind.fundTransferIn => const Color(0xFF90CAF9),
    FinanceAssetMovementKind.legacyOpening ||
    FinanceAssetMovementKind.legacyUnclassified => const Color(0xFFB0BEC5),
  };

  String _money(double value) => '€${value.toStringAsFixed(2)}';

  String _displayFundName(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  Future<void> _editFund({FinanceFund? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    final amount = TextEditingController(
      text: existing?.amount.toStringAsFixed(2) ?? '',
    );
    var category = existing?.category ?? FinanceFundCategory.generic;
    var protected = existing?.protected ?? false;
    var preExisting = true;
    final sources = widget.coordinator.build().sources;
    final selectedSources = <String>{};
    final sourceControllers = {
      for (final source in sources) source.balanceId: TextEditingController(),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) {
          final openingAmount = _parseAmount(amount.text);
          final portions = _selectedPortions(
            sources,
            selectedSources,
            sourceControllers,
          );
          final movedTotal = _portionsTotal(portions);
          final difference = openingAmount == null
              ? 0.0
              : openingAmount - movedTotal;
          final sourcesAreValid =
              portions.length == selectedSources.length &&
              portions.every(
                (portion) =>
                    portion.amount <=
                    sources
                        .firstWhere(
                          (source) => source.balanceId == portion.balanceId,
                        )
                        .availableAmount,
              );
          final canSave =
              name.text.trim().isNotEmpty &&
              (existing != null ||
                  (openingAmount != null &&
                      openingAmount > 0 &&
                      (preExisting ||
                          (selectedSources.isNotEmpty &&
                              sourcesAreValid &&
                              difference.abs() <= 0.001))));
          return AlertDialog(
            title: Text(existing == null ? 'Nuovo fondo' : 'Modifica fondo'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stepTitle(Icons.edit_outlined, 'Descrivi il fondo'),
                    TextField(
                      key: const Key('fund-name'),
                      controller: name,
                      onChanged: (_) => refresh(() {}),
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    TextField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Descrizione',
                      ),
                    ),
                    if (existing == null) ...[
                      TextField(
                        key: const Key('fund-opening-amount'),
                        controller: amount,
                        onChanged: (_) => refresh(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Saldo iniziale',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Saldo già esistente'),
                        subtitle: const Text(
                          'Il denaro era già nel fondo prima di FrodoDesk',
                        ),
                        value: preExisting,
                        onChanged: (value) => refresh(() {
                          preExisting = value;
                          if (value) selectedSources.clear();
                        }),
                      ),
                      if (!preExisting) ...[
                        _stepTitle(
                          Icons.account_balance_outlined,
                          'Da quali conti?',
                        ),
                        ...sources.map(
                          (source) => _accountChoice(
                            source: source,
                            selected: selectedSources.contains(
                              source.balanceId,
                            ),
                            controller: sourceControllers[source.balanceId]!,
                            amountLabel: 'Quanto prendi da questo conto?',
                            onSelected: (selected) => refresh(() {
                              if (selected) {
                                selectedSources.add(source.balanceId);
                              } else {
                                selectedSources.remove(source.balanceId);
                                sourceControllers[source.balanceId]!.clear();
                              }
                            }),
                            onAmountChanged: () => refresh(() {}),
                          ),
                        ),
                        _moneySummary(
                          total: movedTotal,
                          fundBalance: openingAmount ?? 0,
                          residual: openingAmount ?? 0,
                          difference: difference,
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    _stepTitle(Icons.tune, 'Scegli le caratteristiche'),
                    DropdownButtonFormField<FinanceFundCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: FinanceFundCategory.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_categoryLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          refresh(() => category = value ?? category),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fondo protetto'),
                      value: protected,
                      onChanged: (value) => refresh(() => protected = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                key: const Key('save-fund-button'),
                onPressed: !canSave
                    ? null
                    : () async {
                        final parsed = _parseAmount(amount.text)!;
                        if (existing == null) {
                          await widget.coordinator.openFund(
                            name: name.text.trim(),
                            description: description.text.trim(),
                            amount: parsed,
                            protected: protected,
                            category: category,
                            preExisting: preExisting,
                            sources: portions,
                          );
                        } else {
                          await widget.coordinator.updateDetails(
                            current: existing,
                            name: name.text.trim(),
                            description: description.text.trim(),
                            protected: protected,
                            category: category,
                          );
                        }
                        if (context.mounted) Navigator.pop(context, true);
                      },
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _moveMoney(FinanceFund fund, {bool close = false}) async {
    final description = TextEditingController();
    final amount = TextEditingController();
    var action = close
        ? _FundAction.returnToAccounts
        : _FundAction.addFromAccounts;
    final sources = widget.coordinator.build().sources;
    final destinationFunds = widget.coordinator
        .build()
        .funds
        .map((item) => item.fund)
        .where(
          (item) =>
              item.id != fund.id && item.status == FinanceFundStatus.active,
        )
        .toList();
    String? selectedDestinationFundId;
    final selectedSources = <String>{};
    final portionControllers = {
      for (final source in sources) source.balanceId: TextEditingController(),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) {
          final portions = _selectedPortions(
            sources,
            selectedSources,
            portionControllers,
          );
          final portionsTotal = _portionsTotal(portions);
          final spentAmount = _parseAmount(amount.text) ?? 0;
          final operationTotal =
              action == _FundAction.spend ||
                  action == _FundAction.transferToFund
              ? spentAmount
              : portionsTotal;
          final residual = action == _FundAction.addFromAccounts
              ? fund.amount + operationTotal
              : fund.amount - operationTotal;
          final accountsAreValid =
              selectedSources.isNotEmpty &&
              portions.length == selectedSources.length &&
              (action != _FundAction.addFromAccounts ||
                  portions.every(
                    (portion) =>
                        portion.amount <=
                        sources
                            .firstWhere(
                              (source) => source.balanceId == portion.balanceId,
                            )
                            .availableAmount,
                  ));
          final difference = close ? fund.amount - operationTotal : 0.0;
          final actionIsValid = switch (action) {
            _FundAction.spend => true,
            _FundAction.addFromAccounts ||
            _FundAction.returnToAccounts => accountsAreValid,
            _FundAction.transferToFund => selectedDestinationFundId != null,
          };
          final canRegister =
              operationTotal > 0 &&
              residual >= -0.001 &&
              actionIsValid &&
              (!close || difference.abs() <= 0.001);
          return AlertDialog(
            backgroundColor: const Color(0xFFF4F2EC),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            elevation: 24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
            ),
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
            actionsPadding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
            title: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF17351F), Color(0xFF284B31)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _categoryColor(
                        fund.category,
                      ).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _categoryColor(
                          fund.category,
                        ).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      _categoryIcon(fund.category),
                      color: _categoryColor(fund.category),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sposta denaro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_displayFundName(fund.name)} · ${_money(fund.amount)} disponibili',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chiudi',
                    onPressed: () => Navigator.pop(context, false),
                    color: Colors.white70,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _fundActionSelector(
                      action: action,
                      close: close,
                      canTransferBetweenFunds:
                          destinationFunds.isNotEmpty && !close,
                      onChanged: (value) => refresh(() {
                        action = value;
                        selectedDestinationFundId = null;
                        selectedSources.clear();
                        for (final controller in portionControllers.values) {
                          controller.clear();
                        }
                        amount.clear();
                      }),
                    ),
                    const SizedBox(height: 18),
                    if (action == _FundAction.spend)
                      _dialogSectionTitle(
                        Icons.receipt_long_outlined,
                        'Descrivi la spesa',
                        const Color(0xFFE57373),
                      )
                    else if (action == _FundAction.transferToFund)
                      _dialogSectionTitle(
                        Icons.savings_rounded,
                        'Verso quale fondo?',
                        const Color(0xFFB08D57),
                      )
                    else
                      _dialogSectionTitle(
                        Icons.account_balance_outlined,
                        action == _FundAction.addFromAccounts
                            ? 'Da quali conti?'
                            : 'Verso quali conti?',
                        const Color(0xFF4F86A6),
                      ),
                    TextField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Causale (facoltativa)',
                        hintText: 'Aggiungi il motivo del movimento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (action == _FundAction.spend)
                      TextField(
                        controller: amount,
                        key: const Key('fund-spend-amount'),
                        onChanged: (_) => refresh(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Importo speso',
                          prefixText: '€ ',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else if (action == _FundAction.transferToFund) ...[
                      ...destinationFunds.map(
                        (destination) => _fundDestinationChoice(
                          fund: destination,
                          selected: selectedDestinationFundId == destination.id,
                          onSelected: () => refresh(
                            () => selectedDestinationFundId = destination.id,
                          ),
                        ),
                      ),
                      TextField(
                        controller: amount,
                        key: const Key('fund-transfer-amount'),
                        onChanged: (_) => refresh(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Importo da trasferire',
                          prefixText: '€ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else
                      ...sources.map(
                        (source) => _accountChoice(
                          source: source,
                          selected: selectedSources.contains(source.balanceId),
                          controller: portionControllers[source.balanceId]!,
                          amountLabel: action == _FundAction.addFromAccounts
                              ? 'Quanto prendi da questo conto?'
                              : 'Quanto restituisci?',
                          onSelected: (selected) => refresh(() {
                            if (selected) {
                              selectedSources.add(source.balanceId);
                            } else {
                              selectedSources.remove(source.balanceId);
                              portionControllers[source.balanceId]!.clear();
                            }
                          }),
                          onAmountChanged: () => refresh(() {}),
                          financeStyle: true,
                        ),
                      ),
                    _moneySummary(
                      total: operationTotal,
                      fundBalance: fund.amount,
                      residual: residual,
                      difference: difference,
                      financeStyle: true,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF536358),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
                child: const Text(
                  'Annulla',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton(
                key: const Key('register-fund-operation'),
                onPressed: !canRegister
                    ? null
                    : () async {
                        if (action == _FundAction.spend) {
                          await widget.coordinator.spend(
                            fund.id,
                            spentAmount,
                            description.text.trim(),
                            close: close,
                          );
                        } else if (action == _FundAction.transferToFund) {
                          await widget.coordinator.transferBetweenFunds(
                            fund.id,
                            selectedDestinationFundId!,
                            spentAmount,
                            description.text.trim(),
                          );
                        } else if (action == _FundAction.addFromAccounts) {
                          await widget.coordinator.addFromAccounts(
                            fund.id,
                            portions,
                            description.text.trim(),
                          );
                        } else {
                          await widget.coordinator.returnToAccounts(
                            fund.id,
                            portions,
                            description.text.trim(),
                            close: close,
                          );
                        }
                        if (context.mounted) Navigator.pop(context, true);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6841),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD5D9D4),
                  disabledForegroundColor: const Color(0xFF8A938C),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Registra',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _closeFund(FinanceFund fund) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiudi fondo'),
        content: Text(
          'Come vuoi gestire i €${fund.amount.toStringAsFixed(2)} rimasti?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continua'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (fund.amount.abs() <= 0.001) {
      await widget.coordinator.closeEmpty(fund.id);
      if (mounted) setState(() {});
      return;
    }
    if (mounted) await _moveMoney(fund, close: true);
  }

  Widget _stepTitle(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    ),
  );

  Widget _dialogSectionTitle(IconData icon, String text, Color color) =>
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF26332A),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _fundActionSelector({
    required _FundAction action,
    required bool close,
    required bool canTransferBetweenFunds,
    required ValueChanged<_FundAction> onChanged,
  }) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.72),
          const Color(0xFFDDE5DE).withValues(alpha: 0.72),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF17351F).withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: SegmentedButton<_FundAction>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white.withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.06),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF173E26)
              : const Color(0xFF536358),
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF2F7A47)
              : const Color(0xFF718079),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const BorderSide(color: Color(0xFF69A77A), width: 1.35)
              : BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        elevation: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? 2 : 0,
        ),
        shadowColor: WidgetStatePropertyAll(
          const Color(0xFF2F6841).withValues(alpha: 0.18),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
      ),
      segments: [
        if (!close)
          const ButtonSegment(
            value: _FundAction.addFromAccounts,
            label: Text('Nel fondo'),
            icon: Icon(Icons.savings_rounded),
          ),
        const ButtonSegment(
          value: _FundAction.returnToAccounts,
          label: Text('Ai conti'),
          icon: Icon(Icons.account_balance_rounded),
        ),
        if (canTransferBetweenFunds)
          const ButtonSegment(
            value: _FundAction.transferToFund,
            label: Text('Tra fondi'),
            icon: Icon(Icons.swap_horiz_rounded),
          ),
        const ButtonSegment(
          value: _FundAction.spend,
          label: Text('Spesa'),
          icon: Icon(Icons.receipt_long_rounded),
        ),
      ],
      selected: {action},
      onSelectionChanged: (value) => onChanged(value.single),
    ),
  );

  Widget _fundDestinationChoice({
    required FinanceFund fund,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final color = _categoryColor(fund.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE9F2EA) : const Color(0xFFFAFAF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF3D7C50) : const Color(0xFFD8DDD7),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: Key('destination-fund-${fund.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_categoryIcon(fund.category), color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayFundName(fund.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF26332A),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _categoryLabel(fund.category),
                      style: const TextStyle(
                        color: Color(0xFF6B746E),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'SALDO',
                    style: TextStyle(
                      color: Color(0xFF7B847E),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _money(fund.amount),
                    style: const TextStyle(
                      color: Color(0xFF2F6841),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? const Color(0xFF3D7C50)
                    : const Color(0xFFA9B0AB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountChoice({
    required FinanceFundSourceViewData source,
    required bool selected,
    required TextEditingController controller,
    required String amountLabel,
    required ValueChanged<bool> onSelected,
    required VoidCallback onAmountChanged,
    bool financeStyle = false,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: financeStyle
        ? selected
              ? const Color(0xFFE4F0E6)
              : const Color(0xFFFAFAF7)
        : selected
        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
        : Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected
            ? financeStyle
                  ? const Color(0xFF3D7C50)
                  : Theme.of(context).colorScheme.primary
            : financeStyle
            ? const Color(0xFFD8DDD7)
            : Theme.of(context).colorScheme.outlineVariant,
        width: selected ? 1.5 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        InkWell(
          key: Key('fund-account-${source.balanceId}'),
          onTap: () => onSelected(!selected),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (financeStyle)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F86A6).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF4F86A6),
                      size: 22,
                    ),
                  )
                else
                  Checkbox(
                    value: selected,
                    onChanged: (value) => onSelected(value ?? false),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      financeStyle
                          ? Row(
                              children: [
                                FrodoPersonAvatar(
                                  category:
                                      FrodoPersonCategoryResolver.fromKnownName(
                                        source.ownerName,
                                      ),
                                  size: 20,
                                  semanticLabel: source.ownerName,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    source.ownerName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6B746E),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              source.ownerName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Saldo attuale',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '€${source.availableAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: financeStyle ? const Color(0xFF2F6841) : null,
                        fontSize: financeStyle ? 17 : null,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (selected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: TextField(
              key: Key('fund-amount-${source.balanceId}'),
              controller: controller,
              onChanged: (_) => onAmountChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: amountLabel,
                prefixText: '€ ',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _moneySummary({
    required double total,
    required double fundBalance,
    required double residual,
    required double difference,
    bool financeStyle = false,
  }) => Container(
    key: const Key('fund-operation-summary'),
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: financeStyle
          ? const Color(0xFFE7ECE6)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      border: financeStyle ? Border.all(color: const Color(0xFFD1D9D0)) : null,
    ),
    child: Column(
      children: [
        _summaryRow('Totale movimentato', total),
        _summaryRow('Saldo del fondo', fundBalance),
        _summaryRow('Saldo residuo del fondo', residual),
        if (difference.abs() > 0.001)
          _summaryRow('Differenza da completare', difference.abs()),
      ],
    ),
  );

  Widget _summaryRow(String label, double value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          '€${value.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  List<FinanceMoneyPortion> _selectedPortions(
    List<FinanceFundSourceViewData> sources,
    Set<String> selected,
    Map<String, TextEditingController> controllers,
  ) => sources
      .where((source) => selected.contains(source.balanceId))
      .map((source) {
        final value = _parseAmount(controllers[source.balanceId]!.text);
        return value == null || value <= 0
            ? null
            : FinanceMoneyPortion(balanceId: source.balanceId, amount: value);
      })
      .whereType<FinanceMoneyPortion>()
      .toList();

  double _portionsTotal(List<FinanceMoneyPortion> portions) =>
      portions.fold(0, (total, portion) => total + portion.amount);

  double? _parseAmount(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String _categoryLabel(FinanceFundCategory value) => switch (value) {
    FinanceFundCategory.emergency => 'Emergenze',
    FinanceFundCategory.auto => 'Auto',
    FinanceFundCategory.home => 'Casa',
    FinanceFundCategory.health => 'Salute',
    FinanceFundCategory.school => 'Scuola',
    FinanceFundCategory.generic => 'Generico',
  };

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

enum _FundAction { addFromAccounts, returnToAccounts, transferToFund, spend }
