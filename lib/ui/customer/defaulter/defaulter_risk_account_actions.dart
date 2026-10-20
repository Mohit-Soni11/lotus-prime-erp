part of 'defaulter_data_table.dart';

class _AccountActions extends StatelessWidget {
  final DefaulterModel account;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenInterestEntry;
  final VoidCallback onOpenContactRecovery;

  const _AccountActions({
    required this.account,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenContactRecovery,
  });

  @override
  Widget build(BuildContext context) {
    final canManageNotice = account.isNoticeEligible ||
        account.isCollateralRecovery ||
        account.hasNoticeWorkflow;

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionButton(
          icon: DefaulterIcons.openAccount,
          label: DefaulterStrings.btnView,
          color: DefaulterColors.shellBg,
          onTap: onOpenAccount,
        ),
        if (!account.isRecoverySettled)
          _ActionButton(
            icon: DefaulterIcons.collectInterest,
            label: DefaulterStrings.btnInterest,
            color: DefaulterColors.brandGoldDark,
            onTap: onOpenInterestEntry,
          ),
        if (canManageNotice)
          _ActionButton(
            icon: DefaulterIcons.defaulterAlert,
            label: account.isRecoverySettled
                ? 'View Recovery'
                : DefaulterStrings.btnNoticeRecovery,
            color: account.isRecoverySettled
                ? DefaulterColors.statReceivedText
                : DefaulterColors.riskCriticalText,
            onTap: onOpenContactRecovery,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
