// =============================================================================
// FILE        : purchase_top_control_bar.dart
// MODULE      : Customer Metal Purchase
// LAYER       : UI
// DESCRIPTION : Customer old-metal intake setup card.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';

class PurchaseTopControlBar extends StatelessWidget {
  const PurchaseTopControlBar({super.key});

  @override
  Widget build(BuildContext context) {
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
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PurchaseEntryStrings.invoicePreferences,
                            style: PurchaseEntryStyles.highVisHeader,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Customer old-metal acquisition',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: PurchaseEntryColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: PurchaseEntryColors.bodyBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PurchaseEntryColors.bodyBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PurchaseEntryColors.purchaseAccent,
                          ),
                          child: SizedBox(
                            width: 6,
                            height: 6,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'INTAKE READY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: PurchaseEntryColors.purchaseAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                height: 1,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                color: PurchaseEntryColors.bodyBorder,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: PurchaseEntryColors.bodyBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PurchaseEntryColors.bodyBorder),
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
                          title: 'CUSTOMER SELLER',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accentLine(double width, double opacity) => Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: PurchaseEntryColors.purchaseAccent.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _sourceTab({
    required String title,
  }) {
    return SizedBox(
      width: 170,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PurchaseEntryColors.purchaseAccent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 6, height: 6),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
