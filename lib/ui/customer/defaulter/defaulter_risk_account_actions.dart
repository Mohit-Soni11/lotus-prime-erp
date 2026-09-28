part of 'defaulter_data_table.dart';

class _AccountActions extends StatefulWidget {
  final DefaulterModel account;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenInterestEntry;
  final VoidCallback onOpenContactRecovery;
  final VoidCallback onRevealMobile;

  const _AccountActions({
    required this.account,
    required this.onOpenAccount,
    required this.onOpenInterestEntry,
    required this.onOpenContactRecovery,
    required this.onRevealMobile,
  });

  @override
  State<_AccountActions> createState() => _AccountActionsState();
}

class _AccountActionsState extends State<_AccountActions> {
  static final DateFormat _noticeDateFmt = DateFormat('dd MMMM yyyy');

  String? _inlineFeedback;
  Color _feedbackColor = DefaulterColors.statReceivedText;

  @override
  Widget build(BuildContext context) {
    final account = widget.account;

    return SizedBox(
      width: 182,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionButton(
            icon: DefaulterIcons.openAccount,
            label: DefaulterStrings.btnView,
            color: DefaulterColors.shellBg,
            onTap: widget.onOpenAccount,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: DefaulterIcons.collectInterest,
            label: DefaulterStrings.btnInterest,
            color: DefaulterColors.brandGoldDark,
            onTap: widget.onOpenInterestEntry,
          ),
          if (account.riskLevel == DefaulterRiskLevel.critical ||
              account.isCollateralRecovery) ...[
            const SizedBox(height: 8),
            _ActionButton(
              icon: DefaulterIcons.defaulterAlert,
              label: 'Contact Review',
              color: DefaulterColors.riskCriticalText,
              onTap: widget.onOpenContactRecovery,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _IconActionButton(
                  icon: DefaulterIcons.phoneCall,
                  tooltip: DefaulterStrings.btnCall,
                  color: DefaulterColors.callBtnBg,
                  onTap: _showMobile,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IconActionButton(
                  icon: DefaulterIcons.notify,
                  tooltip: DefaulterStrings.btnNotify,
                  color: DefaulterColors.notifyBtnBg,
                  onTap: _copyNotice,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _inlineFeedback == null
                ? const SizedBox(height: 10)
                : Padding(
                    key: ValueKey(_inlineFeedback),
                    padding: const EdgeInsets.only(top: 8),
                    child: _InlineActionFeedback(
                      label: _inlineFeedback!,
                      color: _feedbackColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showMobile() {
    widget.onRevealMobile();
    setState(() {
      _feedbackColor = DefaulterColors.callBtnBg;
      _inlineFeedback = 'Mobile number shown above and copied.';
    });
  }

  Future<void> _copyNotice() async {
    final account = widget.account;
    final notice = _buildNoticeMessage(account);
    await Clipboard.setData(ClipboardData(text: notice));
    if (!mounted) return;
    setState(() {
      _feedbackColor = DefaulterColors.notifyBtnBg;
      _inlineFeedback = 'Professional payment reminder copied.';
    });
  }

  String _buildNoticeMessage(DefaulterModel account) {
    final due = DefaulterLogic.formatAmountCompact(account.totalDue);
    final principal =
        DefaulterLogic.formatAmountCompact(account.principalOutstanding);
    final interest =
        DefaulterLogic.formatAmountCompact(account.interestOutstanding);
    final pieceLabel = account.pieces == 1 ? 'piece' : 'pieces';

    return [
      'Subject: Girvi Payment Reminder',
      '',
      'Dear ${account.customerName},',
      '',
      'This is a formal payment reminder for your pledge account. Please review the account details below and clear the pending amount at the earliest.',
      '',
      'Ticket Number: ${account.referenceNo}',
      'Pledged Item: ${account.itemName}',
      'Metal Type: ${account.metalType}',
      'Purity: ${account.purity}',
      'Pieces: ${account.pieces} $pieceLabel',
      'Net Weight: ${account.netWeight.toStringAsFixed(3)} grams',
      '',
      'Total Payable: $due',
      'Principal Outstanding: $principal',
      'Interest Outstanding: $interest',
      'Monthly Interest Rate: ${account.interestRate.toStringAsFixed(2)} percent per month',
      '',
      'Collection Status: ${account.collectionStage}',
      'Collection Age: ${account.riskAgeFullLabel}',
      'Last Activity Date: ${_noticeDateFmt.format(account.lastActivityAt)}',
      '',
      'Please visit the store or contact us to regularise this account.',
      '',
      'Thank you.',
    ].join('\n');
  }
}

class _InlineActionFeedback extends StatelessWidget {
  final String label;
  final Color color;

  const _InlineActionFeedback({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: DefaulterStyles.customerCity.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: DefaulterColors.bodyTextMain,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      ),
    );
  }
}
