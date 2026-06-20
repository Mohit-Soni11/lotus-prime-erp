part of '../girvi_list_screen.dart';

extension _GirviLedgerOverview on _GirviListScreenState {
  Widget _buildPortfolioOverview() {
    final summary = _controller.summary;
    final openTickets = summary.totalActive + summary.totalOverdue;
    final closedTickets = summary.totalReleased + summary.totalAuctioned;

    final metrics = [
      _OverviewMetricData(
        label: 'Active Principal',
        value: _money(summary.totalPrincipalActive),
        caption: '$openTickets open tickets',
        icon: GirviIcons.loanTerms,
        color: GirviColors.brandGold,
      ),
      _OverviewMetricData(
        label: 'Interest Due',
        value: _money(summary.totalInterestDue),
        caption: 'Accrued unpaid interest',
        icon: GirviIcons.interestRate,
        color: GirviColors.warning,
      ),
      _OverviewMetricData(
        label: 'Overdue',
        value: summary.totalOverdue.toString(),
        caption: 'Tickets needing action',
        icon: GirviIcons.overdue,
        color: GirviColors.danger,
      ),
      _OverviewMetricData(
        label: 'Collected This Month',
        value: _money(summary.totalCollectedThisMonth),
        caption: '$closedTickets closed tickets',
        icon: GirviIcons.cash,
        color: GirviColors.success,
      ),
    ];

    return _LedgerSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LedgerSectionHeader(
            icon: GirviIcons.list,
            color: GirviColors.brandGold,
            title: 'Portfolio Overview',
            subtitle: 'Live position of the Girvi loan book',
            trailing: _LedgerStatusBadge(
              icon: GirviIcons.active,
              label: '${summary.totalActive} active',
              color: GirviColors.success,
            ),
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

class _OverviewMetricTile extends StatelessWidget {
  final _OverviewMetricData metric;

  const _OverviewMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 114),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: metric.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: metric.color.withValues(alpha: 0.18)),
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
    );
  }
}
