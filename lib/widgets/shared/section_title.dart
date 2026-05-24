import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: Colors.black.withOpacity(0.86),
        ),
      ),
    );
  }
}
