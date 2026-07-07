import 'package:flutter/material.dart';

class AliceEventsSection extends StatelessWidget {
  final Widget child;

  const AliceEventsSection({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.18)),
      ),
      child: child,
    );
  }
}
