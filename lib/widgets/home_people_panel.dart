import 'package:flutter/material.dart';

import '../logic/core_store.dart';
import 'person_detail_panel.dart';

class HomePeoplePanel extends StatelessWidget {
  final CoreStore coreStore;

  const HomePeoplePanel({
    super.key,
    required this.coreStore,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Persone",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 6),

            Text(
              "Mini cruscotti vivi della giornata",
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            _personCard(
              context: context,
              name: "Matteo",
              subtitle: "Situazione oggi",
              value: "Turni, ferie e malattia",
              icon: Icons.person_rounded,
            ),

            const SizedBox(height: 12),

            _personCard(
              context: context,
              name: "Chiara",
              subtitle: "Situazione oggi",
              value: "Turni, ferie e malattia",
              icon: Icons.person_rounded,
            ),

            const SizedBox(height: 12),

            _personCard(
              context: context,
              name: "Alice",
              subtitle: "Scuola, eventi e copertura",
              value: "Da collegare dopo",
              icon: Icons.child_care_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _personCard({
    required BuildContext context,
    required String name,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (_) => PersonDetailPanel(
            personName: name,
            coreStore: coreStore,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}