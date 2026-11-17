part of '../metal_rate_detail_screen.dart';

class _HistoryCard extends StatefulWidget {
  final List<MetalRateHistoryEntry> history;
  final Color accent;
  final String purityLabel;
  final MetalRatePriceUnit priceUnit;
  const _HistoryCard(
      {required this.history,
      required this.accent,
      required this.purityLabel,
      required this.priceUnit});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  MetalRateHistoryPeriod _period = MetalRateHistoryPeriod.current;

  @override
  Widget build(BuildContext context) {
    final view = MetalRateHistoryView.build(widget.history, _period);
    return _DetailSection(
      icon: Icons.history_rounded,
      title: 'Rate History',
      accent: widget.accent,
      child: LayoutBuilder(builder: (context, constraints) {
        final trend = _HistoryTrend(
          view: view,
          accent: widget.accent,
          purityLabel: widget.purityLabel,
          priceUnit: widget.priceUnit,
          onPeriodChanged: (period) => setState(() => _period = period),
        );
        final revisions = _HistoryEntries(
            entries: view.revisions,
            accent: widget.accent,
            priceUnit: widget.priceUnit);
        if (constraints.maxWidth < 950) {
          return Column(
              children: [trend, const SizedBox(height: 12), revisions]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: trend),
          const SizedBox(width: 14),
          Expanded(flex: 2, child: revisions),
        ]);
      }),
    );
  }
}

TextStyle _historyText({double size = 13, Color? color}) =>
    MetalRateDetailStyles.body.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color ?? MetalRateColors.textDark,
    );

String _compactMoney(double value) {
  if (value <= 0) return '—';
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.round().toString();
}
