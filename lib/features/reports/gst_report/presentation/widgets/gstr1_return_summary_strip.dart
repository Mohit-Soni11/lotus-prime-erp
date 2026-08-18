import 'package:flutter/material.dart';

import '../../domain/gst_report_models.dart';
import '../gst_report_formatters.dart';
import '../theme/gst_report_theme.dart';

class Gstr1ReturnSummaryStrip extends StatelessWidget {
  const Gstr1ReturnSummaryStrip({
    super.key,
    required this.snapshot,
  });

  final GstReportSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final b2b = _Gstr1Bucket.fromInvoices(snapshot.gstr1B2bInvoices);
    final b2c = _Gstr1Bucket.fromInvoices(snapshot.gstr1B2cInvoices);
    final total = b2b + b2c;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 1100
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 720
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _Gstr1SummaryCard(
                title: 'Total Outward Supplies',
                subtitle: 'B2B + B2C tax invoices',
                icon: Icons.receipt_long_rounded,
                accent: GstReportColors.taxGreen,
                bucket: total,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _Gstr1SummaryCard(
                title: 'B2B Registered Supplies',
                subtitle: 'Customers with GSTIN',
                icon: Icons.business_center_rounded,
                accent: GstReportColors.information,
                bucket: b2b,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _Gstr1SummaryCard(
                title: 'B2C Consumer Supplies',
                subtitle: 'Unregistered / walk-in customers',
                icon: Icons.storefront_rounded,
                accent: GstReportColors.success,
                bucket: b2c,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Gstr1SummaryCard extends StatelessWidget {
  const _Gstr1SummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.bucket,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final _Gstr1Bucket bucket;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GstReportColors.bodyPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: const [
          BoxShadow(
            color: GstReportColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GstReportStyles.body.copyWith(
                        color: GstReportColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GstReportStyles.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _SummaryValue(
                label: 'Invoices',
                value: GstReportFormatters.count(bucket.invoiceCount),
              ),
              _SummaryValue(
                label: 'Taxable',
                value: GstReportFormatters.money(bucket.taxableValue),
              ),
              _SummaryValue(
                label: 'Output GST',
                value: GstReportFormatters.money(bucket.outputGst),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GstReportStyles.body.copyWith(
              color: GstReportColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Gstr1Bucket {
  const _Gstr1Bucket({
    required this.invoiceCount,
    required this.taxableValue,
    required this.outputGst,
  });

  factory _Gstr1Bucket.fromInvoices(List<GstInvoiceRow> invoices) {
    double sum(double Function(GstInvoiceRow row) selector) {
      final value = invoices.fold<double>(0, (total, row) {
        return total + selector(row);
      });
      return (value * 100).round() / 100;
    }

    return _Gstr1Bucket(
      invoiceCount: invoices.length,
      taxableValue: sum((row) => row.taxableAmount),
      outputGst: sum((row) => row.gstAmount),
    );
  }

  final int invoiceCount;
  final double taxableValue;
  final double outputGst;

  _Gstr1Bucket operator +(_Gstr1Bucket other) {
    double round(double value) => (value * 100).round() / 100;

    return _Gstr1Bucket(
      invoiceCount: invoiceCount + other.invoiceCount,
      taxableValue: round(taxableValue + other.taxableValue),
      outputGst: round(outputGst + other.outputGst),
    );
  }
}
