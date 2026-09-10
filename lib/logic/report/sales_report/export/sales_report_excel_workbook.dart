part of 'sales_report_excel_builder.dart';

class _GstBreakup {
  final double cgst;
  final double sgst;
  final double igst;

  const _GstBreakup({
    required this.cgst,
    required this.sgst,
    required this.igst,
  });
}

class _HsnGstAccumulator {
  final String hsnCode;
  final double gstRate;
  final Set<int> invoiceIds = <int>{};
  int lineItemCount = 0;
  int pieces = 0;
  double taxableAmount = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double gstAmount = 0;
  double invoiceAmount = 0;

  _HsnGstAccumulator({
    required this.hsnCode,
    required this.gstRate,
  });

  _HsnGstRow toRow() {
    return _HsnGstRow(
      hsnCode: hsnCode,
      gstRate: gstRate,
      invoiceCount: invoiceIds.length,
      lineItemCount: lineItemCount,
      pieces: pieces,
      taxableAmount: taxableAmount,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      gstAmount: gstAmount,
      invoiceAmount: invoiceAmount,
    );
  }
}

class _HsnGstRow {
  final String hsnCode;
  final double gstRate;
  final int invoiceCount;
  final int lineItemCount;
  final int pieces;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double invoiceAmount;

  const _HsnGstRow({
    required this.hsnCode,
    required this.gstRate,
    required this.invoiceCount,
    required this.lineItemCount,
    required this.pieces,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.gstAmount,
    required this.invoiceAmount,
  });
}

class _CustomerSalesAccumulator {
  final String customerName;
  final String mobile;
  final Set<int> invoiceIds = <int>{};
  final Set<String> businessTypes = <String>{};
  final Set<String> gstins = <String>{};
  double grossAmount = 0;
  double discountAmount = 0;
  double taxableAmount = 0;
  double gstAmount = 0;
  double finalAmount = 0;
  double paidAmount = 0;
  double dueAmount = 0;
  double advanceAmount = 0;
  double tradeInDeduction = 0;

  _CustomerSalesAccumulator({
    required this.customerName,
    required this.mobile,
  });

  _CustomerSalesRow toRow() {
    final normalizedBusinessTypes = businessTypes
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final normalizedGstins = gstins
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    return _CustomerSalesRow(
      customerName: customerName,
      mobile: mobile,
      gstin: normalizedGstins.isEmpty
          ? ''
          : normalizedGstins.length == 1
              ? normalizedGstins.first
              : 'MULTIPLE',
      businessType: normalizedBusinessTypes.length == 1
          ? normalizedBusinessTypes.first
          : 'MIXED',
      invoiceCount: invoiceIds.length,
      grossAmount: grossAmount,
      discountAmount: discountAmount,
      taxableAmount: taxableAmount,
      gstAmount: gstAmount,
      finalAmount: finalAmount,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      advanceAmount: advanceAmount,
      tradeInDeduction: tradeInDeduction,
    );
  }
}

class _CustomerSalesRow {
  final String customerName;
  final String mobile;
  final String gstin;
  final String businessType;
  final int invoiceCount;
  final double grossAmount;
  final double discountAmount;
  final double taxableAmount;
  final double gstAmount;
  final double finalAmount;
  final double paidAmount;
  final double dueAmount;
  final double advanceAmount;
  final double tradeInDeduction;

  const _CustomerSalesRow({
    required this.customerName,
    required this.mobile,
    required this.gstin,
    required this.businessType,
    required this.invoiceCount,
    required this.grossAmount,
    required this.discountAmount,
    required this.taxableAmount,
    required this.gstAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.advanceAmount,
    required this.tradeInDeduction,
  });
}

class _MetalGradeAccumulator {
  final String metalType;
  final String purity;
  final Set<int> invoiceIds = <int>{};
  int lineItemCount = 0;
  int pieces = 0;
  double grossWeight = 0;
  double netWeight = 0;
  double itemAmount = 0;
  double makingAmount = 0;

  _MetalGradeAccumulator({
    required this.metalType,
    required this.purity,
  });

  _MetalGradeRow toRow() {
    return _MetalGradeRow(
      metalType: metalType,
      purity: purity,
      invoiceCount: invoiceIds.length,
      lineItemCount: lineItemCount,
      pieces: pieces,
      grossWeight: grossWeight,
      netWeight: netWeight,
      itemAmount: itemAmount,
      makingAmount: makingAmount,
    );
  }
}

class _MetalGradeRow {
  final String metalType;
  final String purity;
  final int invoiceCount;
  final int lineItemCount;
  final int pieces;
  final double grossWeight;
  final double netWeight;
  final double itemAmount;
  final double makingAmount;

  const _MetalGradeRow({
    required this.metalType,
    required this.purity,
    required this.invoiceCount,
    required this.lineItemCount,
    required this.pieces,
    required this.grossWeight,
    required this.netWeight,
    required this.itemAmount,
    required this.makingAmount,
  });
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
  moneyStrong,
  weight,
  integer,
  integerStrong,
  totalText,
  totalMoney,
  totalWeight,
}

class _ExcelCell {
  final Object? value;
  final _ExcelStyle style;
  final bool isNumber;
  final bool isFormula;

  const _ExcelCell._(
    this.value,
    this.style,
    this.isNumber, {
    this.isFormula = false,
  });

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

  factory _ExcelCell.formula(
    String formula, [
    _ExcelStyle style = _ExcelStyle.normal,
  ]) =>
      _ExcelCell._(formula, style, true, isFormula: true);

  factory _ExcelCell.empty() =>
      const _ExcelCell._('', _ExcelStyle.normal, false);
}

class _WorksheetBuilder {
  final List<double> columnWidths;
  final List<String> _rows = [];
  final List<String> _merges = [];
  String? _autoFilterRef;
  int _rowIndex = 0;

  _WorksheetBuilder({required this.columnWidths});

  int get columnCount => columnWidths.length;

  int get currentRow => _rowIndex;

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
    _merges.add('B$_rowIndex:${_columnName(columnCount)}$_rowIndex');
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

  void setAutoFilter(
    int startRow,
    int endRow,
    int startColumn,
    int endColumn,
  ) {
    if (endRow <= startRow) return;
    _autoFilterRef =
        '${_columnName(startColumn)}$startRow:${_columnName(endColumn)}$endRow';
  }

  String toXml() {
    final columns = [
      for (var index = 0; index < columnWidths.length; index++)
        '<col min="${index + 1}" max="${index + 1}" width="${columnWidths[index]}" customWidth="1"/>',
    ].join();
    final mergeXml = _merges.isEmpty
        ? ''
        : '<mergeCells count="${_merges.length}">${_merges.map((ref) => '<mergeCell ref="$ref"/>').join()}</mergeCells>';
    final dimension = 'A1:${_columnName(columnCount)}$_rowIndex';
    final autoFilterXml =
        _autoFilterRef == null ? '' : '<autoFilter ref="$_autoFilterRef"/>';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<dimension ref="$dimension"/>
<sheetViews><sheetView workbookViewId="0"><pane ySplit="10" topLeftCell="A11" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
<cols>$columns</cols>
<sheetData>${_rows.join()}</sheetData>
$autoFilterXml
$mergeXml
<pageMargins left="0.3" right="0.3" top="0.5" bottom="0.5" header="0.2" footer="0.2"/>
</worksheet>''';
  }

  String _cell(int column, int row, _ExcelCell cell) {
    final ref = '${_columnName(column)}$row';
    final styleId = _styleId(cell.style);
    if (cell.isFormula) {
      final formula = _escape(cell.value?.toString() ?? '0');
      return '<c r="$ref" s="$styleId"><f>$formula</f><v>0</v></c>';
    }
    if (cell.isNumber) {
      return '<c r="$ref" s="$styleId"><v>${_numberValue(cell.value, cell.style)}</v></c>';
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
      case _ExcelStyle.moneyStrong:
        return 12;
      case _ExcelStyle.weight:
        return 9;
      case _ExcelStyle.integer:
        return 10;
      case _ExcelStyle.integerStrong:
        return 11;
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

String _numberValue(Object? value, _ExcelStyle style) {
  final number = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (number == null) return '0';
  switch (style) {
    case _ExcelStyle.weight:
    case _ExcelStyle.totalWeight:
      return number.toStringAsFixed(3);
    case _ExcelStyle.money:
    case _ExcelStyle.moneyStrong:
    case _ExcelStyle.totalMoney:
      return number.toStringAsFixed(2);
    case _ExcelStyle.integer:
    case _ExcelStyle.integerStrong:
      return number.round().toString();
    case _ExcelStyle.normal:
    case _ExcelStyle.title:
    case _ExcelStyle.subtitle:
    case _ExcelStyle.muted:
    case _ExcelStyle.sectionLabel:
    case _ExcelStyle.sectionValue:
    case _ExcelStyle.tableHeader:
    case _ExcelStyle.strong:
    case _ExcelStyle.totalText:
      return number.toString();
  }
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _contentTypesXml(int sheetCount) {
  final sheetOverrides = [
    for (var index = 1; index <= sheetCount; index++)
      '<Override PartName="/xl/worksheets/sheet$index.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
  ].join();
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
$sheetOverrides
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';
}

const _rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

String _workbookRelsXml(int sheetCount) {
  final sheetRelationships = [
    for (var index = 1; index <= sheetCount; index++)
      '<Relationship Id="rId$index" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet$index.xml"/>',
  ].join();
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
$sheetRelationships
<Relationship Id="rId${sheetCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
}

String _workbookXml(List<String> sheetNames) {
  final sheets = [
    for (var index = 0; index < sheetNames.length; index++)
      '<sheet name="${_escape(sheetNames[index])}" sheetId="${index + 1}" r:id="rId${index + 1}"/>',
  ].join();
  return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>$sheets</sheets>
</workbook>''';
}

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
<font><sz val="11"/><color rgb="FF000000"/><name val="Calibri"/></font>
<font><b/><sz val="18"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
<font><b/><sz val="14"/><color rgb="FF000000"/><name val="Calibri"/></font>
<font><sz val="11"/><color rgb="FF000000"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><color rgb="FF000000"/><name val="Calibri"/></font>
</fonts>
<fills count="5">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF111827"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFF8E7B1"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFFFFF"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="2">
<border><left/><right/><top/><bottom/><diagonal/></border>
<border><left style="thin"><color rgb="FF000000"/></left><right style="thin"><color rgb="FF000000"/></right><top style="thin"><color rgb="FF000000"/></top><bottom style="thin"><color rgb="FF000000"/></bottom><diagonal/></border>
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
