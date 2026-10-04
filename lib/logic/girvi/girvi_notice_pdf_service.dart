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

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(24, 24, 24, 22),
        ),
        build: (context) => [
          _header(item, noticeType, noticeLanguage, devanagariFont),
          pw.SizedBox(height: 10),
          ..._noticeBodyWidgets(
            _noticeTextWithoutValuation(noticeText),
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

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(24, 24, 24, 22),
        ),
        build: (context) => [
          _storedNoticeHeader(
            ticketNo,
            noticeType,
            noticeLanguage,
            devanagariFont,
            savedAt,
          ),
          pw.SizedBox(height: 10),
          ..._noticeBodyWidgets(
            _noticeTextWithoutValuation(noticeText),
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
    GirviNoticeType noticeType,
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
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  language == GirviNoticeLanguage.hindi
                      ? 'गिरवी सूचना'
                      : 'GIRVI NOTICE',
                  textDirection: pw.TextDirection.ltr,
                  style: _textStyle(
                    language,
                    devanagariFont,
                    color: PdfColors.white,
                    fontSize: 22,
                    bold: true,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  _noticeTitle(noticeType, language).toUpperCase(),
                  textDirection: pw.TextDirection.ltr,
                  style: _textStyle(
                    language,
                    devanagariFont,
                    color: _gold,
                    fontSize: 12.5,
                    bold: true,
                  ),
                ),
              ],
            ),
          ),
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

  pw.Widget _header(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    pw.Font? devanagariFont,
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
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  language == GirviNoticeLanguage.hindi
                      ? 'गिरवी सूचना'
                      : 'GIRVI NOTICE',
                  textDirection: pw.TextDirection.ltr,
                  style: _textStyle(
                    language,
                    devanagariFont,
                    color: PdfColors.white,
                    fontSize: 22,
                    bold: true,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  _noticeTitle(noticeType, language).toUpperCase(),
                  textDirection: pw.TextDirection.ltr,
                  style: _textStyle(
                    language,
                    devanagariFont,
                    color: _gold,
                    fontSize: 12.5,
                    bold: true,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: _goldLight,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: _gold, width: 1.2),
                  ),
                  child: pw.Text(
                    '${_label('Ticket Number', language)}: ${item.loan.ticketNo}',
                    textDirection: pw.TextDirection.ltr,
                    style: _textStyle(
                      language,
                      devanagariFont,
                      color: _ink,
                      fontSize: 13,
                      bold: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  _dateFormat.format(item.now),
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
                  _noticeSubtitle(noticeType, language),
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
    var skippedTitle = false;
    for (final paragraph in paragraphs) {
      final text = paragraph.trim();
      if (!skippedTitle && text.isNotEmpty) {
        skippedTitle = true;
        continue;
      }
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

  String _noticeSubtitle(
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
  ) {
    if (language == GirviNoticeLanguage.hindi) {
      return switch (noticeType) {
        GirviNoticeType.first => 'पहली निपटान सूचना',
        GirviNoticeType.second => 'दूसरी भुगतान चेतावनी',
        GirviNoticeType.finalNotice => 'अंतिम वसूली सूचना',
      };
    }
    return noticeType.subtitle;
  }

  String _label(String english, GirviNoticeLanguage language) {
    if (language == GirviNoticeLanguage.english) return english;
    return switch (english) {
      'Account Summary' => 'खाता सार',
      'Ticket Number' => 'टिकट नंबर',
      'Notice Date' => 'सूचना दिनांक',
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
      'Settlement Deadline' => 'अंतिम तारीख',
      'Not Set' => 'निश्चित नहीं',
      'Notice Text' => 'सूचना',
      'Customer Acknowledgement' => 'ग्राहक साइन',
      'Authorised Signatory' => 'दुकान साइन',
      _ => english,
    };
  }
}
