import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';

class CustomerMetalPurchaseSummaryStrip extends StatelessWidget {
  final CustomerMetalPurchaseMetalSummary summary;
  final Color accent;

  const CustomerMetalPurchaseSummaryStrip({
    super.key,
    required this.summary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 4 : 2;
          const spacing = 12.0;
          final width =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              _SummaryTile(
                width: width,
                label: 'Total Gross',
                value: CustomerMetalPurchaseFormatters.weight(
                  summary.grossWeight,
                ),
              ),
              _SummaryTile(
                width: width,
                label: 'Total Fine',
                value: CustomerMetalPurchaseFormatters.weight(
                  summary.fineWeight,
                ),
              ),
              _SummaryTile(
                width: width,
                label: 'Amount Paid',
                value: CustomerMetalPurchaseFormatters.amount(summary.amount),
              ),
              _SummaryTile(
                width: width,
                label: 'Total Items',
                value: summary.entryCount.toString(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _SummaryTile({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
