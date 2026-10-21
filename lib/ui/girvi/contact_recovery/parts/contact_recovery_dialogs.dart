part of '../contact_recovery_screen.dart';

class _NoticeEditorDialog extends StatefulWidget {
  final ContactRecoveryCase item;
  final GirviNoticeType noticeType;
  final String initialText;
  final String Function(int days) generateTextForPeriod;
  final Future<void> Function(GirviNoticeLanguage language, String text) onCopy;
  final Future<void> Function(
      GirviNoticeLanguage language, String text, int days) onPreview;
  final Future<bool> Function(
    GirviNoticeLanguage language,
    String text,
    Map<GirviNoticeLanguage, String> allTexts,
    int days,
  ) onSave;

  const _NoticeEditorDialog({
    required this.item,
    required this.noticeType,
    required this.initialText,
    required this.generateTextForPeriod,
    required this.onCopy,
    required this.onPreview,
    required this.onSave,
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
    final oldPeriod =
        'within $_selectedDays day${_selectedDays == 1 ? '' : 's'} after receiving this notice';
    final newPeriod =
        'within $days day${days == 1 ? '' : 's'} after receiving this notice';
    final previousText = _textController.text;
    final nextText = previousText == _generatedText
        ? widget.generateTextForPeriod(days)
        : previousText.replaceFirst(oldPeriod, newPeriod);
    setState(() {
      _selectedDays = days;
      _generatedText = widget.generateTextForPeriod(days);
      _textController.text = nextText;
    });
  }

  String? get _periodError {
    final days = int.tryParse(_daysController.text);
    if (days == null || days < 1 || days > 365) {
      return 'Enter 1 to 365 days.';
    }
    if (!_textController.text.contains(
      'within $days day${days == 1 ? '' : 's'} after receiving this notice',
    )) {
      return 'Keep the response period sentence in the notice text.';
    }
    return null;
  }

  bool get _validPeriod => _periodError == null;

  Future<void> _run(
    Future<void> Function(GirviNoticeLanguage language, String text) action,
  ) async {
    if (_busy || !_validPeriod) return;
    setState(() => _busy = true);
    try {
      await action(GirviNoticeLanguage.english, _textController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_validPeriod) return;
    setState(() => _busy = true);
    try {
      final noticeText = _textController.text.trim();
      final saved = await widget.onSave(
        GirviNoticeLanguage.english,
        noticeText,
        {GirviNoticeLanguage.english: noticeText},
        _selectedDays,
      );
      if (saved && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewPdf() async {
    if (_busy || !_validPeriod) return;
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
                helperText: 'Starts when the customer receives the notice.',
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
        TextButton(
          onPressed: _busy || !_validPeriod ? null : () => _run(widget.onCopy),
          child: Text('Copy Text', style: _actionTextStyle()),
        ),
        OutlinedButton.icon(
          onPressed: _busy || !_validPeriod ? null : _previewPdf,
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
          onPressed: _busy || !_validPeriod ? null : _save,
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
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Approve & Save Notice',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }

  TextStyle _actionTextStyle() {
    return GoogleFonts.inter(
      color: GirviColors.shellBg,
      fontWeight: FontWeight.w800,
    );
  }
}

class _CustomerResponseTimelineDialog extends StatelessWidget {
  const _CustomerResponseTimelineDialog({
    required this.item,
    required this.onResolvePromise,
  });

  final ContactRecoveryCase item;
  final Future<bool> Function({
    required GirviCustomerResponse response,
    required GirviPromiseStatus status,
    String? resolutionNote,
  }) onResolvePromise;

  @override
  Widget build(BuildContext context) {
    final responses = [...item.responseTimeline]
      ..sort((left, right) => right.receivedAt.compareTo(left.receivedAt));
    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 6),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Response Timeline',
                  style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.loan.ticketNo} · factual contact and promise record',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: responses.isEmpty
            ? _ResponseTimelineEmptyState()
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: responses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _CustomerResponseTimelineCard(
                    response: responses[index],
                    onResolve: responses[index].status.isOpen
                        ? () async {
                            final result =
                                await showDialog<_PromiseResolutionResult>(
                              context: context,
                              builder: (context) => _PromiseResolutionDialog(
                                response: responses[index],
                              ),
                            );
                            if (result == null || !context.mounted) return;
                            final updated = await onResolvePromise(
                              response: responses[index],
                              status: result.status,
                              resolutionNote: result.note,
                            );
                            if (updated && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        : null,
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ResponseTimelineEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: GirviColors.bodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GirviColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              color: GirviColors.textMuted,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              'No customer response recorded yet.',
              style: GirviStyles.caption.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Record a factual response from the notice document card.',
              textAlign: TextAlign.center,
              style: GirviStyles.caption.copyWith(color: GirviColors.textMuted),
            ),
          ],
        ),
      );
}

class _CustomerResponseTimelineCard extends StatelessWidget {
  const _CustomerResponseTimelineCard({
    required this.response,
    required this.onResolve,
  });

  final GirviCustomerResponse response;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final isPastDue = response.isDueOn(DateTime.now());
    final statusColor = isPastDue
        ? GirviColors.danger
        : response.status.isOpen
            ? GirviColors.brandGold
            : GirviColors.success;
    final statusLabel = isPastDue ? 'Promise past due' : response.status.label;
    final stageLabel = response.noticeStage == null
        ? 'General account contact'
        : 'Response to approved notice';
    final details = <String>[
      '${response.channel.label} · ${DateFormat('dd MMM yyyy, hh:mm a').format(response.receivedAt)}',
      if (response.promiseDueAt != null)
        'Promised date: ${DateFormat('dd MMM yyyy').format(response.promiseDueAt!)}',
      if (response.promisedAmount != null)
        'Promised amount: ${_formatMoney(response.promisedAmount!)}',
      if ((response.proofReference ?? '').trim().isNotEmpty)
        'Proof: ${response.proofReference!.trim()}',
      if ((response.resolutionNote ?? '').trim().isNotEmpty)
        'Resolution: ${response.resolutionNote!.trim()}',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GirviColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  response.kind.label,
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: GirviStyles.caption.copyWith(
                    color: statusColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stageLabel,
            style: GirviStyles.caption.copyWith(
              color: GirviColors.info,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            response.responseText,
            style: GirviStyles.caption.copyWith(
              color: GirviColors.textDark,
              fontSize: 12.5,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 9),
          for (final detail in details) ...[
            Text(
              detail,
              style: GirviStyles.caption.copyWith(
                color: GirviColors.textMuted,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
          ],
          if (onResolve != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onResolve,
                icon: const Icon(Icons.task_alt_rounded, size: 16),
                label: const Text('Resolve promise'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GirviColors.shellBg,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatMoney(double value) =>
      'Rs ${NumberFormat('#,##0.00', 'en_IN').format(value)}';
}

class _PromiseResolutionResult {
  const _PromiseResolutionResult({required this.status, this.note});

  final GirviPromiseStatus status;
  final String? note;
}

class _PromiseResolutionDialog extends StatefulWidget {
  const _PromiseResolutionDialog({required this.response});

  final GirviCustomerResponse response;

  @override
  State<_PromiseResolutionDialog> createState() =>
      _PromiseResolutionDialogState();
}

class _PromiseResolutionDialogState extends State<_PromiseResolutionDialog> {
  final _noteController = TextEditingController();
  GirviPromiseStatus _status = GirviPromiseStatus.fulfilled;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: GirviColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Resolve Customer Promise',
          style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
        ),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.response.responseText,
                style: GirviStyles.caption.copyWith(
                  color: GirviColors.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<GirviPromiseStatus>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: 'Outcome',
                  filled: true,
                  fillColor: GirviColors.bodyBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                items: const [
                  GirviPromiseStatus.fulfilled,
                  GirviPromiseStatus.partiallyFulfilled,
                  GirviPromiseStatus.missed,
                  GirviPromiseStatus.cancelled,
                ]
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Resolution note (optional)',
                  hintText:
                      'State what actually happened; do not overwrite the original response.',
                  filled: true,
                  fillColor: GirviColors.bodyBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
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
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              _PromiseResolutionResult(
                status: _status,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GirviColors.shellBg,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save outcome'),
          ),
        ],
      );
}

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
    double? promisedAmount,
    DateTime? promiseDueAt,
    String? proofReference,
  }) onSave;

  @override
  State<_CustomerResponseDialog> createState() =>
      _CustomerResponseDialogState();
}

class _CustomerResponseDialogState extends State<_CustomerResponseDialog> {
  final _responseController = TextEditingController();
  final _amountController = TextEditingController();
  final _proofController = TextEditingController();
  GirviCustomerResponseKind _kind = GirviCustomerResponseKind.willVisit;
  GirviContactChannel _channel = GirviContactChannel.phoneCall;
  DateTime? _promiseDueAt;
  bool _busy = false;

  @override
  void dispose() {
    _responseController.dispose();
    _amountController.dispose();
    _proofController.dispose();
    super.dispose();
  }

  Future<void> _selectPromiseDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _promiseDueAt ?? today,
      firstDate: today.subtract(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (selected != null && mounted) setState(() => _promiseDueAt = selected);
  }

  Future<void> _submit() async {
    if (_busy) return;
    final rawAmount = _amountController.text.replaceAll(',', '').trim();
    final amount = rawAmount.isEmpty ? null : double.tryParse(rawAmount);
    if (rawAmount.isNotEmpty && amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid promised amount.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await widget.onSave(
        kind: _kind,
        channel: _channel,
        responseText: _responseController.text,
        promisedAmount: amount,
        promiseDueAt: _promiseDueAt,
        proofReference: _proofController.text,
      );
      if (saved && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noticeLabel = widget.notice.noticeLabel;
    final requiresAmount = _kind == GirviCustomerResponseKind.partialPayment;
    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Record Customer Response',
        style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
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
                style: GirviStyles.caption.copyWith(
                  color: GirviColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _responseDropdown<GirviCustomerResponseKind>(
                label: 'Customer response',
                value: _kind,
                values: GirviCustomerResponseKind.values,
                labelOf: (value) => value.label,
                onChanged: (value) => setState(() {
                  _kind = value;
                  if (!value.isPromise) _promiseDueAt = null;
                  if (value != GirviCustomerResponseKind.partialPayment) {
                    _amountController.clear();
                  }
                }),
              ),
              const SizedBox(height: 10),
              _responseDropdown<GirviContactChannel>(
                label: 'Contact channel',
                value: _channel,
                values: GirviContactChannel.values,
                labelOf: (value) => value.label,
                onChanged: (value) => setState(() => _channel = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _responseController,
                minLines: 3,
                maxLines: 5,
                decoration: _decoration(
                  'Customer statement',
                  'Record facts only, e.g. customer promised to visit on Friday.',
                ),
              ),
              if (_kind.isPromise) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _selectPromiseDate,
                  icon: const Icon(Icons.event_rounded, size: 17),
                  label: Text(
                    _promiseDueAt == null
                        ? 'Select promised date'
                        : 'Promised date: ${DateFormat('dd MMM yyyy').format(_promiseDueAt!)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GirviColors.shellBg,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                  ),
                ),
              ],
              if (requiresAmount) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Promised amount', 'e.g. 2000'),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _proofController,
                decoration: _decoration(
                  'Proof reference (optional)',
                  'WhatsApp export, acknowledgement no., or file path',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
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

  InputDecoration _decoration(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: GirviColors.bodyBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
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
        decoration: _decoration(label, ''),
        items: values
            .map((entry) => DropdownMenuItem<T>(
                  value: entry,
                  child: Text(labelOf(entry)),
                ))
            .toList(growable: false),
        onChanged: _busy
            ? null
            : (value) {
                if (value != null) onChanged(value);
              },
      );
}
