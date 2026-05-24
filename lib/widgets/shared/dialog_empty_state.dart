import 'package:flutter/material.dart';

class DialogEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const DialogEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.black.withOpacity(0.45)),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
