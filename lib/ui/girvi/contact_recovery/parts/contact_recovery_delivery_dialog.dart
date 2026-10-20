part of '../contact_recovery_screen.dart';

class _NoticeDeliveryResult {
  const _NoticeDeliveryResult({
    required this.channel,
    required this.reference,
  });

  final String channel;
  final String reference;
}

class _NoticeDeliveryDialog extends StatefulWidget {
  const _NoticeDeliveryDialog({required this.ticketNo});

  final String ticketNo;

  @override
  State<_NoticeDeliveryDialog> createState() => _NoticeDeliveryDialogState();
}

class _NoticeDeliveryDialogState extends State<_NoticeDeliveryDialog> {
  static const _channels = <String>[
    'In person',
    'Courier',
    'Registered post',
    'Email',
    'WhatsApp',
  ];

  final _referenceController = TextEditingController();
  String _channel = _channels.first;
  String? _error;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  void _record() {
    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      setState(
          () => _error = 'Enter a receipt, tracking or message reference.');
      return;
    }
    Navigator.of(context).pop(
      _NoticeDeliveryResult(channel: _channel, reference: reference),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Customer Delivery'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket ${widget.ticketNo}'),
            const SizedBox(height: 10),
            const Text(
              'Record this only after the approved notice has reached the customer.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _channel,
              decoration: const InputDecoration(labelText: 'Delivery method'),
              items: [
                for (final channel in _channels)
                  DropdownMenuItem(value: channel, child: Text(channel)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _channel = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Delivery evidence reference',
                hintText: 'Receipt, tracking ID or message reference',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
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
          onPressed: _record,
          child: const Text('Confirm Delivery'),
        ),
      ],
    );
  }
}
