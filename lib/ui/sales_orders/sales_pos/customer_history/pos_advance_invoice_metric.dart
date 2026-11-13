import 'package:flutter/material.dart';

import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class PosAdvanceInvoiceMetric extends StatelessWidget {
  const PosAdvanceInvoiceMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.width,
    this.valueColor = SalesPosColors.textDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final double width;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 75),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0DFCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF76532B).withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: const Color(0xFFCE8700)),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF263953),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
