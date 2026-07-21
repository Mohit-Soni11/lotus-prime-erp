part of '../stock_summary_screen.dart';

class _StockSummaryMarketRefillPanel extends StatelessWidget {
  final int soldUnits;
  final double soldWeight;

  const _StockSummaryMarketRefillPanel({
    required this.soldUnits,
    required this.soldWeight,
  });

  @override
  Widget build(BuildContext context) {
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
                      'Market Refill Report',
                      style: _summaryStrongStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sold metal and item list for your next stock purchase trip.',
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
              _InlineMetric(label: 'Sold', value: '$soldUnits pcs'),
              _InlineMetric(
                label: 'Sold Net',
                value: '${_summaryWeight(soldWeight)} g',
              ),
              _PanelActionButton(
                label: 'Open Report',
                icon: Icons.arrow_forward_rounded,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MarketRefillReportScreen(),
                    ),
                  );
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
}
