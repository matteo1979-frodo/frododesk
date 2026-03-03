import 'package:flutter/material.dart';

class SaluteScreen extends StatelessWidget {
  const SaluteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salute")),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Placeholder Salute\n\nQui entrerà: fragilità 30 giorni + appuntamenti + impatto IPS.",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
