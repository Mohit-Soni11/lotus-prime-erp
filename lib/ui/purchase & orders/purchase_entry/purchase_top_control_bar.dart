// =============================================================================
// FILE        : purchase_top_control_bar.dart
// MODULE      : Purchase Entry
// LAYER       : UI
// DESCRIPTION : Purchase preferences card.
//               SOURCE toggle: FROM CUSTOMER | FROM SUPPLIER
//               TAX toggle: NORMAL | GST (default OFF for customer)
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';

class PurchaseTopControlBar extends StatelessWidget {
  final PurchaseEntryController ctrl;

  const PurchaseTopControlBar({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final bool isCustomer =
            ctrl.purchaseSource == PurchaseSource.fromCustomer;
        final bool isGstOn = ctrl.taxType == PurchaseTaxType.gst;

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: PurchaseEntryColors.bodyPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PurchaseEntryColors.bodyBorder),
              boxShadow: const [
                BoxShadow(
                  color: PurchaseEntryColors.shadowLight,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: PurchaseEntryColors.shadowDark,
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── HEADING ROW ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                PurchaseEntryStrings.invoicePreferences,
                                style: PurchaseEntryStyles.highVisHeader,
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 260),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isGstOn
                                      ? PurchaseEntryColors.success
                                      : PurchaseEntryColors.textMuted,
                                ),
                                child: Text(
                                  '${isCustomer ? 'From Seller' : 'From Supplier'}  |  '
                                  '${isGstOn ? 'GST Purchase' : 'Normal Purchase'}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(width: 40),

                      // Status pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isGstOn
                              ? PurchaseEntryColors.success.withOpacity(0.07)
                              : PurchaseEntryColors.bodyBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isGstOn
                                ? PurchaseEntryColors.success.withOpacity(0.35)
                                : PurchaseEntryColors.bodyBorder,
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
                                color: isGstOn
                                    ? PurchaseEntryColors.success
                                    : PurchaseEntryColors.textDark,
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
                                    ? PurchaseEntryColors.success
                                    : PurchaseEntryColors.textDark,
                              ),
                              child: Text(isGstOn ? 'GST ACTIVE' : 'NORMAL'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Divider ──────────────────────────────────────────────
                  Container(
                    height: 1,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    color: PurchaseEntryColors.bodyBorder,
                  ),

                  // ── CONTROLS ROW ─────────────────────────────────────────
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SOURCE SEGMENT
                      Container(
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: PurchaseEntryColors.bodyBg,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: PurchaseEntryColors.bodyBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: PurchaseEntryColors.shadowLight,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _sourceTab(
                              title: 'SELLER',
                              isActive: isCustomer,
                              onTap: () => ctrl
                                  .toggleSource(PurchaseSource.fromCustomer),
                            ),
                            _sourceTab(
                              title: 'SUPPLIER',
                              isActive: !isCustomer,
                              onTap: () => ctrl
                                  .toggleSource(PurchaseSource.fromSupplier),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // GST TOGGLE
                      InkWell(
                        onTap: () => ctrl.toggleTaxType(
                          isGstOn
                              ? PurchaseTaxType.normal
                              : PurchaseTaxType.gst,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isGstOn
                                ? PurchaseEntryColors.success.withOpacity(0.05)
                                : PurchaseEntryColors.bodyPanel,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isGstOn
                                  ? PurchaseEntryColors.success
                                      .withOpacity(0.40)
                                  : PurchaseEntryColors.bodyBorder,
                              width: isGstOn ? 1.5 : 1.0,
                            ),
                            boxShadow: isGstOn
                                ? [
                                    BoxShadow(
                                      color: PurchaseEntryColors.success
                                          .withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : const [
                                    BoxShadow(
                                      color: PurchaseEntryColors.shadowLight,
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
                                    'TAX STATUS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      color: PurchaseEntryColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      isGstOn ? 'GST BILL' : 'NORMAL',
                                      key: ValueKey(isGstOn),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                        color: isGstOn
                                            ? PurchaseEntryColors.success
                                            : PurchaseEntryColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _toggleLabel(
                                    'NRM',
                                    isActive: !isGstOn,
                                    activeColor: PurchaseEntryColors.textDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isGstOn
                                        ? PurchaseEntryIcons.gstToggleOn
                                        : PurchaseEntryIcons.gstToggleOff,
                                    color: isGstOn
                                        ? PurchaseEntryColors.success
                                        : PurchaseEntryColors.textMuted,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 6),
                                  _toggleLabel(
                                    'GST',
                                    isActive: isGstOn,
                                    activeColor: PurchaseEntryColors.success,
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
          color: PurchaseEntryColors.purchaseAccent.withOpacity(opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _sourceTab({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 130,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? PurchaseEntryColors.purchaseAccent
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color:
                          PurchaseEntryColors.purchaseAccent.withOpacity(0.28),
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
                width: isActive ? 6 : 0,
                height: isActive ? 6 : 0,
                margin: EdgeInsets.only(right: isActive ? 6 : 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : PurchaseEntryColors.textDark,
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

  Widget _toggleLabel(
    String label, {
    required bool isActive,
    required Color activeColor,
  }) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 220),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: isActive ? activeColor : PurchaseEntryColors.textMuted,
      ),
      child: Text(label),
    );
  }
}
