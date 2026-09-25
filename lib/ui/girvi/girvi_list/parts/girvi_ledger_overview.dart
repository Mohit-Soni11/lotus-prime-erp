part of '../girvi_list_screen.dart';

extension _GirviLedgerOverview on _GirviListScreenState {
  Widget _buildPortfolioOverview() {
    final summary = _controller.summary;
    final openTickets = summary.totalActive +
        summary.totalOverdue +
        summary.totalReadyForDelivery;

    final metrics = [
      _OverviewMetricData(
        label: 'Principal Outstanding',
        value: _money(summary.totalPrincipalActive),
        caption: '$openTickets open pledge accounts',
        icon: GirviIcons.loanTerms,
        color: GirviColors.brandGold,
      ),
      _OverviewMetricData(
        label: 'Interest Receivable',
        value: _money(summary.totalInterestDue),
        caption: 'Total unpaid interest to collect',
        icon: GirviIcons.interestRate,
        color: GirviColors.warning,
      ),
      _OverviewMetricData(
        label: 'Overdue Receivable',
        value: summary.totalOverdue.toString(),
        caption: 'Receivable ${_money(summary.totalOverdueReceivable)}',
        icon: Icons.event_busy_rounded,
        color: GirviColors.danger,
      ),
      _OverviewMetricData(
        label: 'This Month Collection',
        value: _money(summary.totalCollectedThisMonth),
        caption: 'Interest and release receipts',
        icon: GirviIcons.cash,
        color: GirviColors.success,
      ),
    ];

    return _LedgerSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LedgerSectionHeader(
            icon: GirviIcons.list,
            color: GirviColors.brandGold,
            title: 'Pledge Position',
            subtitle: 'Principal exposure, interest receivable and collections',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1120
                  ? 4
                  : constraints.maxWidth >= 760
                      ? 2
                      : 1;
              const gap = 12.0;
              final tileWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: tileWidth,
                        child: _OverviewMetricTile(metric: metric),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewMetricData {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  const _OverviewMetricData({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });
}

class _OverviewMetricTile extends StatefulWidget {
  final _OverviewMetricData metric;

  const _OverviewMetricTile({required this.metric});

  @override
  State<_OverviewMetricTile> createState() => _OverviewMetricTileState();
}

class _OverviewMetricTileState extends State<_OverviewMetricTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 114),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(_hovered ? 17 : 16),
          decoration: BoxDecoration(
            color: metric.color.withValues(alpha: _hovered ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: metric.color.withValues(alpha: _hovered ? 0.30 : 0.18),
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: metric.color.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              _LedgerIconBox(icon: metric.icon, color: metric.color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        metric.value,
                        style: GoogleFonts.manrope(
                          color: GirviColors.textDark,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: GirviColors.textBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
