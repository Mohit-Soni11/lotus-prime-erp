part of '../contact_recovery_screen.dart';

class _ContactRecoveryOverview extends StatelessWidget {
  final ContactRecoveryState state;

  const _ContactRecoveryOverview({required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1200
              ? 4
              : constraints.maxWidth >= 780
                  ? 2
                  : 1;
          final spacing = columns == 1 ? 10.0 : 14.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: 12,
            children: [
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Notice Queue',
                  value: stats.totalCases.toString(),
                  footer:
                      '${stats.noticeDueCount} ${stats.noticeDueCount == 1 ? 'account' : 'accounts'} in review',
                  accent: GirviColors.warning,
                ),
              ),
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Final Notice',
                  value: stats.finalNoticeCount.toString(),
                  footer: '${state.noticePeriodDays}-day notice cycle',
                  accent: GirviColors.danger,
                ),
              ),
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Net Exposure',
                  value: _money(stats.totalExposure),
                  footer: 'Principal ${_money(stats.principalExposure)}',
                  accent: GirviColors.brandGold,
                ),
              ),
              SizedBox(
                width: width,
                child: _SummaryTile(
                  label: 'Collateral Recovery',
                  value:
                      (stats.disposalReadyCount + stats.recoveryInProgressCount)
                          .toString(),
                  footer:
                      '${stats.recoveryInProgressCount} in collateral recovery',
                  accent: GirviColors.info,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _money(double value) =>
      'Rs ${NumberFormat('#,##,##0', 'en_IN').format(value)}';
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String footer;
  final Color accent;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.footer,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: GirviColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GirviStyles.caption.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
              maxLines: 1,
            ),
          ),
          Text(
            footer,
            style: GirviStyles.caption.copyWith(fontSize: 12.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
