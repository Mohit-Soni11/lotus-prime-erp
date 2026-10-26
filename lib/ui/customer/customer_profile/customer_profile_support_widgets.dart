part of 'customer_profile_screen.dart';

extension _ProfileSupportWidgets on _CustomerProfileScreenState {
  void _showInfoFeedback(String message) {
    if (!mounted) return;
    AppFeedback.show(
      context,
      type: AppFeedbackType.info,
      message: message,
    );
  }

  Widget _buildLoading({String message = "Loading profile..."}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: CustomerProfileColors.brandGold,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: CustomerProfileColors.bodyTextMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            _logic.error ?? "Something went wrong",
            style: const TextStyle(color: CustomerProfileColors.bodyTextMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _logic.refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomerProfileColors.brandGold,
              foregroundColor: Colors.black,
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: CustomerProfileStyles.sectionIconBox,
          height: CustomerProfileStyles.sectionIconBox,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: CustomerProfileStyles.sectionTitle),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: CustomerProfileColors.bodyTextMuted),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: CustomerProfileStyles.infoLabel),
              Text(value, style: CustomerProfileStyles.infoValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ledgerSummaryBox({
    required String title,
    required String primaryLabel,
    required String primaryValue,
    required String secondaryLabel,
    required String secondaryValue,
    required IconData icon,
    required Color color,
    String? tertiaryLabel,
    String? tertiaryValue,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: CustomerProfileColors.bodyTextMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            primaryLabel,
            style: CustomerProfileStyles.snapshotLabel,
          ),
          const SizedBox(height: 3),
          Text(
            primaryValue,
            style: CustomerProfileStyles.snapshotAmount.copyWith(color: color),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.14)),
            ),
            child: Column(
              children: [
                _summaryInlineMetric(
                  secondaryLabel,
                  secondaryValue,
                  color,
                ),
                if (tertiaryLabel != null && tertiaryValue != null) ...[
                  const SizedBox(height: 6),
                  Divider(height: 1, color: color.withValues(alpha: 0.14)),
                  const SizedBox(height: 6),
                  _summaryInlineMetric(
                    tertiaryLabel,
                    tertiaryValue,
                    color,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryInlineMetric(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CustomerProfileColors.bodyTextMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(CustomerProfileModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.isVip
            ? CustomerProfileColors.vipBg
            : CustomerProfileColors.regularBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.isVip
              ? CustomerProfileColors.vipBorder
              : CustomerProfileColors.regularBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            p.isVip ? CustomerProfileIcons.vip : Icons.person_rounded,
            size: 11,
            color: p.isVip
                ? CustomerProfileColors.vipText
                : CustomerProfileColors.regularText,
          ),
          const SizedBox(width: 4),
          Text(
            p.isVip ? "VIP" : "REGULAR",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: p.isVip
                  ? CustomerProfileColors.vipText
                  : CustomerProfileColors.regularText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStatusBadge(CreditStatus status) {
    final Color bg = status == CreditStatus.clear
        ? CustomerProfileColors.clearBg
        : status == CreditStatus.due
            ? CustomerProfileColors.dueBg
            : CustomerProfileColors.defaulterBg;
    final Color text = status == CreditStatus.clear
        ? CustomerProfileColors.clearText
        : status == CreditStatus.due
            ? CustomerProfileColors.dueText
            : CustomerProfileColors.defaulterText;
    final Color border = status == CreditStatus.clear
        ? CustomerProfileColors.clearBorder
        : status == CreditStatus.due
            ? CustomerProfileColors.dueBorder
            : CustomerProfileColors.defaulterBorder;
    final IconData icon = status == CreditStatus.clear
        ? CustomerProfileIcons.clear
        : status == CreditStatus.due
            ? CustomerProfileIcons.due
            : CustomerProfileIcons.defaulter;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: CustomerProfileColors.bodyTextMuted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: CustomerProfileColors.bodyTextMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              color: CustomerProfileColors.bodyTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double val) {
    if (val >= 100000) return "${(val / 100000).toStringAsFixed(1)}L";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(1)}K";
    return val.toStringAsFixed(0);
  }
}
