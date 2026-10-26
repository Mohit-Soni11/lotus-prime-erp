part of '../contact_recovery_screen.dart';

class _NoticeDeliveryConfirmation {
  const _NoticeDeliveryConfirmation({
    required this.channel,
    required this.reference,
    required this.deliveredAt,
  });

  final String channel;
  final String reference;
  final DateTime deliveredAt;
}

extension _NoticeDelivery on _ContactRecoveryScreenState {
  Future<void> _confirmNoticeDelivery(
    ContactRecoveryCase item,
    GirviNoticeAction notice,
  ) async {
    final currentNotice = item.formalNoticeAction;
    final pdfActivity = item.latestPdfActivityForNotice(notice);
    if (currentNotice == null ||
        currentNotice.id != notice.id ||
        pdfActivity == null) {
      _controller.showInlineMessage('Issue the current notice PDF first.');
      return;
    }
    final confirmation = await showDialog<_NoticeDeliveryConfirmation>(
      context: context,
      builder: (context) =>
          _ConfirmNoticeDeliveryDialog(pdfActivity: pdfActivity),
    );
    if (confirmation == null || !mounted) return;
    final approvedText = item
            .documentForNoticeAction(
              notice.id,
              GirviNoticeLanguage.english,
            )
            ?.noticeText ??
        notice.noticeText ??
        '';
    if (approvedText.trim().isEmpty) {
      _controller.showInlineMessage('The saved notice text is unavailable.');
      return;
    }
    await _controller.recordNoticeDeliveryProof(
      item: item,
      noticeType: GirviNoticeType.formal,
      noticeActionId: notice.id,
      noticeText: approvedText,
      noticeLanguage: GirviNoticeLanguage.english,
      actionType: GirviNoticeActionTypes.noticeDeliveryRecorded,
      deliveryChannel: confirmation.channel,
      deliveryStatus: 'Delivered',
      deliveryReference: confirmation.reference,
      deliveredAt: confirmation.deliveredAt,
    );
  }
}

class _ConfirmNoticeDeliveryDialog extends StatelessWidget {
  const _ConfirmNoticeDeliveryDialog({required this.pdfActivity});

  final GirviNoticeAction pdfActivity;

  String get _channel => switch (pdfActivity.actionType) {
        GirviNoticeActionTypes.noticePdfShared => 'WhatsApp',
        GirviNoticeActionTypes.noticePdfPrinted => 'Printed copy',
        GirviNoticeActionTypes.noticePdfSaved => 'Downloaded PDF',
        _ => pdfActivity.deliveryChannel?.trim().isNotEmpty == true
            ? pdfActivity.deliveryChannel!.trim()
            : 'Notice PDF',
      };

  String get _reference => 'NOTICE_PDF_ACTION_${pdfActivity.id}';

  void _confirm(BuildContext context) {
    Navigator.of(context).pop(_NoticeDeliveryConfirmation(
      channel: _channel,
      reference: _reference,
      deliveredAt: DateTime.now(),
    ));
  }

  Widget _recordedDetail(IconData icon, String label, String value) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: GirviColors.inputBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: GirviColors.info),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: GoogleFonts.inter(
                          color: GirviColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GirviColors.cardBorder),
        ),
        title: Text('Confirm Customer Delivery',
            style: GoogleFonts.manrope(
                color: GirviColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm only after the customer received the notice. Its response period starts when you confirm delivery.',
                style: TextStyle(
                    color: GirviColors.textDark, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _recordedDetail(
                Icons.event_rounded,
                'PDF action time',
                DateFormat('dd MMM yyyy, hh:mm a').format(pdfActivity.actionAt),
              ),
              const SizedBox(height: 8),
              _recordedDetail(Icons.send_rounded, 'Recorded method', _channel),
              const SizedBox(height: 8),
              _recordedDetail(
                Icons.tag_rounded,
                'Reference from saved notice action',
                _reference,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: GirviColors.textDark,
              backgroundColor: GirviColors.inputBgLocked,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _confirm(context),
            style: FilledButton.styleFrom(
              backgroundColor: GirviColors.shellBg,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
            child: const Text('Confirm Delivery'),
          ),
        ],
      );
}
