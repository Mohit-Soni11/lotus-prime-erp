import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../../models/reports/sales_report/sales_report_models.dart';
import 'sales_report_export_formatters.dart';

class SalesReportExcelBuilder {
  SalesReportExcelBuilder._();

  static Uint8List buildComplete(
    SalesReportSnapshot snapshot, {
    required SalesReportExportIdentity identity,
    String reportTitle = 'Sales Report',
  }) {
    final sheet = _WorksheetBuilder(
      columnWidths: const [7, 24, 19, 28, 15, 18, 18, 15, 15, 15, 16, 16],
    );
    _addReportHeader(sheet, snapshot, identity, reportTitle);
    _addSalesSummary(sheet, snapshot);
    _addGstSummary(sheet, snapshot);
    _addMetalSummary(sheet, snapshot);
    _addInvoiceLedger(sheet, snapshot);
    _addItemLedger(sheet, snapshot.items);
    return _buildWorkbook(sheet.toXml());
  }

  static void _addReportHeader(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
    SalesReportExportIdentity identity,
    String reportTitle,
  ) {
    final shopName = identity.shopName.trim().isEmpty
        ? 'Sales Report'
        : identity.shopName.trim();
    sheet.addMergedText(shopName.toUpperCase(), 1, 12, _ExcelStyle.title);
    sheet.addMergedText(reportTitle, 1, 12, _ExcelStyle.subtitle);
    for (final line in identity.headerLines.take(3)) {
      sheet.addMergedText(line, 1, 12, _ExcelStyle.muted);
    }
    sheet.addBlankRow();
    sheet.addRow([
      _ExcelCell.text('Period', _ExcelStyle.sectionLabel),
      _ExcelCell.text(
        SalesReportExportFormatters.periodLabel(snapshot.filter),
        _ExcelStyle.sectionValue,
      ),
      _ExcelCell.text('Tax View', _ExcelStyle.sectionLabel),
      _ExcelCell.text(
        SalesReportExportFormatters.taxModeLabel(snapshot.filter.taxMode),
        _ExcelStyle.sectionValue,
      ),
      _ExcelCell.text('Metal View', _ExcelStyle.sectionLabel),
      _ExcelCell.text(snapshot.filter.metalType, _ExcelStyle.sectionValue),
    ]);
    sheet.addBlankRow();
  }

  static void _addSalesSummary(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    sheet.addSection('Sales Summary', 'Invoice value, tax and weight totals');
    sheet.addRow([
      _ExcelCell.text('Metric', _ExcelStyle.tableHeader),
      _ExcelCell.text('Value', _ExcelStyle.tableHeader),
    ]);
    for (final row
        in SalesReportExportFormatters.salesSummaryRows(snapshot.summary)) {
      sheet.addRow([
        _ExcelCell.text(row[0]),
        _ExcelCell.text(row[1], _ExcelStyle.strong),
      ]);
    }
    sheet.addBlankRow();
  }

  static void _addGstSummary(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    sheet.addSection('GST Summary', 'Recorded GST and non-GST exposure');
    sheet.addRow([
      _ExcelCell.text('Metric', _ExcelStyle.tableHeader),
      _ExcelCell.text('Value', _ExcelStyle.tableHeader),
    ]);
    for (final row in SalesReportExportFormatters.gstLiabilityRows(
      snapshot.gstLiability,
    )) {
      sheet.addRow([
        _ExcelCell.text(row[0]),
        _ExcelCell.text(row[1], _ExcelStyle.strong),
      ]);
    }
    sheet.addBlankRow();
  }

  static void _addMetalSummary(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    if (snapshot.metals.isEmpty) return;
    sheet.addSection('Metal Summary', 'Metal-wise sold quantity and value');
    sheet.addRow([
      _ExcelCell.text('Metal', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoices', _ExcelStyle.tableHeader),
      _ExcelCell.text('Items', _ExcelStyle.tableHeader),
      _ExcelCell.text('Pcs', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Net Wt (g)', _ExcelStyle.tableHeader),
      _ExcelCell.text('Making', _ExcelStyle.tableHeader),
      _ExcelCell.text('Sales', _ExcelStyle.tableHeader),
    ]);
    for (final metal in snapshot.metals) {
      sheet.addRow([
        _ExcelCell.text(metal.metalType),
        _ExcelCell.number(metal.invoiceCount, _ExcelStyle.integer),
        _ExcelCell.number(metal.itemCount, _ExcelStyle.integer),
        _ExcelCell.number(metal.pieces, _ExcelStyle.integer),
        _ExcelCell.number(metal.grossWeight, _ExcelStyle.weight),
        _ExcelCell.number(metal.netWeight, _ExcelStyle.weight),
        _ExcelCell.number(metal.makingAmount, _ExcelStyle.money),
        _ExcelCell.number(metal.salesAmount, _ExcelStyle.money),
      ]);
    }
    sheet.addBlankRow();
  }

  static void _addInvoiceLedger(
    _WorksheetBuilder sheet,
    SalesReportSnapshot snapshot,
  ) {
    final weightsByBill =
        SalesReportExportFormatters.invoiceWeights(snapshot.items);
    sheet.addSection('Invoice Ledger', 'Bill-wise sales amount and GST audit');
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Date', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Type', _ExcelStyle.tableHeader),
      _ExcelCell.text('Metal', _ExcelStyle.tableHeader),
      _ExcelCell.text('Net Wt', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross', _ExcelStyle.tableHeader),
      _ExcelCell.text('Discount', _ExcelStyle.tableHeader),
      _ExcelCell.text('Taxable', _ExcelStyle.tableHeader),
      _ExcelCell.text('GST', _ExcelStyle.tableHeader),
      _ExcelCell.text('Final', _ExcelStyle.tableHeader),
    ]);
    for (var index = 0; index < snapshot.invoices.length; index++) {
      final invoice = snapshot.invoices[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(invoice.billNo, _ExcelStyle.strong),
        _ExcelCell.text(SalesReportExportFormatters.dateTime(invoice.billDate)),
        _ExcelCell.text(invoice.customerName),
        _ExcelCell.text(invoice.isGst ? 'GST' : 'NON-GST'),
        _ExcelCell.text(invoice.metalMix),
        _ExcelCell.text(
          SalesReportExportFormatters.weightSummary(
            weightsByBill[invoice.billId] ?? const {},
          ),
        ),
        _ExcelCell.number(invoice.grossAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.discountAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.taxableAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.gstAmount, _ExcelStyle.money),
        _ExcelCell.number(invoice.finalAmount, _ExcelStyle.totalMoney),
      ]);
    }
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.text(
        SalesReportExportFormatters.invoiceWeightTotal(snapshot.items),
        _ExcelStyle.totalText,
      ),
      _ExcelCell.number(
        snapshot.invoices.fold(0, (sum, row) => sum + row.grossAmount),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.number(
        snapshot.invoices.fold(0, (sum, row) => sum + row.discountAmount),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.number(
        snapshot.invoices.fold(0, (sum, row) => sum + row.taxableAmount),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.number(
        snapshot.invoices.fold(0, (sum, row) => sum + row.gstAmount),
        _ExcelStyle.totalMoney,
      ),
      _ExcelCell.number(
        snapshot.invoices.fold(0, (sum, row) => sum + row.finalAmount),
        _ExcelStyle.totalMoney,
      ),
    ]);
    sheet.addBlankRow();
  }

  static void _addItemLedger(
    _WorksheetBuilder sheet,
    List<SalesReportItemRow> items,
  ) {
    sheet.addSection('Item Ledger', 'HUID, purity, quantity and item value');
    sheet.addRow([
      _ExcelCell.text('S.No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Invoice No', _ExcelStyle.tableHeader),
      _ExcelCell.text('Customer', _ExcelStyle.tableHeader),
      _ExcelCell.text('Metal', _ExcelStyle.tableHeader),
      _ExcelCell.text('Item', _ExcelStyle.tableHeader),
      _ExcelCell.text('HUID', _ExcelStyle.tableHeader),
      _ExcelCell.text('Purity', _ExcelStyle.tableHeader),
      _ExcelCell.text('Pcs', _ExcelStyle.tableHeader),
      _ExcelCell.text('Gross Wt', _ExcelStyle.tableHeader),
      _ExcelCell.text('Less Wt', _ExcelStyle.tableHeader),
      _ExcelCell.text('Net Wt', _ExcelStyle.tableHeader),
      _ExcelCell.text('Total', _ExcelStyle.tableHeader),
    ]);
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      sheet.addRow([
        _ExcelCell.number(index + 1, _ExcelStyle.integer),
        _ExcelCell.text(item.billNo, _ExcelStyle.strong),
        _ExcelCell.text(item.customerName),
        _ExcelCell.text(item.metalType),
        _ExcelCell.text(item.itemName),
        _ExcelCell.text(item.huid.isEmpty ? 'Not linked' : item.huid),
        _ExcelCell.text(item.purity),
        _ExcelCell.number(item.quantity, _ExcelStyle.integer),
        _ExcelCell.number(item.grossWeight, _ExcelStyle.weight),
        _ExcelCell.number(item.lessWeight, _ExcelStyle.weight),
        _ExcelCell.number(item.netWeight, _ExcelStyle.weight),
        _ExcelCell.number(item.itemTotal, _ExcelStyle.totalMoney),
      ]);
    }
    sheet.addRow([
      _ExcelCell.text('TOTAL', _ExcelStyle.totalText),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.empty(),
      _ExcelCell.number(
        items.fold(0, (sum, item) => sum + item.quantity),
        _ExcelStyle.integer,
      ),
      _ExcelCell.number(
        items.fold(0, (sum, item) => sum + item.grossWeight),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.number(
        items.fold(0, (sum, item) => sum + item.lessWeight),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.number(
        items.fold(0, (sum, item) => sum + item.netWeight),
        _ExcelStyle.totalWeight,
      ),
      _ExcelCell.number(
        items.fold(0, (sum, item) => sum + item.itemTotal),
        _ExcelStyle.totalMoney,
      ),
    ]);
  }

  static Uint8List _buildWorkbook(String worksheetXml) {
    final archive = Archive()
      ..addFile(_archiveFile('[Content_Types].xml', _contentTypesXml))
      ..addFile(_archiveFile('_rels/.rels', _rootRelsXml))
      ..addFile(_archiveFile('docProps/app.xml', _appXml))
      ..addFile(_archiveFile('docProps/core.xml', _coreXml))
      ..addFile(_archiveFile('xl/workbook.xml', _workbookXml))
      ..addFile(_archiveFile('xl/_rels/workbook.xml.rels', _workbookRelsXml))
      ..addFile(_archiveFile('xl/styles.xml', _stylesXml))
      ..addFile(_archiveFile('xl/worksheets/sheet1.xml', worksheetXml));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static ArchiveFile _archiveFile(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }
}

enum _ExcelStyle {
  normal,
  title,
  subtitle,
  muted,
  sectionLabel,
  sectionValue,
  tableHeader,
  strong,
  money,
  weight,
  integer,
  totalText,
  totalMoney,
  totalWeight,
}

class _ExcelCell {
  final Object? value;
  final _ExcelStyle style;
  final bool isNumber;

  const _ExcelCell._(this.value, this.style, this.isNumber);

  factory _ExcelCell.text(
    String value, [
    _ExcelStyle style = _ExcelStyle.normal,
  ]) =>
      _ExcelCell._(value, style, false);

  factory _ExcelCell.number(
    num value, [
    _ExcelStyle style = _ExcelStyle.normal,
  ]) =>
      _ExcelCell._(value, style, true);

  factory _ExcelCell.empty() =>
      const _ExcelCell._('', _ExcelStyle.normal, false);
}

class _WorksheetBuilder {
  final List<double> columnWidths;
  final List<String> _rows = [];
  final List<String> _merges = [];
  int _rowIndex = 0;

  _WorksheetBuilder({required this.columnWidths});

  void addMergedText(
    String value,
    int startColumn,
    int endColumn,
    _ExcelStyle style,
  ) {
    _rowIndex++;
    _rows.add(
      '<row r="$_rowIndex">${_cell(startColumn, _rowIndex, _ExcelCell.text(value, style))}</row>',
    );
    _merges.add(
      '${_columnName(startColumn)}$_rowIndex:${_columnName(endColumn)}$_rowIndex',
    );
  }

  void addSection(String title, String subtitle) {
    _rowIndex++;
    _rows.add(
      '<row r="$_rowIndex">${_cell(1, _rowIndex, _ExcelCell.text(title, _ExcelStyle.sectionLabel))}${_cell(2, _rowIndex, _ExcelCell.text(subtitle, _ExcelStyle.sectionValue))}</row>',
    );
    _merges.add('B$_rowIndex:L$_rowIndex');
  }

  void addRow(List<_ExcelCell> cells) {
    _rowIndex++;
    final buffer = StringBuffer('<row r="$_rowIndex">');
    for (var index = 0; index < cells.length; index++) {
      buffer.write(_cell(index + 1, _rowIndex, cells[index]));
    }
    buffer.write('</row>');
    _rows.add(buffer.toString());
  }

  void addBlankRow() {
    _rowIndex++;
    _rows.add('<row r="$_rowIndex"/>');
  }

  String toXml() {
    final columns = [
      for (var index = 0; index < columnWidths.length; index++)
        '<col min="${index + 1}" max="${index + 1}" width="${columnWidths[index]}" customWidth="1"/>',
    ].join();
    final mergeXml = _merges.isEmpty
        ? ''
        : '<mergeCells count="${_merges.length}">${_merges.map((ref) => '<mergeCell ref="$ref"/>').join()}</mergeCells>';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetViews><sheetView workbookViewId="0"><pane ySplit="7" topLeftCell="A8" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
<cols>$columns</cols>
<sheetData>${_rows.join()}</sheetData>
$mergeXml
<pageMargins left="0.3" right="0.3" top="0.5" bottom="0.5" header="0.2" footer="0.2"/>
</worksheet>''';
  }

  String _cell(int column, int row, _ExcelCell cell) {
    final ref = '${_columnName(column)}$row';
    final styleId = _styleId(cell.style);
    if (cell.isNumber) {
      return '<c r="$ref" s="$styleId"><v>${cell.value}</v></c>';
    }
    final text = _escape(cell.value?.toString() ?? '');
    return '<c r="$ref" s="$styleId" t="inlineStr"><is><t>$text</t></is></c>';
  }

  int _styleId(_ExcelStyle style) {
    switch (style) {
      case _ExcelStyle.normal:
        return 0;
      case _ExcelStyle.title:
        return 1;
      case _ExcelStyle.subtitle:
        return 2;
      case _ExcelStyle.muted:
        return 3;
      case _ExcelStyle.sectionLabel:
        return 4;
      case _ExcelStyle.sectionValue:
        return 5;
      case _ExcelStyle.tableHeader:
        return 6;
      case _ExcelStyle.strong:
        return 7;
      case _ExcelStyle.money:
        return 8;
      case _ExcelStyle.weight:
        return 9;
      case _ExcelStyle.integer:
        return 10;
      case _ExcelStyle.totalText:
        return 11;
      case _ExcelStyle.totalMoney:
        return 12;
      case _ExcelStyle.totalWeight:
        return 13;
    }
  }
}

String _columnName(int index) {
  var value = index;
  final chars = <String>[];
  while (value > 0) {
    value--;
    chars.insert(0, String.fromCharCode(65 + (value % 26)));
    value ~/= 26;
  }
  return chars.join();
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

const _contentTypesXml =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';

const _rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

const _workbookRelsXml =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

const _workbookXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="Sales Report" sheetId="1" r:id="rId1"/></sheets>
</workbook>''';

const _appXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
<Application>Lotus ERP</Application>
</Properties>''';

const _coreXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:title>Sales Report</dc:title>
<dc:creator>Lotus ERP</dc:creator>
</cp:coreProperties>''';

const _stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<numFmts count="2">
<numFmt numFmtId="164" formatCode="&quot;Rs&quot; #,##0.00"/>
<numFmt numFmtId="165" formatCode="0.000"/>
</numFmts>
<fonts count="5">
<font><sz val="10"/><color rgb="FF111827"/><name val="Calibri"/></font>
<font><b/><sz val="18"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
<font><b/><sz val="14"/><color rgb="FF111827"/><name val="Calibri"/></font>
<font><sz val="10"/><color rgb="FF64748B"/><name val="Calibri"/></font>
<font><b/><sz val="10"/><color rgb="FF111827"/><name val="Calibri"/></font>
</fonts>
<fills count="5">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF1F2937"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFF8E7B1"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFDF8EA"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="2">
<border><left/><right/><top/><bottom/><diagonal/></border>
<border><left style="thin"><color rgb="FFE5E7EB"/></left><right style="thin"><color rgb="FFE5E7EB"/></right><top style="thin"><color rgb="FFE5E7EB"/></top><bottom style="thin"><color rgb="FFE5E7EB"/></bottom><diagonal/></border>
</borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="14">
<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1"/>
<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="2" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="0" fontId="4" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="0" fillId="4" borderId="1" xfId="0" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="4" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="4" fillId="0" borderId="1" xfId="0" applyFont="1" applyBorder="1"/>
<xf numFmtId="164" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/>
<xf numFmtId="165" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/>
<xf numFmtId="3" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/>
<xf numFmtId="0" fontId="4" fillId="4" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="164" fontId="4" fillId="4" borderId="1" xfId="0" applyFont="1" applyNumberFormat="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="165" fontId="4" fillId="4" borderId="1" xfId="0" applyFont="1" applyNumberFormat="1" applyFill="1" applyBorder="1"/>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';
