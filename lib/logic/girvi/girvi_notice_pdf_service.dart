import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/girvi/girvi_notice_action_model.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/notice_auction_model.dart';

class GirviNoticePdfService {
  static const PdfColor _navy = PdfColor.fromInt(0xFF172437);
  static const PdfColor _gold = PdfColor.fromInt(0xFFC89421);
  static const PdfColor _goldLight = PdfColor.fromInt(0xFFFFF7E0);
  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _line = PdfColor.fromInt(0xFF111827);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF7F9FC);
  static const PdfColor _danger = PdfColor.fromInt(0xFFB91C1C);

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final NumberFormat _amountFormat = NumberFormat('#,##,##0', 'en_IN');

  Future<Uint8List> build({
    required NoticeAuctionCase item,
    required GirviNoticeType noticeType,
    required GirviNoticeLanguage noticeLanguage,
    required String noticeText,
  }) async {
    final devanagariFont = noticeLanguage == GirviNoticeLanguage.hindi
        ? await _loadDevanagariFont()
        : null;
    final document = pw.Document(
      theme: await _buildTheme(devanagariFont),
      title: '${noticeType.label} - ${item.loan.ticketNo}',
      author: 'Lotus ERP',
      creator: 'Lotus ERP',
      subject: '${noticeLanguage.label} Girvi notice',
    );

    document.addPage(
      pw.Page(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.fromLTRB(24, 24, 24, 22),
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _header(item, noticeType, noticeLanguage, devanagariFont),
            pw.SizedBox(height: 10),
            _accountSummary(item, noticeType, noticeLanguage, devanagariFont),
            pw.SizedBox(height: 10),
            _noticeBody(
              _pdfNoticeText(noticeText, noticeLanguage),
              noticeLanguage,
              devanagariFont,
            ),
            pw.Spacer(),
            pw.SizedBox(height: 10),
            _signatureBlock(noticeLanguage, devanagariFont),
            pw.SizedBox(height: 10),
            _footer(context),
          ],
        ),
      ),
    );

    return document.save();
  }

  pw.Widget _header(
    NoticeAuctionCase item,
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
                  _dateFormat.format(DateTime.now()),
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

  pw.Widget _accountSummary(
    NoticeAuctionCase item,
    GirviNoticeType noticeType,
    GirviNoticeLanguage language,
    pw.Font? devanagariFont,
  ) {
    final account = item.account;
    final loan = item.loan;
    return pw.Container(
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line, width: 0.65),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _label('Account Summary', language),
            textDirection: pw.TextDirection.ltr,
            style: _textStyle(
              language,
              devanagariFont,
              color: _ink,
              fontSize: 13.8,
              bold: true,
            ),
          ),
          pw.SizedBox(height: 8),
          _pledgedItemStrip(item, language, devanagariFont),
          pw.SizedBox(height: 7),
          pw.Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _metric(
                _label('Notice Stage', language),
                '${noticeType.stage}/3',
                language: language,
                devanagariFont: devanagariFont,
                highlight: true,
              ),
              _metric(
                _label('Customer', language),
                account.customerName,
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Mobile', language),
                account.customerMobile,
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Girvi Date', language),
                _dateFormat.format(loan.startDate),
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Maturity Date', language),
                loan.maturityDate == null
                    ? _label('Not Set', language)
                    : _dateFormat.format(loan.maturityDate!),
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Account Age', language),
                item.loanAgeMonthsDaysLabel,
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Overdue Age', language),
                item.overdueAgeMonthsDaysLabel,
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Principal', language),
                _money(account.principalDue),
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Interest', language),
                _money(account.netInterestDue),
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Total Payable', language),
                _money(account.totalPayable),
                language: language,
                devanagariFont: devanagariFont,
                color: _danger,
              ),
              _metric(
                _label('Pledged Value', language),
                _money(loan.totalValue),
                language: language,
                devanagariFont: devanagariFont,
              ),
              _metric(
                _label('Settlement Deadline', language),
                _dateFormat.format(
                  DateTime.now().add(Duration(days: item.noticePeriodDays)),
                ),
                language: language,
                devanagariFont: devanagariFont,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pledgedItemStrip(
    NoticeAuctionCase item,
    GirviNoticeLanguage language,
    pw.Font? devanagariFont,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _line, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _label('Pledged Item', language).toUpperCase(),
            textDirection: pw.TextDirection.ltr,
            maxLines: 1,
            style: _textStyle(
              language,
              devanagariFont,
              color: _ink,
              fontSize: 8.5,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            _itemSummary(item.loan, language),
            textDirection: pw.TextDirection.ltr,
            maxLines: 2,
            style: _textStyle(
              language,
              devanagariFont,
              color: _ink,
              fontSize: 10.6,
              bold: true,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metric(
    String label,
    String value, {
    required GirviNoticeLanguage language,
    required pw.Font? devanagariFont,
    PdfColor color = _ink,
    bool highlight = false,
  }) {
    return pw.Container(
      width: 158,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        color: highlight ? _goldLight : PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: highlight ? _gold : _line, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            textDirection: pw.TextDirection.ltr,
            maxLines: 1,
            style: _textStyle(
              language,
              devanagariFont,
              color: _ink,
              fontSize: 8.2,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            textDirection: pw.TextDirection.ltr,
            maxLines: 2,
            style: _textStyle(
              language,
              devanagariFont,
              color: color,
              fontSize: 10.8,
              bold: true,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _noticeBody(
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
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _surface,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _line, width: 0.6),
          ),
          child: pw.Text(
            _label('Notice Text', language),
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
        pw.SizedBox(height: 6),
        for (final paragraph in paragraphs)
          paragraph.trim().isEmpty
              ? pw.SizedBox(height: 4)
              : pw.Padding(
                  padding:
                      const pw.EdgeInsets.only(left: 6, right: 6, bottom: 3),
                  child: pw.Text(
                    paragraph,
                    textDirection: pw.TextDirection.ltr,
                    style: _textStyle(
                      language,
                      devanagariFont,
                      color: _ink,
                      fontSize: 10.8,
                      lineSpacing: 1.2,
                    ),
                  ),
                ),
      ],
    );
  }

  String _pdfNoticeText(String noticeText, GirviNoticeLanguage language) {
    final detailPrefixes = language == GirviNoticeLanguage.hindi
        ? const [
            'सूचना दिनांक:',
            'टिकट नंबर:',
            'ग्राहक मोबाइल:',
            'ग्राहक पता:',
            'गिरवी रखने की तारीख:',
            'देय तारीख:',
            'परिपक्वता तारीख:',
            'खाता अवधि:',
            'बकाया अवधि:',
            'ओवरड्यू अवधि:',
            'सूचना चरण:',
            'गिरवी वस्तु:',
            'गिरवी मूल्यांकन:',
            'मूलधन बकाया:',
            'ब्याज बकाया:',
            'कुल देय राशि:',
            'सूचना अवधि:',
            'अंतिम तारीख:',
            'निपटान की अंतिम तिथि:',
            'दुकान साइन',
            'दुकान हस्ताक्षर',
            'अधिकृत हस्ताक्षरकर्ता',
          ]
        : const [
            'Notice Date:',
            'Ticket Number:',
            'Customer Mobile:',
            'Customer Address:',
            'Girvi Date:',
            'Maturity Date:',
            'Account Age:',
            'Overdue Age:',
            'Notice Stage:',
            'Pledged Item:',
            'Pledged Valuation:',
            'Principal Outstanding:',
            'Interest Outstanding:',
            'Total Payable:',
            'Notice Period:',
            'Settlement Deadline:',
            'Authorised Signatory',
          ];
    final lines = <String>[];
    var lastBlank = false;
    for (final line in noticeText.split('\n')) {
      final trimmed = line.trim();
      final isDetail = detailPrefixes.any(trimmed.startsWith);
      if (isDetail) continue;
      if (trimmed.isEmpty) {
        if (!lastBlank && lines.isNotEmpty) {
          lines.add('');
          lastBlank = true;
        }
        continue;
      }
      lines.add(line.trimRight());
      lastBlank = false;
    }
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    return lines.join('\n');
  }

  String _itemSummary(
    GirviLoanModel loan,
    GirviNoticeLanguage language,
  ) {
    final serialLabel =
        language == GirviNoticeLanguage.hindi ? 'क्रमांक' : 'Serial Number';
    final source = loan.itemDescription.trim().isEmpty
        ? loan.itemSummary
        : loan.itemDescription;
    return source
        .replaceAllMapped(
          RegExp(r'#\s*(\d+)'),
          (match) => '$serialLabel ${match.group(1)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  pw.Widget _signatureBlock(
    GirviNoticeLanguage language,
    pw.Font? devanagariFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signature(
          _label('Customer Acknowledgement', language),
          language,
          devanagariFont,
        ),
        _signature(
          _label('Authorised Signatory', language),
          language,
          devanagariFont,
        ),
      ],
    );
  }

  pw.Widget _signature(
    String label,
    GirviNoticeLanguage language,
    pw.Font? devanagariFont,
  ) {
    return pw.Container(
      width: 238,
      padding: const pw.EdgeInsets.only(top: 22),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
      ),
      child: pw.Text(
        label,
        textDirection: pw.TextDirection.ltr,
        style: _textStyle(
          language,
          devanagariFont,
          color: _ink,
          fontSize: 10.2,
          bold: true,
        ),
      ),
    );
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
      'Notice Stage' => 'सूचना चरण',
      'Customer' => 'ग्राहक',
      'Mobile' => 'मोबाइल',
      'Girvi Date' => 'गिरवी तारीख',
      'Maturity Date' => 'देय तारीख',
      'Account Age' => 'खाता अवधि',
      'Overdue Age' => 'बकाया अवधि',
      'Principal' => 'मूलधन',
      'Interest' => 'ब्याज',
      'Total Payable' => 'कुल देय',
      'Pledged Item' => 'गिरवी वस्तु',
      'Pledged Value' => 'गिरवी मूल्य',
      'Settlement Deadline' => 'अंतिम तारीख',
      'Not Set' => 'निश्चित नहीं',
      'Notice Text' => 'सूचना',
      'Customer Acknowledgement' => 'ग्राहक साइन',
      'Authorised Signatory' => 'दुकान साइन',
      _ => english,
    };
  }

  Future<pw.Font?> _loadDevanagariFont() async {
    const assetPath = 'assets/fonts/lohit_devanagari/Lohit-Devanagari.ttf';
    try {
      return pw.Font.ttf(await rootBundle.load(assetPath));
    } catch (_) {
      try {
        final fontFile = File(assetPath);
        if (fontFile.existsSync()) {
          return pw.Font.ttf(_asByteData(await fontFile.readAsBytes()));
        }
      } catch (_) {
        // English notices can still be generated with built-in fonts.
      }
    }
    return null;
  }

  Future<pw.ThemeData> _buildTheme(pw.Font? devanagariFont) async {
    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      fontFallback: devanagariFont == null ? null : [devanagariFont],
    );
  }

  ByteData _asByteData(Uint8List bytes) {
    return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  String _money(double value) => 'Rs ${_amountFormat.format(value)}';
}
