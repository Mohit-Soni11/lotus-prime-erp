import 'package:flutter/material.dart';

import '../../../theme/reports/day_book/day_book_theme.dart';

enum DayBookMetalVisualType { gold, silver }

class DayBookMetalVisual extends StatelessWidget {
  const DayBookMetalVisual({super.key, required this.metal, this.size = 34});

  final DayBookMetalVisualType metal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isGold = metal == DayBookMetalVisualType.gold;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        isGold ? 'lib/logo/gold.jpeg' : 'lib/logo/silver and platinum .jpeg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: isGold ? 'Gold stock' : 'Silver stock',
        errorBuilder: (_, __, ___) => SizedBox(
          width: size,
          height: size,
          child: Icon(
            isGold ? DayBookIcons.gold : DayBookIcons.silver,
            color: isGold ? DayBookColors.goldMetal : DayBookColors.silverMetal,
          ),
        ),
      ),
    );
  }
}
