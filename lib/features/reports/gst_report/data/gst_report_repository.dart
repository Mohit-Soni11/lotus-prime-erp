import 'package:drift/drift.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../database/db/app_database.dart';
import '../../../../models/setting/tax_gst/hsn_code_model.dart';
import '../domain/gst_filing_period.dart';
import '../domain/gst_report_models.dart';

class GstReportRepository {
  GstReportRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  Future<GstReportSnapshot> fetch(GstReportPeriod period) async {
    try {
      final identity = await _fetchIdentity();
      final invoices = await _fetchInvoices(period, identity);
      final nonGstSales = await _fetchNonGstSalesSummary(period);
      final hsnRows = await _fetchHsnSummary(period, invoices);
      final rateRows = _buildRateSummary(hsnRows);
      final dashboard = _buildDashboard(invoices, nonGstSales);
      final audit = _buildAuditFindings(
        identity: identity,
        invoices: invoices,
        hsnRows: hsnRows,
      );

      return GstReportSnapshot(
        period: period,
        identity: identity,
        dashboard: dashboard,
        gstr1B2bInvoices:
            invoices.where((invoice) => invoice.isB2B).toList(growable: false),
        gstr1B2cInvoices:
            invoices.where((invoice) => !invoice.isB2B).toList(growable: false),
        hsnSummary: hsnRows,
        rateSummary: rateRows,
        gstr3b: Gstr3bSummary(
          outwardTaxableValue: dashboard.taxableSales,
          outwardCgst: dashboard.cgstAmount,
          outwardSgst: dashboard.sgstAmount,
          outwardIgst: dashboard.igstAmount,
          nilExemptNonGstValue: dashboard.nonGstSalesEstimate,
        ),
        auditFindings: audit,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'GstReportRepository.fetch failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<GstFilingWorkflowSnapshot> fetchFilingWorkflowSnapshot(
    GstReportPeriod period,
  ) async {
    await _db.ensureGstFilingWorkflowSchema();
    final filing = GstFilingPeriod.fromMonth(period.month);
    final periodKey = _monthKey(period.month);
    final statuses = {
      for (final task in GstFilingTask.values)
        task: GstFilingTaskStatus.empty(
          task: task,
          periodMonth: period.month,
          quarterKey: filing.quarterKey,
          quarterLabel: _quarterTitle(filing),
        ),
    };

    final rows = await _db.customSelect(
      '''
      SELECT
        period_month,
        quarter_key,
        quarter_label,
        task_key,
        amount_snapshot,
        invoice_count_snapshot,
        completed,
        completed_at
      FROM gst_filing_workflow_statuses
      WHERE period_month = ?
        OR (quarter_key = ? AND task_key = ?)
      ''',
      variables: [
        Variable<String>(periodKey),
        Variable<String>(filing.quarterKey),
        Variable<String>(GstFilingTask.quarterReturnFiled.storageKey),
      ],
    ).get();

    for (final row in rows) {
      final task = GstFilingTaskMetadata.fromStorageKey(
        row.read<String>('task_key'),
      );
      if (task == null) continue;
      statuses[task] = GstFilingTaskStatus(
        task: task,
        periodMonth: _parseMonthKey(row.read<String>('period_month')),
        quarterKey: row.read<String>('quarter_key'),
        quarterLabel: row.read<String>('quarter_label'),
        amountSnapshot: _readDouble(row, 'amount_snapshot'),
        invoiceCountSnapshot: row.read<int>('invoice_count_snapshot'),
        completed: row.read<int>('completed') == 1,
        completedAt:
            _parseNullableDate(row.readNullable<String>('completed_at')),
      );
    }

    final completedQuarterRows = await _db.customSelect(
      '''
      SELECT DISTINCT quarter_key
      FROM gst_filing_workflow_statuses
      WHERE financial_year = ?
        AND task_key = ?
        AND completed = 1
      ''',
      variables: [
        Variable<String>(filing.financialYearLabel),
        Variable<String>(GstFilingTask.quarterReturnFiled.storageKey),
      ],
    ).get();

    return GstFilingWorkflowSnapshot(
      periodMonth: period.month,
      quarterKey: filing.quarterKey,
      quarterLabel: _quarterTitle(filing),
      statuses: statuses,
      completedQuarterKeys: completedQuarterRows
          .map((row) => row.read<String>('quarter_key'))
          .toSet(),
    );
  }

  Future<void> setFilingTaskCompletion({
    required GstReportPeriod period,
    required GstFilingTask task,
    required bool completed,
    required double amountSnapshot,
    required int invoiceCountSnapshot,
  }) async {
    await _db.ensureGstFilingWorkflowSchema();
    final filing = GstFilingPeriod.fromMonth(period.month);
    final effectiveMonth = task == GstFilingTask.quarterReturnFiled
        ? filing.quarterEndMonth
        : period.month;
    final now = DateTime.now().toIso8601String();
    final completedAt = completed ? now : null;

    await _db.customStatement(
      '''
      INSERT INTO gst_filing_workflow_statuses (
        period_month,
        financial_year,
        quarter_key,
        quarter_label,
        task_key,
        segment,
        amount_snapshot,
        invoice_count_snapshot,
        completed,
        completed_at,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(period_month, task_key, segment) DO UPDATE SET
        financial_year = excluded.financial_year,
        quarter_key = excluded.quarter_key,
        quarter_label = excluded.quarter_label,
        amount_snapshot = excluded.amount_snapshot,
        invoice_count_snapshot = excluded.invoice_count_snapshot,
        completed = excluded.completed,
        completed_at = excluded.completed_at,
        updated_at = excluded.updated_at
      ''',
      [
        _monthKey(effectiveMonth),
        filing.financialYearLabel,
        filing.quarterKey,
        _quarterTitle(filing),
        task.storageKey,
        task.segmentKey,
        amountSnapshot,
        invoiceCountSnapshot,
        completed ? 1 : 0,
        completedAt,
        now,
        now,
      ],
    );
  }

  Future<GstReportShopIdentity> _fetchIdentity() async {
    final taxConfig = await _db.taxGstDao.fetchConfig();
    final shop = await (_db.select(_db.shopProfiles)
          ..orderBy([(table) => OrderingTerm.desc(table.id)])
          ..limit(1))
        .getSingleOrNull();

    return GstReportShopIdentity(
      shopName: _firstText([
        shop?.legalName,
        shop?.shopName,
        taxConfig?.legalName,
      ], fallback: 'Lotus ERP'),
      gstin: _firstText([taxConfig?.gstin, shop?.gstin]),
      stateCode: _firstText([
        taxConfig?.stateCode,
        _stateCodeFromGstin(taxConfig?.gstin),
        _stateCodeFromGstin(shop?.gstin),
      ]),
      stateName: shop?.state ?? '',
    );
  }

  Future<List<GstInvoiceRow>> _fetchInvoices(
    GstReportPeriod period,
    GstReportShopIdentity identity,
  ) async {
    final rows = await _db.customSelect(
      '''
      SELECT
        b.id,
        b.bill_no,
        b.bill_date,
        COALESCE(NULLIF(TRIM(b.customer_name), ''), 'Walk-in Customer')
          AS customer_name,
        COALESCE(
          NULLIF(TRIM(b.customer_gstin_snapshot), ''),
          NULLIF(TRIM(c.gst_number), ''),
          ''
        ) AS customer_gstin,
        COALESCE(
          NULLIF(TRIM(b.place_of_supply_snapshot), ''),
          NULLIF(TRIM(c.state), ''),
          ''
        ) AS place_of_supply,
        COALESCE(b.bill_type, '') AS bill_type,
        COALESCE(b.taxable_amount, 0.0) AS taxable_amount,
        COALESCE(b.cgst_amount, 0.0) AS cgst_amount,
        COALESCE(b.sgst_amount, 0.0) AS sgst_amount,
        COALESCE(b.igst_amount, 0.0) AS igst_amount,
        COALESCE(b.gst_amount, 0.0) AS gst_amount,
        COALESCE(b.round_off_amount, 0.0) AS round_off_amount,
        COALESCE(b.final_amount, 0.0) AS final_amount
      FROM bills b
      LEFT JOIN customers c ON c.id = b.customer_id
      WHERE b.status = 'ACTIVE'
        AND b.bill_date >= ?
        AND b.bill_date <= ?
        AND (
          COALESCE(b.gst_amount, 0.0) > 0.005
          OR UPPER(COALESCE(b.bill_type, '')) IN ('GST', 'TAX', 'TAX_INVOICE')
          OR b.bill_no LIKE 'TAX-%'
        )
      ORDER BY b.bill_date ASC, b.id ASC
      ''',
      variables: [
        Variable<DateTime>(period.startDate),
        Variable<DateTime>(period.endDate),
      ],
    ).get();

    return rows.map((row) {
      final totalGst = _readDouble(row, 'gst_amount');
      final storedIgst = _readDouble(row, 'igst_amount');
      final split = _normalizedTaxSplit(
        totalGst: totalGst,
        cgst: _readDouble(row, 'cgst_amount'),
        sgst: _readDouble(row, 'sgst_amount'),
        igst: storedIgst,
      );

      return GstInvoiceRow(
        billId: row.read<int>('id'),
        invoiceNo: row.read<String>('bill_no'),
        invoiceDate: row.read<DateTime>('bill_date'),
        customerName: row.read<String>('customer_name'),
        customerGstin: row.read<String>('customer_gstin'),
        placeOfSupply: row.read<String>('place_of_supply'),
        billType: row.read<String>('bill_type'),
        taxableAmount: _readDouble(row, 'taxable_amount'),
        cgstAmount: split.cgst,
        sgstAmount: split.sgst,
        igstAmount: split.igst,
        gstAmount: totalGst,
        roundOffAmount: _readDouble(row, 'round_off_amount'),
        invoiceValue: _readDouble(row, 'final_amount'),
        isGst: true,
      );
    }).toList(growable: false);
  }

  Future<List<GstHsnSummaryRow>> _fetchHsnSummary(
    GstReportPeriod period,
    List<GstInvoiceRow> invoices,
  ) async {
    final invoiceById = {
      for (final invoice in invoices) invoice.billId: invoice
    };
    if (invoiceById.isEmpty) return const [];

    final hsnDescriptions = await _fetchHsnDescriptions();
    final rows = await _db.customSelect(
      '''
      SELECT
        b.id AS bill_id,
        COALESCE(NULLIF(TRIM(i.hsn_code), ''), 'UNMAPPED') AS hsn_code,
        COALESCE(NULLIF(TRIM(i.item_name), ''), 'Jewellery Item') AS item_name,
        COALESCE(i.quantity, 0) AS quantity,
        COALESCE(i.item_total, 0.0) AS item_total,
        COALESCE(i.taxable_amount_snapshot, 0.0) AS taxable_snapshot,
        COALESCE(i.gst_rate_snapshot, 0.0) AS gst_rate_snapshot,
        COALESCE(i.cgst_amount_snapshot, 0.0) AS cgst_snapshot,
        COALESCE(i.sgst_amount_snapshot, 0.0) AS sgst_snapshot,
        COALESCE(i.igst_amount_snapshot, 0.0) AS igst_snapshot,
        COALESCE(i.gst_amount_snapshot, 0.0) AS gst_snapshot
      FROM bill_items i
      INNER JOIN bills b ON b.id = i.bill_id
      WHERE b.status = 'ACTIVE'
        AND b.bill_date >= ?
        AND b.bill_date <= ?
        AND (
          COALESCE(b.gst_amount, 0.0) > 0.005
          OR UPPER(COALESCE(b.bill_type, '')) IN ('GST', 'TAX', 'TAX_INVOICE')
          OR b.bill_no LIKE 'TAX-%'
        )
      ORDER BY i.hsn_code ASC, b.id ASC, i.line_no ASC
      ''',
      variables: [
        Variable<DateTime>(period.startDate),
        Variable<DateTime>(period.endDate),
      ],
    ).get();

    final accumulators = <String, _HsnAccumulator>{};
    for (final row in rows) {
      final billId = row.read<int>('bill_id');
      final invoice = invoiceById[billId];
      if (invoice == null) continue;

      final itemTotal = _readDouble(row, 'item_total');
      final ratio = _allocationRatio(
        itemTotal,
        invoice.invoiceValue - invoice.roundOffAmount,
      );
      final snapshotGst = _readDouble(row, 'gst_snapshot');
      final fallbackGst = invoice.gstAmount * ratio;
      final totalGst = snapshotGst.abs() > 0.005 ? snapshotGst : fallbackGst;
      final taxableSnapshot = _readDouble(row, 'taxable_snapshot');
      final taxable = taxableSnapshot.abs() > 0.005
          ? taxableSnapshot
          : invoice.taxableAmount * ratio;
      final split = _normalizedTaxSplit(
        totalGst: totalGst,
        cgst: _readDouble(row, 'cgst_snapshot').abs() > 0.005
            ? _readDouble(row, 'cgst_snapshot')
            : invoice.cgstAmount * ratio,
        sgst: _readDouble(row, 'sgst_snapshot').abs() > 0.005
            ? _readDouble(row, 'sgst_snapshot')
            : invoice.sgstAmount * ratio,
        igst: _readDouble(row, 'igst_snapshot').abs() > 0.005
            ? _readDouble(row, 'igst_snapshot')
            : invoice.igstAmount * ratio,
      );
      final gstRateSnapshot = _readDouble(row, 'gst_rate_snapshot');
      final gstRate = gstRateSnapshot.abs() > 0.005
          ? gstRateSnapshot
          : taxable.abs() <= 0.005
              ? 0.0
              : (totalGst / taxable) * 100;
      final hsn = row.read<String>('hsn_code');
      final invoiceType = invoice.isB2B ? 'B2B' : 'B2C';
      final key = '$invoiceType|$hsn|${gstRate.toStringAsFixed(2)}';
      final acc = accumulators.putIfAbsent(
        key,
        () => _HsnAccumulator(
          hsnCode: hsn,
          description: hsnDescriptions[hsn] ?? row.read<String>('item_name'),
          gstRate: gstRate,
          invoiceType: invoiceType,
        ),
      );

      acc.invoiceIds.add(invoice.billId);
      acc.lineCount++;
      acc.quantity += row.read<int>('quantity');
      acc.taxableAmount += taxable;
      acc.cgstAmount += split.cgst;
      acc.sgstAmount += split.sgst;
      acc.igstAmount += split.igst;
      acc.gstAmount += totalGst;
      acc.invoiceValue += taxable + totalGst + (invoice.roundOffAmount * ratio);
    }

    final summaries = accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) {
        final typeCompare = a.invoiceType.compareTo(b.invoiceType);
        if (typeCompare != 0) return typeCompare;
        final hsnCompare = a.hsnCode.compareTo(b.hsnCode);
        if (hsnCompare != 0) return hsnCompare;
        return a.gstRate.compareTo(b.gstRate);
      });
    return summaries;
  }

  Future<_NonGstSalesSummary> _fetchNonGstSalesSummary(
    GstReportPeriod period,
  ) async {
    final row = await _db.customSelect(
      '''
      SELECT
        COUNT(*) AS invoice_count,
        COALESCE(SUM(
          CASE
            WHEN COALESCE(b.total_amount, 0.0) > 0.005
              THEN COALESCE(b.total_amount, 0.0)
            ELSE COALESCE(b.final_amount, 0.0)
          END
        ), 0.0) AS sales_amount
      FROM bills b
      WHERE b.status = 'ACTIVE'
        AND b.bill_date >= ?
        AND b.bill_date <= ?
        AND NOT (
          COALESCE(b.gst_amount, 0.0) > 0.005
          OR UPPER(COALESCE(b.bill_type, '')) IN ('GST', 'TAX', 'TAX_INVOICE')
          OR b.bill_no LIKE 'TAX-%'
        )
      ''',
      variables: [
        Variable<DateTime>(period.startDate),
        Variable<DateTime>(period.endDate),
      ],
    ).getSingle();

    return _NonGstSalesSummary(
      invoiceCount: row.read<int>('invoice_count'),
      salesAmount: _readDouble(row, 'sales_amount'),
    );
  }

  Future<Map<String, String>> _fetchHsnDescriptions() async {
    final config = await _db.taxGstDao.fetchConfig();
    final codes = hsnListFromJson(config?.hsnCodesJson);
    return {
      for (final code in codes)
        if (code.hsnCode.trim().isNotEmpty)
          code.hsnCode.trim(): code.category.trim().isEmpty
              ? 'Jewellery / Goods'
              : code.category.trim(),
    };
  }

  GstReportDashboardSummary _buildDashboard(
    List<GstInvoiceRow> invoices,
    _NonGstSalesSummary nonGstSales,
  ) {
    return GstReportDashboardSummary(
      totalInvoices: invoices.length + nonGstSales.invoiceCount,
      gstInvoiceCount: invoices.length,
      nonGstInvoiceCount: nonGstSales.invoiceCount,
      taxableSales: _sum(invoices, (row) => row.taxableAmount),
      cgstAmount: _sum(invoices, (row) => row.cgstAmount),
      sgstAmount: _sum(invoices, (row) => row.sgstAmount),
      igstAmount: _sum(invoices, (row) => row.igstAmount),
      totalGst: _sum(invoices, (row) => row.gstAmount),
      gstInvoiceValue: _sum(invoices, (row) => row.invoiceValue),
      nonGstSalesEstimate: nonGstSales.salesAmount,
    );
  }

  List<GstRateSummaryRow> _buildRateSummary(List<GstHsnSummaryRow> hsnRows) {
    final accumulators = <String, _RateAccumulator>{};
    for (final row in hsnRows) {
      final key = row.gstRate.toStringAsFixed(2);
      final acc = accumulators.putIfAbsent(
        key,
        () => _RateAccumulator(rate: row.gstRate),
      );
      acc.invoiceCount += row.invoiceCount;
      acc.taxableAmount += row.taxableAmount;
      acc.cgstAmount += row.cgstAmount;
      acc.sgstAmount += row.sgstAmount;
      acc.igstAmount += row.igstAmount;
      acc.gstAmount += row.gstAmount;
      acc.invoiceValue += row.invoiceValue;
    }
    return accumulators.values.map((acc) => acc.toRow()).toList()
      ..sort((a, b) => a.rate.compareTo(b.rate));
  }

  List<GstAuditFinding> _buildAuditFindings({
    required GstReportShopIdentity identity,
    required List<GstInvoiceRow> invoices,
    required List<GstHsnSummaryRow> hsnRows,
  }) {
    final findings = <GstAuditFinding>[];
    if (identity.gstin.trim().isEmpty) {
      findings.add(const GstAuditFinding(
        severity: GstAuditSeverity.critical,
        title: 'Shop GSTIN Missing',
        message: 'Configure shop GSTIN before preparing GST returns.',
      ));
    }
    for (final invoice in invoices) {
      if (invoice.isB2B && invoice.customerGstin.length != 15) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.critical,
          title: 'Invalid Customer GSTIN',
          message: 'B2B invoice requires a valid 15-character GSTIN.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
      if (invoice.placeOfSupply.trim().isEmpty) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.warning,
          title: 'Place of Supply Missing',
          message: 'Set place of supply for accurate CGST/SGST/IGST filing.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
      final splitTotal =
          invoice.cgstAmount + invoice.sgstAmount + invoice.igstAmount;
      if ((splitTotal - invoice.gstAmount).abs() > 0.02) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.critical,
          title: 'GST Split Mismatch',
          message: 'CGST, SGST and IGST do not match recorded GST total.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
      final expectedTotal =
          invoice.taxableAmount + invoice.gstAmount + invoice.roundOffAmount;
      if ((expectedTotal - invoice.invoiceValue).abs() > 1.0) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.warning,
          title: 'Invoice Total Mismatch',
          message: 'Taxable + GST + round off differs from invoice total.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
    }
    for (final row in hsnRows) {
      if (row.hsnCode == 'UNMAPPED') {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.critical,
          title: 'Missing HSN',
          message:
              '${row.invoiceType} GST register contains unmapped item rows.',
        ));
      }
    }
    if (findings.isEmpty) {
      findings.add(const GstAuditFinding(
        severity: GstAuditSeverity.info,
        title: 'Return Checks Clear',
        message: 'No GST filing blockers found for this period.',
      ));
    }
    return findings;
  }

  _TaxSplit _normalizedTaxSplit({
    required double totalGst,
    required double cgst,
    required double sgst,
    required double igst,
  }) {
    final roundedTotal = _roundMoney(totalGst);
    final roundedIgst = _roundMoney(igst);
    if (roundedIgst.abs() > 0.005) {
      return _TaxSplit(cgst: 0, sgst: 0, igst: roundedTotal);
    }
    var roundedCgst = _roundMoney(cgst);
    var roundedSgst = _roundMoney(sgst);
    if (roundedCgst.abs() <= 0.005 && roundedSgst.abs() <= 0.005) {
      roundedCgst = _roundMoney(roundedTotal / 2);
    }
    roundedSgst = _roundMoney(roundedTotal - roundedCgst);
    return _TaxSplit(cgst: roundedCgst, sgst: roundedSgst, igst: 0);
  }

  double _allocationRatio(double itemTotal, double invoiceTaxable) {
    if (itemTotal <= 0.005) return 0;
    if (invoiceTaxable.abs() <= 0.005) return 1;
    return itemTotal / invoiceTaxable;
  }

  double _readDouble(QueryRow row, String column) {
    return row.readNullable<double>(column) ?? 0.0;
  }

  double _sum<T>(Iterable<T> rows, double Function(T row) selector) {
    return rows.fold<double>(0, (sum, row) => sum + selector(row));
  }

  double _roundMoney(double amount) => (amount * 100).round() / 100;

  String _monthKey(DateTime value) {
    final month = DateTime(value.year, value.month);
    return '${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}-01';
  }

  DateTime _parseMonthKey(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return DateTime.now();
    return DateTime(parsed.year, parsed.month);
  }

  DateTime? _parseNullableDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _quarterTitle(GstFilingPeriod filing) {
    return '${filing.quarterLabel} ${filing.quarterRangeLabel}';
  }

  String _firstText(List<String?> values, {String fallback = ''}) {
    for (final value in values) {
      final clean = value?.trim() ?? '';
      if (clean.isNotEmpty && clean.toLowerCase() != 'not registered') {
        return clean;
      }
    }
    return fallback;
  }

  String _stateCodeFromGstin(String? gstin) {
    final normalized = gstin?.trim().toUpperCase() ?? '';
    if (normalized.length < 2) return '';
    final code = normalized.substring(0, 2);
    return RegExp(r'^\d{2}$').hasMatch(code) ? code : '';
  }
}

class _TaxSplit {
  const _TaxSplit({
    required this.cgst,
    required this.sgst,
    required this.igst,
  });

  final double cgst;
  final double sgst;
  final double igst;
}

class _NonGstSalesSummary {
  const _NonGstSalesSummary({
    required this.invoiceCount,
    required this.salesAmount,
  });

  final int invoiceCount;
  final double salesAmount;
}

class _HsnAccumulator {
  _HsnAccumulator({
    required this.hsnCode,
    required this.description,
    required this.gstRate,
    required this.invoiceType,
  });

  final String hsnCode;
  final String description;
  final double gstRate;
  final String invoiceType;
  final Set<int> invoiceIds = <int>{};
  int lineCount = 0;
  int quantity = 0;
  double taxableAmount = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double gstAmount = 0;
  double invoiceValue = 0;

  GstHsnSummaryRow toRow() {
    return GstHsnSummaryRow(
      hsnCode: hsnCode,
      description: description,
      gstRate: gstRate,
      invoiceType: invoiceType,
      invoiceCount: invoiceIds.length,
      lineCount: lineCount,
      quantity: quantity,
      taxableAmount: taxableAmount,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      gstAmount: gstAmount,
      invoiceValue: invoiceValue,
    );
  }
}

class _RateAccumulator {
  _RateAccumulator({required this.rate});

  final double rate;
  int invoiceCount = 0;
  double taxableAmount = 0;
  double cgstAmount = 0;
  double sgstAmount = 0;
  double igstAmount = 0;
  double gstAmount = 0;
  double invoiceValue = 0;

  GstRateSummaryRow toRow() {
    return GstRateSummaryRow(
      rate: rate,
      invoiceCount: invoiceCount,
      taxableAmount: taxableAmount,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      gstAmount: gstAmount,
      invoiceValue: invoiceValue,
    );
  }
}
