import 'package:flutter/material.dart';

import '../../models/frodo_observation.dart';
import 'frodo_reason_narrator.dart';

class FrodoReasonStory extends StatelessWidget {
  final FrodoObservation observation;

  const FrodoReasonStory({super.key, required this.observation});

  @override
  Widget build(BuildContext context) {
    final explanations = _visibleExplanations(observation.explanations);

    if (explanations.isEmpty) {
      return const _EmptyReasonStory();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < explanations.length; i++) ...[
          _ReasonStoryStep(
            explanation: explanations[i],
            isLast: i == explanations.length - 1,
          ),
        ],
        const SizedBox(height: 12),
        _StoryConclusion(observation: observation),
      ],
    );
  }

  List<FrodoObservationExplanation> _visibleExplanations(
    List<FrodoObservationExplanation> explanations,
  ) {
    if (explanations.length <= 1) {
      return explanations;
    }

    return explanations
        .where((explanation) => explanation.reasonKey != 'generic')
        .toList();
  }
}

class _ReasonStoryStep extends StatelessWidget {
  final FrodoObservationExplanation explanation;
  final bool isLast;

  const _ReasonStoryStep({required this.explanation, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = _explanationLevelColor(explanation.level);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineMarker(color: color, isLast: isLast),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: _StoryBox(
              title: FrodoReasonNarrator.stepTitle(explanation),
              message: _bodyForExplanation(explanation),
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  String _bodyForExplanation(FrodoObservationExplanation explanation) {
    final parts = explanation.message.split('\n');

    if (parts.length > 1) {
      return parts.skip(1).join('\n').trim();
    }

    return explanation.message.trim();
  }
}

class _StoryConclusion extends StatelessWidget {
  final FrodoObservation observation;

  const _StoryConclusion({required this.observation});

  @override
  Widget build(BuildContext context) {
    return _StoryBox(
      title: '✅ Conclusione',
      message: FrodoReasonNarrator.conclusion(observation),
      color: _observationLevelColor(observation.level),
    );
  }
}

class _StoryBox extends StatelessWidget {
  final String title;
  final String message;
  final Color color;

  const _StoryBox({
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13.2,
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 12.25,
              fontWeight: FontWeight.w700,
              height: 1.30,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  final Color color;
  final bool isLast;

  const _TimelineMarker({required this.color, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.40)),
          ),
          child: Icon(Icons.circle_rounded, color: color, size: 10),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.24),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _EmptyReasonStory extends StatelessWidget {
  const _EmptyReasonStory();

  @override
  Widget build(BuildContext context) {
    return _StoryBox(
      title: '💭 Ragionamento non disponibile',
      message:
          'Frodo non ha ancora motivazioni dettagliate da mostrare per questa osservazione.',
      color: const Color(0xFF90A4AE),
    );
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
