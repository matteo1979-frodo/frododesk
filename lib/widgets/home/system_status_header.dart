import 'package:flutter/material.dart';

import '../../models/ips_snapshot.dart' as snap;

class SystemStatusHeader extends StatelessWidget {
  final bool hasTodayCoverageIssue;
  final snap.IpsLevel ipsLevel;

  final String stateText;
  final String mainSentence;
  final String? systemDetail;

  const SystemStatusHeader({
    super.key,
    required this.hasTodayCoverageIssue,
    required this.ipsLevel,
    required this.stateText,
    required this.mainSentence,
    this.systemDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color:
                (hasTodayCoverageIssue
                        ? const Color(0xFFE57373)
                        : const Color(0xFF8BC34A))
                    .withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Center(
            child: Text(
              hasTodayCoverageIssue
                  ? "✋"
                  : ipsLevel == snap.IpsLevel.green
                  ? "😌"
                  : ipsLevel == snap.IpsLevel.yellow
                  ? "😐"
                  : "😨",
              style: const TextStyle(fontSize: 30),
            ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stateText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                mainSentence,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  color: const Color(0xFF8BC34A),
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF8BC34A).withOpacity(0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),

              if (systemDetail != null) ...[
                const SizedBox(height: 6),
                Text(
                  systemDetail!,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
