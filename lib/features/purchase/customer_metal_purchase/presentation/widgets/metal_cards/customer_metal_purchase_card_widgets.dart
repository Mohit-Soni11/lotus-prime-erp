import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';

class CustomerMetalPurchaseCardHeader extends StatelessWidget {
  final String title;
  final String caption;
  final Color accent;
  final String assetPath;

  const CustomerMetalPurchaseCardHeader({
    super.key,
    required this.title,
    required this.caption,
    required this.accent,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetalAvatar(
          assetPath: assetPath,
          accent: accent,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomerMetalPurchaseSummaryPanel extends StatelessWidget {
  final CustomerMetalPurchaseMetalSummary summary;
  final Color accent;

  const CustomerMetalPurchaseSummaryPanel({
    super.key,
    required this.summary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricsRow(
            leftLabel: 'Available Gross',
            leftValue: CustomerMetalPurchaseFormatters.weight(
              summary.grossWeight,
            ),
            rightLabel: 'Available Fine',
            rightValue: CustomerMetalPurchaseFormatters.weight(
              summary.fineWeight,
            ),
          ),
          const SizedBox(height: 12),
          _MetricsRow(
            leftLabel: 'Amount Paid',
            leftValue: CustomerMetalPurchaseFormatters.amount(summary.amount),
            rightLabel: 'Total Items',
            rightValue: summary.entryCount.toString(),
          ),
        ],
      ),
    );
  }
}

class CustomerMetalPurchaseCardFooter extends StatelessWidget {
  final String actionLabel;
  final Color accent;
  final CustomerMetalPurchaseMetalSummary summary;

  const CustomerMetalPurchaseCardFooter({
    super.key,
    required this.actionLabel,
    required this.accent,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CustomerMetalPurchaseBadge(
              label: 'Direct ${summary.directPurchaseCount}',
              accent: accent,
            ),
            CustomerMetalPurchaseBadge(
              label: 'Trade-In ${summary.tradeInCount}',
              accent: accent,
            ),
            CustomerMetalPurchaseBadge(
              label: 'Refund ${summary.refundCount}',
              accent: accent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                actionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: Colors.black,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _MetricsRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricText(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricText(label: rightLabel, value: rightValue),
        ),
      ],
    );
  }
}

class _MetricText extends StatelessWidget {
  final String label;
  final String value;

  const _MetricText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class CustomerMetalPurchaseBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const CustomerMetalPurchaseBadge({
    super.key,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _MetalAvatar extends StatelessWidget {
  final String assetPath;
  final Color accent;

  const _MetalAvatar({
    required this.assetPath,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.34),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
