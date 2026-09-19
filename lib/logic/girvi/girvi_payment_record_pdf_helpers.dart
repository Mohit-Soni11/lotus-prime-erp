part of 'girvi_payment_record_pdf_service.dart';

const _paymentRecordLine = PdfColor.fromInt(0xFFB8C0CC);
const _paymentRecordGold = PdfColor.fromInt(0xFFC89421);
const _paymentRecordGoldLight = PdfColor.fromInt(0xFFFBF6E9);
const _paymentRecordInk = PdfColor.fromInt(0xFF172033);
const _paymentRecordMuted = PdfColor.fromInt(0xFF111111);
const _paymentRecordRowTint = PdfColor.fromInt(0xFFF3F6FA);

List<_PledgedPaymentRecordItem> buildPledgedPaymentRecordRows(
  GirviLoanWithCustomer account,
  GirviLoanDetails? details,
) {
  final detailedItems = details?.items ?? const <GirviLoanItemDetails>[];
  if (detailedItems.isNotEmpty) {
    return detailedItems
        .map(
          (details) => _PledgedPaymentRecordItem(
            serialNo: details.item.serialNo,
            metal: details.item.metalType,
            itemName: details.item.itemName,
            pieces: details.item.pieces,
            purity: details.item.purity,
            grossWeight: details.item.grossWeight,
            lessWeight: details.item.lessWeight,
            netWeight: details.item.netWeight,
            ratePerGram: details.item.ratePerGram,
            value: details.item.valuationAmount,
          ),
        )
        .toList(growable: false);
  }

  return [
    _PledgedPaymentRecordItem(
      serialNo: 1,
      metal: account.loan.metalTypeEnum.displayName,
      itemName: account.loan.itemDescription,
      pieces: account.loan.itemCount,
      purity: account.loan.metalPurity,
      grossWeight: account.loan.grossWeight,
      lessWeight: account.loan.stoneWeight,
      netWeight: account.loan.netWeight,
      ratePerGram: account.loan.ratePerGram,
      value: account.loan.totalValue,
    ),
  ];
}

List<_PaymentRecordPhoto> loadPaymentRecordItemPhotos(
  GirviLoanWithCustomer account,
  GirviLoanDetails? details,
) {
  final photos = <_PaymentRecordPhoto>[];
  for (final itemDetails in details?.items ?? const <GirviLoanItemDetails>[]) {
    for (final photo in itemDetails.photos) {
      final loaded = _loadPaymentRecordPhoto(
        path: photo.filePath,
        serialNo: itemDetails.item.serialNo,
        title: itemDetails.item.itemName,
      );
      if (loaded != null) photos.add(loaded);
    }
  }

  if (photos.isEmpty) {
    final loaded = _loadPaymentRecordPhoto(
      path: account.loan.itemPhotoPath,
      serialNo: 1,
      title: account.loan.itemDescription,
    );
    if (loaded != null) photos.add(loaded);
  }
  return photos;
}

_PaymentRecordPhoto? _loadPaymentRecordPhoto({
  required String? path,
  required int serialNo,
  required String title,
}) {
  final resolved = path?.trim() ?? '';
  if (resolved.isEmpty) return null;
  final file = File(resolved);
  if (!file.existsSync()) return null;
  try {
    return _PaymentRecordPhoto(
      serialNo: serialNo,
      title: title,
      image: pw.MemoryImage(file.readAsBytesSync()),
    );
  } catch (_) {
    return null;
  }
}

pw.Widget buildPaymentRecordPhotoSection(List<_PaymentRecordPhoto> photos) {
  const columns = 3;
  return pw.Column(
    children: [
      for (var start = 0; start < photos.length; start += columns) ...[
        if (start > 0) pw.SizedBox(height: 9),
        _buildPhotoRow(
          photos.sublist(
            start,
            start + columns < photos.length ? start + columns : photos.length,
          ),
          columns,
        ),
      ],
    ],
  );
}

pw.Widget _buildPhotoRow(List<_PaymentRecordPhoto> photos, int columns) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < columns; index++) ...[
        if (index > 0) pw.SizedBox(width: 9),
        pw.Expanded(
          child: index < photos.length
              ? _buildPhotoCard(photos[index])
              : pw.SizedBox(),
        ),
      ],
    ],
  );
}

pw.Widget _buildPhotoCard(_PaymentRecordPhoto photo) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(5),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: _paymentRecordLine, width: 0.7),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 94,
          width: double.infinity,
          padding: const pw.EdgeInsets.all(3),
          decoration: const pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Image(photo.image, fit: pw.BoxFit.contain),
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const pw.BoxDecoration(
                color: _paymentRecordGoldLight,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Text(
                '#${photo.serialNo}',
                style: pw.TextStyle(
                  color: _paymentRecordGold,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 5),
            pw.Expanded(
              child: pw.Text(
                photo.title,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  color: _paymentRecordInk,
                  fontSize: 9.2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget buildPaymentRecordDetailTable(List<List<String>> rows) {
  return pw.TableHelper.fromTextArray(
    headers: null,
    data: rows,
    border: pw.TableBorder.all(color: _paymentRecordLine, width: 0.6),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    cellStyle: pw.TextStyle(
      fontSize: 9,
      color: _paymentRecordInk,
      fontWeight: pw.FontWeight.bold,
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.05),
      1: pw.FlexColumnWidth(1.45),
    },
    cellAlignments: const {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerRight,
    },
    oddRowDecoration: const pw.BoxDecoration(color: _paymentRecordRowTint),
  );
}

pw.Widget buildPaymentRecordSignatureBlock() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _signatureLine('Customer Signature'),
      _signatureLine('Authorized Signature'),
    ],
  );
}

pw.Widget _signatureLine(String label) {
  return pw.SizedBox(
    width: 190,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 1, color: _paymentRecordLine),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: _paymentRecordMuted),
        ),
      ],
    ),
  );
}

pw.Widget buildPaymentRecordFooter(
    pw.Context context, GirviInvoiceBranding branding) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        'Generated by ${branding.printShopName}',
        style: const pw.TextStyle(color: _paymentRecordMuted, fontSize: 8),
      ),
      pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(color: _paymentRecordMuted, fontSize: 8),
      ),
    ],
  );
}
