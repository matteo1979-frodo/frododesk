import 'package:flutter/material.dart';

import '../../core/frododesk_modules.dart';
import '../../engines/observation/observation_engine.dart';
import '../../models/frodo_observation.dart';
import '../../widgets/observation/expandable_list.dart';
import '../../widgets/observation/observation_card.dart';

class FinanceObservationsPage extends StatelessWidget {
  const FinanceObservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final observations = ObservationEngine.collectForModule(
      FrodoModules.finance,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F1D12),
      appBar: AppBar(
        title: const Text('Observation Finanze'),
        backgroundColor: Colors.black.withOpacity(0.08),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.34)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  children: [
                    const Text(
                      'Cosa sta osservando FrodoDesk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${observations.length} osservazioni economiche attive',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (observations.isEmpty)
                      const _ObservationEmptyCard()
                    else
                      ...observations.map(
                        (observation) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _FinanceObservationCard(
                            observation: observation,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceObservationCard extends StatelessWidget {
  final FrodoObservation observation;

  const _FinanceObservationCard({required this.observation});

  @override
  Widget build(BuildContext context) {
    final color = ObservationCard.levelColor(observation.level);

    return ObservationCard(
      observation: observation,
      details:
          observation.details == null || observation.details!.trim().isEmpty
          ? null
          : observation.title == 'Scadenze'
          ? _DeadlineSectionsBox(text: observation.details!, color: color)
          : _ObservationTextBox(text: observation.details!),
      impact: observation.impact == null || observation.impact!.trim().isEmpty
          ? null
          : _ImpactBox(text: observation.impact!, color: color),
      action: observation.action == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(observation.action!.label),
              ),
            ),
    );
  }
}

class _DeadlineSectionsBox extends StatelessWidget {
  final String text;
  final Color color;

  const _DeadlineSectionsBox({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final sections = text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          _DeadlineSectionTile(block: sections[i], color: color),
          if (i != sections.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DeadlineSectionTile extends StatelessWidget {
  final String block;
  final Color color;

  const _DeadlineSectionTile({required this.block, required this.color});

  @override
  Widget build(BuildContext context) {
    final lines = block
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final title = lines.isNotEmpty ? lines[0] : '';
    final status = lines.length > 1 ? lines[1] : '';
    final items = lines.length > 2 ? lines.skip(2).toList() : <String>[];

    final isEmpty = block.contains('Nessuna') && items.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DeadlineHeader(title: title, status: status),
          if (!isEmpty && items.isNotEmpty) ...[
            const SizedBox(height: 9),
            ExpandableList(items: items, accentColor: color, previewCount: 3),
          ],
        ],
      ),
    );
  }
}

class _DeadlineHeader extends StatelessWidget {
  final String title;
  final String status;

  const _DeadlineHeader({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontSize: 13.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (status.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            status,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _ObservationTextBox extends StatelessWidget {
  final String text;

  const _ObservationTextBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.11)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.78),
          fontSize: 12.8,
          fontWeight: FontWeight.w700,
          height: 1.32,
        ),
      ),
    );
  }
}

class _ImpactBox extends StatelessWidget {
  final String text;
  final Color color;

  const _ImpactBox({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObservationEmptyCard extends StatelessWidget {
  const _ObservationEmptyCard();

  @override
  Widget build(BuildContext context) {
    return _FinanceObservationCard(
      observation: FrodoObservation(
        id: 'finance_observations_empty',
        module: FrodoModules.finance,
        category: FrodoObservationCategory.finance,
        title: 'Nessuna osservazione',
        message:
            'Al momento FrodoDesk non rileva elementi economici da segnalare.',
        priority: 0,
        level: FrodoObservationLevel.info,
        createdAt: DateTime.now(),
      ),
    );
  }
}
