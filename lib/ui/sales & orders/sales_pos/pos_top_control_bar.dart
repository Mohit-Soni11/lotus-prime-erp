// ==========================================
// FILE: pos_top_control_bar.dart
// TYPE: Smart UI Component (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Compact toggle with perfect badge alignment.
//              ✅ Strictly mapped Colors, Icons, and TextStyles.
//              ✅ Wrap-content layout via IntrinsicWidth.
// ==========================================

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';

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
        final bool isGstOn  = ctrl.billType   == BillType.gst;

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: SalesPosColors.bodyPanelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SalesPosColors.bodyBorder),
              boxShadow: const [
                BoxShadow(color: SalesPosColors.shadowLight, blurRadius: 8,  offset: Offset(0, 2)),
                BoxShadow(color: SalesPosColors.shadowDark, blurRadius: 20, offset: Offset(0, 6)),
              ],
            ),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: [

                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  // HEADING ROW
                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      // LEFT PART: Lines and Titles
                      Row(
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
                              _accentLine(7,  0.18),
                            ],
                          ),

                          const SizedBox(width: 12),

                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "INVOICE PREFERENCES", 
                                style: SalesPosStyles.highVisHeader,
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 260),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isGstOn
                                      ? SalesPosColors.success
                                      : SalesPosColors.bodyTextMuted, 
                                ),
                                child: Text(
                                  "${isRetail ? 'Retail Trade' : 'Wholesale Trade'}  ·  ${isGstOn ? 'Tax Invoice' : 'Normal Bill'}",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(width: 40), 

                      // RIGHT PART: Status pill (Badge)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isGstOn
                              ? SalesPosColors.success.withOpacity(0.07)
                              : SalesPosColors.bodyBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isGstOn
                                ? SalesPosColors.success.withOpacity(0.35)
                                : SalesPosColors.bodyBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              width: 6, height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isGstOn
                                    ? SalesPosColors.success
                                    : SalesPosColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 260),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: isGstOn
                                    ? SalesPosColors.success
                                    : SalesPosColors.textDark,
                              ),
                              child: Text(isGstOn ? "GST ACTIVE" : "NORMAL"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Divider ──
                  Container(
                    height: 1,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    color: SalesPosColors.bodyBorder,
                  ),

                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  // CONTROLS ROW
                  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                  Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: [

                      // --- MODE SEGMENT (RETAIL / WHOLESALE) ---
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
                              title: "RETAIL",
                              isActive: isRetail,
                              onTap: () => ctrl.toggleBillingMode(BillingMode.retail),
                            ),
                            _buildModeTab(
                              title: "WHOLESALE",
                              isActive: !isRetail,
                              onTap: () => ctrl.toggleBillingMode(BillingMode.wholesale),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16), 

                      // --- BILL TYPE (NORMAL / GST) ---
                      InkWell(
                        onTap: () {
                          ctrl.toggleBillType(
                            isGstOn ? BillType.normal : BillType.gst,
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        splashColor: SalesPosColors.success.withOpacity(0.06),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          height: 52, 
                          padding: const EdgeInsets.symmetric(horizontal: 16), 
                          decoration: BoxDecoration(
                            color: isGstOn ? SalesPosColors.success.withOpacity(0.05) : SalesPosColors.bodyPanelBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isGstOn
                                  ? SalesPosColors.success.withOpacity(0.40)
                                  : SalesPosColors.bodyBorder,
                              width: isGstOn ? 1.5 : 1.0,
                            ),
                            boxShadow: isGstOn
                                ? [
                                    BoxShadow(
                                      color: SalesPosColors.success.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : const [
                                    BoxShadow(
                                      color: SalesPosColors.shadowLight,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, 
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "TAX STATUS",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900, 
                                      letterSpacing: 1.0,
                                      color: SalesPosColors.textDark, 
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      isGstOn ? "GST INVOICE" : "NORMAL", 
                                      key: ValueKey(isGstOn),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900, 
                                        letterSpacing: 0.2,
                                        color: isGstOn
                                            ? SalesPosColors.success
                                            : SalesPosColors.textDark, 
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 24), 

                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildToggleLabel(
                                    label: "NRM", 
                                    isActive: !isGstOn,
                                    activeColor: SalesPosColors.textDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isGstOn
                                        ? SalesPosIcons.gstToggleOn
                                        : SalesPosIcons.gstToggleOff,
                                    color: isGstOn
                                        ? SalesPosColors.success
                                        : SalesPosColors.bodyTextMuted, 
                                    size: 36,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildToggleLabel(
                                    label: "TAX",
                                    isActive: isGstOn,
                                    activeColor: SalesPosColors.success,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
          color: SalesPosColors.brandGold.withOpacity(opacity),
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
                      color: SalesPosColors.brandGold.withOpacity(0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width:  isActive ? 6 : 0,
                height: isActive ? 6 : 0,
                margin: EdgeInsets.only(right: isActive ? 6 : 0),
                decoration: const BoxDecoration(
                  color: SalesPosColors.textDark, 
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: SalesPosColors.textDark, 
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700, 
                  fontSize: 13, 
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleLabel({
    required String label,
    required bool isActive,
    required Color activeColor,
  }) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 220),
      style: TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.w900, 
        letterSpacing: 0.5,
        color: isActive ? activeColor : SalesPosColors.bodyTextMuted,
      ),
      child: Text(label),
    );
  }
}