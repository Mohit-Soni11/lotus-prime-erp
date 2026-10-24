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
    if (currentNotice == null ||
        currentNotice.id != notice.id ||
        item.latestPdfActivityForNotice(notice) == null) {
      _controller.showInlineMessage('Issue the current notice PDF first.');
      return;
    }
    final confirmation = await showDialog<_NoticeDeliveryConfirmation>(
      context: context,
      builder: (context) => _ConfirmNoticeDeliveryDialog(notice: notice),
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

class _ConfirmNoticeDeliveryDialog extends StatefulWidget {
  const _ConfirmNoticeDeliveryDialog({required this.notice});

  final GirviNoticeAction notice;

  @override
  State<_ConfirmNoticeDeliveryDialog> createState() =>
      _ConfirmNoticeDeliveryDialogState();
}

class _ConfirmNoticeDeliveryDialogState
    extends State<_ConfirmNoticeDeliveryDialog> {
  static const _channels = [
    'In person',
    'WhatsApp',
    'Registered post',
    'Other',
  ];
  final _reference = TextEditingController();
  late String _channel =
      widget.notice.actionType == GirviNoticeActionTypes.noticePdfShared
          ? 'WhatsApp'
          : 'In person';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final approvedDay = DateUtils.dateOnly(widget.notice.actionAt);
    final selected = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(_date),
      firstDate: approvedDay,
      lastDate: today,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: GirviColors.shellBg,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  void _confirm() {
    final reference = _reference.text.trim();
    if (reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a handover or sending reference.'),
      ));
      return;
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(_date);
    final deliveredAt = selected == today
        ? DateTime.now()
        : DateTime(selected.year, selected.month, selected.day, 23, 59, 59);
    Navigator.of(context).pop(_NoticeDeliveryConfirmation(
      channel: _channel,
      reference: reference,
      deliveredAt: deliveredAt,
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Confirm Customer Delivery'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm only after the notice reached the customer. The response period starts from this date.',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _channel,
                dropdownColor: Colors.white,
                decoration:
                    const InputDecoration(labelText: 'Delivery channel'),
                items: [
                  for (final channel in _channels)
                    DropdownMenuItem(value: channel, child: Text(channel)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _channel = value);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  'Delivered on ${DateFormat('dd MMM yyyy').format(_date)}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reference,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: 'Delivery reference',
                  hintText: 'Handover acknowledgment or sent message reference',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _confirm,
            child: const Text('Confirm Delivery'),
          ),
        ],
      );
}
