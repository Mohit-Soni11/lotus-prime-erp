part of '../metal_rate_detail_screen.dart';

class _HistoryCard extends StatefulWidget {
  final List<MetalRateHistoryEntry> history;
  final Color accent;
  final String purityLabel;
  const _HistoryCard({
    required this.history,
    required this.accent,
    required this.purityLabel,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  int _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    final entries = _rangeDays == 0
        ? widget.history
        : widget.history
            .where((entry) => !entry.changedAt.isBefore(cutoff))
            .toList();
    return _DetailSection(
      icon: Icons.access_time_rounded,
      title: 'Rate History',
      subtitle: 'Saved rate revisions for audit and bill verification.',
      accent: widget.accent,
      child: LayoutBuilder(builder: (context, constraints) {
        final trend = _HistoryTrend(
          history: entries,
          accent: widget.accent,
          purityLabel: widget.purityLabel,
          rangeDays: _rangeDays,
          onRangeChanged: (value) => setState(() => _rangeDays = value),
        );
        final list = _HistoryEntries(entries: entries, accent: widget.accent);
        if (constraints.maxWidth < 1050) {
          return Column(children: [
            trend,
            const SizedBox(height: 12),
            list,
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: trend),
          const SizedBox(width: 14),
          Expanded(flex: 2, child: list),
        ]);
      }),
    );
  }
}

class _HistoryTrend extends StatelessWidget {
  final List<MetalRateHistoryEntry> history;
  final Color accent;
  final String purityLabel;
  final int rangeDays;
  final ValueChanged<int> onRangeChanged;
  const _HistoryTrend({
    required this.history,
    required this.accent,
    required this.purityLabel,
    required this.rangeDays,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final points = history.reversed
        .where((entry) => entry.profile.primaryShopRatePer10g > 0)
        .toList(growable: false);
    return Container(
      height: 205,
      padding: const EdgeInsets.all(13),
      decoration: MetalRateDetailStyles.tint(accent),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Text('Selling Rate Trend ($purityLabel)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalRateDetailStyles.body.copyWith(
                      color: MetalRateColors.textDark,
                      fontWeight: FontWeight.w900))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MetalRateColors.cardBorder)),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
              value: rangeDays,
              isDense: true,
              style: MetalRateDetailStyles.body.copyWith(
                  color: MetalRateColors.textDark, fontWeight: FontWeight.w700),
              items: const [
                DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                DropdownMenuItem(value: 90, child: Text('Last 90 days')),
                DropdownMenuItem(value: 0, child: Text('All history')),
              ],
              onChanged: (value) {
                if (value != null) onRangeChanged(value);
              },
            )),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
            child: points.length < 2
                ? Center(
                    child: Text(
                        points.isEmpty
                            ? 'No saved rates in this period'
                            : 'Save another rate to see the trend',
                        style: MetalRateDetailStyles.body))
                : _HistoryLineChart(points: points, accent: accent)),
      ]),
    );
  }
}

class _HistoryLineChart extends StatelessWidget {
  final List<MetalRateHistoryEntry> points;
  final Color accent;
  const _HistoryLineChart({required this.points, required this.accent});

  @override
  Widget build(BuildContext context) {
    final values =
        points.map((entry) => entry.profile.primaryShopRatePer10g).toList();
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final padding = math.max((high - low) * 0.18, high * 0.008);
    final minY = math.max(0, low - padding).toDouble();
    final maxY = high + padding;
    return LineChart(LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: math.max((maxY - minY) / 3, 1),
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: MetalRateColors.cardBorder, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) => Text(_compactMoney(value),
              style: MetalRateDetailStyles.body.copyWith(fontSize: 10)),
        )),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 23,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 ||
                index >= points.length ||
                (index != 0 &&
                    index != points.length - 1 &&
                    points.length > 4)) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(DateFormat('dd MMM').format(points[index].changedAt),
                  style: MetalRateDetailStyles.body.copyWith(fontSize: 10)),
            );
          },
        )),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < values.length; i++)
              FlSpot(i.toDouble(), values[i]),
          ],
          color: accent,
          barWidth: 2.5,
          dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3.4,
                  color: Colors.white,
                  strokeColor: accent,
                  strokeWidth: 2)),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accent.withValues(alpha: 0.20),
                accent.withValues(alpha: 0.01)
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

class _HistoryEntries extends StatelessWidget {
  final List<MetalRateHistoryEntry> entries;
  final Color accent;
  const _HistoryEntries({required this.entries, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        height: 205,
        padding: const EdgeInsets.all(5),
        decoration: MetalRateDetailStyles.tint(accent),
        child: entries.isEmpty
            ? Center(
                child: Text('No saved revisions in this period',
                    style: MetalRateDetailStyles.body))
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 5),
                itemBuilder: (context, index) =>
                    _HistoryEntry(entry: entries[index], accent: accent),
              ),
      );
}

class _HistoryEntry extends StatelessWidget {
  final MetalRateHistoryEntry entry;
  final Color accent;
  const _HistoryEntry({required this.entry, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: MetalRateColors.cardBorder)),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: MetalRateDetailStyles.tint(accent),
            child: Icon(Icons.receipt_long_rounded, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(entry.changedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalRateDetailStyles.body.copyWith(
                        color: MetalRateColors.textDark,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                    'Sell ${_money(entry.profile.primaryShopRatePer10g)}  |  Buy ${_money(entry.profile.primaryBuyRatePer10g)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalRateDetailStyles.body.copyWith(fontSize: 11)),
              ])),
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(maxWidth: 126),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: MetalRateDetailStyles.tint(accent),
            child: Text(entry.source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MetalRateDetailStyles.body.copyWith(
                    fontSize: 10, color: accent, fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

String _compactMoney(double value) {
  if (value <= 0) return '—';
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.round().toString();
}
