import 'package:flutter/material.dart';

class HiddenAliceEventsLink extends StatelessWidget {
  final int hiddenCount;
  final VoidCallback onTap;

  const HiddenAliceEventsLink({
    super.key,
    required this.hiddenCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hiddenCount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            "+$hiddenCount altri eventi",
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
