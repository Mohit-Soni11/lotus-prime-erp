part of '../notice_auction_screen.dart';

class _SavedNoticePreviewDialog extends StatefulWidget {
  final _SavedNoticeDraft draft;
  final Future<void> Function() onDownload;
  final Future<void> Function() onPrint;

  const _SavedNoticePreviewDialog({
    required this.draft,
    required this.onDownload,
    required this.onPrint,
  });

  @override
  State<_SavedNoticePreviewDialog> createState() =>
      _SavedNoticePreviewDialogState();
}

class _SavedNoticePreviewDialogState extends State<_SavedNoticePreviewDialog> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final actionDate = DateFormat('dd MMM yyyy, hh:mm a').format(
      draft.action.actionAt,
    );

    return AlertDialog(
      backgroundColor: GirviColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(24),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GirviColors.brandGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GirviColors.brandGold.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              '0${draft.noticeType.stage}',
              style: GoogleFonts.inter(
                color: GirviColors.brandGold,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.noticeType.label,
                  style: GirviStyles.sectionTitle.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  '${draft.item.loan.ticketNo} | ${draft.item.account.customerName} | ${draft.language.label} | $actionDate',
                  style: GirviStyles.caption.copyWith(
                    color: GirviColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 780,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 560),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: GirviColors.bodyBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GirviColors.cardBorder),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              draft.noticeText,
              style: GoogleFonts.inter(
                color: GirviColors.textDark,
                fontSize: 13.6,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GirviStyles.caption.copyWith(
              color: GirviColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _busy ? null : () => _run(widget.onDownload),
          icon: const Icon(Icons.download_rounded, size: 17),
          label: const Text('Save PDF'),
          style: TextButton.styleFrom(
            foregroundColor: GirviColors.textDark,
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : () => _run(widget.onPrint),
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.print_rounded, size: 17),
          label: Text(
            _busy ? 'Working' : 'Print PDF',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GirviColors.shellBg,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoticeEditorDialog extends StatefulWidget {
  final NoticeAuctionCase item;
  final GirviNoticeType noticeType;
  final Map<GirviNoticeLanguage, String> initialTexts;
  final GirviNoticeLanguage initialLanguage;
  final Future<void> Function(GirviNoticeLanguage language, String text) onCopy;
  final Future<void> Function(GirviNoticeLanguage language, String text)
      onPrint;
  final Future<void> Function(GirviNoticeLanguage language, String text)
      onShare;
  final Future<bool> Function(GirviNoticeLanguage language, String text) onSave;

  const _NoticeEditorDialog({
    required this.item,
    required this.noticeType,
    required this.initialTexts,
    required this.initialLanguage,
    required this.onCopy,
    required this.onPrint,
    required this.onShare,
    required this.onSave,
  });

  @override
  State<_NoticeEditorDialog> createState() => _NoticeEditorDialogState();
}

class _NoticeEditorDialogState extends State<_NoticeEditorDialog> {
  late final TextEditingController _textController;
  late GirviNoticeLanguage _language;
  late final Map<GirviNoticeLanguage, String> _texts;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _texts = Map<GirviNoticeLanguage, String>.from(widget.initialTexts);
    _textController = TextEditingController(text: _texts[_language] ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function(GirviNoticeLanguage language, String text) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _syncCurrentLanguageText();
      await action(_language, _textController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _syncCurrentLanguageText();
      final saved = await widget.onSave(_language, _textController.text.trim());
      if (saved && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setLanguage(GirviNoticeLanguage value) {
    if (_busy || value == _language) return;
    _syncCurrentLanguageText();
    setState(() {
      _language = value;
      _textController.text = _texts[value] ?? '';
    });
  }

  void _syncCurrentLanguageText() {
    _texts[_language] = _textController.text;
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
            Row(
              children: [
                Expanded(
                  child: _NoticeLanguageButton(
                    label: 'Hindi',
                    selected: _language == GirviNoticeLanguage.hindi,
                    onTap: () => _setLanguage(GirviNoticeLanguage.hindi),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NoticeLanguageButton(
                    label: 'English',
                    selected: _language == GirviNoticeLanguage.english,
                    onTap: () => _setLanguage(GirviNoticeLanguage.english),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
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
                  borderSide: const BorderSide(color: GirviColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: GirviColors.brandGold,
                    width: 1.4,
                  ),
                ),
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
          onPressed: _busy ? null : () => _run(widget.onCopy),
          child: Text('Copy Text', style: _actionTextStyle()),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(widget.onShare),
          child: Text('Share PDF', style: _actionTextStyle()),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(widget.onPrint),
          child: Text('Print PDF', style: _actionTextStyle()),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: GirviColors.shellBg,
            foregroundColor: Colors.white,
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
                  'Save Notice',
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

class _NoticeLanguageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NoticeLanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? GirviColors.shellBg : GirviColors.bodyBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? GirviColors.shellBg : GirviColors.cardBorder,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : GirviColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
