import 'package:drift/drift.dart';

import '../../core/logging/app_logger.dart';
import '../../database/db/app_database.dart';
import '../../logic/report/sales_report/sales_report_invoice_scope.dart';
import '../../models/reports/sales_report/sales_report_models.dart';

class SalesReportRepository {
  SalesReportRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  Future<SalesReportSnapshot> fetchReport(SalesReportFilter filter) async {
    try {
      final normalized = _normalizeFilter(filter);
      final sourceInvoices = await _fetchInvoices(normalized);
      final items = await _fetchItems(normalized);
      final invoices = _requiresItemScopedInvoices(normalized)
          ? scopeSalesReportInvoicesToItems(
              invoices: sourceInvoices,
              items: items,
            )
          : sourceInvoices;
      final gstLiability = await _fetchGstLiability(normalized);
      final metals = _buildMetalSummaries(items);
      final summary = _buildSummary(invoices, items);
      final availableMetals = await _fetchAvailableMetals();

      return SalesReportSnapshot(
        filter: normalized,
        summary: summary,
        gstLiability: gstLiability,
        metals: metals,
        invoices: invoices,
        items: items,
        availableMetals: availableMetals,
      );
    } catch (error, stackTrace) {
      AppLogger.error('SalesReportRepository.fetchReport failed: $error');
      AppLogger.debug(stackTrace.toString());
      rethrow;
    }
  }

  SalesReportFilter _normalizeFilter(SalesReportFilter filter) {
    final start = DateTime(
      filter.startDate.year,
      filter.startDate.month,
      filter.startDate.day,
    );
    final end = DateTime(
      filter.endDate.year,
      filter.endDate.month,
      filter.endDate.day,
      23,
      59,
      59,
    );
    return filter.copyWith(startDate: start, endDate: end);
  }

  bool _requiresItemScopedInvoices(SalesReportFilter filter) {
    final metal = filter.metalType.trim().toUpperCase();
    return metal.isNotEmpty && metal != 'ALL';
  }

  Future<SalesReportGstLiabilitySummary> _fetchGstLiability(
    SalesReportFilter filter,
  ) async {
    final monthlyFilter = filter.copyWith(
      taxMode: SalesReportTaxMode.all,
      paymentFilter: SalesReportPaymentFilter.all,
      metalType: 'ALL',
      query: '',
    );
    final invoices = await _fetchInvoices(monthlyFilter);
    return _buildGstLiabilitySummary(invoices);
  }

  Future<List<SalesReportInvoiceRow>> _fetchInvoices(
    SalesReportFilter filter,
  ) async {
    final where = _buildBillWhere(filter);
    final rows = await _db.customSelect(
      '''
      SELECT
        b.id,
        b.bill_no,
        b.bill_date,
        COALESCE(NULLIF(TRIM(b.customer_name), ''), 'Walk-in Customer')
          AS customer_name,
        COALESCE(b.mobile, '') AS mobile,
        COALESCE(b.bill_type, '') AS bill_type,
        COALESCE(b.payment_status, '') AS payment_status,
        COALESCE(b.total_amount, 0.0) AS total_amount,
        COALESCE(b.discount, 0.0) AS discount_amount,
        COALESCE(b.taxable_amount, 0.0) AS taxable_amount,
        COALESCE(b.gst_amount, 0.0) AS gst_amount,
        COALESCE(b.round_off_amount, 0.0) AS round_off_amount,
        COALESCE(b.final_amount, 0.0) AS final_amount,
        COALESCE(b.paid_amount, 0.0) AS paid_amount,
        COALESCE(b.due_amount, 0.0) AS due_amount,
        COALESCE(b.cash_paid, 0.0) AS cash_paid,
        COALESCE(b.upi_paid, 0.0) AS upi_paid,
        COALESCE(b.card_paid, 0.0) AS card_paid,
        COALESCE(b.advance_paid, 0.0) AS advance_paid,
        COALESCE(b.making_total, 0.0) AS making_total,
        COALESCE(b.old_gold_deduction, 0.0) AS trade_in_deduction,
        (
          SELECT COUNT(*)
          FROM bill_items i
          WHERE i.bill_id = b.id
        ) AS item_count,
        (
          SELECT GROUP_CONCAT(DISTINCT UPPER(COALESCE(i.metal_type, '')))
          FROM bill_items i
          WHERE i.bill_id = b.id
        ) AS metal_mix
      FROM bills b
      ${where.sql}
      ORDER BY b.bill_date DESC, b.id DESC
      ''',
      variables: where.variables,
    ).get();

    return rows.map((row) {
      final billNo = row.read<String>('bill_no');
      final gstAmount = _readDouble(row, 'gst_amount');
      return SalesReportInvoiceRow(
        billId: row.read<int>('id'),
        billNo: billNo,
        billDate: row.read<DateTime>('bill_date'),
        customerName: row.read<String>('customer_name'),
        mobile: row.read<String>('mobile'),
        billType: row.read<String>('bill_type'),
        paymentStatus: row.read<String>('payment_status'),
        isGst: _isGstBill(billNo, gstAmount, row.read<String>('bill_type')),
        grossAmount: _readDouble(row, 'total_amount'),
        discountAmount: _readDouble(row, 'discount_amount'),
        taxableAmount: _readDouble(row, 'taxable_amount'),
        gstAmount: gstAmount,
        roundOffAmount: _readDouble(row, 'round_off_amount'),
        finalAmount: _readDouble(row, 'final_amount'),
        paidAmount: _readDouble(row, 'paid_amount'),
        dueAmount: _readDouble(row, 'due_amount'),
        cashAmount: _readDouble(row, 'cash_paid'),
        upiAmount: _readDouble(row, 'upi_paid'),
        cardAmount: _readDouble(row, 'card_paid'),
        advanceAmount: _readDouble(row, 'advance_paid'),
        makingAmount: _readDouble(row, 'making_total'),
        tradeInDeduction: _readDouble(row, 'trade_in_deduction'),
        itemCount: row.read<int>('item_count'),
        metalMix: row.readNullable<String>('metal_mix') ?? '',
      );
    }).toList(growable: false);
  }

  Future<List<SalesReportItemRow>> _fetchItems(SalesReportFilter filter) async {
    final where = _buildBillWhere(filter, itemAlias: 'i');
    final rows = await _db.customSelect(
      '''
      SELECT
        b.id AS bill_id,
        b.bill_no,
        b.bill_date,
        COALESCE(NULLIF(TRIM(b.customer_name), ''), 'Walk-in Customer')
          AS customer_name,
        COALESCE(b.bill_type, '') AS bill_type,
        COALESCE(b.gst_amount, 0.0) AS gst_amount,
        i.line_no,
        COALESCE(i.metal_type, '') AS metal_type,
        COALESCE(i.item_name, '') AS item_name,
        COALESCE(i.huid, '') AS huid,
        COALESCE(i.purity, '') AS purity,
        COALESCE(i.quantity, 0) AS quantity,
        COALESCE(i.gross_weight, 0.0) AS gross_weight,
        COALESCE(i.less_weight, 0.0) AS less_weight,
        COALESCE(i.net_weight, 0.0) AS net_weight,
        COALESCE(i.fine_weight, 0.0) AS fine_weight,
        COALESCE(i.rate, 0.0) AS rate,
        COALESCE(i.making_charge_type, '') AS making_charge_type,
        COALESCE(i.making_charge, 0.0) AS making_charge,
        COALESCE(i.item_total, 0.0) AS item_total,
        COALESCE(i.linked_stock_sku, '') AS stock_sku,
        COALESCE(i.stock_unit_cost, 0.0) AS stock_cost,
        COALESCE(i.stock_profit_amount, 0.0) AS stock_profit
      FROM bill_items i
      INNER JOIN bills b ON b.id = i.bill_id
      ${where.sql}
      ORDER BY b.bill_date DESC, b.id DESC, i.line_no ASC
      ''',
      variables: where.variables,
    ).get();

    return rows.map((row) {
      final billNo = row.read<String>('bill_no');
      final gstAmount = _readDouble(row, 'gst_amount');
      return SalesReportItemRow(
        billId: row.read<int>('bill_id'),
        billNo: billNo,
        billDate: row.read<DateTime>('bill_date'),
        customerName: row.read<String>('customer_name'),
        isGst: _isGstBill(billNo, gstAmount, row.read<String>('bill_type')),
        lineNo: row.read<int>('line_no'),
        metalType: _displayMetal(row.read<String>('metal_type')),
        itemName: row.read<String>('item_name'),
        huid: row.read<String>('huid'),
        purity: row.read<String>('purity'),
        quantity: row.read<int>('quantity'),
        grossWeight: _readDouble(row, 'gross_weight'),
        lessWeight: _readDouble(row, 'less_weight'),
        netWeight: _readDouble(row, 'net_weight'),
        fineWeight: _readDouble(row, 'fine_weight'),
        rate: _readDouble(row, 'rate'),
        makingChargeType: row.read<String>('making_charge_type'),
        makingCharge: _readDouble(row, 'making_charge'),
        itemTotal: _readDouble(row, 'item_total'),
        stockSku: row.read<String>('stock_sku'),
        stockCostAmount: _readDouble(row, 'stock_cost'),
        profitAmount: _readDouble(row, 'stock_profit'),
      );
    }).toList(growable: false);
  }

  Future<List<String>> _fetchAvailableMetals() async {
    final rows = await _db.customSelect(
      '''
      SELECT DISTINCT UPPER(TRIM(COALESCE(metal_type, ''))) AS metal
      FROM bill_items
      WHERE TRIM(COALESCE(metal_type, '')) <> ''
      ORDER BY metal ASC
      ''',
    ).get();

    final metals = rows
        .map((row) => _displayMetal(row.read<String>('metal')))
        .where((metal) => metal.isNotEmpty)
        .toList();
    return ['ALL', ...metals];
  }

  _SalesReportWhere _buildBillWhere(
    SalesReportFilter filter, {
    String? itemAlias,
  }) {
    final clauses = <String>[
      "b.status = 'ACTIVE'",
      'b.bill_date >= ?',
      'b.bill_date <= ?',
    ];
    final variables = <Variable<Object>>[
      Variable<DateTime>(filter.startDate),
      Variable<DateTime>(filter.endDate),
    ];

    switch (filter.taxMode) {
      case SalesReportTaxMode.gst:
        clauses.add(_gstPredicate());
        break;
      case SalesReportTaxMode.nonGst:
        clauses.add('NOT (${_gstPredicate()})');
        break;
      case SalesReportTaxMode.all:
        break;
    }

    switch (filter.paymentFilter) {
      case SalesReportPaymentFilter.paid:
        clauses.add('COALESCE(b.due_amount, 0.0) <= 0.005');
        break;
      case SalesReportPaymentFilter.due:
        clauses.add('COALESCE(b.due_amount, 0.0) > 0.005');
        break;
      case SalesReportPaymentFilter.partial:
        clauses.add('''
          COALESCE(b.due_amount, 0.0) > 0.005
          AND COALESCE(b.paid_amount, 0.0) > 0.005
        ''');
        break;
      case SalesReportPaymentFilter.all:
        break;
    }

    final metal = filter.metalType.trim().toUpperCase();
    if (metal.isNotEmpty && metal != 'ALL') {
      if (itemAlias == null) {
        clauses.add('''
          EXISTS (
            SELECT 1
            FROM bill_items mi
            WHERE mi.bill_id = b.id
              AND UPPER(TRIM(COALESCE(mi.metal_type, ''))) = ?
          )
        ''');
      } else {
        clauses.add("UPPER(TRIM(COALESCE($itemAlias.metal_type, ''))) = ?");
      }
      variables.add(Variable<String>(metal));
    }

    final query = filter.query.trim().toLowerCase();
    if (query.isNotEmpty) {
      final like = '%$query%';
      clauses.add('''
        (
          LOWER(b.bill_no) LIKE ?
          OR LOWER(COALESCE(b.customer_name, '')) LIKE ?
          OR LOWER(COALESCE(b.mobile, '')) LIKE ?
          OR EXISTS (
            SELECT 1
            FROM bill_items qi
            WHERE qi.bill_id = b.id
              AND (
                LOWER(COALESCE(qi.item_name, '')) LIKE ?
                OR LOWER(COALESCE(qi.huid, '')) LIKE ?
                OR LOWER(COALESCE(qi.linked_stock_sku, '')) LIKE ?
              )
          )
        )
      ''');
      variables.addAll([
        Variable<String>(like),
        Variable<String>(like),
        Variable<String>(like),
        Variable<String>(like),
        Variable<String>(like),
        Variable<String>(like),
      ]);
    }

    return _SalesReportWhere(
      sql: 'WHERE ${clauses.join('\nAND ')}',
      variables: variables,
    );
  }

  String _gstPredicate() {
    return '''
      (
        b.bill_no LIKE 'TAX-%'
        OR COALESCE(b.gst_amount, 0.0) > 0.005
        OR UPPER(COALESCE(b.bill_type, '')) IN ('GST', 'TAX', 'TAX_INVOICE')
      )
    ''';
  }

  SalesReportSummary _buildSummary(
    List<SalesReportInvoiceRow> invoices,
    List<SalesReportItemRow> items,
  ) {
    var gstCount = 0;
    var nonGstCount = 0;
    double gross = 0;
    double discount = 0;
    double taxable = 0;
    double gst = 0;
    double roundOff = 0;
    double finalAmount = 0;
    double paid = 0;
    double due = 0;
    double cash = 0;
    double upi = 0;
    double card = 0;
    double advance = 0;
    double making = 0;

    for (final invoice in invoices) {
      if (invoice.isGst) {
        gstCount++;
      } else {
        nonGstCount++;
      }
      gross += invoice.grossAmount;
      discount += invoice.discountAmount;
      taxable += invoice.taxableAmount;
      gst += invoice.gstAmount;
      roundOff += invoice.roundOffAmount;
      finalAmount += invoice.finalAmount;
      paid += invoice.paidAmount;
      due += invoice.dueAmount;
      cash += invoice.cashAmount;
      upi += invoice.upiAmount;
      card += invoice.cardAmount;
      advance += invoice.advanceAmount;
      making += invoice.makingAmount;
    }

    double cost = 0;
    double profit = 0;
    double netWeight = 0;
    for (final item in items) {
      cost += item.stockCostAmount;
      profit += item.profitAmount;
      netWeight += item.netWeight;
    }

    return SalesReportSummary(
      invoiceCount: invoices.length,
      gstInvoiceCount: gstCount,
      nonGstInvoiceCount: nonGstCount,
      grossAmount: gross,
      discountAmount: discount,
      taxableAmount: taxable,
      gstAmount: gst,
      roundOffAmount: roundOff,
      finalAmount: finalAmount,
      paidAmount: paid,
      dueAmount: due,
      cashAmount: cash,
      upiAmount: upi,
      cardAmount: card,
      advanceAmount: advance,
      makingAmount: making,
      stockCostAmount: cost,
      profitAmount: profit,
      netWeight: netWeight,
    );
  }

  SalesReportGstLiabilitySummary _buildGstLiabilitySummary(
    List<SalesReportInvoiceRow> invoices,
  ) {
    var gstCount = 0;
    var nonGstCount = 0;
    double gstTaxable = 0;
    double gstFinal = 0;
    double recordedGst = 0;
    double nonGstSales = 0;

    for (final invoice in invoices) {
      if (invoice.isGst) {
        gstCount++;
        gstTaxable += _taxableBaseFor(invoice);
        gstFinal += invoice.finalAmount;
        recordedGst += invoice.gstAmount;
      } else {
        nonGstCount++;
        nonGstSales += _taxableBaseFor(invoice);
      }
    }

    return SalesReportGstLiabilitySummary(
      invoiceCount: invoices.length,
      gstInvoiceCount: gstCount,
      nonGstInvoiceCount: nonGstCount,
      gstTaxableAmount: gstTaxable,
      gstFinalAmount: gstFinal,
      recordedGstAmount: recordedGst,
      nonGstSalesAmount: nonGstSales,
      projectedGstAmount: nonGstSales * 0.03,
    );
  }

  double _taxableBaseFor(SalesReportInvoiceRow invoice) {
    if (invoice.taxableAmount > 0.005) return invoice.taxableAmount;
    final discountedGross = invoice.grossAmount - invoice.discountAmount;
    if (discountedGross > 0.005) return discountedGross;
    if (invoice.gstAmount <= 0.005) return invoice.finalAmount;
    return invoice.grossAmount;
  }

  List<SalesReportMetalSummary> _buildMetalSummaries(
    List<SalesReportItemRow> items,
  ) {
    final invoiceSets = <String, Set<int>>{};
    final totals = <String, _MetalAccumulator>{};

    for (final item in items) {
      final metal = _displayMetal(item.metalType);
      if (metal.isEmpty) continue;
      invoiceSets.putIfAbsent(metal, () => <int>{}).add(item.billId);
      final acc = totals.putIfAbsent(metal, _MetalAccumulator.new);
      acc.itemCount++;
      acc.pieces += item.quantity;
      acc.grossWeight += item.grossWeight;
      acc.netWeight += item.netWeight;
      acc.makingAmount += item.makingCharge;
      acc.salesAmount += item.itemTotal;
      acc.stockCostAmount += item.stockCostAmount;
      acc.profitAmount += item.profitAmount;
    }

    final summaries = totals.entries.map((entry) {
      final acc = entry.value;
      return SalesReportMetalSummary(
        metalType: entry.key,
        invoiceCount: invoiceSets[entry.key]?.length ?? 0,
        itemCount: acc.itemCount,
        pieces: acc.pieces,
        grossWeight: acc.grossWeight,
        netWeight: acc.netWeight,
        makingAmount: acc.makingAmount,
        salesAmount: acc.salesAmount,
        stockCostAmount: acc.stockCostAmount,
        profitAmount: acc.profitAmount,
      );
    }).toList()
      ..sort((a, b) => b.salesAmount.compareTo(a.salesAmount));

    return summaries;
  }

  bool _isGstBill(String billNo, double gstAmount, String billType) {
    final upperNo = billNo.toUpperCase();
    final upperType = billType.toUpperCase();
    return upperNo.startsWith('TAX-') ||
        gstAmount > 0.005 ||
        upperType == 'GST' ||
        upperType == 'TAX' ||
        upperType == 'TAX_INVOICE';
  }

  String _displayMetal(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return '';
    final lower = normalized.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  double _readDouble(QueryRow row, String column) {
    return row.readNullable<double>(column) ?? 0.0;
  }
}

class _SalesReportWhere {
  final String sql;
  final List<Variable<Object>> variables;

  const _SalesReportWhere({
    required this.sql,
    required this.variables,
  });
}

class _MetalAccumulator {
  int itemCount = 0;
  int pieces = 0;
  double grossWeight = 0;
  double netWeight = 0;
  double makingAmount = 0;
  double salesAmount = 0;
  double stockCostAmount = 0;
  double profitAmount = 0;
}
