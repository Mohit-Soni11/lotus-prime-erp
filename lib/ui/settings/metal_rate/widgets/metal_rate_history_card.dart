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
    final visible = history.take(6).toList(growable: false);

    return _SectionCard(
      icon: MetalRateIcons.benchmark,
      title: 'Rate History',
      subtitle:
          'Latest saved counter rates for verification and old bill checks.',
      color: accent,
      child: visible.isEmpty
          ? _InfoLine(
              text:
                  'No saved history yet. Save rates once to create the first daily log.',
              color: accent,
            )
          : Column(
              children: visible
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry == visible.last ? 0 : 8,
                      ),
                      child: _HistoryRow(entry: entry, accent: accent),
                    ),
                  )
                  .toList(),
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
