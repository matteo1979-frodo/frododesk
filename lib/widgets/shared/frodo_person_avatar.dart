import 'package:flutter/material.dart';

enum FrodoPersonCategory {
  adultMan,
  adultWoman,
  boy,
  girl,
  elderlyMan,
  elderlyWoman,
  neutral,
}

abstract final class FrodoPersonCategoryResolver {
  static FrodoPersonCategory fromKnownName(String name) =>
      switch (name.trim().toLowerCase()) {
        'matteo' => FrodoPersonCategory.adultMan,
        'chiara' => FrodoPersonCategory.adultWoman,
        'alice' => FrodoPersonCategory.girl,
        'sandra' => FrodoPersonCategory.elderlyWoman,
        _ => FrodoPersonCategory.neutral,
      };
}

class FrodoPersonAvatar extends StatelessWidget {
  final FrodoPersonCategory category;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;
  final String? semanticLabel;

  const FrodoPersonAvatar({
    super.key,
    required this.category,
    this.size = 20,
    this.foregroundColor = const Color(0xFF765E3C),
    this.backgroundColor = const Color(0x29765E3C),
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _iconFor(category),
          color: foregroundColor,
          size: size * 0.72,
        ),
      ),
    ),
  );

  static IconData _iconFor(FrodoPersonCategory category) => switch (category) {
    FrodoPersonCategory.adultMan => Icons.man_rounded,
    FrodoPersonCategory.adultWoman => Icons.woman_rounded,
    FrodoPersonCategory.boy => Icons.boy_rounded,
    FrodoPersonCategory.girl => Icons.girl_rounded,
    FrodoPersonCategory.elderlyMan => Icons.elderly_rounded,
    FrodoPersonCategory.elderlyWoman => Icons.elderly_woman_rounded,
    FrodoPersonCategory.neutral => Icons.person_rounded,
  };
}
