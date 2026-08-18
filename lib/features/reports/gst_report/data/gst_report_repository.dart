import 'package:drift/drift.dart';

import '../../../../core/tax/gst_jurisdiction.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../database/db/app_database.dart';
import '../../../../models/setting/tax_gst/hsn_code_model.dart';
import '../domain/gst_filing_period.dart';
import '../domain/gst_quarter_filing_ledger.dart';
import '../domain/gst_report_models.dart';

class GstReportRepository {
  GstReportRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;
  static const double _defaultInclusiveGstRatePercent = 3.0;

  Future<GstReportSnapshot> fetch(GstReportPeriod period) async {
    try {
      final identity = await _fetchIdentity();
      final invoices = await _fetchInvoices(period, identity);
      final nonGstSales = await _fetchNonGstSalesSummary(period);
      final hsnRows = await _fetchHsnSummary(period, invoices);
      final rateRows = _buildRateSummary(invoices);
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
          nilExemptNonGstValue: 0,
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
        COALESCE(portal_reference, '') AS portal_reference,
        COALESCE(cpin, '') AS cpin,
        COALESCE(cin, '') AS cin,
        COALESCE(payment_mode, '') AS payment_mode,
        COALESCE(notes, '') AS notes,
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
        portalReference: row.read<String>('portal_reference'),
        cpin: row.read<String>('cpin'),
        cin: row.read<String>('cin'),
        paymentMode: row.read<String>('payment_mode'),
        notes: row.read<String>('notes'),
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

  Future<GstQuarterFilingLedger> fetchQuarterFilingLedger(
    GstReportPeriod period,
  ) async {
    final filing = GstFilingPeriod.fromMonth(period.month);
    final monthLedgers = <GstQuarterFilingMonthLedger>[];

    for (final month in filing.quarterMonths) {
      final monthPeriod = GstReportPeriod.forMonth(month);
      final monthSnapshot = await fetch(monthPeriod);
      final workflow = await fetchFilingWorkflowSnapshot(monthPeriod);
      monthLedgers.add(
        GstQuarterFilingMonthLedger(
          filing: GstFilingPeriod.fromMonth(month),
          taxLiability: monthSnapshot.dashboard.outputGstLiability,
          invoiceCount: monthSnapshot.dashboard.gstInvoiceCount,
          b2bInvoiceCount: monthSnapshot.gstr1B2bInvoices.length,
          b2bTaxLiability: _sum(
            monthSnapshot.gstr1B2bInvoices,
            (row) => row.gstAmount,
          ),
          b2cInvoiceCount: monthSnapshot.gstr1B2cInvoices.length,
          b2cTaxLiability: _sum(
            monthSnapshot.gstr1B2cInvoices,
            (row) => row.gstAmount,
          ),
          monthlyPaymentStatus:
              workflow.statusFor(GstFilingTask.monthlyTaxPayment),
          b2bIffStatus: workflow.statusFor(GstFilingTask.b2bIffUpload),
          b2bReturnStatus: workflow.statusFor(GstFilingTask.b2bReturnFiled),
          b2cReturnStatus: workflow.statusFor(GstFilingTask.b2cReturnFiled),
        ),
      );
    }

    final quarterSnapshot = await fetch(
      GstReportPeriod(
        startDate: filing.quarterStartMonth,
        endDate: DateTime(
          filing.quarterEndMonth.year,
          filing.quarterEndMonth.month + 1,
          0,
          23,
          59,
          59,
        ),
      ),
    );
    final quarterWorkflow = await fetchFilingWorkflowSnapshot(
      GstReportPeriod.forMonth(filing.quarterEndMonth),
    );

    return GstQuarterFilingLedger(
      filing: filing,
      months: monthLedgers,
      quarterReturnStatus:
          quarterWorkflow.statusFor(GstFilingTask.quarterReturnFiled),
      quarterTaxLiability: quarterSnapshot.dashboard.outputGstLiability,
      quarterInvoiceCount: quarterSnapshot.dashboard.gstInvoiceCount,
    );
  }

  Future<void> setFilingTaskCompletion({
    required GstReportPeriod period,
    required GstFilingTask task,
    required bool completed,
    required double amountSnapshot,
    required int invoiceCountSnapshot,
    String portalReference = '',
    String cpin = '',
    String cin = '',
    String paymentMode = '',
    String notes = '',
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
        portal_reference,
        cpin,
        cin,
        payment_mode,
        notes,
        completed,
        completed_at,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(period_month, task_key, segment) DO UPDATE SET
        financial_year = excluded.financial_year,
        quarter_key = excluded.quarter_key,
        quarter_label = excluded.quarter_label,
        amount_snapshot = excluded.amount_snapshot,
        invoice_count_snapshot = excluded.invoice_count_snapshot,
        portal_reference = excluded.portal_reference,
        cpin = excluded.cpin,
        cin = excluded.cin,
        payment_mode = excluded.payment_mode,
        notes = excluded.notes,
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
        _nullableText(portalReference),
        _nullableText(cpin),
        _nullableText(cin),
        _nullableText(paymentMode),
        _nullableText(notes),
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
    final gstin = _firstText([taxConfig?.gstin, shop?.gstin]);
    final configuredStateName = _firstText([
      GstJurisdictionResolver.stateNameFromText(shop?.state),
      shop?.state,
    ]);
    final stateCode = _firstText([
      _stateCodeFromGstin(gstin),
      taxConfig?.stateCode,
      GstJurisdictionResolver.stateCodeFromText(shop?.state),
    ]);
    final registeredStateName =
        GstJurisdictionResolver.canonicalStateName(stateCode);

    return GstReportShopIdentity(
      shopName: _firstText([
        shop?.legalName,
        shop?.shopName,
        taxConfig?.legalName,
      ], fallback: 'Lotus ERP'),
      gstin: gstin,
      stateCode: stateCode,
      stateName: _firstText([registeredStateName, configuredStateName]),
      configuredStateName: configuredStateName,
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
          NULLIF(TRIM(c.city), ''),
          ''
        ) AS place_of_supply,
        COALESCE(
          NULLIF(TRIM(b.customer_state_code_snapshot), ''),
          ''
        ) AS customer_state_code,
        COALESCE(NULLIF(TRIM(c.state), ''), '') AS customer_state_name,
        COALESCE(NULLIF(TRIM(b.shop_state_code_snapshot), ''), '') AS shop_state_code,
        COALESCE(NULLIF(TRIM(b.shop_gstin_snapshot), ''), '') AS shop_gstin,
        COALESCE(b.bill_type, '') AS bill_type,
        COALESCE(b.document_type, 'TAX_INVOICE') AS document_type,
        COALESCE(b.gst_pricing_mode, 'GST_EXCLUSIVE') AS gst_pricing_mode,
        COALESCE(b.total_amount, 0.0) AS total_amount,
        COALESCE(b.taxable_amount, 0.0) AS taxable_amount,
        COALESCE(b.cgst_amount, 0.0) AS cgst_amount,
        COALESCE(b.sgst_amount, 0.0) AS sgst_amount,
        COALESCE(b.igst_amount, 0.0) AS igst_amount,
        COALESCE(b.gst_amount, 0.0) AS gst_amount,
        COALESCE((
          SELECT SUM(
            COALESCE(i.item_total, 0.0) *
            (
              COALESCE(NULLIF(i.gst_rate_snapshot, 0.0), $_defaultInclusiveGstRatePercent) /
              (100.0 + COALESCE(NULLIF(i.gst_rate_snapshot, 0.0), $_defaultInclusiveGstRatePercent))
            )
          )
          FROM bill_items i
          WHERE i.bill_id = b.id
        ), 0.0) AS legacy_inclusive_gst,
        COALESCE(b.round_off_amount, 0.0) AS round_off_amount,
        COALESCE(b.final_amount, 0.0) AS final_amount
      FROM bills b
      LEFT JOIN customers c ON c.id = b.customer_id
      WHERE b.status = 'ACTIVE'
        AND b.bill_date >= ?
        AND b.bill_date <= ?
        AND UPPER(COALESCE(b.document_type, 'TAX_INVOICE')) <> 'QUOTATION'
        AND UPPER(COALESCE(b.tax_treatment, 'TAXABLE_SUPPLY')) = 'TAXABLE_SUPPLY'
        AND (
          COALESCE(b.gst_amount, 0.0) > 0.005
          OR COALESCE(b.taxable_amount, 0.0) > 0.005
          OR COALESCE(b.total_amount, 0.0) > 0.005
          OR COALESCE(b.final_amount, 0.0) > 0.005
        )
      ORDER BY b.bill_date ASC, b.id ASC
      ''',
      variables: [
        Variable<DateTime>(period.startDate),
        Variable<DateTime>(period.endDate),
      ],
    ).get();

    return rows.map((row) {
      final storedGst = _readDouble(row, 'gst_amount');
      final storedTaxable = _readDouble(row, 'taxable_amount');
      final grossFallback = _firstPositive([
        storedTaxable,
        _readDouble(row, 'total_amount'),
        _readDouble(row, 'final_amount') - _readDouble(row, 'round_off_amount'),
      ]);
      final rawPricingMode = row.read<String>('gst_pricing_mode');
      final legacyInclusive = storedGst <= 0.005 && grossFallback > 0.005;
      final pricingMode = legacyInclusive ? 'GST_INCLUSIVE' : rawPricingMode;
      final itemRateInclusiveGst = _readDouble(row, 'legacy_inclusive_gst');
      final computedGst = legacyInclusive
          ? _roundMoney(
              itemRateInclusiveGst > 0.005
                  ? itemRateInclusiveGst
                  : grossFallback *
                      _defaultInclusiveGstRatePercent /
                      (100 + _defaultInclusiveGstRatePercent),
            )
          : storedGst;
      final computedTaxable = legacyInclusive
          ? _roundMoney(grossFallback - computedGst)
          : storedTaxable;
      final storedIgst = _readDouble(row, 'igst_amount');
      final customerGstin = row.read<String>('customer_gstin');
      final customerStateCode = row.read<String>('customer_state_code');
      final customerStateName = row.read<String>('customer_state_name');
      final rawPlaceOfSupply = row.read<String>('place_of_supply');
      final jurisdiction = GstJurisdictionResolver.resolve(
        shopGstin: _firstText([row.read<String>('shop_gstin'), identity.gstin]),
        shopStateCode: _firstText([
          row.read<String>('shop_state_code'),
          identity.stateCode,
        ]),
        shopStateName: identity.stateName,
        customerGstin: customerGstin,
        customerStateCode: customerStateCode,
        customerStateName: customerStateName,
        placeOfSupply: rawPlaceOfSupply,
      );
      final split = _normalizedTaxSplit(
        totalGst: computedGst,
        cgst: _readDouble(row, 'cgst_amount'),
        sgst: _readDouble(row, 'sgst_amount'),
        igst: storedIgst,
        jurisdiction: jurisdiction,
      );
      final effectiveGst = _roundMoney(split.cgst + split.sgst + split.igst);
      final invoiceValue =
          legacyInclusive ? grossFallback : _readDouble(row, 'final_amount');
      final placeOfSupply = _firstText([
        jurisdiction.placeOfSupplyName,
        rawPlaceOfSupply,
      ]);

      return GstInvoiceRow(
        billId: row.read<int>('id'),
        invoiceNo: row.read<String>('bill_no'),
        invoiceDate: row.read<DateTime>('bill_date'),
        customerName: row.read<String>('customer_name'),
        customerGstin: customerGstin,
        placeOfSupply: placeOfSupply,
        customerStateCode: customerStateCode,
        placeOfSupplyStateCode: jurisdiction.placeOfSupplyStateCode,
        shopStateCode: jurisdiction.shopStateCode,
        supplyType: jurisdiction.supplyType,
        billType: row.read<String>('bill_type'),
        documentType: row.read<String>('document_type'),
        gstPricingMode: pricingMode,
        taxableAmount: computedTaxable,
        cgstAmount: split.cgst,
        sgstAmount: split.sgst,
        igstAmount: split.igst,
        gstAmount: effectiveGst,
        roundOffAmount: _readDouble(row, 'round_off_amount'),
        invoiceValue: invoiceValue,
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
        AND UPPER(COALESCE(b.document_type, 'TAX_INVOICE')) <> 'QUOTATION'
        AND UPPER(COALESCE(b.tax_treatment, 'TAXABLE_SUPPLY')) = 'TAXABLE_SUPPLY'
        AND (
          COALESCE(b.gst_amount, 0.0) > 0.005
          OR COALESCE(b.taxable_amount, 0.0) > 0.005
          OR COALESCE(b.total_amount, 0.0) > 0.005
          OR COALESCE(b.final_amount, 0.0) > 0.005
        )
      ORDER BY b.id ASC, i.line_no ASC, i.id ASC
      ''',
      variables: [
        Variable<DateTime>(period.startDate),
        Variable<DateTime>(period.endDate),
      ],
    ).get();

    final rowsByBill = <int, List<QueryRow>>{};
    for (final row in rows) {
      final billId = row.read<int>('bill_id');
      if (!invoiceById.containsKey(billId)) continue;
      rowsByBill.putIfAbsent(billId, () => <QueryRow>[]).add(row);
    }

    final accumulators = <String, _HsnAccumulator>{};
    for (final entry in rowsByBill.entries) {
      final invoice = invoiceById[entry.key];
      if (invoice == null) continue;
      final allocatedLines = _allocateInvoiceHsnLines(invoice, entry.value);

      for (final line in allocatedLines) {
        final hsn = line.row.read<String>('hsn_code');
        final invoiceType = invoice.isB2B ? 'B2B' : 'B2C';
        final key = '$invoiceType|$hsn|${line.gstRate.toStringAsFixed(2)}';
        final acc = accumulators.putIfAbsent(
          key,
          () => _HsnAccumulator(
            hsnCode: hsn,
            description:
                hsnDescriptions[hsn] ?? line.row.read<String>('item_name'),
            gstRate: line.gstRate,
            invoiceType: invoiceType,
          ),
        );

        acc.invoiceIds.add(invoice.billId);
        acc.lineCount++;
        acc.quantity += line.row.read<int>('quantity');
        acc.taxableAmount += line.taxableAmount;
        acc.cgstAmount += line.cgstAmount;
        acc.sgstAmount += line.sgstAmount;
        acc.igstAmount += line.igstAmount;
        acc.gstAmount += line.gstAmount;
        acc.invoiceValue += line.invoiceValue;
      }
    }
    for (final invoice in invoices) {
      if (rowsByBill.containsKey(invoice.billId)) continue;
      final gstRate = invoice.taxableAmount.abs() <= 0.005
          ? 0.0
          : (invoice.gstAmount / invoice.taxableAmount) * 100;
      final invoiceType = invoice.isB2B ? 'B2B' : 'B2C';
      final key = '$invoiceType|UNMAPPED|${gstRate.toStringAsFixed(2)}';
      final acc = accumulators.putIfAbsent(
        key,
        () => _HsnAccumulator(
          hsnCode: 'UNMAPPED',
          description: 'Invoice item details pending',
          gstRate: gstRate,
          invoiceType: invoiceType,
        ),
      );

      acc.invoiceIds.add(invoice.billId);
      acc.taxableAmount += invoice.taxableAmount;
      acc.cgstAmount += invoice.cgstAmount;
      acc.sgstAmount += invoice.sgstAmount;
      acc.igstAmount += invoice.igstAmount;
      acc.gstAmount += invoice.gstAmount;
      acc.invoiceValue += invoice.invoiceValue;
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

  List<_AllocatedHsnLine> _allocateInvoiceHsnLines(
    GstInvoiceRow invoice,
    List<QueryRow> rows,
  ) {
    if (rows.isEmpty) return const [];
    final bases = rows.map((row) {
      final snapshotTaxable = _readDouble(row, 'taxable_snapshot');
      final snapshotGst = _readDouble(row, 'gst_snapshot');
      final itemTotal = _readDouble(row, 'item_total');
      return _firstPositive([
        snapshotTaxable + snapshotGst,
        itemTotal,
        snapshotTaxable,
      ]);
    }).toList(growable: false);
    final totalBasis = bases.fold<double>(0, (sum, value) => sum + value);
    final equalRatio = 1 / rows.length;

    var remainingTaxable = invoice.taxableAmount;
    var remainingCgst = invoice.cgstAmount;
    var remainingSgst = invoice.sgstAmount;
    var remainingIgst = invoice.igstAmount;
    var remainingGst = invoice.gstAmount;
    var remainingInvoiceValue = invoice.invoiceValue;

    final allocated = <_AllocatedHsnLine>[];
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final isLast = index == rows.length - 1;
      final ratio = totalBasis > 0.005 ? bases[index] / totalBasis : equalRatio;
      final taxable = isLast
          ? _roundMoney(remainingTaxable)
          : _roundMoney(invoice.taxableAmount * ratio);
      final cgst = isLast
          ? _roundMoney(remainingCgst)
          : _roundMoney(invoice.cgstAmount * ratio);
      final sgst = isLast
          ? _roundMoney(remainingSgst)
          : _roundMoney(invoice.sgstAmount * ratio);
      final igst = isLast
          ? _roundMoney(remainingIgst)
          : _roundMoney(invoice.igstAmount * ratio);
      final gst = isLast
          ? _roundMoney(remainingGst)
          : _roundMoney(invoice.gstAmount * ratio);
      final invoiceValue = isLast
          ? _roundMoney(remainingInvoiceValue)
          : _roundMoney(invoice.invoiceValue * ratio);
      final gstRateSnapshot = _readDouble(row, 'gst_rate_snapshot');
      final gstRate = gstRateSnapshot.abs() > 0.005
          ? gstRateSnapshot
          : taxable.abs() <= 0.005
              ? 0.0
              : (gst / taxable) * 100;

      allocated.add(_AllocatedHsnLine(
        row: row,
        taxableAmount: taxable,
        cgstAmount: cgst,
        sgstAmount: sgst,
        igstAmount: igst,
        gstAmount: gst,
        invoiceValue: invoiceValue,
        gstRate: gstRate,
      ));

      remainingTaxable = _roundMoney(remainingTaxable - taxable);
      remainingCgst = _roundMoney(remainingCgst - cgst);
      remainingSgst = _roundMoney(remainingSgst - sgst);
      remainingIgst = _roundMoney(remainingIgst - igst);
      remainingGst = _roundMoney(remainingGst - gst);
      remainingInvoiceValue = _roundMoney(remainingInvoiceValue - invoiceValue);
    }
    return allocated;
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
        AND UPPER(COALESCE(b.document_type, 'TAX_INVOICE')) <> 'QUOTATION'
        AND UPPER(COALESCE(b.tax_treatment, 'TAXABLE_SUPPLY')) = 'TAXABLE_SUPPLY'
        AND NOT (
          COALESCE(b.gst_amount, 0.0) > 0.005
          OR COALESCE(b.taxable_amount, 0.0) > 0.005
          OR COALESCE(b.total_amount, 0.0) > 0.005
          OR COALESCE(b.final_amount, 0.0) > 0.005
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
    final exclusiveInvoices = invoices
        .where((row) => _isExclusivePricing(row.gstPricingMode))
        .toList(growable: false);
    final inclusiveInvoices = invoices
        .where((row) => _isInclusivePricing(row.gstPricingMode))
        .toList(growable: false);
    final exclusive = _pricingSummary(exclusiveInvoices);
    final inclusive = _pricingSummary(inclusiveInvoices);

    return GstReportDashboardSummary(
      totalInvoices: invoices.length + nonGstSales.invoiceCount,
      gstInvoiceCount: invoices.length,
      nonGstInvoiceCount: nonGstSales.invoiceCount,
      exclusive: exclusive,
      inclusive: inclusive,
      gstExclusiveSales: exclusive.taxableValue,
      gstInclusiveSales: inclusive.taxableValue,
      taxableSales: _sum(invoices, (row) => row.taxableAmount),
      cgstAmount: _sum(invoices, (row) => row.cgstAmount),
      sgstAmount: _sum(invoices, (row) => row.sgstAmount),
      igstAmount: _sum(invoices, (row) => row.igstAmount),
      totalGst: _sum(invoices, (row) => row.gstAmount),
      gstInvoiceValue: _sum(invoices, (row) => row.invoiceValue),
      taxReviewSales: nonGstSales.salesAmount,
    );
  }

  List<GstRateSummaryRow> _buildRateSummary(List<GstInvoiceRow> invoices) {
    final accumulators = <String, _RateAccumulator>{};
    for (final invoice in invoices) {
      final rate = invoice.taxableAmount.abs() <= 0.005
          ? 0.0
          : _roundMoney((invoice.gstAmount / invoice.taxableAmount) * 100);
      final key = rate.toStringAsFixed(2);
      final acc = accumulators.putIfAbsent(
        key,
        () => _RateAccumulator(rate: rate),
      );
      acc.invoiceCount++;
      acc.taxableAmount += invoice.taxableAmount;
      acc.cgstAmount += invoice.cgstAmount;
      acc.sgstAmount += invoice.sgstAmount;
      acc.igstAmount += invoice.igstAmount;
      acc.gstAmount += invoice.gstAmount;
      acc.invoiceValue += invoice.invoiceValue;
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
    final shopGstin = GstJurisdictionResolver.validateGstin(identity.gstin);
    if (shopGstin.isEmpty) {
      findings.add(const GstAuditFinding(
        severity: GstAuditSeverity.critical,
        title: 'Shop GSTIN Missing',
        message: 'Configure shop GSTIN before preparing GST returns.',
      ));
    } else if (!shopGstin.isValidFormat) {
      findings.add(const GstAuditFinding(
        severity: GstAuditSeverity.critical,
        title: 'Invalid Shop GSTIN',
        message: 'Shop GSTIN must be a valid 15-character GSTIN.',
      ));
    }
    if (shopGstin.stateCode.isNotEmpty &&
        identity.stateCode.isNotEmpty &&
        shopGstin.stateCode != identity.stateCode) {
      findings.add(GstAuditFinding(
        severity: GstAuditSeverity.critical,
        title: 'Shop State Code Mismatch',
        message:
            'GSTIN state ${shopGstin.stateCode} does not match configured state ${identity.stateCode}.',
      ));
    }
    final configuredStateCode =
        GstJurisdictionResolver.stateCodeFromText(identity.configuredStateName);
    if (configuredStateCode.isNotEmpty &&
        identity.stateCode.isNotEmpty &&
        configuredStateCode != identity.stateCode) {
      findings.add(GstAuditFinding(
        severity: GstAuditSeverity.critical,
        title: 'Shop State Name Mismatch',
        message:
            'Shop profile state ${identity.configuredStateName} maps to $configuredStateCode, but GST registration state is ${identity.stateCode}.',
      ));
    }
    for (final invoice in invoices) {
      final customerGstin =
          GstJurisdictionResolver.validateGstin(invoice.customerGstin);
      if (invoice.isB2B && !customerGstin.isValidFormat) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.critical,
          title: 'Invalid Customer GSTIN',
          message: 'B2B invoice requires a valid 15-character GSTIN.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
      if (invoice.placeOfSupplyStateCode.trim().isEmpty) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.warning,
          title: 'Place of Supply Missing',
          message:
              'Set customer state or GSTIN so CGST/SGST/IGST can be classified correctly.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
      if (customerGstin.stateCode.isNotEmpty &&
          invoice.placeOfSupplyStateCode.isNotEmpty &&
          customerGstin.stateCode != invoice.placeOfSupplyStateCode) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.warning,
          title: 'GSTIN State And Place Of Supply Differ',
          message:
              'Customer GSTIN state ${customerGstin.stateCode} differs from place of supply ${invoice.placeOfSupplyStateCode}. Verify delivery state before filing.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
      if (invoice.taxableAmount > 0.005 && invoice.gstAmount <= 0.005) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.critical,
          title: 'Taxable Invoice With Zero GST',
          message:
              'Completed taxable sale must be GST Exclusive or GST Inclusive, not zero-GST.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
      if (invoice.documentType.trim().toUpperCase() == 'QUOTATION') {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.critical,
          title: 'Quotation Included In GST',
          message: 'Quotation or estimate must be converted before GST filing.',
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
      if (invoice.placeOfSupplyStateCode.isNotEmpty &&
          invoice.shopStateCode.isNotEmpty &&
          invoice.shopStateCode != invoice.placeOfSupplyStateCode &&
          invoice.igstAmount <= 0.005 &&
          invoice.gstAmount > 0.005) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.critical,
          title: 'IGST Required',
          message:
              'Inter-state supply must be reported under IGST, not CGST/SGST.',
          invoiceNo: invoice.invoiceNo,
        ));
      }
      if (invoice.placeOfSupplyStateCode.isNotEmpty &&
          invoice.shopStateCode.isNotEmpty &&
          invoice.shopStateCode == invoice.placeOfSupplyStateCode &&
          invoice.igstAmount > 0.005) {
        findings.add(GstAuditFinding(
          severity: GstAuditSeverity.critical,
          title: 'CGST/SGST Required',
          message:
              'Intra-state supply must be reported under CGST and SGST, not IGST.',
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
    required GstJurisdiction jurisdiction,
  }) {
    final split = GstJurisdictionResolver.splitOutputTax(
      totalGst: totalGst,
      jurisdiction: jurisdiction,
      storedCgst: cgst,
      storedSgst: sgst,
      storedIgst: igst,
    );
    return _TaxSplit(cgst: split.cgst, sgst: split.sgst, igst: split.igst);
  }

  double _readDouble(QueryRow row, String column) {
    return row.readNullable<double>(column) ?? 0.0;
  }

  double _sum<T>(Iterable<T> rows, double Function(T row) selector) {
    return _roundMoney(
      rows.fold<double>(0, (sum, row) => sum + selector(row)),
    );
  }

  double _roundMoney(double amount) => (amount * 100).round() / 100;

  double _firstPositive(List<double> values) {
    for (final value in values) {
      if (value > 0.005) return value;
    }
    return 0;
  }

  GstPricingModeSummary _pricingSummary(List<GstInvoiceRow> invoices) {
    return GstPricingModeSummary(
      invoiceCount: invoices.length,
      invoiceValue: _sum(invoices, (row) => row.invoiceValue),
      taxableValue: _sum(invoices, (row) => row.taxableAmount),
      cgstAmount: _sum(invoices, (row) => row.cgstAmount),
      sgstAmount: _sum(invoices, (row) => row.sgstAmount),
      igstAmount: _sum(invoices, (row) => row.igstAmount),
      outputGst: _sum(invoices, (row) => row.gstAmount),
    );
  }

  bool _isInclusivePricing(String value) {
    return value.trim().toUpperCase() == 'GST_INCLUSIVE';
  }

  bool _isExclusivePricing(String value) {
    return !_isInclusivePricing(value);
  }

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

  String? _nullableText(String value) {
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  String _stateCodeFromGstin(String? gstin) {
    return GstJurisdictionResolver.stateCodeFromGstin(gstin);
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

class _AllocatedHsnLine {
  const _AllocatedHsnLine({
    required this.row,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.gstAmount,
    required this.invoiceValue,
    required this.gstRate,
  });

  final QueryRow row;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double gstAmount;
  final double invoiceValue;
  final double gstRate;
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
      taxableAmount: _roundMoney(taxableAmount),
      cgstAmount: _roundMoney(cgstAmount),
      sgstAmount: _roundMoney(sgstAmount),
      igstAmount: _roundMoney(igstAmount),
      gstAmount: _roundMoney(gstAmount),
      invoiceValue: _roundMoney(invoiceValue),
    );
  }

  double _roundMoney(double amount) => (amount * 100).round() / 100;
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
      taxableAmount: _roundMoney(taxableAmount),
      cgstAmount: _roundMoney(cgstAmount),
      sgstAmount: _roundMoney(sgstAmount),
      igstAmount: _roundMoney(igstAmount),
      gstAmount: _roundMoney(gstAmount),
      invoiceValue: _roundMoney(invoiceValue),
    );
  }

  double _roundMoney(double amount) => (amount * 100).round() / 100;
}
