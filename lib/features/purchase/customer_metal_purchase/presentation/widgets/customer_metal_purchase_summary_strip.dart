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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1200
              ? 5
              : constraints.maxWidth >= 760
                  ? 3
                  : 1;
          const spacing = 12.0;
          final width =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              _SummaryTile(
                width: width,
                label: 'Available Gross',
                value: CustomerMetalPurchaseFormatters.weight(
                  summary.grossWeight,
                ),
                accent: accent,
              ),
              _SummaryTile(
                width: width,
                label: 'Available Fine',
                value: CustomerMetalPurchaseFormatters.weight(
                  summary.fineWeight,
                ),
                accent: accent,
              ),
              _SummaryTile(
                width: width,
                label: 'Settlement Value',
                value: CustomerMetalPurchaseFormatters.amount(summary.amount),
                accent: accent,
              ),
              _SummaryTile(
                width: width,
                label: 'Total Items',
                value: summary.entryCount.toString(),
                accent: accent,
              ),
              _SummaryTile(
                width: width,
                label: 'Total Customers',
                value: summary.customerCount.toString(),
                accent: accent,
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
  final Color accent;

  const _SummaryTile({
    required this.width,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E0D8)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
