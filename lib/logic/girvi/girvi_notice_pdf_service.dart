import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/pdf/lotus_pdf_theme.dart';
import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/contact_recovery_model.dart';

class GirviNoticePdfService {
  static const PdfColor _navy = PdfColor.fromInt(0xFF172437);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC89421);
  static const PdfColor _goldLight = PdfColor.fromInt(0xFFFFF7E0);
  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  Future<Uint8List> build({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
  }) async {
    final devanagariFont = noticeLanguage == GirviNoticeLanguage.hindi
        ? await LotusPdfTheme.loadDevanagariFont()
        : null;
    final document = pw.Document(
      theme: await LotusPdfTheme.reportTheme(),
      title: '${noticeType.label} - ${item.loan.ticketNo}',
      author: 'Lotus ERP',
      creator: 'Lotus ERP',
      subject: '${noticeLanguage.label} Girvi notice',
    );
    final itemImage = await _loadItemImage(item);
    final headerData = _extractHeaderData(
      noticeText,
      fallbackTicketNo: item.loan.ticketNo,
      fallbackDate: _dateFormat.format(item.now),
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(24, 24, 24, 22),
        ),
        build: (context) => [
          _header(
            ticketNo: item.loan.ticketNo,
            noticeDate: _dateFormat.format(item.now),
            language: noticeLanguage,
            devanagariFont: devanagariFont,
          ),
          pw.SizedBox(height: 12),
          _noticeHero(
            header: headerData,
            noticeType: noticeType,
            language: noticeLanguage,
            devanagariFont: devanagariFont,
          ),
          pw.SizedBox(height: 9),
          _accountSnapshot(
            item: item,
            itemImage: itemImage,
            language: noticeLanguage,
            devanagariFont: devanagariFont,
          ),
          pw.SizedBox(height: 10),
          ..._noticeBodyWidgets(
            _noticeBodyText(noticeText),
            noticeLanguage,
            devanagariFont,
          ),
        ],
        footer: _footer,
      ),
    );

    return document.save();
  }

  Future<Uint8List> buildStoredNotice({
    required String ticketNo,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
    required DateTime savedAt,
    ContactRecoveryCase? item,
  }) async {
    final devanagariFont = noticeLanguage == GirviNoticeLanguage.hindi
        ? await LotusPdfTheme.loadDevanagariFont()
        : null;
    final document = pw.Document(
      theme: await LotusPdfTheme.reportTheme(),
      title: '${noticeType.label} - $ticketNo',
      author: 'Lotus ERP',
      creator: 'Lotus ERP',
      subject: 'Stored ${noticeLanguage.label} Girvi notice',
    );
    final itemImage = item == null ? null : await _loadItemImage(item);
    final headerData = _extractHeaderData(
      noticeText,
      fallbackTicketNo: ticketNo,
      fallbackDate: _dateFormat.format(savedAt),
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(24, 24, 24, 22),
        ),
        build: (context) => [
          _storedNoticeHeader(
            ticketNo,
            noticeLanguage,
            devanagariFont,
            savedAt,
          ),
          pw.SizedBox(height: 10),
          _noticeHero(
            header: headerData,
            noticeType: noticeType,
            language: noticeLanguage,
            devanagariFont: devanagariFont,
          ),
          if (item != null) ...[
            pw.SizedBox(height: 9),
            _accountSnapshot(
              item: item,
              itemImage: itemImage,
              language: noticeLanguage,
              devanagariFont: devanagariFont,
            ),
          ],
          pw.SizedBox(height: 10),
          ..._noticeBodyWidgets(
            _noticeBodyText(noticeText),
            noticeLanguage,
            devanagariFont,
          ),
        ],
        footer: _footer,
      ),
    );

    return document.save();
  }

  pw.Widget _storedNoticeHeader(
    String ticketNo,
    GirviNoticeLanguage language,
    pw.Font? devanagariFont,
    DateTime savedAt,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _brandMark(language, devanagariFont),
          pw.SizedBox(width: 14),
          pw.Container(
            width: 158,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${_label('Ticket Number', language)}: $ticketNo',
                  textDirection: pw.TextDirection.ltr,
                  textAlign: pw.TextAlign.right,
                  style: _textStyle(
                    language,
                    devanagariFont,
                    color: _ink,
                    fontSize: 11.5,
                    bold: true,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${_label('Notice Date', language)}: ${_dateFormat.format(savedAt)}',
                  textDirection: pw.TextDirection.ltr,
                  textAlign: pw.TextAlign.right,
                  style: _textStyle(
                    language,
                    devanagariFont,
                    color: _ink,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _header({
    required String ticketNo,
    required String noticeDate,
    required GirviNoticeLanguage language,
    required pw.Font? devanagariFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _brandMark(language, devanagariFont),
          pw.SizedBox(width: 14),
          pw.Container(
            width: 142,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${_label('Ticket Number', language)}: $ticketNo',
                  textDirection: pw.TextDirection.ltr,
                  style: _textStyle(
                    language,
                    devanagariFont,
                    color: _ink,
                    fontSize: 11.5,
                    bold: true,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${_label('Notice Date', language)}: $noticeDate',
                  textDirection: pw.TextDirection.ltr,
                  textAlign: pw.TextAlign.right,
                  style: _textStyle(
                    language,
                    devanagariFont,
                    color: _ink,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _brandMark(GirviNoticeLanguage language, pw.Font? devanagariFont) =>
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'LOTUS ERP',
              style: _textStyle(
                language,
                devanagariFont,
                color: PdfColors.white,
                fontSize: 20,
                bold: true,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Simple  •  Secure  •  Smart',
              style: _textStyle(
                language,
                devanagariFont,
                color: PdfColors.white,
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      );

  _NoticeHeaderData _extractHeaderData(
    String noticeText, {
    required String fallbackTicketNo,
    required String fallbackDate,
  }) {
    String valueFor(List<String> prefixes, String fallback) {
      for (final rawLine in noticeText.split('\n')) {
        final line = rawLine.trim();
        final separator = line.indexOf(':');
        if (separator < 0) continue;
        final key = line.substring(0, separator).trim().toLowerCase();
        if (prefixes.any((prefix) => key == prefix.toLowerCase())) {
          final value = line.substring(separator + 1).trim();
          if (value.isNotEmpty) return value;
        }
      }
      return fallback;
    }

    return _NoticeHeaderData(
      noticeNumber: valueFor(const ['Notice Number', 'सूचना नंबर'], fallbackTicketNo),
      noticeDate: valueFor(const ['Notice Date', 'सूचना दिनांक'], fallbackDate),
      pledgeReference:
          valueFor(const ['Pledge Reference', 'गिरवी संदर्भ'], fallbackTicketNo),
      subject: valueFor(const ['Subject', 'विषय'], ''),
    );
  }

  String _noticeBodyText(String noticeText) {
    final lines = _noticeTextWithoutValuation(noticeText).split('\n');
    final subjectIndex = lines.indexWhere((line) {
      final trimmed = line.trim();
      return trimmed.startsWith('Subject:') || trimmed.startsWith('विषय:');
    });
    if (subjectIndex >= 0 && subjectIndex + 1 < lines.length) {
      return lines.skip(subjectIndex + 1).join('\n').trim();
    }
    final firstContentIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
    return firstContentIndex < 0
        ? ''
        : lines.skip(firstContentIndex + 1).join('\n').trim();
  }

  pw.Widget _noticeHero({
    required _NoticeHeaderData header,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage language,
    required pw.Font? devanagariFont,
  }) {
    final title = language == GirviNoticeLanguage.hindi
        ? 'गिरवी सूचना'
        : 'GIRVI NOTICE';
    final heading = _noticeTitle(noticeType, language).toUpperCase();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            title,
            style: _textStyle(
              language,
              devanagariFont,
              color: _navy,
              fontSize: 24,
              bold: true,
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: pw.BoxDecoration(
              color: _gold,
              borderRadius: pw.BorderRadius.circular(999),
            ),
            child: pw.Text(
              heading,
              style: _textStyle(
                language,
                devanagariFont,
                color: _navy,
                fontSize: 11.5,
                bold: true,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 7),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF4FAFF),
            borderRadius: pw.BorderRadius.circular(7),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFB9DBF7)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _heroField(
                  '${_label('Notice Number', language)}: ${header.noticeNumber}',
                  language,
                  devanagariFont,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _heroField(
                  '${_label('Notice Date', language)}: ${header.noticeDate}',
                  language,
                  devanagariFont,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _heroField(
                  '${_label('Pledge Reference', language)}: ${header.pledgeReference}',
                  language,
                  devanagariFont,
                ),
              ),
            ],
          ),
        ),
        if (header.subject.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              color: _goldLight,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _gold, width: 0.65),
            ),
            child: pw.Text(
              '${_label('Subject', language)}: ${header.subject}',
              style: _textStyle(
                language,
                devanagariFont,
                color: _ink,
                fontSize: 10.3,
                bold: true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _heroField(
    String value,
    GirviNoticeLanguage language,
    pw.Font? devanagariFont,
  ) =>
      pw.Text(
        value,
        style: _textStyle(
          language,
          devanagariFont,
          color: _navy,
          fontSize: 9.4,
          bold: true,
        ),
      );

  pw.Widget _accountSnapshot({
    required ContactRecoveryCase item,
    required pw.MemoryImage? itemImage,
    required GirviNoticeLanguage language,
    required pw.Font? devanagariFont,
  }) {
    final loan = item.loan;
    final account = item.account;
    final money = NumberFormat('#,##,##0.00', 'en_IN');
    final rows = <List<String>>[
      [_label('Pledged Item', language), loan.itemDescription],
      [_label('Net Weight', language), '${loan.netWeight.toStringAsFixed(3)} g'],
      [_label('Original Principal', language), 'Rs ${money.format(account.originalPrincipal)}'],
      [_label('Pledge Date', language), _dateFormat.format(loan.startDate)],
      [_label('Maturity Date', language), loan.maturityDate == null ? _label('Not Set', language) : _dateFormat.format(loan.maturityDate!)],
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(7),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFB9DBF7)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 70,
            height: 70,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF6F8FA),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFD7E1EA)),
            ),
            child: itemImage == null
                ? pw.Text(
                    language == GirviNoticeLanguage.hindi ? 'वस्तु\nछवि नहीं' : 'Item\nimage\nnot available',
                    textAlign: pw.TextAlign.center,
                    style: _textStyle(
                      language,
                      devanagariFont,
                      color: const PdfColor.fromInt(0xFF64748B),
                      fontSize: 8,
                      bold: true,
                    ),
                  )
                : pw.Image(itemImage, fit: pw.BoxFit.cover),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final row in rows) ...[
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '${row.first}: ',
                          style: _textStyle(language, devanagariFont, color: _navy, fontSize: 9.2, bold: true),
                        ),
                        pw.TextSpan(
                          text: row.last,
                          style: _textStyle(language, devanagariFont, color: _ink, fontSize: 9.2),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 3),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Container(
            width: 150,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF4FAFF),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _heroField('${_label('Actual Duration', language)}: ${item.loanAgeMonthsDaysLabel}', language, devanagariFont),
                pw.SizedBox(height: 5),
                _heroField('${_label('Interest Calculation Period', language)}: ${item.chargeableInterestMonthsLabel}', language, devanagariFont),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<pw.MemoryImage?> _loadItemImage(ContactRecoveryCase item) async {
    final candidates = <String>[
      ...item.itemPhotoPaths,
      if (item.loan.itemPhotoPath != null) item.loan.itemPhotoPath!,
    ];
    for (final path in candidates) {
      final normalizedPath = path.trim();
      if (normalizedPath.isEmpty) continue;
      try {
        final file = File(normalizedPath);
        if (!await file.exists()) continue;
        return pw.MemoryImage(await file.readAsBytes());
      } catch (_) {
        // Item media is optional. A notice must remain printable without it.
      }
    }
    return null;
  }

  List<pw.Widget> _noticeBodyWidgets(
    String noticeText,
    GirviNoticeLanguage language,
    pw.Font? devanagariFont,
  ) {
    final serialLabel =
        language == GirviNoticeLanguage.hindi ? 'क्रमांक' : 'Serial Number';
    final paragraphs = noticeText
        .replaceAllMapped(
          RegExp(r'#\s*(\d+)'),
          (match) => '$serialLabel ${match.group(1)}',
        )
        .split('\n')
        .map((line) => line.trimRight())
        .toList(growable: false);
    final content = <pw.Widget>[];
    for (final paragraph in paragraphs) {
      final text = paragraph.trim();
      if (text.isEmpty) {
        content.add(pw.SizedBox(height: 5));
        continue;
      }
      if (_isNoticeSectionHeading(text, language)) {
        content
          ..add(pw.SizedBox(height: 7))
          ..add(
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _goldLight,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: _gold, width: 0.7),
              ),
              child: pw.Text(
                text,
                textDirection: pw.TextDirection.ltr,
                style: _textStyle(
                  language,
                  devanagariFont,
                  color: _ink,
                  fontSize: 11.2,
                  bold: true,
                ),
              ),
            ),
          );
        continue;
      }
      final isSubject = text.startsWith('Subject:') || text.startsWith('विषय:');
      content.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 5, right: 5, bottom: 4),
          child: pw.Text(
            text,
            textDirection: pw.TextDirection.ltr,
            style: _textStyle(
              language,
              devanagariFont,
              color: isSubject ? _navy : _ink,
              fontSize: isSubject ? 11.3 : 10.5,
              bold: isSubject,
              lineSpacing: 1.25,
            ),
          ),
        ),
      );
    }
    return content;
  }

  bool _isNoticeSectionHeading(String value, GirviNoticeLanguage language) {
    final english = <String>{
      'Dear Customer',
      'Pledge Account and Duration',
      'Interest Breakdown',
      'Simple Interest Breakdown',
      'Compound Interest Breakdown',
      'Payments and Adjustments',
      'Previous Contact and Customer Response',
      'Final Outstanding Summary',
      'Required Action',
      'Simple Interest Period',
    };
    final hindi = <String>{
      'प्रिय ग्राहक',
      'गिरवी खाता और अवधि',
      'ब्याज विवरण',
      'साधारण ब्याज विवरण',
      'चक्रवृद्धि ब्याज विवरण',
      'भुगतान और समायोजन',
      'पूर्व संपर्क और ग्राहक प्रतिक्रिया',
      'अंतिम बकाया सारांश',
      'आवश्यक कार्रवाई',
      'साधारण ब्याज अवधि',
    };
    if ((language == GirviNoticeLanguage.hindi ? hindi : english)
        .contains(value)) {
      return true;
    }
    return value.startsWith('Compound Year ') ||
        value.startsWith('Remaining Compound Period') ||
        value.startsWith('चक्रवृद्धि वर्ष ') ||
        value.startsWith('शेष चक्रवृद्धि अवधि');
  }

  String _noticeTextWithoutValuation(String noticeText) {
    const hiddenPrefixes = <String>[
      'Pledged Valuation:',
      'Pledged Value:',
      'Valuation:',
      'गिरवी मूल्यांकन:',
      'गिरवी मूल्य:',
      'मूल्यांकन:',
    ];
    return noticeText
        .split('\n')
        .where((line) {
          final trimmed = line.trim();
          return !hiddenPrefixes.any(trimmed.startsWith);
        })
        .join('\n')
        .trim();
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated by Lotus ERP',
          textDirection: pw.TextDirection.ltr,
          style: const pw.TextStyle(color: _ink, fontSize: 8.5),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          textDirection: pw.TextDirection.ltr,
          style: const pw.TextStyle(color: _ink, fontSize: 8.5),
        ),
      ],
    );
  }

  pw.TextStyle _textStyle(
    GirviNoticeLanguage language,
    pw.Font? devanagariFont, {
    required PdfColor color,
    required double fontSize,
    bool bold = false,
    double? lineSpacing,
  }) {
    return pw.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontFallback: devanagariFont == null ? const [] : [devanagariFont],
      lineSpacing: lineSpacing,
    );
  }

  String _noticeTitle(
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
  ) {
    if (language == GirviNoticeLanguage.hindi) {
      return switch (noticeType) {
        GirviNoticeType.first => 'पहली सूचना',
        GirviNoticeType.second => 'दूसरी सूचना',
        GirviNoticeType.finalNotice => 'अंतिम सूचना',
      };
    }
    return noticeType.label;
  }

  String _label(String english, GirviNoticeLanguage language) {
    if (language == GirviNoticeLanguage.english) return english;
    return switch (english) {
      'Account Summary' => 'खाता सार',
      'Ticket Number' => 'टिकट नंबर',
      'Notice Date' => 'सूचना दिनांक',
      'Notice Number' => 'सूचना नंबर',
      'Pledge Reference' => 'गिरवी संदर्भ',
      'Notice Stage' => 'सूचना चरण',
      'Customer' => 'ग्राहक',
      'Mobile' => 'मोबाइल',
      'Girvi Date' => 'गिरवी तारीख',
      'Maturity Date' => 'देय तारीख',
      'Account Age' => 'खाता अवधि',
      'Actual Duration' => 'वास्तविक अवधि',
      'Calendar Duration' => 'कैलेंडर अवधि',
      'Interest Calculation Period' => 'ब्याज गणना अवधि',
      'Overdue Age' => 'बकाया अवधि',
      'Principal' => 'मूलधन',
      'Interest' => 'ब्याज',
      'Total Payable' => 'कुल देय',
      'Pledged Item' => 'गिरवी वस्तु',
      'Original Principal' => 'मूल मूलधन',
      'Pledge Date' => 'गिरवी तारीख',
      'Settlement Deadline' => 'अंतिम तारीख',
      'Not Set' => 'निश्चित नहीं',
      'Notice Text' => 'सूचना',
      'Customer Acknowledgement' => 'ग्राहक साइन',
      'Authorised Signatory' => 'दुकान साइन',
      _ => english,
    };
  }
}

class _NoticeHeaderData {
  const _NoticeHeaderData({
    required this.noticeNumber,
    required this.noticeDate,
    required this.pledgeReference,
    required this.subject,
  });

  final String noticeNumber;
  final String noticeDate;
  final String pledgeReference;
  final String subject;
}
