import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_metal_cards/customer_metal_purchase_metal_visuals.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseReportSummaryBand extends StatelessWidget {
  final CustomerMetalPurchaseDashboardSummary summary;
  final Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
      metalSummaries;

  const CustomerMetalPurchaseReportSummaryBand({
    super.key,
    required this.summary,
    required this.metalSummaries,
  });

  @override
  Widget build(BuildContext context) {
    final netWeightBreakdown = _buildNetWeightBreakdown(metalSummaries);
    final metrics = [
      _PurchaseReportKpiMetric(
        label: 'Purchase Value',
        value: CustomerMetalPurchaseFormatters.amount(summary.amount),
        icon: Icons.currency_rupee_rounded,
        accent: PurchaseEntryColors.purchaseAccent,
        tint: const Color(0xFFEFF6FF),
      ),
      _PurchaseReportKpiMetric(
        label: 'Paid',
        value: CustomerMetalPurchaseFormatters.amount(summary.paidAmount),
        icon: Icons.account_balance_wallet_rounded,
        accent: PurchaseEntryColors.success,
        tint: const Color(0xFFECFDF5),
      ),
      _PurchaseReportKpiMetric(
        label: 'Pending',
        value: CustomerMetalPurchaseFormatters.amount(summary.pendingAmount),
        icon: Icons.pending_actions_rounded,
        accent: summary.pendingAmount > 0.005
            ? PurchaseEntryColors.danger
            : PurchaseEntryColors.success,
        tint: summary.pendingAmount > 0.005
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFECFDF5),
      ),
      _PurchaseReportKpiMetric(
        label: 'Net Weight',
        value: CustomerMetalPurchaseFormatters.weight(summary.netWeight),
        icon: Icons.scale_rounded,
        accent: const Color(0xFF2563EB),
        tint: const Color(0xFFEFF6FF),
        breakdown: netWeightBreakdown,
      ),
      _PurchaseReportKpiMetric(
        label: 'Vouchers',
        value: summary.voucherCount.toString(),
        icon: Icons.receipt_long_rounded,
        accent: const Color(0xFF7C3AED),
        tint: const Color(0xFFF5F3FF),
      ),
      _PurchaseReportKpiMetric(
        label: 'Sellers',
        value: summary.customerCount.toString(),
        icon: Icons.groups_2_rounded,
        accent: const Color(0xFF0891B2),
        tint: const Color(0xFFECFEFF),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 6
            : constraints.maxWidth >= 760
                ? 3
                : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _PurchaseReportKpiCard(metric: metric),
              ),
          ],
        );
      },
    );
  }

  List<_PurchaseReportMetalWeight> _buildNetWeightBreakdown(
    Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
        summaries,
  ) {
    final entries = summaries.entries.toList(growable: false)
      ..sort((left, right) => left.key.index.compareTo(right.key.index));

    return [
      for (final entry in entries)
        if (entry.value.netWeight > 0.005)
          _PurchaseReportMetalWeight(
            label: entry.key.label,
            compactValue: _compactWeight(entry.value.netWeight),
            accent: visualsForCustomerPurchaseMetal(entry.key).accent,
          ),
    ];
  }

  String _compactWeight(double value) {
    return CustomerMetalPurchaseFormatters.weight(value);
  }
}

class _PurchaseReportKpiCard extends StatelessWidget {
  final _PurchaseReportKpiMetric metric;

  const _PurchaseReportKpiCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: metric.accent.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _KpiFrontContent(metric: metric),
    );
  }
}

class _KpiFrontContent extends StatelessWidget {
  final _PurchaseReportKpiMetric metric;

  const _KpiFrontContent({required this.metric});

  @override
  Widget build(BuildContext context) {
    final hasBreakdown = metric.breakdown.isNotEmpty;

    return Row(
      children: [
        _KpiIcon(metric: metric),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  metric.value,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: metric.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasBreakdown) ...[
          Container(
            width: 1,
            height: 46,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFE2E8F0),
          ),
          _InlineMetalSplitPanel(items: metric.breakdown),
        ],
      ],
    );
  }
}

class _KpiIcon extends StatelessWidget {
  final _PurchaseReportKpiMetric metric;

  const _KpiIcon({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: metric.tint,
        shape: BoxShape.circle,
        border: Border.all(color: metric.accent.withValues(alpha: 0.10)),
      ),
      child: Icon(metric.icon, color: metric.accent, size: 23),
    );
  }
}

class _InlineMetalSplitPanel extends StatelessWidget {
  final List<_PurchaseReportMetalWeight> items;

  const _InlineMetalSplitPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(2).toList(growable: false);
    final hiddenCount = items.length - visibleItems.length;

    return SizedBox(
      width: hiddenCount > 0 ? 104 : 94,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < visibleItems.length; index++) ...[
            _InlineMetalSplitRow(item: visibleItems[index]),
            if (index != visibleItems.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child:
                    Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              ),
          ],
          if (hiddenCount > 0) ...[
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerRight,
              child: _MoreMetalBadge(count: hiddenCount),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineMetalSplitRow extends StatelessWidget {
  final _PurchaseReportMetalWeight item;

  const _InlineMetalSplitRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 19,
              height: 19,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: item.accent.withValues(alpha: 0.22)),
              ),
              child: Text(
                item.shortLabel,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: item.accent,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.compactValue,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MoreMetalBadge extends StatelessWidget {
  final int count;

  const _MoreMetalBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '+$count',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}

class _PurchaseReportKpiMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color tint;
  final List<_PurchaseReportMetalWeight> breakdown;

  const _PurchaseReportKpiMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.tint,
    this.breakdown = const [],
  });
}

class _PurchaseReportMetalWeight {
  final String label;
  final String compactValue;
  final Color accent;

  const _PurchaseReportMetalWeight({
    required this.label,
    required this.compactValue,
    required this.accent,
  });

  String get shortLabel {
    switch (label) {
      case 'Gold':
        return 'G';
      case 'Silver':
        return 'S';
      case 'Diamond':
        return 'D';
      case 'Platinum':
        return 'P';
      default:
        return label.isEmpty ? '?' : label.substring(0, 1).toUpperCase();
    }
  }
}
