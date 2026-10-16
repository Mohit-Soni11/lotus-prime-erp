import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../models/girvi/girvi_notice_action_model.dart';

/// Displays only approved language versions, with an independent PDF per tab.
class NoticePdfLanguagePreview extends StatefulWidget {
  const NoticePdfLanguagePreview({
    super.key,
    required this.title,
    required this.ticketNo,
    required this.availableLanguages,
    required this.initialLanguage,
    required this.buildPdf,
  });

  final String title;
  final String ticketNo;
  final Set<GirviNoticeLanguage> availableLanguages;
  final GirviNoticeLanguage initialLanguage;
  final Future<Uint8List> Function(GirviNoticeLanguage) buildPdf;

  @override
  State<NoticePdfLanguagePreview> createState() =>
      _NoticePdfLanguagePreviewState();
}

class _NoticePdfLanguagePreviewState extends State<NoticePdfLanguagePreview> {
  static const _background = Color(0xFF111827);
  final _documents = <GirviNoticeLanguage, Future<Uint8List>>{};
  late GirviNoticeLanguage _language;

  @override
  void initState() {
    super.initState();
    assert(widget.availableLanguages.contains(widget.initialLanguage));
    _language = widget.initialLanguage;
  }

  Future<Uint8List> get _document => _documents.putIfAbsent(
        _language,
        () => Future<Uint8List>.sync(() => widget.buildPdf(_language)),
      );

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
        backgroundColor: _background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.title} | ${widget.ticketNo} · ${_language.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: () => Navigator.of(context).pop(),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final language in GirviNoticeLanguage.values)
                      Tooltip(
                        message: widget.availableLanguages.contains(language)
                            ? 'View approved ${language.label} PDF'
                            : '${language.label} was not saved for this notice',
                        child: ChoiceChip(
                          key:
                              ValueKey('notice-language-${language.fileLabel}'),
                          label: Text(language.label),
                          selected: _language == language,
                          onSelected:
                              widget.availableLanguages.contains(language)
                                  ? (_) => setState(() => _language = language)
                                  : null,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.availableLanguages.length <
                  GirviNoticeLanguage.values.length)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(
                    'Only the saved language is available for this older notice. Its approved content has not been changed.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  // Never display a previous language's bytes while loading another.
                  key: ValueKey(_language),
                  future: _document,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_language.label} PDF could not be loaded.',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => setState(() {
                                _documents.remove(_language);
                              }),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return PdfPreview(
                      key: ValueKey('pdf-${_language.fileLabel}'),
                      build: (_) async => snapshot.requireData,
                      initialPageFormat: PdfPageFormat.a4,
                      allowPrinting: false,
                      allowSharing: false,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      useActions: false,
                      maxPageWidth: 920,
                      scrollViewDecoration:
                          const BoxDecoration(color: _background),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}
