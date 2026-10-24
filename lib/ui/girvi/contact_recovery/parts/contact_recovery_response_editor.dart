part of '../contact_recovery_screen.dart';

class _CustomerResponseDialog extends StatefulWidget {
  const _CustomerResponseDialog({
    required this.item,
    required this.notice,
    required this.onSave,
  });

  final ContactRecoveryCase item;
  final GirviNoticeAction notice;
  final Future<bool> Function({
    required GirviCustomerResponseKind kind,
    required GirviContactChannel channel,
    required String responseText,
    DateTime? promiseDueAt,
  }) onSave;

  @override
  State<_CustomerResponseDialog> createState() =>
      _CustomerResponseDialogState();
}

class _CustomerResponseDialogState extends State<_CustomerResponseDialog> {
  final _responseController = TextEditingController();
  GirviCustomerResponseKind _kind = GirviCustomerResponseKind.willVisit;
  GirviContactChannel _channel = GirviContactChannel.phoneCall;
  DateTime? _promiseDueAt;
  bool _busy = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  String _automaticStatement() => switch (_kind) {
        GirviCustomerResponseKind.willVisit =>
          'Customer will visit the shop on ${DateFormat('dd MMM yyyy').format(_promiseDueAt!)}.',
        GirviCustomerResponseKind.extensionRequest =>
          'Customer requested more time until ${DateFormat('dd MMM yyyy').format(_promiseDueAt!)}.',
        GirviCustomerResponseKind.holdRequest =>
          'Customer requested the account to be held until ${DateFormat('dd MMM yyyy').format(_promiseDueAt!)}.',
        GirviCustomerResponseKind.recoveryRequest =>
          'Customer requested recovery settlement.',
        GirviCustomerResponseKind.noResponse =>
          'No customer response was received by the notice deadline.',
      };

  String get _followUpDateLabel => switch (_kind) {
        GirviCustomerResponseKind.willVisit => 'Visit date',
        GirviCustomerResponseKind.extensionRequest => 'Extension until',
        GirviCustomerResponseKind.holdRequest => 'Hold until',
        _ => 'Follow-up date',
      };

  Future<void> _selectFollowUpDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _promiseDueAt ?? today,
      firstDate: today.subtract(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 3650)),
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
    if (selected != null && mounted) setState(() => _promiseDueAt = selected);
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_kind.requiresFollowUpDate && _promiseDueAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select $_followUpDateLabel before saving.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await widget.onSave(
        kind: _kind,
        channel: _channel,
        responseText: _responseController.text.trim().isEmpty
            ? _automaticStatement()
            : _responseController.text.trim(),
        promiseDueAt: _promiseDueAt,
      );
      if (saved && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noticeLabel = widget.notice.noticeLabel;
    final kinds = GirviCustomerResponseKind.values
        .where((kind) =>
            kind != GirviCustomerResponseKind.noResponse ||
            widget.item.isNoticePeriodComplete)
        .toList(growable: false);
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GirviColors.cardBorder),
      ),
      title: Text(
        'Record Customer Response',
        style: GoogleFonts.manrope(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$noticeLabel · ${widget.item.loan.ticketNo}',
                style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _responseDropdown<GirviCustomerResponseKind>(
                label: 'Customer response',
                value: _kind,
                values: kinds,
                labelOf: (value) => value.label,
                onChanged: (value) => setState(() {
                  _kind = value;
                  if (!value.requiresFollowUpDate) _promiseDueAt = null;
                  if (value == GirviCustomerResponseKind.noResponse) {
                    _channel = GirviContactChannel.other;
                  }
                }),
              ),
              if (_kind != GirviCustomerResponseKind.noResponse) ...[
                const SizedBox(height: 10),
                _responseDropdown<GirviContactChannel>(
                  label: 'Contact channel',
                  value: _channel,
                  values: GirviContactChannel.values,
                  labelOf: (value) => value.label,
                  onChanged: (value) => setState(() => _channel = value),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _responseController,
                minLines: 3,
                maxLines: 5,
                style: _fieldTextStyle,
                cursorColor: Colors.black,
                decoration: _decoration(
                  'Additional notes (optional)',
                  'Leave blank to use the standard response record.',
                ),
              ),
              if (_kind.requiresFollowUpDate) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _selectFollowUpDate,
                  icon: const Icon(Icons.event_rounded, size: 17),
                  label: Text(
                    _promiseDueAt == null
                        ? 'Select $_followUpDateLabel'
                        : '$_followUpDateLabel: ${DateFormat('dd MMM yyyy').format(_promiseDueAt!)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: const Color(0xFFFFFCF6),
                    side: const BorderSide(color: GirviColors.cardBorder),
                    textStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: const Color(0xFFF3F4F6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 17),
          label: Text(_busy ? 'Saving' : 'Save Response'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GirviColors.shellBg,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  TextStyle get _fieldTextStyle => GoogleFonts.inter(
        color: Colors.black,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      );

  InputDecoration _decoration(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: GoogleFonts.inter(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
        hintStyle: GoogleFonts.inter(
          color: Colors.black54,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFFFFCF6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: GirviColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: GirviColors.brandGold, width: 1.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _responseDropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) labelOf,
    required ValueChanged<T> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: Colors.white,
        iconEnabledColor: Colors.black,
        style: _fieldTextStyle,
        decoration: _decoration(label, ''),
        items: values
            .map((entry) => DropdownMenuItem<T>(
                  value: entry,
                  child: Text(
                    labelOf(entry),
                    style: _fieldTextStyle,
                  ),
                ))
            .toList(growable: false),
        onChanged: _busy
            ? null
            : (value) {
                if (value != null) onChanged(value);
              },
      );
}
