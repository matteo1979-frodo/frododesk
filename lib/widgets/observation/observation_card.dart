import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/frodo_observation.dart';

class ObservationCard extends StatelessWidget {
  final FrodoObservation observation;
  final Widget? details;
  final Widget? impact;
  final Widget? action;

  const ObservationCard({
    super.key,
    required this.observation,
    this.details,
    this.impact,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(observation.level);
    final icon = _levelIcon(observation.level);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.135),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ObservationIcon(color: color, icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      observation.message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 13.8,
                        fontWeight: FontWeight.w700,
                        height: 1.28,
                      ),
                    ),
                    if (observation.targetDate != null) ...[
                      const SizedBox(height: 8),
                      _SmallMetaLine(
                        icon: Icons.calendar_month_rounded,
                        text:
                            '${observation.targetDate!.day.toString().padLeft(2, '0')}/${observation.targetDate!.month.toString().padLeft(2, '0')}/${observation.targetDate!.year}',
                      ),
                    ],
                    if (details != null) ...[
                      const SizedBox(height: 12),
                      details!,
                    ],
                    if (observation.scenarios.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ScenariosBox(scenarios: observation.scenarios),
                    ],
                    if (observation.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _RecommendationsBox(
                        recommendations: observation.recommendations,
                        color: color,
                      ),
                    ],
                    if (impact != null) ...[
                      const SizedBox(height: 11),
                      impact!,
                    ],
                    if (action != null) ...[
                      const SizedBox(height: 12),
                      action!,
                    ],
                    const SizedBox(height: 11),
                    _StatusPill(
                      label: _levelDescription(observation.level),
                      color: color,
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

  static Color levelColor(FrodoObservationLevel level) {
    return _levelColor(level);
  }

  static Color _levelColor(FrodoObservationLevel level) {
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

  static IconData _levelIcon(FrodoObservationLevel level) {
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

  static String _levelDescription(FrodoObservationLevel level) {
    switch (level) {
      case FrodoObservationLevel.problem:
        return 'Problema';
      case FrodoObservationLevel.attention:
        return 'Richiede attenzione';
      case FrodoObservationLevel.opportunity:
        return 'Opportunità';
      case FrodoObservationLevel.success:
        return 'Situazione positiva';
      case FrodoObservationLevel.info:
        return 'Informazione';
    }
  }
}

class _ScenariosBox extends StatelessWidget {
  final List<FrodoObservationScenario> scenarios;

  const _ScenariosBox({required this.scenarios});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < scenarios.length; i++) ...[
          _ScenarioTile(scenario: scenarios[i]),
          if (i != scenarios.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  final FrodoObservationScenario scenario;

  const _ScenarioTile({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final color = ObservationCard.levelColor(scenario.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scenario.title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontSize: 13.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scenario.message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
          if (scenario.projectedBalance != null) ...[
            const SizedBox(height: 8),
            Text(
              'Saldo previsto: €${scenario.projectedBalance!.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (scenario.steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...scenario.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '✓ $step',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 12.4,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendationsBox extends StatelessWidget {
  final List<FrodoObservationRecommendation> recommendations;
  final Color color;

  const _RecommendationsBox({
    required this.recommendations,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...recommendations]
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Azioni consigliate',
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontSize: 13.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...sorted.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 12.6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (recommendation.description != null &&
                            recommendation.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            recommendation.description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.64),
                              fontSize: 12.1,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
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
}

class _ObservationIcon extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _ObservationIcon({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }
}

class _SmallMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallMetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.52)),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.58),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
