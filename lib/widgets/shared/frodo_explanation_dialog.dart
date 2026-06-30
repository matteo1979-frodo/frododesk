import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/frodo_observation.dart';

Future<void> showFrodoExplanationDialog({
  required BuildContext context,
  required FrodoObservation observation,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => FrodoExplanationDialog(observation: observation),
  );
}

class FrodoExplanationDialog extends StatelessWidget {
  final FrodoObservation observation;

  const FrodoExplanationDialog({super.key, required this.observation});

  @override
  Widget build(BuildContext context) {
    final explanations = observation.explanations;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FrodoBrainIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Come ha ragionato Frodo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Ti mostro i controlli principali che hanno portato a questa osservazione.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 12.8,
                              fontWeight: FontWeight.w700,
                              height: 1.28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ObservationSummary(observation: observation),
                const SizedBox(height: 14),
                if (explanations.isEmpty)
                  const _EmptyExplanationState()
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < explanations.length; i++) ...[
                            _ExplanationTile(explanation: explanations[i]),
                            if (i != explanations.length - 1)
                              const SizedBox(height: 9),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Ho capito'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.16),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.white.withOpacity(0.16)),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ObservationSummary extends StatelessWidget {
  final FrodoObservation observation;

  const _ObservationSummary({required this.observation});

  @override
  Widget build(BuildContext context) {
    final color = _observationLevelColor(observation.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            observation.title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            observation.message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontSize: 12.4,
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationTile extends StatelessWidget {
  final FrodoObservationExplanation explanation;

  const _ExplanationTile({required this.explanation});

  @override
  Widget build(BuildContext context) {
    final color = _explanationLevelColor(explanation.level);
    final parts = explanation.message.split('\n');
    final title = parts.isNotEmpty ? parts.first.trim() : '💡 Valutazione';
    final body = parts.length > 1
        ? parts.skip(1).join('\n').trim()
        : explanation.message.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LevelDot(color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                if (body.isNotEmpty && body != title) ...[
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.66),
                      fontSize: 12.25,
                      fontWeight: FontWeight.w700,
                      height: 1.30,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExplanationState extends StatelessWidget {
  const _EmptyExplanationState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        'Frodo non ha ancora motivazioni dettagliate da mostrare per questa osservazione.',
        style: TextStyle(
          color: Colors.white.withOpacity(0.66),
          fontSize: 12.6,
          fontWeight: FontWeight.w700,
          height: 1.28,
        ),
      ),
    );
  }
}

class _FrodoBrainIcon extends StatelessWidget {
  const _FrodoBrainIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      alignment: Alignment.center,
      child: const Text('🧠', style: TextStyle(fontSize: 24)),
    );
  }
}

class _LevelDot extends StatelessWidget {
  final Color color;

  const _LevelDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Icon(_levelIcon(color), color: color, size: 16),
    );
  }

  IconData _levelIcon(Color color) {
    return Icons.circle_rounded;
  }
}

Color _observationLevelColor(FrodoObservationLevel level) {
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

Color _explanationLevelColor(FrodoObservationExplanationLevel level) {
  switch (level) {
    case FrodoObservationExplanationLevel.critical:
      return const Color(0xFFE53935);
    case FrodoObservationExplanationLevel.warning:
      return const Color(0xFFFFB74D);
    case FrodoObservationExplanationLevel.positive:
      return const Color(0xFF66BB6A);
    case FrodoObservationExplanationLevel.neutral:
      return const Color(0xFF90A4AE);
  }
}
