// lib/screens/copertura_screen.dart
import 'package:flutter/material.dart';
import '../logic/core_store.dart';

class CoperturaScreen extends StatelessWidget {
  final CoreStore coreStore;

  const CoperturaScreen({super.key, required this.coreStore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copertura')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copertura (debug)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Sandra globale: ${coreStore.settingsStore.isSandraDisponibile}',
            ),
            Text('Uscita 13 globale: ${coreStore.settingsStore.isUscita13}'),
            const SizedBox(height: 12),
            const Text(
              'Questa schermata è temporanea.\nServe solo a far compilare e non mischiare più store dentro le screen.',
            ),
          ],
        ),
      ),
    );
  }
}
