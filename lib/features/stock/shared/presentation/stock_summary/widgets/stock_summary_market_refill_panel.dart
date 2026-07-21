part of '../stock_summary_screen.dart';

class _StockSummaryMarketRefillPanel extends StatelessWidget {
  final MarketRefillReport report;
  final VoidCallback onReportClosed;

  const _StockSummaryMarketRefillPanel({
    required this.report,
    required this.onReportClosed,
  });

  @override
  Widget build(BuildContext context) {
    final gold = _metalSummary('gold');
    final silver = _metalSummary('silver');
    final totalSold = report.summary.soldQuantity;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8DDC9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final header = Row(
            children: [
              const _SummaryIconBox(
                icon: Icons.storefront_rounded,
                accent: InvColors.brandGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Purchase List',
                      style: _summaryStrongStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sold items waiting for your next market purchase trip.',
                      style: _summaryMutedStyle(),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InlineMetric(label: 'Total Sold', value: '$totalSold unit'),
              _MarketMetalMetric(
                label: 'Gold',
                value: _metalValue(gold),
                lines: gold.itemGroups,
                accent: InvColors.brandGold,
                icon: Icons.workspace_premium_rounded,
              ),
              _MarketMetalMetric(
                label: 'Silver',
                value: _metalValue(silver),
                lines: silver.itemGroups,
                accent: const Color(0xFF64748B),
                icon: Icons.circle_outlined,
              ),
              _PanelActionButton(
                label: 'Open List',
                icon: Icons.arrow_forward_rounded,
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => const MarketRefillReportScreen(),
                        ),
                      )
                      .then((_) => onReportClosed());
                },
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: header),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }

  MarketRefillMetalSummary _metalSummary(String metal) {
    for (final summary in report.metals) {
      if (summary.metal.trim().toLowerCase() == metal) return summary;
    }
    return MarketRefillMetalSummary(
      metal: metal,
      soldQuantity: 0,
      availableQuantity: 0,
      refillQuantity: 0,
      itemGroups: 0,
      soldNetWeight: 0,
      availableNetWeight: 0,
    );
  }

  String _metalValue(MarketRefillMetalSummary summary) {
    if (summary.soldQuantity <= 0) return '0 unit';
    final rows = report.rows
        .where(
          (row) =>
              row.metal.trim().toLowerCase() ==
              summary.metal.trim().toLowerCase(),
        )
        .toList(growable: false);
    final units = rows.map((row) => row.unitLabel).toSet();
    if (units.length == 1) return '${summary.soldQuantity} ${units.single}';
    return '${summary.soldQuantity} unit';
  }
}

class _MarketMetalMetric extends StatelessWidget {
  final String label;
  final String value;
  final int lines;
  final Color accent;
  final IconData icon;

  const _MarketMetalMetric({
    required this.label,
    required this.value,
    required this.lines,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _summaryMutedStyle(fontSize: 10)),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryStrongStyle(fontSize: 12.5),
                ),
                Text(
                  '$lines item',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryMutedStyle(fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
