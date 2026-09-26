part of '../notice_auction_screen.dart';

class _NoticeDocumentStrip extends StatelessWidget {
  final NoticeAuctionCase item;
  final ValueChanged<GirviNoticeAction> onViewNotice;
  final ValueChanged<GirviNoticeAction> onDownloadNotice;
  final ValueChanged<GirviNoticeAction> onPrintNotice;

  const _NoticeDocumentStrip({
    required this.item,
    required this.onViewNotice,
    required this.onDownloadNotice,
    required this.onPrintNotice,
  });

  @override
  Widget build(BuildContext context) {
    final actions = item.preparedNoticeActions;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notice Documents',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _NoticeCountBadge(label: item.noticesSentLabel),
            ],
          ),
          const SizedBox(height: 9),
          if (actions.isEmpty)
            const _NoNoticeDocuments()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map(
                (action) {
                  final stage = _noticeStageFromAction(action) ?? 1;
                  return _NoticeDocumentCard(
                    action: action,
                    latestProof: item.latestDeliveryProofForStage(stage),
                    onView: () => onViewNotice(action),
                    onDownload: () => onDownloadNotice(action),
                    onPrint: () => onPrintNotice(action),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }
}

class _NoticeCountBadge extends StatelessWidget {
  final String label;

  const _NoticeCountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: GirviColors.brandGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: GirviColors.brandGold.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GirviStyles.caption.copyWith(
          color: GirviColors.brandGold,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NoNoticeDocuments extends StatelessWidget {
  const _NoNoticeDocuments();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Text(
        'No notice document has been prepared yet.',
        style: GirviStyles.caption.copyWith(
          color: GirviColors.textDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoticeDocumentCard extends StatelessWidget {
  final GirviNoticeAction action;
  final GirviNoticeAction? latestProof;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onPrint;

  const _NoticeDocumentCard({
    required this.action,
    required this.latestProof,
    required this.onView,
    required this.onDownload,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final noticeType = _noticeTypeFromAction(action);
    final timestamp =
        DateFormat('dd MMM yyyy, hh:mm a').format(action.actionAt);
    final proof = latestProof;
    final proofTimestamp = proof == null
        ? null
        : DateFormat('dd MMM yyyy, hh:mm a')
            .format(proof.deliveredAt ?? proof.actionAt);
    final color = _noticeStageColor(noticeType);

    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 196,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.28)),
          boxShadow: const [
            BoxShadow(
              color: GirviColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.24)),
                  ),
                  child: Text(
                    '0${noticeType.stage}',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    noticeType.label,
                    style: GirviStyles.caption.copyWith(
                      color: GirviColors.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prepared $timestamp',
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: proof == null
                    ? GirviColors.warningBg.withValues(alpha: 0.45)
                    : GirviColors.successBg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: proof == null
                      ? GirviColors.warning.withValues(alpha: 0.24)
                      : GirviColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                proof == null
                    ? 'Proof pending'
                    : '${proof.deliveryProofLabel} - $proofTimestamp',
                style: GirviStyles.caption.copyWith(
                  color: GirviColors.textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    onTap: onView,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'Save',
                    icon: Icons.download_rounded,
                    onTap: onDownload,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _MiniNoticeAction(
                    label: 'Print',
                    icon: Icons.print_rounded,
                    onTap: onPrint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _noticeStageColor(GirviNoticeType noticeType) {
    switch (noticeType) {
      case GirviNoticeType.first:
        return GirviColors.warning;
      case GirviNoticeType.second:
        return GirviColors.danger;
      case GirviNoticeType.finalNotice:
        return GirviColors.info;
    }
  }
}

class _MiniNoticeAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniNoticeAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label == 'Save' ? 'Download PDF' : '$label notice',
      waitDuration: const Duration(milliseconds: 450),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GirviColors.bodyBg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: GirviColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: GirviColors.textDark),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseActions extends StatelessWidget {
  final NoticeAuctionCase item;
  final VoidCallback onOpenAccount;
  final VoidCallback? onPrepareNotice;
  final VoidCallback? onCloseDisposal;

  const _CaseActions({
    required this.item,
    required this.onOpenAccount,
    required this.onPrepareNotice,
    required this.onCloseDisposal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButton(
          label: 'Open Account',
          color: GirviColors.shellBg,
          onTap: onOpenAccount,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: item.stage == NoticeAuctionStage.settled
              ? 'Workflow Closed'
              : item.nextNoticeType?.label ?? '3 Notices Prepared',
          color: GirviColors.warning,
          onTap: onPrepareNotice,
        ),
        const SizedBox(height: 8),
        _ActionButton(
          label: item.stage == NoticeAuctionStage.settled
              ? 'Closed'
              : 'Close Recovery',
          color: item.stage == NoticeAuctionStage.settled
              ? GirviColors.success
              : GirviColors.danger,
          onTap: onCloseDisposal,
        ),
        const SizedBox(height: 8),
        Text(
          item.stageDescription,
          style: GirviStyles.caption.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  final NoticeAuctionCase item;

  const _StageBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.accentBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.accentColor.withValues(alpha: 0.38)),
      ),
      child: Text(
        item.stageLabel,
        style: GirviStyles.statusBadge.copyWith(color: item.accentColor),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                color: GirviColors.textHint,
              ),
            ),
            TextSpan(
              text: value,
              style: GirviStyles.caption.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _AmountTile({
    required this.label,
    required this.value,
    this.accent = GirviColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 74,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GirviColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GirviStyles.caption.copyWith(fontSize: 12.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color : GirviColors.inputBgLocked,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color : GirviColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: enabled ? Colors.white : GirviColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
