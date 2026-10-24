part of '../contact_recovery_screen.dart';

class _NoticeEditorDialog extends StatefulWidget {
  final ContactRecoveryCase item;
  final GirviNoticeType noticeType;
  final String initialText;
  final String Function(int days) generateTextForPeriod;
  final Future<void> Function(
      GirviNoticeLanguage language, String text, int days) onPreview;
  final Future<bool> Function(
    GirviNoticeLanguage language,
    String text,
    Map<GirviNoticeLanguage, String> allTexts,
    int days,
    _NoticeSendMethod method,
  ) onSend;

  const _NoticeEditorDialog({
    required this.item,
    required this.noticeType,
    required this.initialText,
    required this.generateTextForPeriod,
    required this.onPreview,
    required this.onSend,
  });

  @override
  State<_NoticeEditorDialog> createState() => _NoticeEditorDialogState();
}

class _NoticeEditorDialogState extends State<_NoticeEditorDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _daysController;
  late String _generatedText;
  late int _selectedDays;
  bool _busy = false;
  bool _isEditing = false;
  String _busyLabel = 'Preparing notice PDF...';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _selectedDays =
        widget.item.noticePeriodDays > 0 ? widget.item.noticePeriodDays : 7;
    _daysController = TextEditingController(text: '$_selectedDays');
    _generatedText = widget.initialText;
  }

  @override
  void dispose() {
    _textController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _updatePeriod(String value) {
    final days = int.tryParse(value);
    if (days == null || days < 1 || days > 365) {
      setState(() {});
      return;
    }
    final oldPeriod = 'on or before ${_responseDate(_selectedDays)}';
    final newPeriod = 'on or before ${_responseDate(days)}';
    final previousText = _textController.text;
    final nextText = previousText == _generatedText
        ? widget.generateTextForPeriod(days)
        : previousText.replaceAll(oldPeriod, newPeriod);
    setState(() {
      _selectedDays = days;
      _generatedText = widget.generateTextForPeriod(days);
      _textController.text = nextText;
    });
  }

  String _responseDate(int days) => DateFormat('dd MMMM yyyy').format(DateTime(
        widget.item.now.year,
        widget.item.now.month,
        widget.item.now.day + days,
      ));

  String? get _periodError {
    final days = int.tryParse(_daysController.text);
    if (days == null || days < 1 || days > 365) {
      return 'Enter 1 to 365 days.';
    }
    if (!_textController.text.contains('on or before ${_responseDate(days)}')) {
      return 'Keep the selected response date in the notice text.';
    }
    return null;
  }

  bool get _validPeriod => _periodError == null;

  String? get _approvalError => GirviNoticeApprovalValidator.validate(
        generatedText: _generatedText,
        approvedText: _textController.text,
      );

  bool get _validNotice => _validPeriod && _approvalError == null;

  Future<void> _send() async {
    if (_busy || !_validNotice) return;
    final method = await showDialog<_NoticeSendMethod>(
      context: context,
      builder: (context) => const _NoticeSendDialog(),
    );
    if (method == null || !mounted) return;
    setState(() {
      _busy = true;
      _busyLabel = switch (method) {
        _NoticeSendMethod.print => 'Preparing PDF for printer...',
        _NoticeSendMethod.whatsapp => 'Preparing PDF for WhatsApp...',
        _NoticeSendMethod.download => 'Preparing PDF for download...',
      };
    });
    try {
      // Give Flutter one frame to paint the active state before PDF creation
      // performs synchronous layout work on the desktop UI isolate.
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final noticeText = _textController.text.trim();
      final sent = await widget.onSend(
        GirviNoticeLanguage.english,
        noticeText,
        {GirviNoticeLanguage.english: noticeText},
        _selectedDays,
        method,
      );
      if (sent && mounted) Navigator.of(context, rootNavigator: true).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewPdf() async {
    if (_busy || !_validNotice) return;
    setState(() => _busy = true);
    try {
      await widget.onPreview(
        GirviNoticeLanguage.english,
        _textController.text.trim(),
        _selectedDays,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(24),
      title: Text(
        widget.noticeType.label,
        style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
      ),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.item.loan.ticketNo} | ${widget.item.account.customerName} | ${widget.noticeType.subtitle}',
              style: GirviStyles.caption.copyWith(
                fontSize: 12.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('notice-response-days'),
              controller: _daysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _updatePeriod,
              style: GirviStyles.fieldInput,
              cursorColor: GirviColors.shellBg,
              decoration: InputDecoration(
                labelText: 'Response period (days)',
                helperText: 'Due date is calculated from the notice date.',
                errorText: _periodError,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelStyle: GirviStyles.fieldLabel,
                floatingLabelStyle: GirviStyles.fieldLabel,
                helperStyle: GirviStyles.fieldHint.copyWith(fontSize: 12.5),
                errorStyle: GirviStyles.fieldHint.copyWith(
                  fontSize: 12.5,
                  color: GirviColors.danger,
                ),
                suffixText: 'days',
                suffixStyle: GirviStyles.fieldHint,
                filled: true,
                fillColor: GirviColors.inputBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: GirviColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: GirviColors.shellBg,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: GirviColors.danger),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: GirviColors.danger,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: _isEditing ? 'Preview notice' : 'Edit notice text',
                child: IconButton(
                  onPressed: _busy
                      ? null
                      : () {
                          setState(() => _isEditing = !_isEditing);
                        },
                  icon: Icon(
                    _isEditing
                        ? Icons.visibility_outlined
                        : Icons.edit_outlined,
                    size: 19,
                  ),
                  color: GirviColors.shellBg,
                  style: IconButton.styleFrom(
                    backgroundColor: GirviColors.bodyBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                      side: const BorderSide(color: GirviColors.cardBorder),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isEditing
                  ? TextField(
                      key: const ValueKey('notice-text-editor'),
                      controller: _textController,
                      onChanged: (_) => setState(() {}),
                      minLines: 16,
                      maxLines: 22,
                      style: GoogleFonts.inter(
                        fontSize: 13.2,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: GirviColors.textDark,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: GirviColors.bodyBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: GirviColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: GirviColors.brandGold,
                            width: 1.4,
                          ),
                        ),
                      ),
                    )
                  : _NoticeDocumentPreview(
                      key: const ValueKey('notice-document-preview'),
                      noticeText: _textController.text,
                      language: GirviNoticeLanguage.english,
                      noticeType: widget.noticeType,
                    ),
            ),
            if (_approvalError != null) ...[
              const SizedBox(height: 8),
              Text(
                _approvalError!,
                style: GirviStyles.fieldHint.copyWith(
                  color: GirviColors.danger,
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GirviStyles.caption.copyWith(color: GirviColors.textMuted),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _busy || !_validNotice ? null : _previewPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
          label: const Text('Preview PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: GirviColors.shellBg,
            disabledForegroundColor: GirviColors.shellBorder,
            backgroundColor: GirviColors.cardBg,
            side: const BorderSide(color: GirviColors.shellBorder, width: 1.3),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
            minimumSize: const Size(145, 42),
          ),
        ),
        ElevatedButton(
          onPressed: _busy || !_validNotice ? null : _send,
          style: ElevatedButton.styleFrom(
            backgroundColor: GirviColors.shellBg,
            foregroundColor: Colors.white,
            disabledBackgroundColor: GirviColors.inputBgLocked,
            disabledForegroundColor: GirviColors.shellBorder,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
            minimumSize: const Size(180, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _busy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      _busyLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Send Notice',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }
}
