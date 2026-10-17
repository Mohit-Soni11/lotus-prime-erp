part of '../girvi_notice_pdf_service.dart';

pw.Widget _accountSummary(
  ContactRecoveryCase item,
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
              _label('Notice Status', language),
              language == GirviNoticeLanguage.hindi
                  ? 'समीक्षा हेतु'
                  : 'For review',
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
              _label('Actual Duration', language),
              item.loanAgeLabel,
              language: language,
              devanagariFont: devanagariFont,
            ),
            _metric(
              _label('Calendar Duration', language),
              item.loanAgeMonthsDaysLabel,
              language: language,
              devanagariFont: devanagariFont,
            ),
            _metric(
              _label('Interest Calculation Period', language),
              item.chargeableInterestMonthsLabel,
              language: language,
              devanagariFont: devanagariFont,
              highlight: true,
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
              _money(item.verifiedInterestDue),
              language: language,
              devanagariFont: devanagariFont,
            ),
            _metric(
              _label('Total Payable', language),
              _money(item.verifiedTotalPayable),
              language: language,
              devanagariFont: devanagariFont,
              color: _danger,
            ),
            _metric(
              _label('Settlement Deadline', language),
              _dateFormat.format(
                item.now.add(Duration(days: item.noticePeriodDays)),
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
  ContactRecoveryCase item,
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
