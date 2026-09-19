part of '../new_girvi_screen.dart';

extension NewGirviInvoicePrintActions on _NewGirviScreenState {
  Future<void> printGirviInvoice() async {
    _syncPledgedItemsToController();
    final customer = _ctrl.selectedCustomer;
    if (customer == null) return;
    final pdf = pw.Document();
    final createdAt = DateTime.now();
    final itemPhotos = _pledgedItems
        .expand(
          (item) => item.validPhotoPaths.map(
            (path) => MapEntry(item.serialNo, File(path)),
          ),
        )
        .toList();

    String amount(double value) => _formatSmartMoney(value);
    String date(DateTime value) => _dateFmt.format(value);

    pw.Widget infoLine(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget sectionTitle(String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF111827)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LOTUS ERP',
                        style: pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('GIRVI LOAN INVOICE',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 3),
                    pw.Text('Pawn loan ticket and pledged item receipt',
                        style: const pw.TextStyle(
                            color: PdfColors.grey300, fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(_ctrl.ticketNo,
                        style: pw.TextStyle(
                            color: PdfColors.amber,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(date(createdAt),
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      sectionTitle('Customer Details'),
                      infoLine('Name', customer.name, bold: true),
                      infoLine('Mobile', customer.mobile),
                      infoLine('City', customer.city ?? '-'),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFBF7ED),
                    border: pw.Border.all(color: PdfColors.amber100),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      sectionTitle('Loan Summary'),
                      infoLine('Principal', amount(_ctrl.loanAmount),
                          bold: true),
                      infoLine(
                        'Interest Rate',
                        _ctrl.interestRate > 0
                            ? '${_formatSmartPercent(_ctrl.interestRate)} / month'
                            : '-',
                      ),
                      infoLine(
                        'Loan Tenure',
                        _ctrl.durationMonths > 0
                            ? '${_ctrl.durationMonths} months'
                            : '-',
                      ),
                      infoLine('Disbursement', _disbursementSummaryLabel),
                      infoLine(
                        'Maturity Date',
                        _ctrl.durationMonths > 0
                            ? date(_ctrl.maturityDate)
                            : '-',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          sectionTitle('Pledged Item'),
          pw.TableHelper.fromTextArray(
            headers: const [
              'S.No',
              'Metal',
              'Description',
              'Purity',
              'Pieces',
              'Gross Wt.',
              'Less Wt.',
              'Net Wt.',
              'Val. Purity',
              'Fine Wt.',
              'HUID',
              'Pledged Value',
            ],
            data: _pledgedItems.map((item) {
              final description = item.descriptionCtrl.text.trim();
              final huid = item.huidCtrl.text.trim();
              return [
                item.serialNo.toString(),
                item.metalType.displayName,
                description.isEmpty ? '-' : description,
                item.purityLabel,
                item.itemCount.toString(),
                _formatSmartWeight(item.grossWeight, dashWhenZero: true),
                _formatSmartWeight(item.lessWeight, dashWhenZero: true),
                _formatSmartWeight(item.netWeight, dashWhenZero: true),
                item.valuationPurityLabel,
                _formatSmartWeight(item.fineWeight, dashWhenZero: true),
                huid.isEmpty ? '-' : huid,
                amount(item.itemValue),
              ];
            }).toList(),
            headerStyle:
                pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7.2),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1EDE4)),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          if (itemPhotos.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            sectionTitle('Pledged Item Photos'),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: itemPhotos.map((entry) {
                final bytes = entry.value.readAsBytesSync();
                return pw.Container(
                  width: 126,
                  height: 108,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Item #${entry.key}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Expanded(
                        child: pw.Image(
                          pw.MemoryImage(bytes),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF9FAFB),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Text(
              'This document records the loan disbursement against the pledged item listed above. Final settlement will be calculated as per actual release date, applicable interest, and any approved charges.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'girvi_invoice_${_ctrl.ticketNo.replaceAll('/', '_')}.pdf',
    );
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _sectionFade[i],
        child: SlideTransition(position: _sectionSlide[i], child: child),
      );
}

class _SavedTicketSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SavedTicketSummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: GirviColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: GirviColors.textDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
