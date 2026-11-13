import 'package:flutter/material.dart';

import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class PosAdvanceCarouselArrow extends StatelessWidget {
  const PosAdvanceCarouselArrow({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 94,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(13),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF1),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFF0DFCA)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF76532B).withValues(alpha: 0.10),
                  blurRadius: 7,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: enabled
                  ? SalesPosColors.goldHoverDark
                  : const Color(0xFFBFA57C),
            ),
          ),
        ),
      ),
    );
  }
}
