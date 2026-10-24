part of 'defaulter_data_table.dart';

class _AccountMetrics extends StatelessWidget {
  final DefaulterModel account;

  const _AccountMetrics({required this.account});

  @override
  Widget build(BuildContext context) {
    if (account.isRecoverySettled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DefaulterColors.riskMetricBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: DefaulterColors.riskMetricBorder),
        ),
        child: Text(
          switch (account.recoveryDispositionStatus) {
            'MELTED' => 'Item melted · Account closed',
            'SOLD' => 'Item sold · Account closed',
            _ => 'Recovery closed',
          },
          style: DefaulterStyles.customerCity.copyWith(
            color: DefaulterColors.bodyTextMain,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    final metrics = [
      (
        'Principal Due',
        account.principalOutstanding,
        DefaulterColors.statPrincipalText,
        false
      ),
      (
        'Interest Due',
        account.interestOutstanding,
        DefaulterColors.riskCriticalText,
        false
      ),
      (
        'Total to Collect',
        account.totalDue,
        DefaulterColors.riskCriticalText,
        true
      ),
      (
        'Already Collected',
        account.totalReceived,
        DefaulterColors.statReceivedText,
        false
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
                ? 2
                : 1;
        const spacing = 9.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map((metric) => _MetricTile(
                    width: width,
                    label: metric.$1,
                    value: DefaulterLogic.formatAmountCompact(metric.$2),
                    color: metric.$3,
                    highlighted: metric.$4,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Color color;
  final bool highlighted;

  const _MetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.065)
            : DefaulterColors.riskMetricBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: highlighted
              ? color.withValues(alpha: 0.22)
              : DefaulterColors.riskMetricBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DefaulterStyles.customerCity.copyWith(
              color: DefaulterColors.bodyTextMain,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: DefaulterStyles.amountText.copyWith(
                color: color,
                fontSize: highlighted ? 19 : 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
