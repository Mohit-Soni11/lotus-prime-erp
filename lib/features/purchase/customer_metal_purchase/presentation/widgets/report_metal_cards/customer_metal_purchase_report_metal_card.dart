import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/utils/customer_metal_purchase_formatters.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_metal_cards/customer_metal_purchase_metal_visuals.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseReportMetalCard extends StatefulWidget {
  final String periodLabel;
  final CustomerMetalPurchaseMetalSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const CustomerMetalPurchaseReportMetalCard({
    super.key,
    required this.periodLabel,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  State<CustomerMetalPurchaseReportMetalCard> createState() =>
      _CustomerMetalPurchaseReportMetalCardState();
}

class _CustomerMetalPurchaseReportMetalCardState
    extends State<CustomerMetalPurchaseReportMetalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final visuals = visualsForCustomerPurchaseMetal(widget.summary.metal);
    final borderColor = widget.selected || _hovered
        ? visuals.accent.withValues(alpha: 0.62)
        : visuals.accent.withValues(alpha: 0.24);
    final hasPending = widget.summary.pendingAmount > 0.005;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.006 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            splashColor: visuals.accent.withValues(alpha: 0.08),
            highlightColor: visuals.accent.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: widget.selected ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.selected || _hovered ? 0.08 : 0.045,
                    ),
                    blurRadius: widget.selected || _hovered ? 18 : 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 4,
                    color: widget.selected
                        ? visuals.accent
                        : visuals.accent.withValues(alpha: 0.26),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetalCardHeader(
                          periodLabel: widget.periodLabel,
                          summary: widget.summary,
                          visuals: visuals,
                          selected: widget.selected,
                        ),
                        const SizedBox(height: 16),
                        _MetalMetricRail(
                          metrics: [
                            _MetalMetric(
                              label: 'Net Weight',
                              value: CustomerMetalPurchaseFormatters.weight(
                                widget.summary.netWeight,
                              ),
                            ),
                            _MetalMetric(
                              label: 'Fine Weight',
                              value: CustomerMetalPurchaseFormatters.weight(
                                widget.summary.fineWeight,
                              ),
                            ),
                            _MetalMetric(
                              label: 'Value',
                              value: CustomerMetalPurchaseFormatters.amount(
                                widget.summary.amount,
                              ),
                            ),
                            _MetalMetric(
                              label: 'Paid',
                              value: CustomerMetalPurchaseFormatters.amount(
                                widget.summary.paidAmount,
                              ),
                              valueColor: PurchaseEntryColors.success,
                            ),
                            if (hasPending)
                              _MetalMetric(
                                label: 'Pending',
                                value: CustomerMetalPurchaseFormatters.amount(
                                  widget.summary.pendingAmount,
                                ),
                                valueColor: PurchaseEntryColors.danger,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _MetalCardFooter(
                    entryCount: widget.summary.entryCount,
                    customerCount: widget.summary.customerCount,
                    accent: visuals.accent,
                    tint: visuals.softTint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetalCardHeader extends StatelessWidget {
  final String periodLabel;
  final CustomerMetalPurchaseMetalSummary summary;
  final CustomerMetalPurchaseMetalVisuals visuals;
  final bool selected;

  const _MetalCardHeader({
    required this.periodLabel,
    required this.summary,
    required this.visuals,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: visuals.softTint.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: visuals.accent.withValues(alpha: 0.20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            visuals.assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              visuals.fallbackIcon,
              color: visuals.accent,
              size: 27,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      summary.metal.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: PurchaseEntryColors.textMain,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    _SelectedPill(accent: visuals.accent),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                periodLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedPill extends StatelessWidget {
  final Color accent;

  const _SelectedPill({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Icon(Icons.check_rounded, color: accent, size: 17),
    );
  }
}

class _MetalMetricRail extends StatelessWidget {
  final List<_MetalMetric> metrics;

  const _MetalMetricRail({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          const spacing = 10.0;
          final width = (constraints.maxWidth - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: 10,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: width,
                  child: _CompactMetricCell(metric: metric),
                ),
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              Expanded(child: _MetricCell(metric: metrics[index])),
              if (index != metrics.length - 1)
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFFE5E7EB),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  final _MetalMetric metric;

  const _MetricCell({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            metric.value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: metric.valueColor ?? PurchaseEntryColors.textMain,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactMetricCell extends StatelessWidget {
  final _MetalMetric metric;

  const _CompactMetricCell({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: _MetricCell(metric: metric),
    );
  }
}

class _MetalCardFooter extends StatelessWidget {
  final int entryCount;
  final int customerCount;
  final Color accent;
  final Color tint;

  const _MetalCardFooter({
    required this.entryCount,
    required this.customerCount,
    required this.accent,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          _FooterMetric(
            icon: Icons.receipt_long_rounded,
            label: _countLabel(entryCount, 'line'),
            accent: accent,
          ),
          const SizedBox(width: 18),
          Container(width: 1, height: 19, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 18),
          _FooterMetric(
            icon: Icons.groups_2_rounded,
            label: _countLabel(customerCount, 'seller'),
            accent: accent,
          ),
        ],
      ),
    );
  }

  String _countLabel(int count, String noun) {
    return '$count ${count == 1 ? noun : '${noun}s'}';
  }
}

class _FooterMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _FooterMetric({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: PurchaseEntryColors.textMain,
          ),
        ),
      ],
    );
  }
}

class _MetalMetric {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetalMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });
}
