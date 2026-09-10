// ==========================================
// FILE: pos_top_control_bar.dart
// TYPE: Smart UI Component (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Compact toggle with perfect badge alignment.
//               Strictly mapped Colors, Icons, and TextStyles.
//               Wrap-content layout via IntrinsicWidth.
// ==========================================

import 'package:flutter/material.dart';

import '../../../features/sales_pos/domain/services/sales_invoice_tax_policy.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'invoice_preferences/pos_invoice_tax_mode_segment.dart';

class PosTopControlBar extends StatelessWidget {
  final PosBillingController ctrl;

  const PosTopControlBar({
    super.key,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final bool isRetail = ctrl.billingMode == BillingMode.retail;
        final bool isGstOn = SalesInvoiceTaxPolicy.appliesGst(ctrl.billType);
        final Color statusColor =
            isGstOn ? SalesPosColors.success : SalesPosColors.textDark;

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: SalesPosColors.bodyPanelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SalesPosColors.bodyBorder),
              boxShadow: const [
                BoxShadow(
                    color: SalesPosColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2)),
                BoxShadow(
                    color: SalesPosColors.shadowDark,
                    blurRadius: 20,
                    offset: Offset(0, 6)),
              ],
            ),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //
                  // HEADING ROW
                  //
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LEFT PART: Lines and Titles
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _accentLine(20, 1.0),
                                const SizedBox(height: 3),
                                _accentLine(13, 0.45),
                                const SizedBox(height: 3),
                                _accentLine(7, 0.18),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "INVOICE PREFERENCES",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SalesPosStyles.highVisHeader,
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 260),
                                    style: TextStyle(
                                      fontSize: SalesPosStyles.fontCaption,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                    child: Text(
                                      "${isRetail ? 'B2C Retail' : 'B2B Registered'}    ${SalesInvoiceTaxPolicy.title(ctrl.billType)}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // RIGHT PART: Status pill (Badge)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 260),
                              style: TextStyle(
                                fontSize: SalesPosStyles.fontCaption,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                                color: statusColor,
                              ),
                              child: Text(
                                SalesInvoiceTaxPolicy.statusLabel(
                                    ctrl.billType),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  //  Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    color: SalesPosColors.bodyBorder,
                  ),

                  //
                  // CONTROLS ROW
                  //
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- MODE SEGMENT (B2C / B2B) ---
                      Container(
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: SalesPosColors.bodyBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SalesPosColors.bodyBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: SalesPosColors.shadowLight,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeTab(
                              title: "B2C",
                              isActive: isRetail,
                              onTap: () =>
                                  ctrl.toggleBillingMode(BillingMode.retail),
                            ),
                            _buildModeTab(
                              title: "B2B",
                              isActive: !isRetail,
                              onTap: () =>
                                  ctrl.toggleBillingMode(BillingMode.wholesale),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),
                      PosInvoiceTaxModeSegment(controller: ctrl),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _accentLine(double width, double opacity) => Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: SalesPosColors.brandGold.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildModeTab({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 125,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        splashColor: SalesPosColors.brandGoldLight,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? SalesPosColors.brandGold : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: SalesPosColors.brandGold.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: isActive ? 6 : 0,
                height: isActive ? 6 : 0,
                margin: EdgeInsets.only(right: isActive ? 6 : 0),
                decoration: const BoxDecoration(
                  color: SalesPosColors.textDark,
                  shape: BoxShape.circle,
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SalesPosColors.textDark,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      fontSize: SalesPosStyles.fontLabel,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
