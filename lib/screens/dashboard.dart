import 'package:flutter/material.dart';

class SpesePage extends StatelessWidget {
  const SpesePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestione Spese")),
      body: ListView( // Usiamo ListView per evitare che il contenuto esca dallo schermo
        padding: const EdgeInsets.all(16),
        children: const [
          Card(child: ListTile(title: Text("Bolletta Luce"), subtitle: Text("Scadenza: 20/03"), trailing: Text("€ 85"))),
          Card(child: ListTile(title: Text("Affitto"), subtitle: Text("Scadenza: 01/04"), trailing: Text("€ 600"))),
          // Qui potrai aggiungere infinite righe senza rompere la Dashboard!
        ],
      ),
    );
  }
}