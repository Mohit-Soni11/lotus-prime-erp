import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';

class CustomerMetalPurchaseEntryCard extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final Color accent;

  const CustomerMetalPurchaseEntryCard({
    super.key,
    required this.entry,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EntryHeader(entry: entry, accent: accent),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 4
                  : constraints.maxWidth >= 640
                      ? 2
                      : 1;
              const spacing = 12.0;
              final width =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _MeasureTile(
                    width: width,
                    label: 'Gross Weight',
                    value: CustomerMetalPurchaseFormatters.weight(
                      entry.grossWeight,
                    ),
                  ),
                  _MeasureTile(
                    width: width,
                    label: 'Paid Touch',
                    value: CustomerMetalPurchaseFormatters.purity(entry.purity),
                  ),
                  _MeasureTile(
                    width: width,
                    label: 'Fine Weight',
                    value: CustomerMetalPurchaseFormatters.weight(
                      entry.fineWeight,
                    ),
                  ),
                  _MeasureTile(
                    width: width,
                    label: 'Amount Paid',
                    value: CustomerMetalPurchaseFormatters.amount(entry.amount),
                  ),
                  _MeasureTile(
                    width: width,
                    label: 'Purchase Rate',
                    value: CustomerMetalPurchaseFormatters.rate(
                      entry.effectiveRate,
                    ),
                  ),
                  _MeasureTile(
                    width: width,
                    label: 'Reference No',
                    value: entry.referenceNo,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EntryHeader extends StatelessWidget {
  final CustomerMetalPurchaseEntry entry;
  final Color accent;

  const _EntryHeader({
    required this.entry,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                entry.itemDescription.isEmpty
                    ? entry.metalType
                    : entry.itemDescription,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _SourceBadge(label: entry.source, accent: accent),
            const SizedBox(height: 8),
            Text(
              CustomerMetalPurchaseFormatters.date(entry.date),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MeasureTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _MeasureTile({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E0D8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
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
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _SourceBadge({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}
