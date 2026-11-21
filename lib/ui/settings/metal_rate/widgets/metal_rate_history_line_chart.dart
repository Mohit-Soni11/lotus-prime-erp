part of '../metal_rate_detail_screen.dart';

class _HistoryLineChart extends StatelessWidget {
  final MetalRateHistoryView view;
  final Color accent;
  final MetalRatePriceUnit priceUnit;
  const _HistoryLineChart(
      {required this.view, required this.accent, required this.priceUnit});

  @override
  Widget build(BuildContext context) {
    final points = view.points;
    final values = points
        .where((point) => point.isAvailable)
        .map((point) => priceUnit.toMarket(point.rate))
        .toList();
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final padding = math.max((high - low) * 0.18, math.max(high * 0.002, 1));
    final interval = _historyGridInterval(high - low + padding * 2);
    final minY =
        math.max(0, ((low - padding) / interval).floor() * interval).toDouble();
    final maxY = ((high + padding) / interval).ceil() * interval;
    final duration = view.end.difference(view.start).inMilliseconds;
    final spots = [
      for (final point in points)
        if (!point.isAvailable)
          FlSpot.nullSpot
        else
          FlSpot(
              duration == 0
                  ? 0
                  : point.time.difference(view.start).inMilliseconds / duration,
              priceUnit.toMarket(point.rate)),
    ];
    return LayoutBuilder(
        builder: (context, constraints) => LineChart(
            LineChartData(
              minX: 0,
              maxX: 1,
              minY: minY,
              maxY: maxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: MetalRateColors.cardBorder, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 82,
                        interval: interval,
                        getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                  NumberFormat.decimalPattern('en_IN')
                                      .format(value),
                                  textAlign: TextAlign.right,
                                  style: _historyText(size: 10)),
                            ))),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: constraints.maxWidth < 380
                            ? 1
                            : view.period == MetalRateHistoryPeriod.year
                                ? 0.25
                                : 0.5,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > 1) {
                            return const SizedBox.shrink();
                          }
                          final time = view.start.add(Duration(
                              milliseconds: (duration * value).round()));
                          final format = switch (view.period) {
                            MetalRateHistoryPeriod.current =>
                              DateFormat('h:mm a'),
                            MetalRateHistoryPeriod.month => DateFormat('d MMM'),
                            MetalRateHistoryPeriod.year => DateFormat('MMM'),
                          };
                          return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 6,
                              fitInside:
                                  SideTitleFitInsideData.fromTitleMeta(meta),
                              child: Text(format.format(time),
                                  style: _historyText(size: 10)));
                        })),
              ),
              lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                maxContentWidth: 190,
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
                  lineChartStepData: const LineChartStepData(
                      stepDirection: LineChartStepData.stepDirectionForward),
                  dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
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
            ),
            key: const ValueKey('metal-rate-history-chart')));
  }
}

double _historyGridInterval(double range) {
  final target = range / 4;
  final magnitude =
      math.pow(10, (math.log(target) / math.ln10).floor()).toDouble();
  final fraction = target / magnitude;
  final step = fraction <= 1
      ? 1
      : fraction <= 2
          ? 2
          : fraction <= 5
              ? 5
              : 10;
  return step * magnitude;
}
