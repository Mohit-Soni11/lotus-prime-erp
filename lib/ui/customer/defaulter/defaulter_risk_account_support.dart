part of 'defaulter_data_table.dart';

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: DefaulterColors.bodyBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DefaulterColors.bodyBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: DefaulterColors.bodyTextMuted),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              style: DefaulterStyles.customerMobile.copyWith(fontSize: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    final clickable = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
    if (tooltip == null) return clickable;
    return Tooltip(message: tooltip!, child: clickable);
  }
}

class _RiskBadge extends StatelessWidget {
  final DefaulterRiskLevel level;
  final String? label;

  const _RiskBadge({required this.level, this.label});

  @override
  Widget build(BuildContext context) {
    final config = _riskConfig(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: config.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: config.dot,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label ?? config.label,
            style: DefaulterStyles.riskBadgeText.copyWith(color: config.text),
          ),
        ],
      ),
    );
  }
}

class _RecoveryClosedBadge extends StatelessWidget {
  const _RecoveryClosedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: DefaulterColors.statReceivedBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: DefaulterColors.statReceivedText.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'RECOVERY CLOSED',
        style: DefaulterStyles.riskBadgeText.copyWith(
          color: DefaulterColors.statReceivedText,
        ),
      ),
    );
  }
}

class _PromiseMonitoringBadge extends StatelessWidget {
  const _PromiseMonitoringBadge();

  @override
  Widget build(BuildContext context) => const _FollowUpBadge(
        label: 'PROMISE MONITORING',
        color: DefaulterColors.riskMediumText,
      );
}

class _FollowUpDueBadge extends StatelessWidget {
  const _FollowUpDueBadge();

  @override
  Widget build(BuildContext context) => const _FollowUpBadge(
        label: 'ACTION DUE',
        color: DefaulterColors.riskCriticalText,
      );
}

class _FollowUpBadge extends StatelessWidget {
  const _FollowUpBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: DefaulterStyles.riskBadgeText.copyWith(color: color),
        ),
      );
}

_RiskConfig _riskConfig(DefaulterRiskLevel level) {
  switch (level) {
    case DefaulterRiskLevel.critical:
      return const _RiskConfig(
        label: DefaulterStrings.riskCritical,
        bg: DefaulterColors.riskCriticalBg,
        border: DefaulterColors.riskCriticalBorder,
        text: DefaulterColors.riskCriticalText,
        dot: DefaulterColors.riskCriticalDot,
      );
    case DefaulterRiskLevel.high:
      return const _RiskConfig(
        label: DefaulterStrings.riskHigh,
        bg: DefaulterColors.riskHighBg,
        border: DefaulterColors.riskHighBorder,
        text: DefaulterColors.riskHighText,
        dot: DefaulterColors.riskHighDot,
      );
    case DefaulterRiskLevel.medium:
      return const _RiskConfig(
        label: DefaulterStrings.riskMedium,
        bg: DefaulterColors.riskMediumBg,
        border: DefaulterColors.riskMediumBorder,
        text: DefaulterColors.riskMediumText,
        dot: DefaulterColors.riskMediumDot,
      );
    case DefaulterRiskLevel.low:
      return const _RiskConfig(
        label: DefaulterStrings.riskLow,
        bg: DefaulterColors.riskLowBg,
        border: DefaulterColors.riskLowBorder,
        text: DefaulterColors.riskLowText,
        dot: DefaulterColors.riskLowDot,
      );
  }
}

class _RiskConfig {
  final String label;
  final Color bg;
  final Color border;
  final Color text;
  final Color dot;

  const _RiskConfig({
    required this.label,
    required this.bg,
    required this.border,
    required this.text,
    required this.dot,
  });
}
