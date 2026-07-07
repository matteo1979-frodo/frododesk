import 'package:flutter/material.dart';

class AliceSchoolHeader extends StatelessWidget {
  final String orario;
  final bool uscitaAnticipata;

  const AliceSchoolHeader({
    super.key,
    required this.orario,
    required this.uscitaAnticipata,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(orario),
        if (uscitaAnticipata) ...[
          const SizedBox(height: 6),
          const Text(
            "Uscita anticipata Alice scuola",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
