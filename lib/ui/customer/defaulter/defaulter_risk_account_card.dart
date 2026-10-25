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
  bool _mobileVisible = false;

  @override
  Widget build(BuildContext context) {
    final account = widget.account;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DefaulterColors.riskCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DefaulterColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
            color: DefaulterColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (account.isRecoverySettled &&
              (account.recoveryDispositionStatus == 'MELTED' ||
                  account.recoveryDispositionStatus == 'SOLD'))
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Text(
                      account.recoveryDispositionStatus!,
                      style: TextStyle(
                        color: DefaulterColors.riskCriticalText
                            .withValues(alpha: 0.26),
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final identity = _AccountIdentity(
                    account: account,
                    mobileVisible: _mobileVisible,
                    onRevealMobile: () => setState(() => _mobileVisible = true),
                  );
                  final actions = _AccountActions(
                    account: account,
                    onOpenAccount: widget.onOpenAccount,
                    onOpenInterestEntry: widget.onOpenInterestEntry,
                    onOpenContactRecovery: widget.onOpenContactRecovery,
                  );
                  if (constraints.maxWidth < 970) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        identity,
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: actions,
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: 16),
                      Flexible(
                        fit: FlexFit.tight,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: actions,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (!account.isRecoverySettled) ...[
                const SizedBox(height: 14),
                Container(height: 1, color: DefaulterColors.bodyBorderLight),
                const SizedBox(height: 14),
                _AccountMetrics(account: account),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
