import 'package:flutter/material.dart';

import '../../utils/calendario_formatters.dart';

class SandraCompactRow extends StatelessWidget {
  final String title;
  final TimeOfDay start;
  final TimeOfDay end;
  final bool serve;
  final bool manual;
  final VoidCallback onEdit;
  final ValueChanged<bool> onChanged;

  const SandraCompactRow({
    super.key,
    required this.title,
    required this.start,
    required this.end,
    required this.serve,
    required this.manual,
    required this.onEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "$title   ${fmtTimeOfDay(start)}–${fmtTimeOfDay(end)}",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: "Modifica fascia",
                onPressed: onEdit,
              ),
              Switch(value: manual, onChanged: onChanged),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 2),
            child: _SandraNeedText(serve: serve, manual: manual),
          ),
        ],
      ),
    );
  }
}

class _SandraNeedText extends StatelessWidget {
  final bool serve;
  final bool manual;

  const _SandraNeedText({required this.serve, required this.manual});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    if (serve && manual) {
      text = "Serve dal motore • attivata manualmente";
      color = Colors.orange;
    } else if (serve) {
      text = "Serve dal motore";
      color = Colors.red;
    } else if (manual) {
      text = "Attivata manualmente";
      color = Colors.blueGrey;
    } else {
      text = "Non serve dal motore";
      color = Colors.green;
    }

    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}
