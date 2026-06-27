import 'package:flutter/material.dart';

import '../../../presentation/theme/billing_setup_design_tokens.dart';

class SalesBillingHeader extends StatelessWidget {
  final VoidCallback onBack;

  const SalesBillingHeader({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: const BoxDecoration(
        color: BillingSetupDesignTokens.header,
        border: Border(
          bottom: BorderSide(color: BillingSetupDesignTokens.headerBorder),
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Back to Billing Setup',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onBack,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF182234),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BillingSetupDesignTokens.sales.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: BillingSetupDesignTokens.sales.withValues(alpha: 0.36),
              ),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: BillingSetupDesignTokens.sales,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Billing Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Metal-wise invoice fields, policies, and print controls',
                  style: TextStyle(
                    color: Color(0xFFB8C1D1),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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
