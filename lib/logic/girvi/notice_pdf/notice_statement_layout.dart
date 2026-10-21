part of '../girvi_notice_pdf_service.dart';

const _noticeNavy = PdfColor.fromInt(0xFF063562);
const _noticeDeepNavy = PdfColor.fromInt(0xFF072747);
const _noticeGold = PdfColor.fromInt(0xFFF1C96A);
const _noticePaleGold = PdfColor.fromInt(0xFFFFF4D8);
const _noticeBlueTint = PdfColor.fromInt(0xFFF1F7FC);
const _noticeBorder = PdfColor.fromInt(0xFFC5DDF1);
const _noticeInk = PdfColor.fromInt(0xFF0C3157);
const _noticeOutstanding = PdfColor.fromInt(0xFFB42318);
const _noticeReceived = PdfColor.fromInt(0xFF087F5B);
const _noticeBlack = PdfColor.fromInt(0xFF202020);
const _noticeDarkGold = PdfColor.fromInt(0xFF916A16);

class _NoticeStatementLayout {
  const _NoticeStatementLayout({
    required this.statement,
    required this.language,
    required this.ticketNo,
    required this.noticeType,
    required this.savedAt,
    required this.deadline,
    required this.noticePeriodDays,
    required this.branding,
    required this.logo,
    required this.signature,
    required this.itemPhoto,
    required this.originalLoanDurationMonths,
  });

  final NoticeStatementData statement;
  final GirviNoticeLanguage language;
  final String ticketNo;
  final GirviNoticeType noticeType;
  final DateTime savedAt;
  final DateTime? deadline;
  final int? noticePeriodDays;
  final GirviInvoiceBranding branding;
  final pw.MemoryImage? logo;
  final pw.MemoryImage? signature;
  final pw.MemoryImage? itemPhoto;
  final int? originalLoanDurationMonths;

  bool get hindi => language == GirviNoticeLanguage.hindi;
  String t(String english, String hindiText) => hindi ? hindiText : english;
  String printText(String value) =>
      value.replaceAll(RegExp(r'\bRs (?=\d)'), '₹ ');
  String get dateText =>
      statement.noticeDate ?? DateFormat('dd MMM yyyy').format(savedAt);

  List<String> get _headerPhones {
    final configuredPrimary = branding.printValue('mobile_number').trim();
    final candidates = [
      configuredPrimary.isNotEmpty ? configuredPrimary : branding.shopMobile,
      branding.printValue('help_desk_number'),
      branding.shopAlternateMobile,
    ];
    final numbers = <String>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      final value = candidate.trim();
      if (value.isEmpty) continue;
      final digits = value.replaceAll(RegExp(r'\D'), '');
      final key = digits.length >= 10
          ? digits.substring(digits.length - 10)
          : value.toLowerCase();
      if (!seen.add(key)) continue;
      numbers.add(digits.length == 10 ? '+91 $digits' : value);
      if (numbers.length == 2) break;
    }
    return numbers;
  }

  pw.TextStyle _style(double size,
          {bool bold = false, PdfColor color = _noticeInk}) =>
      pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      );

  pw.Widget header(pw.Context context) => pw.Column(children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(8, 7, 8, 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _noticeDarkGold, width: 1),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: 68,
                height: 68,
                child: logo == null
                    ? _shopMonogram()
                    : pw.Image(logo!, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 12),
              pw.Container(width: 0.8, height: 67, color: _noticeGold),
              pw.SizedBox(width: 13),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      branding.printShopName.toUpperCase(),
                      style: _style(21, bold: true, color: _noticeBlack),
                    ),
                    if (branding.printShopAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        branding.printShopAddress,
                        style: _style(10.2, bold: true, color: _noticeBlack),
                      ),
                    ],
                  ],
                ),
              ),
              if (_headerPhones.isNotEmpty) ...[
                pw.SizedBox(width: 13),
                pw.SizedBox(
                  width: 166,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _headerMeta('Mobile', _headerPhones.first),
                      if (_headerPhones.length > 1) ...[
                        pw.SizedBox(height: 8),
                        _headerMeta('Alternate', _headerPhones[1]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 10),
      ]);

  pw.Widget _headerMeta(String label, String value) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 65,
            child: pw.Text(
              label,
              style: _style(10.2, bold: true, color: _noticeBlack),
            ),
          ),
          pw.Text(':', style: _style(10.2, bold: true, color: _noticeBlack)),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _style(10.7, bold: true, color: _noticeBlack),
            ),
          ),
        ],
      );

  pw.Widget _shopMonogram() => pw.Container(
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _noticeDarkGold, width: 1.2),
        ),
        child: pw.Center(
          child: pw.Text(
            branding.initial,
            style: _style(27, bold: true, color: _noticeDarkGold),
          ),
        ),
      );

  pw.Widget _card(pw.Widget content, {double padding = 5}) => pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.all(padding),
        decoration: pw.BoxDecoration(
          color: _noticeBlueTint,
          border: pw.Border.all(color: _noticeBorder, width: 0.8),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: content,
      );
}
