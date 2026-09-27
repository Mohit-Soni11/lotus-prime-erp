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

  const _RiskBadge({required this.level});

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
            config.label,
            style: DefaulterStyles.riskBadgeText.copyWith(color: config.text),
          ),
        ],
      ),
    );
  }
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
