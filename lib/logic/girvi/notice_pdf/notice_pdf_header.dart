part of '../girvi_notice_pdf_service.dart';

pw.Widget _storedNoticeHeader(
  String ticketNo,
  GirviNoticeType noticeType,
  GirviNoticeLanguage language,
  pw.Font? devanagariFont,
  DateTime savedAt,
  int? legacyNoticeStage,
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
                (GirviNoticeHistory.title(legacyNoticeStage,
                            hindi: language == GirviNoticeLanguage.hindi) ??
                        _noticeTitle(noticeType, language))
                    .toUpperCase(),
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
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
