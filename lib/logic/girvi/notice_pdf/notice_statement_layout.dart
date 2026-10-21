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
  String get noticeLabel => t('FORMAL NOTICE', 'औपचारिक सूचना');

  pw.TextStyle _style(double size,
          {bool bold = false, PdfColor color = _noticeInk}) =>
      pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      );

  pw.Widget header(pw.Context context) => pw.Column(children: [
        pw.Table(columnWidths: const {
          0: pw.FixedColumnWidth(543)
        }, children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _noticeDeepNavy),
            children: [
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: pw.Row(children: [
                  pw.SizedBox(
                    width: 42,
                    height: 42,
                    child: logo == null
                        ? _shopMonogram()
                        : pw.Image(logo!, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 11),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          branding.printShopName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 19,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 0.35,
                          ),
                        ),
                        if (branding.printShopAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            branding.printShopAddress,
                            style: _style(9.2, color: _noticeGold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 11),
                  pw.Container(width: 0.7, height: 43, color: _noticeGold),
                  pw.SizedBox(width: 12),
                  pw.SizedBox(
                    width: 188,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _headerMeta('Invoice No.', ticketNo),
                        pw.SizedBox(height: 7),
                        _headerMeta('Notice Date', dateText),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ]),
        pw.Container(height: 5, color: _noticeGold),
        pw.SizedBox(height: 8),
      ]);

  pw.Widget _headerMeta(String label, String value) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(label, style: _style(9.2, color: _noticeGold)),
          ),
          pw.Text(':', style: _style(9.2, color: _noticeGold)),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _style(10.2, bold: true, color: PdfColors.white),
            ),
          ),
        ],
      );

  pw.Widget footer(pw.Context context) => pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(height: 4),
          pw.Container(height: 4, color: _noticeGold),
          pw.Table(columnWidths: const {
            0: pw.FixedColumnWidth(543)
          }, children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _noticeDeepNavy),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 15, vertical: 7),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(branding.printShopName,
                          style: _style(8, color: PdfColors.white)),
                      pw.Text(
                        '${t('Page', 'पृष्ठ')} ${context.pageNumber} ${t('of', 'का')} ${context.pagesCount}',
                        style: _style(8, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ]),
        ],
      );

  pw.Widget _shopMonogram() => pw.Container(
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _noticeGold, width: 1.5),
        ),
        child: pw.Center(
          child: pw.Text(
            branding.initial,
            style: _style(22, bold: true, color: _noticeGold),
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

  pw.Widget _pair(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 112, child: pw.Text(label, style: _style(8))),
            pw.Expanded(
                child: pw.Text(printText(value), style: _style(8, bold: true))),
          ],
        ),
      );
}
