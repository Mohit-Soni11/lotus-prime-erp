part of 'due_collection_entry_screen.dart';

class _SettlementPreview extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final DueCollectionBillModel bill;

  const _SettlementPreview({required this.ctrl, required this.bill});

  @override
  Widget build(BuildContext context) {
    final collected = ctrl.amount.clamp(0.0, bill.dueAmount).toDouble();
    final discount = ctrl.discountAmount.clamp(0.0, bill.dueAmount).toDouble();
    final settlement =
        (collected + discount).clamp(0.0, bill.dueAmount).toDouble();
    final balance = ctrl.balanceAfterSave;
    final progress = bill.dueAmount <= 0 ? 0.0 : settlement / bill.dueAmount;
    final isClosing = balance <= 0.5 && settlement > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DueCollectionEntryStyles.flatPanel(
          color: DueCollectionEntryColors.panelSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MoneyLine(
              label: 'Collecting Now',
              value: collected,
              color: DueCollectionEntryColors.success),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _MoneyLine(
                label: 'Discount / Waiver',
                value: discount,
                color: DueCollectionEntryColors.warning),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress.clamp(0.0, 1.0),
              backgroundColor: DueCollectionEntryColors.bodyBorder,
              valueColor: AlwaysStoppedAnimation<Color>(isClosing
                  ? DueCollectionEntryColors.success
                  : DueCollectionEntryColors.brandGold),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  isClosing
                      ? 'Bill will close after save'
                      : 'Partial settlement',
                  style: DueCollectionEntryStyles.label.copyWith(
                    color: isClosing
                        ? DueCollectionEntryColors.success
                        : DueCollectionEntryColors.warning,
                  ),
                ),
              ),
              Text(
                DueCollectionEntryController.formatAmount(balance),
                style: DueCollectionEntryStyles.rowTitle.copyWith(
                  color: isClosing
                      ? DueCollectionEntryColors.success
                      : DueCollectionEntryColors.warning,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StickySaveFooter extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;

  const _StickySaveFooter({
    required this.ctrl,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: DueCollectionEntryColors.bodyPanel,
        border: Border(
          top: BorderSide(color: DueCollectionEntryColors.bodyBorder),
        ),
      ),
      child: _SaveActions(
        ctrl: ctrl,
        onSave: onSave,
        onSaveAndPrint: onSaveAndPrint,
      ),
    );
  }
}

class _SaveActions extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final VoidCallback onSave;
  final VoidCallback onSaveAndPrint;

  const _SaveActions({
    required this.ctrl,
    required this.onSave,
    required this.onSaveAndPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SaveActionButton(
            ctrl: ctrl,
            label: ctrl.isSaving
                ? DueCollectionEntryStrings.saving
                : DueCollectionEntryStrings.saveCollection,
            icon: DueCollectionEntryIcons.save,
            onTap: onSave,
            filled: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SaveActionButton(
            ctrl: ctrl,
            label: DueCollectionEntryStrings.saveAndPrint,
            icon: DueCollectionEntryIcons.printReceipt,
            onTap: onSaveAndPrint,
            filled: false,
          ),
        ),
      ],
    );
  }
}

class _SaveActionButton extends StatelessWidget {
  final DueCollectionEntryController ctrl;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _SaveActionButton({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = ctrl.canAttemptSave;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? (filled
                  ? DueCollectionEntryColors.brandGold
                  : DueCollectionEntryColors.bodyPanel)
              : DueCollectionEntryColors.bodyBorder,
          borderRadius: BorderRadius.circular(10),
          border: filled
              ? null
              : Border.all(
                  color: enabled
                      ? DueCollectionEntryColors.brandGold
                      : DueCollectionEntryColors.bodyBorder),
          boxShadow: enabled && filled
              ? [
                  BoxShadow(
                    color: DueCollectionEntryColors.brandGold
                        .withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (ctrl.isSaving && filled)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF111827)))
            else
              Icon(icon,
                  size: 18,
                  color: filled
                      ? const Color(0xFF111827)
                      : DueCollectionEntryColors.brandGold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    color: filled
                        ? const Color(0xFF111827)
                        : DueCollectionEntryColors.brandGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0),
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
