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
    final current =
        view.points.isEmpty ? 0.0 : priceUnit.toMarket(view.points.last.rate);
    final change = priceUnit.toMarket(view.change);
    return Container(
      height: 310,
      padding: const EdgeInsets.all(16),
      decoration: MetalRateDetailStyles.tint(accent),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Selling Rate Trend',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _historyText(size: 15)),
          ),
          const SizedBox(width: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  style: MetalRateDetailStyles.value.copyWith(fontSize: 22)),
              Text('/ ${priceUnit.label}', style: _historyText(size: 12)),
              if (view.points.isNotEmpty)
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
            child: view.points.isEmpty
                ? Center(
                    child: Text('No saved rate for this period',
                        style: _historyText()))
                : _HistoryLineChart(
                    view: view, accent: accent, priceUnit: priceUnit)),
      ]),
    );
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

class _HistoryLineChart extends StatelessWidget {
  final MetalRateHistoryView view;
  final Color accent;
  final MetalRatePriceUnit priceUnit;
  const _HistoryLineChart(
      {required this.view, required this.accent, required this.priceUnit});

  @override
  Widget build(BuildContext context) {
    final points = view.points;
    final values =
        points.map((point) => priceUnit.toMarket(point.rate)).toList();
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final padding = math.max((high - low) * 0.18, high * 0.008);
    final minY = math.max(0, low - padding).toDouble();
    final maxY = high + padding;
    final duration = view.end.difference(view.start).inMilliseconds;
    final spots = [
      for (final point in points)
        FlSpot(
            duration == 0
                ? 0
                : point.time.difference(view.start).inMilliseconds / duration,
            priceUnit.toMarket(point.rate)),
    ];
    return LineChart(LineChartData(
      minX: 0,
      maxX: 1,
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: math.max((maxY - minY) / 3, 1),
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: MetalRateColors.cardBorder, strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) =>
                    Text(_compactMoney(value), style: _historyText(size: 10)))),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval:
                    view.period == MetalRateHistoryPeriod.year ? 0.25 : 0.5,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value > 1) return const SizedBox.shrink();
                  final time = view.start
                      .add(Duration(milliseconds: (duration * value).round()));
                  final format = switch (view.period) {
                    MetalRateHistoryPeriod.current => DateFormat('h a'),
                    MetalRateHistoryPeriod.month => DateFormat('d MMM'),
                    MetalRateHistoryPeriod.year => DateFormat('MMM'),
                  };
                  return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(format.format(time),
                          style: _historyText(size: 10)));
                })),
      ),
      lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (spots) => [
          for (final spot in spots)
            LineTooltipItem(
                '${DateFormat('d MMM, h:mm a').format(points[spot.spotIndex].time)}\n'
                '${_money(spot.y)} / ${priceUnit.label}',
                _historyText(size: 12, color: Colors.white)),
        ],
      )),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          color: accent,
          barWidth: 3,
          isCurved: false,
          isStepLineChart: true,
          dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: index == spots.length - 1 ? 4 : 2.5,
                  color: Colors.white,
                  strokeColor: accent,
                  strokeWidth: 2)),
          belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.01)
                ],
              )),
        )
      ],
    ));
  }
}
