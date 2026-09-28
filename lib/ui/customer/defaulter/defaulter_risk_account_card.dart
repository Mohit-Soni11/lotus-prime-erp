part of 'defaulter_data_table.dart';

class _RiskAccountCard extends StatefulWidget {
  final DefaulterModel account;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenInterestEntry;
  final VoidCallback onOpenContactRecovery;

  const _RiskAccountCard({
    super.key,
    required this.account,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenContactRecovery,
  });

  @override
  State<_RiskAccountCard> createState() => _RiskAccountCardState();
}

class _RiskAccountCardState extends State<_RiskAccountCard> {
  bool _hovered = false;
  bool _mobileVisible = false;

  @override
  Widget build(BuildContext context) {
    final account = widget.account;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered
              ? DefaulterColors.riskCardHoverBg
              : DefaulterColors.riskCardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _riskBorder(account.riskLevel).withValues(
              alpha: _hovered ? 0.62 : 0.30,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? DefaulterColors.shadowMedium
                  : DefaulterColors.shadowLight,
              blurRadius: _hovered ? 12 : 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 980;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AccountIdentity(
                    account: account,
                    mobileVisible: _mobileVisible,
                    onRevealMobile: _revealMobile,
                  ),
                  const SizedBox(height: 12),
                  _AccountMetrics(account: account),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _AccountActions(
                      account: account,
                      onOpenAccount: widget.onOpenAccount,
                      onOpenInterestEntry: widget.onOpenInterestEntry,
                      onOpenContactRecovery: widget.onOpenContactRecovery,
                      onRevealMobile: _revealMobile,
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: _AccountIdentity(
                    account: account,
                    mobileVisible: _mobileVisible,
                    onRevealMobile: _revealMobile,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 8,
                  child: _AccountMetrics(account: account),
                ),
                const SizedBox(width: 14),
                _AccountActions(
                  account: account,
                  onOpenAccount: widget.onOpenAccount,
                  onOpenInterestEntry: widget.onOpenInterestEntry,
                  onOpenContactRecovery: widget.onOpenContactRecovery,
                  onRevealMobile: _revealMobile,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _riskBorder(DefaulterRiskLevel level) {
    switch (level) {
      case DefaulterRiskLevel.critical:
        return DefaulterColors.riskCriticalBorder;
      case DefaulterRiskLevel.high:
        return DefaulterColors.riskHighBorder;
      case DefaulterRiskLevel.medium:
        return DefaulterColors.riskMediumBorder;
      case DefaulterRiskLevel.low:
        return DefaulterColors.riskLowBorder;
    }
  }

  void _revealMobile() async {
    await Clipboard.setData(ClipboardData(text: widget.account.mobile));
    if (!mounted) return;
    if (_mobileVisible) return;
    setState(() => _mobileVisible = true);
  }
}
