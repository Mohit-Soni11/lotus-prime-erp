part of '../stock_summary_screen.dart';

enum _MovementFeedFilter { all, added, sold }

class _RecentMovementPanel extends StatefulWidget {
  final List<StockSummaryMovement> records;

  const _RecentMovementPanel({required this.records});

  @override
  State<_RecentMovementPanel> createState() => _RecentMovementPanelState();
}

class _RecentMovementPanelState extends State<_RecentMovementPanel> {
  _MovementFeedFilter _filter = _MovementFeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final visibleRecords = widget.records
        .where((record) => _matchesFilter(record, _filter))
        .toList(growable: false);

    return _SummaryPanel(
      title: 'Recent Stock Movement',
      subtitle: _subtitleFor(_filter),
      icon: Icons.timeline_rounded,
      action: _MovementFilterTabs(
        selected: _filter,
        allCount: widget.records.length,
        addedCount: widget.records.where((record) => record.isInward).length,
        soldCount: widget.records.where((record) => record.isSold).length,
        onChanged: (filter) => setState(() => _filter = filter),
      ),
      child: widget.records.isEmpty
          ? const _SummaryEmptyState(message: 'No stock movement recorded yet.')
          : visibleRecords.isEmpty
              ? _SummaryEmptyState(message: _emptyMessageFor(_filter))
              : Column(
                  children: [
                    for (final record in visibleRecords) ...[
                      _MovementSummaryRow(record: record),
                      if (record != visibleRecords.last)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
    );
  }

  bool _matchesFilter(
    StockSummaryMovement record,
    _MovementFeedFilter filter,
  ) {
    switch (filter) {
      case _MovementFeedFilter.added:
        return record.isInward;
      case _MovementFeedFilter.sold:
        return record.isSold;
      case _MovementFeedFilter.all:
        return true;
    }
  }

  String _subtitleFor(_MovementFeedFilter filter) {
    switch (filter) {
      case _MovementFeedFilter.added:
        return 'Only latest inward stock entries.';
      case _MovementFeedFilter.sold:
        return 'Only latest sold inventory entries.';
      case _MovementFeedFilter.all:
        return 'Latest inward, sold and restored inventory activity.';
    }
  }

  String _emptyMessageFor(_MovementFeedFilter filter) {
    switch (filter) {
      case _MovementFeedFilter.added:
        return 'No added stock movement found in recent activity.';
      case _MovementFeedFilter.sold:
        return 'No sold stock movement found in recent activity.';
      case _MovementFeedFilter.all:
        return 'No stock movement recorded yet.';
    }
  }
}

class _MovementFilterTabs extends StatelessWidget {
  final _MovementFeedFilter selected;
  final int allCount;
  final int addedCount;
  final int soldCount;
  final ValueChanged<_MovementFeedFilter> onChanged;

  const _MovementFilterTabs({
    required this.selected,
    required this.allCount,
    required this.addedCount,
    required this.soldCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8DDC9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MovementFilterTab(
            label: 'All',
            count: allCount,
            selected: selected == _MovementFeedFilter.all,
            accent: InvColors.brandGold,
            onTap: () => onChanged(_MovementFeedFilter.all),
          ),
          _MovementFilterTab(
            label: 'Added',
            count: addedCount,
            selected: selected == _MovementFeedFilter.added,
            accent: InvColors.success,
            onTap: () => onChanged(_MovementFeedFilter.added),
          ),
          _MovementFilterTab(
            label: 'Sold',
            count: soldCount,
            selected: selected == _MovementFeedFilter.sold,
            accent: InvColors.danger,
            onTap: () => onChanged(_MovementFeedFilter.sold),
          ),
        ],
      ),
    );
  }
}

class _MovementFilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _MovementFilterTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : InvColors.textDark,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementSummaryRow extends StatelessWidget {
  final StockSummaryMovement record;

  const _MovementSummaryRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final accent = record.isSold
        ? InvColors.danger
        : record.isRestore
            ? const Color(0xFF2563EB)
            : InvColors.success;
    final label = record.isSold
        ? 'Sold'
        : record.isRestore
            ? 'Restored'
            : 'Added';
    return _SummaryRowShell(
      accent: accent,
      icon: record.isSold
          ? Icons.point_of_sale_rounded
          : record.isRestore
              ? Icons.restore_rounded
              : Icons.add_business_rounded,
      title: '$label | ${_fallback(record.itemName, 'Stock Item')}',
      subtitle: [
        _fallback(record.metal, 'Metal'),
        if (record.sourceNumber.trim().isNotEmpty) record.sourceNumber,
        _summaryDate(record.occurredAt),
      ].join(' | '),
      metrics: [
        _InlineMetric(label: 'PCS', value: record.quantity.toString()),
        _InlineMetric(
          label: 'Net',
          value: '${_summaryWeight(record.netWeight)} g',
        ),
      ],
    );
  }
}

class _SummaryRowShell extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> metrics;

  const _SummaryRowShell({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADCC5)),
      ),
      child: Row(
        children: [
          _SummaryIconBox(icon: icon, accent: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryStrongStyle(fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _summaryMutedStyle(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Wrap(spacing: 10, runSpacing: 10, children: metrics),
        ],
      ),
    );
  }
}
