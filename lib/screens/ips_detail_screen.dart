// lib/screens/ips_detail_screen.dart
import 'package:flutter/material.dart';

import '../logic/core_store.dart';
import '../logic/ips/ips_detail_snapshot.dart';
import '../models/ips_snapshot.dart' as snap;

class IpsDetailScreen extends StatefulWidget {
  final CoreStore coreStore;

  const IpsDetailScreen({super.key, required this.coreStore});

  @override
  State<IpsDetailScreen> createState() => _IpsDetailScreenState();
}

class _IpsDetailScreenState extends State<IpsDetailScreen> {
  CoreStore get coreStore => widget.coreStore;

  @override
  Widget build(BuildContext context) {
    // ✅ La UI si aggiorna quando IpsStore notifica (refresh() notifica sempre)
    return ValueListenableBuilder<snap.IpsSnapshot>(
      valueListenable: coreStore.ipsStore,
      builder: (context, _, __) {
        final IpsDetailSnapshot snapshot = coreStore.buildIpsDetailSnapshot();

        return Scaffold(
          appBar: AppBar(
            title: const Text("Dettaglio IPS"),
            actions: [
              IconButton(
                tooltip: "Aggiorna IPS",
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  coreStore.ipsStore.refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("IPS aggiornato")),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(snapshot),
          ),
        );
      },
    );
  }

  Widget _buildBody(IpsDetailSnapshot s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row("Modulo", s.moduleId.name),
        const SizedBox(height: 8),
        _row("Score", "${s.score}/100"),
        const SizedBox(height: 8),
        _row("Livello", s.level.name),
        const SizedBox(height: 8),
        _row("Evento critico", s.isCriticalEvent ? "Sì" : "No"),
        const SizedBox(height: 8),
        _row("Reason", s.reasonCode.code()),
        const SizedBox(height: 24),
        const Text("Nota", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          "Questa schermata legge SOLO lo snapshot certificato (snapshotV1) "
          "e non ricalcola nulla.",
        ),
      ],
    );
  }

  Widget _row(String k, String v) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(k)),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
