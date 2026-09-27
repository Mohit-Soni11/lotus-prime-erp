part of 'defaulter_data_table.dart';

class _AccountMetrics extends StatelessWidget {
  final DefaulterModel account;

  const _AccountMetrics({required this.account});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 720
            ? 5
            : maxWidth >= 440
                ? 3
                : 2;
        const spacing = 8.0;
        final tileWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _MetricTile(
              width: tileWidth,
              label: 'Principal Due',
              value: DefaulterLogic.formatAmountCompact(
                account.principalOutstanding,
              ),
              color: DefaulterColors.statPrincipalText,
            ),
            _MetricTile(
              width: tileWidth,
              label: 'Interest Due',
              value: DefaulterLogic.formatAmountCompact(
                account.interestOutstanding,
              ),
              color: DefaulterColors.riskHighText,
              subLabel: '${account.interestRate.toStringAsFixed(2)}% monthly',
            ),
            _MetricTile(
              width: tileWidth,
              label: 'Total Receivable',
              value: DefaulterLogic.formatAmountCompact(account.totalDue),
              color: DefaulterColors.riskCriticalText,
            ),
            _MetricTile(
              width: tileWidth,
              label: 'Collection Age',
              value: account.riskAgeLabel,
              color: _riskConfig(account.riskLevel).text,
              subLabel: account.collectionStage,
            ),
            _MetricTile(
              width: tileWidth,
              label: 'Total Received',
              value: DefaulterLogic.formatAmountCompact(account.totalReceived),
              color: DefaulterColors.statReceivedText,
              subLabel: account.hasPaymentHistory
                  ? 'Collection history'
                  : 'No receipt recorded',
            ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final String? subLabel;
  final Color color;

  const _MetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 98),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DefaulterColors.riskMetricBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DefaulterColors.riskMetricBorder),
          boxShadow: const [
            BoxShadow(
              color: DefaulterColors.shadowLight,
              blurRadius: 7,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: DefaulterStyles.customerCity.copyWith(
                fontWeight: FontWeight.w800,
                color: DefaulterColors.bodyTextMain,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: DefaulterStyles.amountText.copyWith(
                  color: color,
                  fontSize: 16.5,
                ),
                maxLines: 1,
              ),
            ),
            if (subLabel != null && subLabel!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subLabel!,
                style: DefaulterStyles.interestRate.copyWith(
                  fontSize: 12.2,
                  height: 1.15,
                  color: DefaulterColors.bodyTextHint,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
