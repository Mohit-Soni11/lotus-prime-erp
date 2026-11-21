part of '../metal_rate_detail_screen.dart';

class _HistoryCard extends StatefulWidget {
  final List<MetalRateHistoryEntry> history;
  final Color accent;
  final List<String> purityLabels;
  final MetalRatePriceUnit priceUnit;
  const _HistoryCard(
      {required this.history,
      required this.accent,
      required this.purityLabels,
      required this.priceUnit});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  MetalRateHistoryPeriod _period = MetalRateHistoryPeriod.current;
  String? _selectedPurity;

  @override
  void didUpdateWidget(covariant _HistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedPurity != null &&
        !widget.purityLabels.contains(_selectedPurity)) {
      _selectedPurity = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPurity = _selectedPurity ??
        (widget.purityLabels.isEmpty ? null : widget.purityLabels.first);
    final view = MetalRateHistoryView.build(
      widget.history,
      _period,
      purityLabel: selectedPurity,
    );
    return _DetailSection(
      icon: Icons.history_rounded,
      title: 'Rate History',
      accent: widget.accent,
      child: LayoutBuilder(builder: (context, constraints) {
        final trend = _HistoryTrend(
          view: view,
          accent: widget.accent,
          purityLabel: selectedPurity ?? 'Metal',
          purityLabels: widget.purityLabels,
          priceUnit: widget.priceUnit,
          onPeriodChanged: (period) => setState(() => _period = period),
          onPurityChanged: (purity) => setState(() => _selectedPurity = purity),
        );
        final revisions = _HistoryEntries(
            entries: view.changeEntries
                .where((revision) => revision.summaryChanges.isNotEmpty)
                .toList(growable: false),
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
