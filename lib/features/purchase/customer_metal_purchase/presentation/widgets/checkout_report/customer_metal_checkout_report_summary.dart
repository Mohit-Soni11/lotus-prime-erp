part of '../../screens/customer_metal_checkout_report_screen.dart';

class _SelectedMonthSummaryBand extends StatelessWidget {
  final _CheckoutMonthSummary summary;

  const _SelectedMonthSummaryBand({required this.summary});

  @override
  Widget build(BuildContext context) {
    return CustomerMetalPurchaseFilterSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final periodMetrics = [
            _MetricPill(
                label: 'Selected Month', value: _monthName(summary.month)),
            _MetricPill(label: 'Checkout Lines', value: '${summary.lineCount}'),
            _MetricPill(label: 'Batches', value: '${summary.batchCount}'),
          ];
          final metalSummaries = summary.visibleMetalSummaries;
          final compact = constraints.maxWidth < 840;
          final cardWidth =
              compact ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 10, runSpacing: 10, children: periodMetrics),
              const SizedBox(height: 12),
              if (metalSummaries.isEmpty)
                const CustomerMetalPurchaseEmptyState(
                  message:
                      'No melted metal summary found for the selected month.',
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final metalSummary in metalSummaries)
                      _MetalCheckoutBreakdownCard(
                        width: cardWidth,
                        summary: metalSummary,
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthLedgerSection extends StatelessWidget {
  final String title;
  final List<CustomerMetalPurchaseEntry> entries;

  const _MonthLedgerSection({
    required this.title,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerMetalPurchaseLedgerTable(
      title: title,
      subtitle: entries.isEmpty
          ? 'No metal checkout records found for this month.'
          : '${entries.length} checkout lines ready for audit',
      entries: entries,
      emptyMessage: 'No checkout report data for the selected month.',
      dateColumnLabel: 'Checkout Date',
      dateSelector: (entry) => entry.transferredToMeltingAt ?? entry.date,
    );
  }
}

class _MetalCheckoutBreakdownCard extends StatelessWidget {
  final double width;
  final _CheckoutMetalSummary summary;

  const _MetalCheckoutBreakdownCard({
    required this.width,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = visualsForCustomerPurchaseMetal(summary.metal);

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: visuals.softSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: visuals.accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: visuals.softTint.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: visuals.accent.withValues(alpha: 0.18),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    visuals.assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      visuals.fallbackIcon,
                      size: 19,
                      color: visuals.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${summary.metal.label} Checkout',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _cardTitleStyle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.lineCount} lines | ${summary.batchCount} batches',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _cardSubTitleStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetalMetricTile(
                  label: 'Net Weight',
                  value:
                      CustomerMetalPurchaseFormatters.weight(summary.netWeight),
                ),
                _MetalMetricTile(
                  label: 'Fine Weight',
                  value: CustomerMetalPurchaseFormatters.weight(
                    summary.fineWeight,
                  ),
                ),
                _MetalMetricTile(
                  label: 'Purchase Value',
                  value: CustomerMetalPurchaseFormatters.amount(summary.amount),
                ),
                _MetalMetricTile(
                  label: 'Paid',
                  value: CustomerMetalPurchaseFormatters.amount(
                      summary.paidAmount),
                  valueColor: const Color(0xFF059669),
                ),
                _MetalMetricTile(
                  label: 'Pending',
                  value: CustomerMetalPurchaseFormatters.amount(
                    summary.pendingAmount,
                  ),
                  valueColor: summary.pendingAmount > 0.005
                      ? PurchaseEntryColors.danger
                      : Colors.black,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetalMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetalMetricTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _pillLabelStyle),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pillValueStyle.copyWith(
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8D2C8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _pillLabelStyle),
          Text(value, style: _pillValueStyle),
        ],
      ),
    );
  }
}
