import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/frododesk_modules.dart';
import '../../engines/observation/observation_engine.dart';
import '../../models/frodo_observation.dart';

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
            child: Container(color: Colors.black.withOpacity(0.30)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const Text(
                      'Cosa sta osservando FrodoDesk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${observations.length} osservazioni economiche attive',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (observations.isEmpty)
                      const _ObservationEmptyCard()
                    else
                      ...observations.map(
                        (observation) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
    final color = _levelColor(observation.level);
    final icon = _levelIcon(observation.level);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      observation.message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.30,
                      ),
                    ),
                    if (observation.targetDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Data collegata: ${observation.targetDate!.day.toString().padLeft(2, '0')}/${observation.targetDate!.month.toString().padLeft(2, '0')}/${observation.targetDate!.year}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (observation.action != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(observation.action!.label),
                        ),
                      ),
                    ],
                    if (observation.details != null &&
                        observation.details!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Dettaglio',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                          observation.details!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.30,
                          ),
                        ),
                      ),
                    ],

                    if (observation.impact != null &&
                        observation.impact!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Impatto',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                          observation.impact!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.30,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _levelDescription(observation.level),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _levelColor(FrodoObservationLevel level) {
    switch (level) {
      case FrodoObservationLevel.problem:
        return const Color(0xFFE53935);
      case FrodoObservationLevel.attention:
        return const Color(0xFFFFB74D);
      case FrodoObservationLevel.opportunity:
        return const Color(0xFF42A5F5);
      case FrodoObservationLevel.success:
        return const Color(0xFF66BB6A);
      case FrodoObservationLevel.info:
        return const Color(0xFF90A4AE);
    }
  }

  IconData _levelIcon(FrodoObservationLevel level) {
    switch (level) {
      case FrodoObservationLevel.problem:
        return Icons.error_rounded;
      case FrodoObservationLevel.attention:
        return Icons.warning_amber_rounded;
      case FrodoObservationLevel.opportunity:
        return Icons.lightbulb_rounded;
      case FrodoObservationLevel.success:
        return Icons.check_circle_rounded;
      case FrodoObservationLevel.info:
        return Icons.info_rounded;
    }
  }

  String _levelDescription(FrodoObservationLevel level) {
    switch (level) {
      case FrodoObservationLevel.problem:
        return "Problema";
      case FrodoObservationLevel.attention:
        return "Richiede attenzione";
      case FrodoObservationLevel.opportunity:
        return "Opportunità";
      case FrodoObservationLevel.success:
        return "Situazione positiva";
      case FrodoObservationLevel.info:
        return "Informazione";
    }
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
