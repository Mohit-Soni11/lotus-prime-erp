// =============================================================================
// FILE        : smart_shimmer_row.dart
// MODULE      : Shared → Smart Input → UI → Widgets
// LAYER       : UI (Presentational only)
// PURPOSE     : Loading skeleton — API result aane tak dikhta hai
// =============================================================================

import 'package:flutter/material.dart';
import 'smart_input_colors.dart';
import 'smart_input_styles.dart';

class SmartShimmerRow extends StatefulWidget {
  const SmartShimmerRow({super.key});

  @override
  State<SmartShimmerRow> createState() => _SmartShimmerRowState();
}

class _SmartShimmerRowState extends State<SmartShimmerRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Row(
          children: [
            // Spell correction placeholder (wider)
            _ShimmerBox(width: 170, isRound: false, opacity: _anim.value),
            const SizedBox(width: 10),
            // Chip placeholders
            _ShimmerBox(width: 70, isRound: true, opacity: _anim.value),
            const SizedBox(width: 8),
            _ShimmerBox(width: 70, isRound: true, opacity: _anim.value),
            const SizedBox(width: 8),
            _ShimmerBox(width: 70, isRound: true, opacity: _anim.value),
          ],
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.isRound,
    required this.opacity,
  });

  final double width;
  final bool isRound;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: 30,
        decoration: SmartInputStyles.shimmerPill(isRound: isRound).copyWith(
          color: SmartInputColors.shimmerBase,
        ),
      ),
    );
  }
}
