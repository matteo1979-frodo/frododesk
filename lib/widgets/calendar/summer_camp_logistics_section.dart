import 'package:flutter/material.dart';

import '../../logic/calendar/models/alice_summer_camp_logistics.dart';
import '../../logic/calendar/view_models/alice_summer_camp_logistics_view_model.dart';

class SummerCampLogisticsSection extends StatelessWidget {
  final AliceSummerCampLogisticsViewModel model;
  final ValueChanged<AliceLogisticProviderRef?> onDropOffChanged;
  final ValueChanged<AliceLogisticProviderRef?> onPickUpChanged;

  const SummerCampLogisticsSection({
    super.key,
    required this.model,
    required this.onDropOffChanged,
    required this.onPickUpChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        model.sectionTitle,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      _Leg(model: model.dropOff, onChanged: onDropOffChanged),
      const SizedBox(height: 12),
      _Leg(model: model.pickUp, onChanged: onPickUpChanged),
      if (model.hasLogisticGaps) ...[
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Buchi logistici',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        ...model.logisticGaps.map(
          (gap) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gap.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(gap.description),
                if (gap.alternatives.isNotEmpty)
                  Text(_alternativesText(gap.alternatives)),
              ],
            ),
          ),
        ),
        _Count(
          model.logisticGapCount == 1
              ? '1 buco logistico'
              : '${model.logisticGapCount} buchi logistici',
        ),
      ],
    ],
  );
}

class _Leg extends StatelessWidget {
  final AliceSummerCampLogisticLegViewModel model;
  final ValueChanged<AliceLogisticProviderRef?> onChanged;
  const _Leg({required this.model, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = switch (model.visualState) {
      AliceSummerCampLogisticVisualState.success => Colors.green,
      AliceSummerCampLogisticVisualState.decision => Colors.amber.shade800,
      AliceSummerCampLogisticVisualState.conflict => Colors.orange.shade900,
      AliceSummerCampLogisticVisualState.gap => Colors.red,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AliceLogisticProviderOptionViewModel>(
          initialValue: model.options.firstWhere(
            (option) => option.provider == model.assignedProvider,
          ),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: '${model.fieldLabel} ${model.intervalLabel}',
          ),
          items: model.options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option.label)),
              )
              .toList(),
          onChanged: (option) {
            if (option != null) onChanged(option.provider);
          },
        ),
        const SizedBox(height: 6),
        Text(
          model.title,
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
        Text(model.description),
        if (model.alternatives.isNotEmpty)
          Text(_alternativesText(model.alternatives)),
        Text(model.realityText, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _alternativesText(List<String> alternatives) =>
    '${alternatives.length == 1 ? 'Alternativa disponibile' : 'Alternative disponibili'}: ${alternatives.join(', ')}.';

class _Count extends StatelessWidget {
  final String text;
  const _Count(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}
