part of '../metal_rate_detail_screen.dart';

class _HistoryCard extends StatelessWidget {
  final List<MetalRateHistoryEntry> history;
  final Color accent;

  const _HistoryCard({
    required this.history,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final visible = history.take(8).toList(growable: false);

    return _SectionCard(
      icon: MetalRateIcons.benchmark,
      title: 'Rate History',
      subtitle:
          'Saved database log with daily movement for audit and bill verification.',
      color: accent,
      child: visible.isEmpty
          ? _InfoLine(
              text:
                  'No saved history yet. Save rates once to create the first daily log.',
              color: accent,
            )
          : Column(
              children: [
                if (visible.length >= 2) ...[
                  _RateHistoryChart(history: visible, accent: accent),
                  const SizedBox(height: 12),
                ],
                ...visible.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry == visible.last ? 0 : 8,
                    ),
                    child: _HistoryRow(entry: entry, accent: accent),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RateHistoryChart extends StatelessWidget {
  final List<MetalRateHistoryEntry> history;
  final Color accent;

  const _RateHistoryChart({
    required this.history,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final ordered = history.reversed
        .where((entry) => entry.profile.primaryShopRatePer10g > 0)
        .toList(growable: false);
    final values =
        ordered.map((entry) => entry.profile.primaryShopRatePer10g).toList();
    if (values.length < 2) {
      return const SizedBox.shrink();
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = math.max((maxValue - minValue) * 0.18, maxValue * 0.015);
    final minY = math.max(0, minValue - padding).toDouble();
    final maxY = (maxValue + padding).toDouble();

    return Container(
      height: 218,
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 10),
      decoration: MetalRateStyles.softPanel(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(MetalRateIcons.market, color: accent, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Selling Rate Trend',
                  style: MetalRateStyles.cardTitle,
                ),
              ),
              Text(
                '${DateFormat('dd MMM').format(ordered.first.changedAt)} - ${DateFormat('dd MMM').format(ordered.last.changedAt)}',
                style: MetalRateStyles.smallLabel.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (ordered.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxY == minY ? 1 : math.max((maxY - minY) / 3, 1),
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: MetalRateColors.cardBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      getTitlesWidget: (value, meta) => Text(
                        _compactMoney(value),
                        style: GoogleFonts.inter(
                          color: MetalRateColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= ordered.length) {
                          return const SizedBox.shrink();
                        }
                        if (ordered.length > 5 &&
                            index != 0 &&
                            index != ordered.length - 1 &&
                            index.isOdd) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('dd/MM')
                                .format(ordered[index].changedAt),
                            style: GoogleFonts.inter(
                              color: MetalRateColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < ordered.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    color: accent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3.4,
                        color: MetalRateColors.cardBg,
                        strokeWidth: 2,
                        strokeColor: accent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.20),
                          accent.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final index = spot.x.round();
                      final entry = ordered[index];
                      return LineTooltipItem(
                        '${DateFormat('dd MMM yyyy').format(entry.changedAt)}\n${_money(entry.profile.primaryShopRatePer10g)}',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MetalRateHistoryEntry entry;
  final Color accent;

  const _HistoryRow({
    required this.entry,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final changedAt =
        DateFormat('dd MMM yyyy, hh:mm a').format(entry.changedAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MetalRateColors.inputBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: MetalRateColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: MetalRateStyles.softPanel(accent),
            child: Icon(MetalRateIcons.save, color: accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  changedAt,
                  style: GoogleFonts.inter(
                    color: MetalRateColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sell ${_money(entry.profile.primaryShopRatePer10g)} | Buy ${_money(entry.profile.primaryBuyRatePer10g)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MetalRateColors.textBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalRateStyles.smallLabel.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

String _compactMoney(double value) {
  if (value <= 0) {
    return '--';
  }
  if (value >= 100000) {
    return '${(value / 100000).toStringAsFixed(1)}L';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }
  return value.round().toString();
}
