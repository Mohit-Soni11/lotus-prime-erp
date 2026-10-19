part of 'girvi_invoice_pdf_service.dart';

extension _GirviInvoicePdfTableSections on GirviInvoicePdfService {
  pw.Widget _buildItemsTable(
    List<GirviInvoiceItemDraft> items,
    GirviInvoiceFieldSettings settings,
    bool compact,
  ) {
    final columns = _visibleColumns(settings);
    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration:
            const pw.BoxDecoration(color: GirviInvoicePdfService._navySoft),
        children: [
          for (final column in columns)
            _buildTableCell(
              column.header,
              compact: compact,
              header: true,
              alignment: column.alignment,
            ),
        ],
      ),
      for (var index = 0; index < items.length; index++)
        _buildItemRow(items[index], index, columns, compact),
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: GirviInvoicePdfService._line, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Table(
        columnWidths: {
          for (var index = 0; index < columns.length; index++)
            index: pw.FlexColumnWidth(columns[index].width),
        },
        border: const pw.TableBorder(
          horizontalInside:
              pw.BorderSide(color: GirviInvoicePdfService._line, width: 0.45),
          verticalInside:
              pw.BorderSide(color: GirviInvoicePdfService._line, width: 0.45),
        ),
        children: rows,
      ),
    );
  }

  pw.TableRow _buildItemRow(
    GirviInvoiceItemDraft item,
    int index,
    List<_GirviInvoiceColumn> columns,
    bool compact,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: index.isEven ? PdfColors.white : GirviInvoicePdfService._surface,
      ),
      children: [
        for (final column in columns)
          _buildTableCell(
            column.value(item),
            compact: compact,
            alignment: column.alignment,
            strong: column.strong,
          ),
      ],
    );
  }

  List<_GirviInvoiceColumn> _visibleColumns(
    GirviInvoiceFieldSettings settings,
  ) {
    final columns = <_GirviInvoiceColumn>[
      if (settings.showSerialNumber)
        _GirviInvoiceColumn(
          header: 'S.No',
          width: 0.46,
          alignment: pw.Alignment.center,
          strong: true,
          value: (item) => item.serialNo.toString(),
        ),
      if (settings.showMetal)
        _GirviInvoiceColumn(
          header: 'Metal',
          width: 0.72,
          alignment: pw.Alignment.center,
          value: (item) => item.metal,
        ),
      if (settings.showItemName)
        _GirviInvoiceColumn(
          header: 'Item',
          width: 2.35,
          alignment: pw.Alignment.centerLeft,
          strong: true,
          value: (item) => item.description,
        ),
      if (settings.showPieces)
        _GirviInvoiceColumn(
          header: 'Pcs',
          width: 0.48,
          alignment: pw.Alignment.center,
          value: (item) => item.pieces.toString(),
        ),
      if (settings.showHuid)
        _GirviInvoiceColumn(
          header: 'HUID',
          width: 0.9,
          alignment: pw.Alignment.center,
          value: (item) => item.huid.isEmpty ? '-' : item.huid,
        ),
      if (settings.showPurity)
        _GirviInvoiceColumn(
          header: 'Purity',
          width: 0.7,
          alignment: pw.Alignment.center,
          value: (item) => item.purity,
        ),
      if (settings.showGrossWeight)
        _GirviInvoiceColumn(
          header: 'Gross Wt.',
          width: 0.92,
          alignment: pw.Alignment.centerRight,
          value: (item) => '${item.grossWeight.toStringAsFixed(3)} g',
        ),
      if (settings.showLessWeight)
        _GirviInvoiceColumn(
          header: 'Less Wt.',
          width: 0.86,
          alignment: pw.Alignment.centerRight,
          value: (item) => '${item.lessWeight.toStringAsFixed(3)} g',
        ),
      if (settings.showNetWeight)
        _GirviInvoiceColumn(
          header: 'Net Wt.',
          width: 0.92,
          alignment: pw.Alignment.centerRight,
          strong: true,
          value: (item) => '${item.netWeight.toStringAsFixed(3)} g',
        ),
    ];
    if (columns.isNotEmpty) return columns;
    return [
      _GirviInvoiceColumn(
        header: 'Item',
        width: 1,
        alignment: pw.Alignment.centerLeft,
        strong: true,
        value: (item) => item.description,
      ),
    ];
  }

  pw.Widget _buildTableCell(
    String value, {
    required bool compact,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    bool header = false,
    bool strong = false,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 3 : 4,
        vertical: compact ? 5 : 6.5,
      ),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          color: header ? PdfColors.white : GirviInvoicePdfService._ink,
          fontSize: header ? (compact ? 7.2 : 8) : (compact ? 7.4 : 8.4),
          fontWeight:
              header || strong ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
