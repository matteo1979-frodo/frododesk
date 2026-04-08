import 'package:flutter/material.dart';

class StatusVisual {
  final String emoji;
  final Color color;
  final bool isBusy;

  const StatusVisual({
    required this.emoji,
    required this.color,
    required this.isBusy,
  });
}

StatusVisual getStatusVisual(String text) {
  final t = text.toLowerCase();

  if (t.contains("malattia a letto")) {
    return const StatusVisual(
      emoji: "🛌",
      color: Colors.red,
      isBusy: true,
    );
  }

  if (t.contains("malattia")) {
    return const StatusVisual(
      emoji: "🤒",
      color: Colors.orange,
      isBusy: true,
    );
  }

  if (t.contains("occupato") || t.contains("occupata")) {
    return const StatusVisual(
      emoji: "💼",
      color: Colors.red,
      isBusy: true,
    );
  }

  if (t.contains("libero") || t.contains("libera")) {
    return const StatusVisual(
      emoji: "🤗",
      color: Colors.green,
      isBusy: false,
    );
  }

  if (t.contains("a casa") || t.contains("casa")) {
    return const StatusVisual(
      emoji: "🏠",
      color: Colors.blue,
      isBusy: false,
    );
  }

  if (t.contains("scuola")) {
    return const StatusVisual(
      emoji: "🎒",
      color: Colors.orange,
      isBusy: true,
    );
  }

  if (t.contains("visita")) {
    return const StatusVisual(
      emoji: "🧑‍⚕️",
      color: Colors.purple,
      isBusy: true,
    );
  }

  return const StatusVisual(
    emoji: "",
    color: Colors.grey,
    isBusy: false,
  );
}