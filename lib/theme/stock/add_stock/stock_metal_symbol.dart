import 'package:flutter/material.dart';

enum StockMetalSymbolType { gold, silver }

/// Compact metal identity mark for stock headers and section badges.
class StockMetalSymbol extends StatelessWidget {
  const StockMetalSymbol({
    super.key,
    required this.metal,
    required this.color,
    this.size = 24,
  });

  final StockMetalSymbolType metal;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final symbol = metal == StockMetalSymbolType.gold ? 'Au' : 'Ag';
    final label = metal == StockMetalSymbolType.gold ? 'Gold' : 'Silver';

    return Semantics(
      label: '$label stock',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.hexagon_outlined, size: size, color: color),
            Text(
              symbol,
              style: TextStyle(
                color: color,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
