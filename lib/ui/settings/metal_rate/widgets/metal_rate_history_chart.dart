part of '../metal_rate_detail_screen.dart';

class _HistoryTrend extends StatelessWidget {
  final MetalRateHistoryView view;
  final Color accent;
  final String purityLabel;
  final List<String> purityLabels;
  final MetalRatePriceUnit priceUnit;
  final ValueChanged<MetalRateHistoryPeriod> onPeriodChanged;
  final ValueChanged<String> onPurityChanged;
  const _HistoryTrend(
      {required this.view,
      required this.accent,
      required this.purityLabel,
      required this.purityLabels,
      required this.priceUnit,
      required this.onPeriodChanged,
      required this.onPurityChanged});

  @override
  Widget build(BuildContext context) {
    final current = priceUnit.toMarket(view.currentRate);
    final change = priceUnit.toMarket(view.change);
    return LayoutBuilder(
        builder: (context, constraints) => Container(
              height: constraints.maxWidth < 430 ? 390 : 350,
              padding: const EdgeInsets.all(16),
              decoration: MetalRateDetailStyles.tint(accent),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text('Selling Rate Trend',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _historyText(size: 15)),
                          _HistoryPeriodFilter(
                              selected: view.period,
                              accent: accent,
                              onChanged: onPeriodChanged),
                        ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 30,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final purity in purityLabels)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                key: ValueKey('history-purity-$purity'),
                                onTap: () => onPurityChanged(purity),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: purity == purityLabel
                                        ? accent.withValues(alpha: 0.16)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: purity == purityLabel
                                            ? accent
                                            : MetalRateColors.cardBorder),
                                  ),
                                  child: Text(_purityLabel(purity),
                                      style: _historyText(size: 11)),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          Text(_money(current),
                              style: MetalRateDetailStyles.value
                                  .copyWith(fontSize: 22)),
                          Text('/ ${priceUnit.label}',
                              style: _historyText(size: 12)),
                          if (view.hasCurrentRate)
                            Text(
                                '${change > 0 ? '+' : change < 0 ? '−' : ''}${change == 0 ? '₹ 0' : _money(change.abs())}  '
                                '(${change > 0 ? '+' : ''}${view.changePercent.toStringAsFixed(1)}%)',
                                style: _historyText(
                                    size: 12,
                                    color: change > 0
                                        ? MetalRateDetailStyles.greenInk
                                        : change < 0
                                            ? MetalRateDetailStyles.orangeInk
                                            : MetalRateColors.textDark)),
                        ]),
                    const SizedBox(height: 12),
                    Expanded(
                        child: !view.hasSavedRate
                            ? Center(
                                child: Text('No saved rate for this period',
                                    style: _historyText()))
                            : _HistoryLineChart(
                                view: view,
                                accent: accent,
                                priceUnit: priceUnit)),
                  ]),
            ));
  }
}

class _HistoryPeriodFilter extends StatelessWidget {
  final MetalRateHistoryPeriod selected;
  final Color accent;
  final ValueChanged<MetalRateHistoryPeriod> onChanged;
  const _HistoryPeriodFilter(
      {required this.selected, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: MetalRateColors.cardBorder),
            borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final period in MetalRateHistoryPeriod.values)
            InkWell(
              key: ValueKey('history-${period.name}'),
              onTap: () => onChanged(period),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                    color: selected == period
                        ? accent.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7)),
                child: Text(
                    switch (period) {
                      MetalRateHistoryPeriod.current => 'Current',
                      MetalRateHistoryPeriod.month => 'Month',
                      MetalRateHistoryPeriod.year => 'Year',
                    },
                    style: _historyText(
                        size: 12,
                        color: selected == period
                            ? accent
                            : MetalRateColors.textDark)),
              ),
            ),
        ]),
      );
}
