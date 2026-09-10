import 'package:flutter/material.dart';

import '../../../../features/sales_pos/domain/services/sales_invoice_tax_policy.dart';
import '../../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';

class PosInvoiceTaxModeSegment extends StatelessWidget {
  final PosBillingController controller;

  const PosInvoiceTaxModeSegment({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isGst = SalesInvoiceTaxPolicy.appliesGst(controller.billType);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 252,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isGst
            ? SalesPosColors.success.withValues(alpha: 0.06)
            : SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGst
              ? SalesPosColors.success.withValues(alpha: 0.32)
              : SalesPosColors.bodyBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: SalesPosColors.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _TaxModeTab(
            label: 'NORMAL',
            subtitle: 'No GST',
            icon: Icons.receipt_outlined,
            isActive: !isGst,
            activeColor: SalesPosColors.textDark,
            onTap: () => controller.toggleBillType(BillType.normal),
          ),
          const SizedBox(width: 4),
          _TaxModeTab(
            label: 'GST',
            subtitle: 'Tax invoice',
            icon: Icons.receipt_long_rounded,
            isActive: isGst,
            activeColor: SalesPosColors.success,
            onTap: () => controller.toggleBillType(BillType.gst),
          ),
        ],
      ),
    );
  }
}

class _TaxModeTab extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TaxModeTab({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? activeColor : SalesPosColors.bodyTextMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight:
                              isActive ? FontWeight.w900 : FontWeight.w800,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground.withValues(
                            alpha: isActive ? 0.86 : 0.72,
                          ),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
