import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/repositories/return_reversal_repository.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/services/return_reversal_valuation_service.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

class ReturnReversalDriftRepository implements ReturnReversalRepository {
  final AppDatabase _database;
  static const _maxVoucherPostAttempts = 3;
  static const _weightTolerance = 0.0001;
  static const _valuationService = ReturnReversalValuationService();

  const ReturnReversalDriftRepository(this._database);

  @override
  Future<ReturnReversalTransactionSummary> fetchTransactionSummary() async {
    await _database.ensureReturnReversalSchema();
    final postedRow = await _database.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN operation_type = 'SALES_RETURN' THEN 1 ELSE 0 END), 0) AS posted_returns,
        COALESCE(SUM(CASE WHEN operation_type = 'BOOKING_CANCELLATION' THEN 1 ELSE 0 END), 0) AS posted_cancellations,
        COALESCE(SUM(return_value), 0.0) AS return_value,
        COALESCE((
          SELECT SUM(received_net_weight)
          FROM return_voucher_lines
          WHERE status <> 'VOIDED'
        ), 0.0) AS restored_weight
      FROM return_vouchers
      WHERE status <> 'VOIDED'
      ''',
    ).getSingle();
    final eligibleSalesRow = await _database.customSelect(
      '''
      SELECT COUNT(DISTINCT b.id) AS invoice_count
      FROM bills b
      WHERE b.status NOT IN ('CANCELLED', 'RETURNED')
        AND EXISTS (
          SELECT 1
          FROM bill_items i
          WHERE i.bill_id = b.id
            AND NOT EXISTS (
              SELECT 1
              FROM return_voucher_lines l
              WHERE l.source_type = 'SALES_INVOICE'
                AND l.source_id = b.id
                AND l.source_line_no = i.line_no
                AND l.status <> 'VOIDED'
            )
        )
      ''',
    ).getSingle();
    final eligibleBookingRow = await _database.customSelect(
      '''
      SELECT COUNT(*) AS booking_count
      FROM sales_orders o
      WHERE o.status NOT IN ('CANCELLED', 'DELIVERED')
        AND NOT EXISTS (
          SELECT 1
          FROM return_vouchers v
          WHERE v.source_type = 'ADVANCE_BOOKING'
            AND v.source_id = o.id
            AND v.status <> 'VOIDED'
        )
      ''',
    ).getSingle();
    return ReturnReversalTransactionSummary(
      eligibleSalesInvoices: eligibleSalesRow.read<int>('invoice_count'),
      eligibleAdvanceBookings: eligibleBookingRow.read<int>('booking_count'),
      postedReturns: postedRow.read<int>('posted_returns'),
      postedCancellations: postedRow.read<int>('posted_cancellations'),
      refundableAmount: _readDouble(postedRow, 'return_value'),
      restoredNetWeight: _readDouble(postedRow, 'restored_weight'),
    );
  }

  @override
  Future<ReturnReversalLookupResult> findCustomerHistoryByMobile(
    String mobile,
  ) async {
    await _database.ensureReturnReversalSchema();
    final normalizedMobile = _normalizePhone(mobile);
    if (normalizedMobile.isEmpty) {
      return const ReturnReversalLookupResult.empty();
    }

    final salesInvoices = await _findSalesInvoicesByMobile(normalizedMobile);
    final advanceBookings = await _findAdvanceBookingsByMobile(
      normalizedMobile,
    );
    final customerPurchases = await _findCustomerPurchasesByMobile(
      normalizedMobile,
    );

    return ReturnReversalLookupResult(
      salesInvoices: salesInvoices,
      advanceBookings: advanceBookings,
      customerPurchases: customerPurchases,
    );
  }

  @override
  Future<ReturnReversalSourceDocument?> findSourceDocumentByNumber(
    String documentNumber,
  ) async {
    await _database.ensureReturnReversalSchema();
    final sourceNumber = documentNumber.trim();
    if (sourceNumber.isEmpty) {
      return null;
    }

    return await _findSalesInvoiceByNumber(sourceNumber) ??
        await _findAdvanceBookingByNumber(sourceNumber) ??
        await _findCustomerPurchaseByNumber(sourceNumber);
  }

  Future<List<ReturnReversalSourceDocument>> _findSalesInvoicesByMobile(
    String normalizedMobile,
  ) async {
    final rows = await _database.customSelect(
      '''
      SELECT
        b.id,
        b.bill_no,
        b.customer_id,
        COALESCE(NULLIF(b.customer_name, ''), c.name, '') AS customer_name,
        COALESCE(NULLIF(b.mobile, ''), c.mobile, '') AS mobile,
        COALESCE(c.address_line1, '') AS address_line1,
        COALESCE(c.address_line2, '') AS address_line2,
        COALESCE(c.city, '') AS city,
        b.bill_date,
        b.total_amount,
        b.discount,
        b.taxable_amount,
        b.cgst_amount,
        b.sgst_amount,
        b.igst_amount,
        b.gst_amount,
        b.making_total,
        b.round_off_amount,
        b.final_amount,
        b.paid_amount,
        b.cash_paid,
        b.upi_paid,
        b.card_paid,
        b.advance_paid,
        b.due_amount,
        b.old_gold_deduction,
        b.payment_status,
        b.billing_mode,
        b.gst_pricing_mode,
        b.status
      FROM bills b
      LEFT JOIN customers c ON c.id = b.customer_id
      WHERE REPLACE(REPLACE(COALESCE(NULLIF(b.mobile, ''), c.mobile, ''), ' ', ''), '-', '') = ?
        AND b.status <> 'CANCELLED'
      ORDER BY b.bill_date DESC, b.id DESC
      LIMIT 100
      ''',
      variables: [drift.Variable.withString(normalizedMobile)],
    ).get();

    final documents = <ReturnReversalSourceDocument>[];
    for (final row in rows) {
      documents.add(await _mapSalesInvoice(row));
    }
    return documents;
  }

  Future<ReturnReversalSourceDocument?> _findSalesInvoiceByNumber(
    String documentNumber,
  ) async {
    final row = await _database.customSelect(
      '''
      SELECT
        b.id,
        b.bill_no,
        b.customer_id,
        COALESCE(NULLIF(b.customer_name, ''), c.name, '') AS customer_name,
        COALESCE(NULLIF(b.mobile, ''), c.mobile, '') AS mobile,
        COALESCE(c.address_line1, '') AS address_line1,
        COALESCE(c.address_line2, '') AS address_line2,
        COALESCE(c.city, '') AS city,
        b.bill_date,
        b.total_amount,
        b.discount,
        b.taxable_amount,
        b.cgst_amount,
        b.sgst_amount,
        b.igst_amount,
        b.gst_amount,
        b.making_total,
        b.round_off_amount,
        b.final_amount,
        b.paid_amount,
        b.cash_paid,
        b.upi_paid,
        b.card_paid,
        b.advance_paid,
        b.due_amount,
        b.old_gold_deduction,
        b.payment_status,
        b.billing_mode,
        b.gst_pricing_mode,
        b.status
      FROM bills b
      LEFT JOIN customers c ON c.id = b.customer_id
      WHERE UPPER(TRIM(b.bill_no)) = UPPER(TRIM(?))
        AND b.status <> 'CANCELLED'
      LIMIT 1
      ''',
      variables: [drift.Variable.withString(documentNumber)],
    ).getSingleOrNull();

    return row == null ? null : _mapSalesInvoice(row);
  }

  Future<ReturnReversalSourceDocument> _mapSalesInvoice(
    drift.QueryRow row,
  ) async {
    final billId = row.read<int>('id');
    final items = await (_database.select(_database.billItems)
          ..where((table) => table.billId.equals(billId))
          ..orderBy([(table) => drift.OrderingTerm.asc(table.lineNo)]))
        .get();
    final reversalLines = await _reversalLinesFor(
      sourceType: 'SALES_INVOICE',
      sourceId: billId,
    );
    final billTotal = _readDouble(row, 'total_amount');
    final billDiscount = _readDouble(row, 'discount');
    final lines = <ReturnReversalSourceLineItem>[
      for (final item in items)
        ReturnReversalSourceLineItem(
          sourceLineId: item.id,
          lineNo: item.lineNo,
          metalType: item.metalType,
          description: item.itemName,
          hsnCode: item.hsnCode ?? '',
          purity: item.purity,
          quantity: item.quantity,
          quantityUnitCode: _normalizedUnitCode(
            storedUnit: item.quantityUnitCode,
            metalType: item.metalType,
            itemName: item.itemName,
          ),
          grossWeight: item.grossWeight,
          lessWeight: item.lessWeight,
          lessWeightPerPiece: item.lessWeightPerPiece,
          netWeight: item.netWeight,
          fineWeight: item.fineWeight,
          rate: item.rate,
          makingChargeType: item.makingChargeType,
          makingChargeInput: item.makingChargeInput,
          makingAmount: item.makingCharge,
          discountAmount: _allocatedDiscount(
            lineValue: item.itemTotal,
            billTotal: billTotal,
            billDiscount: billDiscount,
          ),
          taxableAmount: item.taxableAmountSnapshot,
          gstAmount: item.gstAmountSnapshot,
          invoiceValue: item.invoiceValueSnapshot,
          value: item.itemTotal,
          huidNumber: item.huid ?? '',
          linkedStockItemId: item.linkedStockItemId,
          linkedStockUnitId: item.linkedStockUnitId,
          linkedStockSku: item.linkedStockSku ?? '',
          status: row.readNullable<String>('status') ?? 'ACTIVE',
          reversalStatus: reversalLines[item.lineNo]?.status ?? '',
          reversalVoucherNo: reversalLines[item.lineNo]?.voucherNo ?? '',
          reversalDate: reversalLines[item.lineNo]?.createdAt,
          reversalReceivedNetWeight:
              reversalLines[item.lineNo]?.receivedNetWeight,
          reversalHuidMatched: reversalLines[item.lineNo]?.huidMatched,
          reversalUnitMatched: reversalLines[item.lineNo]?.unitMatched,
          reversalIncludeMakingCharge:
              reversalLines[item.lineNo]?.includeMakingCharge,
          reversalStockDisposition:
              reversalLines[item.lineNo]?.stockDisposition ?? '',
          reversalMetalReturnAmount:
              reversalLines[item.lineNo]?.metalReturnAmount,
          reversalMakingReturnedAmount:
              reversalLines[item.lineNo]?.makingReturnedAmount,
          reversalLineReturnValue: reversalLines[item.lineNo]?.lineReturnValue,
        ),
    ];
    final reversedLineCount =
        lines.where((line) => line.reversalStatus.isNotEmpty).length;

    return ReturnReversalSourceDocument(
      id: billId,
      type: ReturnReversalSourceDocumentType.salesInvoice,
      documentNo: row.read<String>('bill_no'),
      customerId: row.readNullable<int>('customer_id'),
      customerName: row.readNullable<String>('customer_name') ?? '',
      mobile: row.readNullable<String>('mobile') ?? '',
      address: _joinAddress(
        row.readNullable<String>('address_line1'),
        row.readNullable<String>('address_line2'),
        row.readNullable<String>('city'),
      ),
      documentDate: _readDateTime(row, 'bill_date'),
      grossValue: _readDouble(row, 'total_amount'),
      discountAmount: _readDouble(row, 'discount'),
      taxableAmount: _readDouble(row, 'taxable_amount'),
      cgstAmount: _readDouble(row, 'cgst_amount'),
      sgstAmount: _readDouble(row, 'sgst_amount'),
      igstAmount: _readDouble(row, 'igst_amount'),
      gstAmount: _readDouble(row, 'gst_amount'),
      makingTotal: _readDouble(row, 'making_total'),
      roundOffAmount: _readDouble(row, 'round_off_amount'),
      finalAmount: _readDouble(row, 'final_amount'),
      paidAmount: _readDouble(row, 'paid_amount'),
      cashPaid: _readDouble(row, 'cash_paid'),
      upiPaid: _readDouble(row, 'upi_paid'),
      cardPaid: _readDouble(row, 'card_paid'),
      advancePaid: _readDouble(row, 'advance_paid'),
      dueAmount: _readDouble(row, 'due_amount'),
      tradeInDeduction: _readDouble(row, 'old_gold_deduction'),
      paymentStatus: row.readNullable<String>('payment_status') ?? '',
      billingMode: row.readNullable<String>('billing_mode') ?? '',
      gstPricingMode: row.readNullable<String>('gst_pricing_mode') ?? '',
      netWeight: lines.fold<double>(
        0,
        (total, line) => total + line.netWeight,
      ),
      lineItems: lines,
      reversalStatus: _documentReversalStatus(
        reversedLineCount: reversedLineCount,
        totalLineCount: lines.length,
      ),
      reversalVoucherNo: _firstReversalVoucherNo(reversalLines),
      reversedLineCount: reversedLineCount,
    );
  }

  Future<List<ReturnReversalSourceDocument>> _findAdvanceBookingsByMobile(
    String normalizedMobile,
  ) async {
    final rows = await _database.customSelect(
      '''
      SELECT
        o.id,
        o.order_no,
        o.customer_id,
        c.name AS customer_name,
        c.mobile,
        COALESCE(c.address_line1, '') AS address_line1,
        COALESCE(c.address_line2, '') AS address_line2,
        COALESCE(c.city, '') AS city,
        COALESCE(o.created_at, 0) AS created_at,
        o.item_name,
        o.metal_type,
        o.approx_weight,
        o.locked_rate,
        o.status,
        COALESCE(SUM(a.amount_paid), 0.0) AS paid_amount
      FROM sales_orders o
      INNER JOIN customers c ON c.id = o.customer_id
      LEFT JOIN order_advances a ON a.order_id = o.id
      WHERE REPLACE(REPLACE(COALESCE(c.mobile, ''), ' ', ''), '-', '') = ?
      GROUP BY o.id
      ORDER BY o.id DESC
      LIMIT 100
      ''',
      variables: [drift.Variable.withString(normalizedMobile)],
    ).get();

    return rows.map(_mapAdvanceBooking).toList(growable: false);
  }

  Future<ReturnReversalSourceDocument?> _findAdvanceBookingByNumber(
    String documentNumber,
  ) async {
    final row = await _database.customSelect(
      '''
      SELECT
        o.id,
        o.order_no,
        o.customer_id,
        c.name AS customer_name,
        c.mobile,
        COALESCE(c.address_line1, '') AS address_line1,
        COALESCE(c.address_line2, '') AS address_line2,
        COALESCE(c.city, '') AS city,
        COALESCE(o.created_at, 0) AS created_at,
        o.item_name,
        o.metal_type,
        o.approx_weight,
        o.locked_rate,
        o.status,
        COALESCE(SUM(a.amount_paid), 0.0) AS paid_amount
      FROM sales_orders o
      INNER JOIN customers c ON c.id = o.customer_id
      LEFT JOIN order_advances a ON a.order_id = o.id
      WHERE UPPER(TRIM(o.order_no)) = UPPER(TRIM(?))
      GROUP BY o.id
      LIMIT 1
      ''',
      variables: [drift.Variable.withString(documentNumber)],
    ).getSingleOrNull();

    return row == null ? null : _mapAdvanceBooking(row);
  }

  ReturnReversalSourceDocument _mapAdvanceBooking(drift.QueryRow row) {
    final weight = _readDouble(row, 'approx_weight');
    final rate = _readDouble(row, 'locked_rate');
    final paidAmount = _readDouble(row, 'paid_amount');
    final estimatedOrderValue = rate > 0 && weight > 0 ? weight * rate : 0.0;
    final lineValue = paidAmount > 0 ? paidAmount : estimatedOrderValue;
    final status = row.readNullable<String>('status') ?? 'PENDING';
    final line = ReturnReversalSourceLineItem(
      lineNo: 1,
      metalType: row.readNullable<String>('metal_type') ?? 'GOLD',
      description: row.readNullable<String>('item_name') ?? 'Booked Jewellery',
      quantity: 1,
      grossWeight: weight,
      netWeight: weight,
      rate: rate,
      value: lineValue,
      status: status,
      reversalStatus: status.toUpperCase() == 'CANCELLED' ? 'CANCELLED' : '',
    );

    return ReturnReversalSourceDocument(
      id: row.read<int>('id'),
      type: ReturnReversalSourceDocumentType.advanceBooking,
      documentNo: row.read<String>('order_no'),
      customerId: row.readNullable<int>('customer_id'),
      customerName: row.readNullable<String>('customer_name') ?? '',
      mobile: row.readNullable<String>('mobile') ?? '',
      address: _joinAddress(
        row.readNullable<String>('address_line1'),
        row.readNullable<String>('address_line2'),
        row.readNullable<String>('city'),
      ),
      documentDate: _readDateTime(row, 'created_at'),
      grossValue: lineValue,
      paidAmount: paidAmount,
      dueAmount: 0,
      netWeight: weight,
      lineItems: [line],
      reversalStatus: status.toUpperCase() == 'CANCELLED' ? 'CANCELLED' : '',
      reversedLineCount: status.toUpperCase() == 'CANCELLED' ? 1 : 0,
    );
  }

  Future<List<ReturnReversalSourceDocument>> _findCustomerPurchasesByMobile(
    String normalizedMobile,
  ) async {
    final rows = await _database.customSelect(
      '''
      SELECT
        id,
        voucher_no,
        customer_id,
        party_name,
        mobile,
        COALESCE(city, '') AS city,
        created_at,
        grand_total,
        total_paid,
        balance_due,
        payment_status,
        status
      FROM purchase_vouchers
      WHERE source_type = 'CUSTOMER'
        AND REPLACE(REPLACE(COALESCE(mobile, ''), ' ', ''), '-', '') = ?
        AND status <> 'CANCELLED'
      ORDER BY created_at DESC, id DESC
      LIMIT 100
      ''',
      variables: [drift.Variable.withString(normalizedMobile)],
    ).get();

    final documents = <ReturnReversalSourceDocument>[];
    for (final row in rows) {
      documents.add(await _mapCustomerPurchase(row));
    }
    return documents;
  }

  Future<ReturnReversalSourceDocument?> _findCustomerPurchaseByNumber(
    String documentNumber,
  ) async {
    final row = await _database.customSelect(
      '''
      SELECT
        id,
        voucher_no,
        customer_id,
        party_name,
        mobile,
        COALESCE(city, '') AS city,
        created_at,
        grand_total,
        total_paid,
        balance_due,
        payment_status,
        status
      FROM purchase_vouchers
      WHERE source_type = 'CUSTOMER'
        AND UPPER(TRIM(voucher_no)) = UPPER(TRIM(?))
        AND status <> 'CANCELLED'
      LIMIT 1
      ''',
      variables: [drift.Variable.withString(documentNumber)],
    ).getSingleOrNull();

    return row == null ? null : _mapCustomerPurchase(row);
  }

  @override
  Future<ReturnReversalProcessResult> processReturn(
    ReturnReversalProcessRequest request,
  ) async {
    await _database.ensureReturnReversalSchema();
    _validateProcessRequest(request);

    for (var attempt = 1; attempt <= _maxVoucherPostAttempts; attempt++) {
      try {
        return await _processReturnOnce(request);
      } catch (error) {
        final canRetry =
            attempt < _maxVoucherPostAttempts && _isVoucherNoConflict(error);
        if (!canRetry) {
          rethrow;
        }
      }
    }
    throw StateError('Unable to post return voucher. Please try again.');
  }

  Future<ReturnReversalProcessResult> _processReturnOnce(
    ReturnReversalProcessRequest request,
  ) async {
    final sourceType = _sourceTypeStorage(request.sourceDocument.type);
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    var voucherId = 0;
    var voucherNo = '';
    var returnValue = 0.0;
    var dueAdjustedAmount = 0.0;
    var customerCreditAmount = 0.0;
    var makingReturnedAmount = 0.0;

    await _database.transaction(() async {
      await _assertProcessLinesAvailable(request, sourceType);
      voucherNo = await _nextReturnVoucherNo(request.operationType);

      for (final returnLine in request.lines) {
        final sourceLine =
            request.sourceDocument.lineByNo(returnLine.sourceLineNo)!;
        final valuation = _valuationService.valueLine(
          sourceLine: sourceLine,
          returnLine: returnLine,
        );
        returnValue += valuation.returnValue;
        makingReturnedAmount += valuation.makingReturnedAmount;
      }
      returnValue = _roundMoney(returnValue);
      makingReturnedAmount = _roundMoney(makingReturnedAmount);
      dueAdjustedAmount = _roundMoney(
        request.sourceDocument.type ==
                ReturnReversalSourceDocumentType.salesInvoice
            ? request.sourceDocument.dueAmount
                .clamp(0.0, returnValue)
                .toDouble()
            : 0.0,
      );
      customerCreditAmount = _roundMoney(returnValue - dueAdjustedAmount);

      await _insertReturnVoucher(
        request: request,
        voucherNo: voucherNo,
        sourceType: sourceType,
        returnValue: returnValue,
        dueAdjustedAmount: dueAdjustedAmount,
        customerCreditAmount: customerCreditAmount,
        makingReturnedAmount: makingReturnedAmount,
        nowMs: nowMs,
      );
      voucherId = await _lastInsertRowId();

      for (final returnLine in request.lines) {
        final sourceLine =
            request.sourceDocument.lineByNo(returnLine.sourceLineNo)!;
        final valuation = _valuationService.valueLine(
          sourceLine: sourceLine,
          returnLine: returnLine,
        );
        await _insertReturnLine(
          voucherId: voucherId,
          voucherNo: voucherNo,
          sourceType: sourceType,
          sourceDocument: request.sourceDocument,
          sourceLine: sourceLine,
          returnLine: returnLine,
          valuation: valuation,
          nowMs: nowMs,
        );
        await _applyStockDisposition(
          voucherId: voucherId,
          voucherNo: voucherNo,
          sourceDocument: request.sourceDocument,
          sourceLine: sourceLine,
          returnLine: returnLine,
          valuation: valuation,
          now: now,
          nowMs: nowMs,
        );
      }

      await _applySourceStatus(
        request: request,
        sourceType: sourceType,
        now: now,
      );
      await _postCustomerCreditLedger(
        request: request,
        voucherNo: voucherNo,
        creditAmount: customerCreditAmount,
        now: now,
      );
    });

    return ReturnReversalProcessResult(
      voucherId: voucherId,
      voucherNo: voucherNo,
      processedLineCount: request.lines.length,
      returnValue: returnValue,
      dueAdjustedAmount: dueAdjustedAmount,
      customerCreditAmount: customerCreditAmount,
      status: 'POSTED',
    );
  }

  Future<ReturnReversalSourceDocument> _mapCustomerPurchase(
    drift.QueryRow row,
  ) async {
    final voucherId = row.read<int>('id');
    final reversalLines = await _reversalLinesFor(
      sourceType: 'CUSTOMER_PURCHASE',
      sourceId: voucherId,
    );
    final itemRows = await _database.customSelect(
      '''
      SELECT
        line_no,
        metal_type,
        item_description,
        quantity,
        gross_weight,
        net_weight,
        rate,
        line_amount
      FROM purchase_voucher_items
      WHERE purchase_voucher_id = ?
      ORDER BY line_no ASC, id ASC
      ''',
      variables: [drift.Variable.withInt(voucherId)],
    ).get();
    final lines = [
      for (final item in itemRows)
        ReturnReversalSourceLineItem(
          lineNo: item.read<int>('line_no'),
          metalType: item.readNullable<String>('metal_type') ?? 'OLD METAL',
          description:
              item.readNullable<String>('item_description') ?? 'Old Metal',
          quantity: item.readNullable<int>('quantity') ?? 1,
          grossWeight: _readDouble(item, 'gross_weight'),
          netWeight: _readDouble(item, 'net_weight'),
          rate: _readDouble(item, 'rate'),
          value: _readDouble(item, 'line_amount'),
          status: row.readNullable<String>('payment_status') ?? 'SAVED',
          reversalStatus:
              reversalLines[item.read<int>('line_no')]?.status ?? '',
          reversalVoucherNo:
              reversalLines[item.read<int>('line_no')]?.voucherNo ?? '',
        ),
    ];
    final reversedLineCount =
        lines.where((line) => line.reversalStatus.isNotEmpty).length;

    return ReturnReversalSourceDocument(
      id: voucherId,
      type: ReturnReversalSourceDocumentType.customerPurchase,
      documentNo: row.read<String>('voucher_no'),
      customerId: row.readNullable<int>('customer_id'),
      customerName: row.readNullable<String>('party_name') ?? '',
      mobile: row.readNullable<String>('mobile') ?? '',
      address: row.readNullable<String>('city') ?? '',
      documentDate: _readDateTime(row, 'created_at'),
      grossValue: _readDouble(row, 'grand_total'),
      paidAmount: _readDouble(row, 'total_paid'),
      dueAmount: _readDouble(row, 'balance_due'),
      netWeight: lines.fold<double>(
        0,
        (total, line) => total + line.netWeight,
      ),
      lineItems: lines,
      reversalStatus: _documentReversalStatus(
        reversedLineCount: reversedLineCount,
        totalLineCount: lines.length,
      ),
      reversalVoucherNo: _firstReversalVoucherNo(reversalLines),
      reversedLineCount: reversedLineCount,
    );
  }

  void _validateProcessRequest(ReturnReversalProcessRequest request) {
    if (!request.operationType.acceptsSourceType(request.sourceDocument.type)) {
      throw StateError('Selected document is not valid for this operation.');
    }
    if (request.lines.isEmpty) {
      throw StateError('Add at least one item to the return cart.');
    }
    final isAdvanceBookingCancellation =
        request.operationType.isBookingCancellation &&
            request.sourceDocument.type ==
                ReturnReversalSourceDocumentType.advanceBooking;
    final seen = <int>{};
    for (final line in request.lines) {
      if (!seen.add(line.sourceLineNo)) {
        throw StateError('Duplicate return line ${line.sourceLineNo}.');
      }
      final sourceLine = request.sourceDocument.lineByNo(line.sourceLineNo);
      if (sourceLine == null) {
        throw StateError('Invoice line ${line.sourceLineNo} no longer exists.');
      }
      if (sourceLine.isReversed) {
        throw StateError('Line ${line.sourceLineNo} is already reversed.');
      }
      if (isAdvanceBookingCancellation) {
        if (line.stockDisposition !=
            ReturnReversalStockDisposition.notApplicable) {
          throw StateError(
            'Booking cancellation does not use stock routing.',
          );
        }
        continue;
      }
      if (line.receivedNetWeight <= 0) {
        throw StateError(
            'Received net weight is required for line ${line.sourceLineNo}.');
      }
      if (line.receivedNetWeight - sourceLine.netWeight > _weightTolerance) {
        throw StateError(
          'Received net weight for line ${line.sourceLineNo} cannot exceed the original sold net weight.',
        );
      }
      if ((!line.huidMatched || !line.unitMatched) &&
          line.stockDisposition != ReturnReversalStockDisposition.managerHold) {
        throw StateError(
          'Line ${line.sourceLineNo} has a verification mismatch. Move it to manager hold before processing.',
        );
      }
    }
  }

  Future<void> _assertProcessLinesAvailable(
    ReturnReversalProcessRequest request,
    String sourceType,
  ) async {
    for (final line in request.lines) {
      final row = await _database.customSelect(
        '''
        SELECT COUNT(*) AS line_count
        FROM return_voucher_lines
        WHERE source_type = ?
          AND source_id = ?
          AND source_line_no = ?
          AND status <> 'VOIDED'
        ''',
        variables: [
          drift.Variable.withString(sourceType),
          drift.Variable.withInt(request.sourceDocument.id),
          drift.Variable.withInt(line.sourceLineNo),
        ],
      ).getSingle();
      if (row.read<int>('line_count') > 0) {
        throw StateError(
            'Line ${line.sourceLineNo} has already been processed.');
      }
    }
  }

  Future<void> _insertReturnLine({
    required int voucherId,
    required String voucherNo,
    required String sourceType,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required int nowMs,
  }) async {
    final values = <String, Object?>{
      'return_voucher_id': voucherId,
      'source_type': sourceType,
      'source_id': sourceDocument.id,
      'source_number': sourceDocument.documentNo,
      'source_line_no': sourceLine.lineNo,
      'source_bill_item_id': sourceLine.sourceLineId,
      'stock_item_id': sourceLine.linkedStockItemId,
      'stock_unit_id': sourceLine.linkedStockUnitId,
      'stock_disposition': returnLine.stockDisposition.storageValue,
      'metal_type': sourceLine.metalType,
      'item_description': sourceLine.description,
      'huid': sourceLine.huidNumber.trim().isEmpty
          ? null
          : sourceLine.huidNumber.trim(),
      'quantity': sourceLine.quantity,
      'quantity_unit_code': sourceLine.quantityUnitCode,
      'purity': sourceLine.purity,
      'sold_net_weight': sourceLine.netWeight,
      'received_net_weight': returnLine.receivedNetWeight,
      'short_weight': (sourceLine.netWeight - returnLine.receivedNetWeight)
          .clamp(0.0, double.infinity),
      'rate': sourceLine.rate,
      'sold_item_value': sourceLine.displayLineTotal,
      'adjusted_item_value': valuation.adjustedLineAmount,
      'available_making_amount': valuation.adjustedMakingAmount,
      'making_returned_amount': valuation.makingReturnedAmount,
      'metal_return_amount': valuation.metalAmount,
      'line_return_value': valuation.returnValue,
      'huid_matched': returnLine.huidMatched ? 1 : 0,
      'unit_matched': returnLine.unitMatched ? 1 : 0,
      'status': 'POSTED',
      'created_at': nowMs,
      'action': returnLine.stockDisposition.storageValue,
    };
    await _insertFilteringExistingColumns(
      tableName: 'return_voucher_lines',
      values: values,
    );
  }

  Future<void> _insertReturnVoucher({
    required ReturnReversalProcessRequest request,
    required String voucherNo,
    required String sourceType,
    required double returnValue,
    required double dueAdjustedAmount,
    required double customerCreditAmount,
    required double makingReturnedAmount,
    required int nowMs,
  }) {
    final operatorNote = request.operatorNote.trim();
    final values = <String, Object?>{
      'voucher_no': voucherNo,
      'operation_type': _operationTypeStorage(request.operationType),
      'source_type': sourceType,
      'source_id': request.sourceDocument.id,
      'source_number': request.sourceDocument.documentNo,
      'customer_id': request.sourceDocument.customerId,
      'customer_name': request.sourceDocument.customerName,
      'mobile': request.sourceDocument.mobile,
      'settlement_mode': request.settlementMode.storageValue,
      'original_total_amount': request.sourceDocument.finalAmount,
      'return_value': returnValue,
      'due_adjusted_amount': dueAdjustedAmount,
      'customer_credit_amount': customerCreditAmount,
      'making_returned_amount': makingReturnedAmount,
      'status': 'POSTED',
      'operator_note': operatorNote.isEmpty ? null : operatorNote,
      'created_at': nowMs,
      'updated_at': nowMs,
      'action': _operationTypeStorage(request.operationType),
    };
    return _insertFilteringExistingColumns(
      tableName: 'return_vouchers',
      values: values,
    );
  }

  Future<void> _insertFilteringExistingColumns({
    required String tableName,
    required Map<String, Object?> values,
  }) async {
    final existingColumns = await _columnNamesFor(tableName);
    final filtered = Map.fromEntries(
      values.entries.where((entry) => existingColumns.contains(entry.key)),
    );
    final columns = filtered.keys.map((column) => '"$column"').join(', ');
    final placeholders = List.filled(filtered.length, '?').join(', ');
    await _database.customStatement(
      'INSERT INTO "$tableName" ($columns) VALUES ($placeholders)',
      filtered.values.toList(growable: false),
    );
  }

  Future<Set<String>> _columnNamesFor(String tableName) async {
    final rows =
        await _database.customSelect('PRAGMA table_info("$tableName")').get();
    return rows
        .map((row) => row.data['name'])
        .whereType<String>()
        .map((name) => name.toLowerCase())
        .toSet();
  }

  Future<void> _applyStockDisposition({
    required int voucherId,
    required String voucherNo,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required DateTime now,
    required int nowMs,
  }) async {
    if (sourceDocument.type != ReturnReversalSourceDocumentType.salesInvoice) {
      return;
    }

    if (returnLine.stockDisposition == ReturnReversalStockDisposition.melting) {
      await _postMeltingPurchaseLine(
        voucherNo: voucherNo,
        sourceDocument: sourceDocument,
        sourceLine: sourceLine,
        returnLine: returnLine,
        valuation: valuation,
        nowMs: nowMs,
      );
      await _moveLinkedUnitToStatus(
        sourceLine: sourceLine,
        voucherNo: voucherNo,
        newStatus: 'Melting',
        reason: 'Sales return routed to melting',
        now: now,
        nowMs: nowMs,
      );
      return;
    }

    final targetStatus = returnLine.stockDisposition ==
            ReturnReversalStockDisposition.managerHold
        ? 'On Hold'
        : 'Available';
    final movementType = returnLine.stockDisposition ==
            ReturnReversalStockDisposition.managerHold
        ? 'RETURN_HOLD'
        : 'SALE_RESTORE';

    final createdStockItem = sourceLine.linkedStockItemId == null;
    final stockItemId = sourceLine.linkedStockItemId ??
        await _createReturnedStockItem(
          voucherNo: voucherNo,
          sourceDocument: sourceDocument,
          sourceLine: sourceLine,
          returnLine: returnLine,
          valuation: valuation,
          status: targetStatus,
          nowMs: nowMs,
        );

    if (sourceLine.linkedStockUnitId != null) {
      await _moveLinkedUnitToStatus(
        sourceLine: sourceLine,
        voucherNo: voucherNo,
        newStatus: targetStatus,
        reason: returnLine.stockDisposition ==
                ReturnReversalStockDisposition.managerHold
            ? 'Sales return held for manager review'
            : 'Sales return restored to sellable stock',
        now: now,
        nowMs: nowMs,
      );
      await _database.customStatement(
        '''
        UPDATE stock_items
        SET quantity = quantity + 1,
            is_active = 1,
            status = ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [targetStatus, nowMs, stockItemId],
      );
    } else if (!createdStockItem) {
      await _createReturnedStockUnit(
        stockItemId: stockItemId,
        sku: sourceLine.linkedStockSku.trim().isEmpty
            ? '$voucherNo-L${sourceLine.lineNo.toString().padLeft(3, '0')}'
            : sourceLine.linkedStockSku.trim(),
        batchCode: voucherNo,
        sourceLine: sourceLine,
        returnLine: returnLine,
        valuation: valuation,
        status: targetStatus,
        nowMs: nowMs,
      );
      await _database.customStatement(
        '''
        UPDATE stock_items
        SET quantity = quantity + 1,
            is_active = 1,
            status = ?,
            updated_at = ?
        WHERE id = ?
        ''',
        [targetStatus, nowMs, stockItemId],
      );
    }

    await _insertReturnStockMovement(
      stockItemId: stockItemId,
      movementType: movementType,
      voucherNo: voucherNo,
      sourceLine: sourceLine,
      returnLine: returnLine,
      nowMs: nowMs,
      reason: targetStatus == 'Available'
          ? 'Sales return stock restore'
          : 'Sales return manager hold',
    );
  }

  Future<void> _moveLinkedUnitToStatus({
    required ReturnReversalSourceLineItem sourceLine,
    required String voucherNo,
    required String newStatus,
    required String reason,
    required DateTime now,
    required int nowMs,
  }) async {
    final stockUnitId = sourceLine.linkedStockUnitId;
    if (stockUnitId == null) {
      return;
    }
    final row = await _database.customSelect(
      '''
      SELECT
        id,
        stock_item_id,
        unit_code,
        huid,
        batch_code,
        status
      FROM stock_item_units
      WHERE id = ?
      LIMIT 1
      ''',
      variables: [drift.Variable.withInt(stockUnitId)],
    ).getSingleOrNull();
    if (row == null) {
      throw StateError(
          'Linked stock unit for line ${sourceLine.lineNo} no longer exists.');
    }
    final previousStatus = row.readNullable<String>('status') ?? '';
    await _database.customStatement(
      '''
      UPDATE stock_item_units
      SET status = ?, sold_at = NULL, updated_at = ?
      WHERE id = ?
      ''',
      [newStatus, nowMs, stockUnitId],
    );
    await _database.customStatement(
      '''
      INSERT INTO stock_unit_status_events (
        stock_unit_id,
        stock_item_id,
        unit_code,
        huid,
        batch_code,
        previous_status,
        new_status,
        reason,
        source_type,
        source_number,
        created_at
      ) VALUES (?, NULLIF(?, 0), ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockUnitId,
        row.readNullable<int>('stock_item_id') ??
            sourceLine.linkedStockItemId ??
            0,
        row.readNullable<String>('unit_code') ?? sourceLine.linkedStockSku,
        row.readNullable<String>('huid') ?? sourceLine.huidNumber,
        row.readNullable<String>('batch_code') ?? voucherNo,
        previousStatus,
        newStatus,
        reason,
        'SALES_RETURN',
        voucherNo,
        nowMs,
      ],
    );
  }

  Future<int> _createReturnedStockItem({
    required String voucherNo,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required String status,
    required int nowMs,
  }) async {
    final sku = '$voucherNo-L${sourceLine.lineNo.toString().padLeft(3, '0')}';
    final stockItemId = await _database.into(_database.stockItems).insert(
          StockItemsCompanion(
            sku: drift.Value(sku),
            itemName: drift.Value(sourceLine.description),
            description: drift.Value(
              'Returned from ${sourceDocument.documentNo}; original line ${sourceLine.lineNo}',
            ),
            category: drift.Value(_categoryForMetal(sourceLine.metalType)),
            subCategory: const drift.Value('Sales Return'),
            metalType: drift.Value(_metalDisplayName(sourceLine.metalType)),
            purity: drift.Value(sourceLine.purity),
            grossWeight: drift.Value(returnLine.receivedNetWeight),
            stoneWeight: const drift.Value(0),
            netWeight: drift.Value(returnLine.receivedNetWeight),
            purchaseRate: drift.Value(sourceLine.rate),
            makingCharge: drift.Value(valuation.makingReturnedAmount),
            makingChargeType: drift.Value(sourceLine.makingChargeType),
            purchasePrice: drift.Value(valuation.returnValue),
            mrp: drift.Value(sourceLine.displayLineTotal),
            hsnCode: drift.Value(sourceLine.hsnCode.trim().isEmpty
                ? null
                : sourceLine.hsnCode.trim()),
            huid: drift.Value(sourceLine.huidNumber.trim().isEmpty
                ? null
                : sourceLine.huidNumber.trim()),
            quantity: const drift.Value(1),
            status: drift.Value(status),
            isActive: drift.Value(status == 'Available'),
          ),
        );
    await _createReturnedStockUnit(
      stockItemId: stockItemId,
      sku: sku,
      batchCode: voucherNo,
      sourceLine: sourceLine,
      returnLine: returnLine,
      valuation: valuation,
      status: status,
      nowMs: nowMs,
      pieceNo: 1,
    );
    return stockItemId;
  }

  Future<void> _createReturnedStockUnit({
    required int stockItemId,
    required String sku,
    required String batchCode,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required String status,
    required int nowMs,
    int? pieceNo,
  }) async {
    final resolvedPieceNo = pieceNo ?? await _nextStockUnitPieceNo(stockItemId);
    await _database.customStatement(
      '''
      INSERT INTO stock_item_units (
        stock_item_id,
        batch_code,
        unit_code,
        piece_no,
        metal_type,
        item_type,
        item_name,
        huid,
        gross_weight,
        less_weight,
        net_weight,
        purity_percent,
        actual_fine_weight,
        rate_per_gram,
        making_amount,
        unit_cost,
        status,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockItemId,
        batchCode,
        '$sku-U${resolvedPieceNo.toString().padLeft(3, '0')}',
        resolvedPieceNo,
        _metalDisplayName(sourceLine.metalType),
        'Sales Return',
        sourceLine.description,
        sourceLine.huidNumber.trim().isEmpty
            ? null
            : sourceLine.huidNumber.trim(),
        returnLine.receivedNetWeight,
        0.0,
        returnLine.receivedNetWeight,
        _purityPercent(sourceLine.purity),
        sourceLine.displayFineWeight * valuation.receivedRatio,
        sourceLine.rate,
        valuation.makingReturnedAmount,
        valuation.returnValue,
        status,
        nowMs,
        nowMs,
      ],
    );
  }

  Future<int> _nextStockUnitPieceNo(int stockItemId) async {
    final row = await _database.customSelect(
      '''
      SELECT COALESCE(MAX(piece_no), 0) + 1 AS next_piece_no
      FROM stock_item_units
      WHERE stock_item_id = ?
      ''',
      variables: [drift.Variable.withInt(stockItemId)],
    ).getSingle();
    return row.read<int>('next_piece_no');
  }

  Future<void> _postMeltingPurchaseLine({
    required String voucherNo,
    required ReturnReversalSourceDocument sourceDocument,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required ReturnReversalLineValuation valuation,
    required int nowMs,
  }) async {
    final meltingVoucherNo = 'MELT-$voucherNo';
    var row = await _database.customSelect(
      'SELECT id FROM purchase_vouchers WHERE voucher_no = ? LIMIT 1',
      variables: [drift.Variable.withString(meltingVoucherNo)],
    ).getSingleOrNull();

    if (row == null) {
      final sequence = await _nextPurchaseSequence();
      await _database.customStatement(
        '''
        INSERT INTO purchase_vouchers (
          voucher_no,
          sequence_no,
          source_type,
          customer_id,
          party_name,
          mobile,
          tax_type,
          gross_amount,
          taxable_amount,
          grand_total,
          total_paid,
          balance_due,
          payment_status,
          stock_entry_count,
          status,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          meltingVoucherNo,
          sequence,
          'CUSTOMER',
          sourceDocument.customerId,
          sourceDocument.customerName,
          sourceDocument.mobile,
          'NORMAL',
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          'RETURN_MELTING',
          0,
          'MELTING',
          nowMs,
          nowMs,
        ],
      );
      row = await _database.customSelect(
        'SELECT id FROM purchase_vouchers WHERE voucher_no = ? LIMIT 1',
        variables: [drift.Variable.withString(meltingVoucherNo)],
      ).getSingle();
    }

    final purchaseVoucherId = row.read<int>('id');
    await _database.customStatement(
      '''
      INSERT INTO purchase_voucher_items (
        purchase_voucher_id,
        line_no,
        sku,
        metal_type,
        item_description,
        gross_weight,
        less_weight,
        net_weight,
        purity,
        fine_weight,
        rate,
        quantity,
        quantity_mode,
        line_amount,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        purchaseVoucherId,
        sourceLine.lineNo,
        '$meltingVoucherNo-L${sourceLine.lineNo.toString().padLeft(3, '0')}',
        _metalDisplayName(sourceLine.metalType),
        '${sourceLine.description} | Return melting ${sourceDocument.documentNo}',
        returnLine.receivedNetWeight,
        0.0,
        returnLine.receivedNetWeight,
        _purityPercent(sourceLine.purity),
        sourceLine.displayFineWeight * valuation.receivedRatio,
        sourceLine.rate,
        sourceLine.quantity,
        sourceLine.quantityUnitCode,
        valuation.metalAmount,
        nowMs,
      ],
    );
    await _database.customStatement(
      '''
      UPDATE purchase_vouchers
      SET gross_amount = gross_amount + ?,
          taxable_amount = taxable_amount + ?,
          grand_total = grand_total + ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        valuation.metalAmount,
        valuation.metalAmount,
        valuation.metalAmount,
        nowMs,
        purchaseVoucherId,
      ],
    );
  }

  Future<void> _insertReturnStockMovement({
    required int stockItemId,
    required String movementType,
    required String voucherNo,
    required ReturnReversalSourceLineItem sourceLine,
    required ReturnReversalProcessLineInput returnLine,
    required int nowMs,
    required String reason,
  }) async {
    await _database.customStatement(
      '''
      INSERT INTO stock_movements (
        stock_item_id,
        movement_type,
        source_type,
        source_id,
        source_line_no,
        source_number,
        sku_snapshot,
        metal_type_snapshot,
        item_name_snapshot,
        quantity_delta,
        gross_weight_delta,
        net_weight_delta,
        fine_weight_delta,
        reason,
        occurred_at,
        created_at,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        stockItemId,
        movementType,
        'SALES_RETURN',
        voucherNo,
        sourceLine.lineNo,
        voucherNo,
        sourceLine.linkedStockSku.trim().isEmpty
            ? '$voucherNo-L${sourceLine.lineNo.toString().padLeft(3, '0')}'
            : sourceLine.linkedStockSku.trim(),
        _metalDisplayName(sourceLine.metalType),
        sourceLine.description,
        1,
        returnLine.receivedNetWeight,
        returnLine.receivedNetWeight,
        sourceLine.displayFineWeight *
            _valuationService
                .valueLine(sourceLine: sourceLine, returnLine: returnLine)
                .receivedRatio,
        reason,
        nowMs,
        nowMs,
        nowMs,
      ],
    );
  }

  Future<void> _applySourceStatus({
    required ReturnReversalProcessRequest request,
    required String sourceType,
    required DateTime now,
  }) async {
    final postedLineCount = await _postedLineCount(
      sourceType: sourceType,
      sourceId: request.sourceDocument.id,
    );
    final fullyProcessed =
        postedLineCount >= request.sourceDocument.lineItems.length;

    switch (request.sourceDocument.type) {
      case ReturnReversalSourceDocumentType.salesInvoice:
        final newDue = (request.sourceDocument.dueAmount -
                _valuationService.totalReturnValue(
                  sourceDocument: request.sourceDocument,
                  returnLines: request.lines,
                ))
            .clamp(0.0, double.infinity)
            .toDouble();
        await (_database.update(_database.bills)
              ..where((bill) => bill.id.equals(request.sourceDocument.id)))
            .write(
          BillsCompanion(
            dueAmount: drift.Value(_roundMoney(newDue)),
            paymentStatus: drift.Value(newDue <= 0.5 ? 'PAID' : 'PARTIAL'),
            status:
                drift.Value(fullyProcessed ? 'RETURNED' : 'PARTIALLY_RETURNED'),
            updatedAt: drift.Value(now),
          ),
        );
      case ReturnReversalSourceDocumentType.advanceBooking:
        await (_database.update(_database.salesOrders)
              ..where((order) => order.id.equals(request.sourceDocument.id)))
            .write(
          SalesOrdersCompanion(
            status: const drift.Value('CANCELLED'),
            notes: const drift.Value('Cancelled via return desk'),
            updatedAt: drift.Value(now),
          ),
        );
      case ReturnReversalSourceDocumentType.customerPurchase:
        await _database.customStatement(
          '''
          UPDATE purchase_vouchers
          SET status = ?, updated_at = ?
          WHERE id = ?
          ''',
          [
            fullyProcessed ? 'RETURNED' : 'PARTIALLY_RETURNED',
            now.millisecondsSinceEpoch,
            request.sourceDocument.id
          ],
        );
    }
  }

  Future<void> _postCustomerCreditLedger({
    required ReturnReversalProcessRequest request,
    required String voucherNo,
    required double creditAmount,
    required DateTime now,
  }) async {
    final customerId = request.sourceDocument.customerId;
    if (creditAmount <= 0.005 || customerId == null) {
      return;
    }
    await _database.into(_database.customerAccountLedger).insert(
          CustomerAccountLedgerCompanion.insert(
            customerId: customerId,
            entryType: 'CREDIT',
            sourceType: _operationTypeStorage(request.operationType),
            sourceReference: drift.Value(voucherNo),
            amount: drift.Value(creditAmount),
            paymentMode: const drift.Value('CUSTOMER_CREDIT'),
            notes: drift.Value(
              '${request.operationType.title} credit against ${request.sourceDocument.documentNo}',
            ),
            entryDate: drift.Value(now),
            isVoided: const drift.Value(false),
          ),
        );
  }

  Future<int> _postedLineCount({
    required String sourceType,
    required int sourceId,
  }) async {
    final row = await _database.customSelect(
      '''
      SELECT COUNT(*) AS line_count
      FROM return_voucher_lines
      WHERE source_type = ?
        AND source_id = ?
        AND status <> 'VOIDED'
      ''',
      variables: [
        drift.Variable.withString(sourceType),
        drift.Variable.withInt(sourceId),
      ],
    ).getSingle();
    return row.read<int>('line_count');
  }

  Future<int> _lastInsertRowId() async {
    final row = await _database
        .customSelect('SELECT last_insert_rowid() AS id')
        .getSingle();
    return row.read<int>('id');
  }

  Future<int> _nextPurchaseSequence() async {
    final row = await _database
        .customSelect(
          'SELECT COALESCE(MAX(sequence_no), 0) AS max_no FROM purchase_vouchers',
        )
        .getSingle();
    return row.read<int>('max_no') + 1;
  }

  Future<String> _nextReturnVoucherNo(
    ReturnReversalOperationType operationType,
  ) async {
    final prefix =
        operationType == ReturnReversalOperationType.salesReturn ? 'SR' : 'BC';
    final year = DateTime.now().year.toString().substring(2);
    final row = await _database
        .customSelect(
          'SELECT COALESCE(MAX(id), 0) AS max_id FROM return_vouchers',
        )
        .getSingle();
    final next = row.read<int>('max_id') + 1;
    return '$prefix-$year-${next.toString().padLeft(5, '0')}';
  }

  bool _isVoucherNoConflict(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('unique') &&
        message.contains('return_vouchers') &&
        message.contains('voucher_no');
  }

  Future<Map<int, _PostedReturnLine>> _reversalLinesFor({
    required String sourceType,
    required int sourceId,
  }) async {
    final rows = await _database.customSelect(
      '''
      SELECT
        l.source_line_no,
        l.status,
        v.voucher_no,
        l.stock_disposition,
        l.received_net_weight,
        l.metal_return_amount,
        l.making_returned_amount,
        l.line_return_value,
        l.huid_matched,
        l.unit_matched,
        l.created_at
      FROM return_voucher_lines l
      INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
      WHERE l.source_type = ?
        AND l.source_id = ?
        AND l.status <> 'VOIDED'
      ''',
      variables: [
        drift.Variable.withString(sourceType),
        drift.Variable.withInt(sourceId),
      ],
    ).get();
    return {
      for (final row in rows)
        row.read<int>('source_line_no'): _PostedReturnLine(
          status: row.readNullable<String>('status') ?? 'POSTED',
          voucherNo: row.readNullable<String>('voucher_no') ?? '',
          stockDisposition: row.readNullable<String>('stock_disposition') ?? '',
          receivedNetWeight: _readDouble(row, 'received_net_weight'),
          metalReturnAmount: _readDouble(row, 'metal_return_amount'),
          makingReturnedAmount: _readDouble(row, 'making_returned_amount'),
          lineReturnValue: _readDouble(row, 'line_return_value'),
          huidMatched: (row.readNullable<int>('huid_matched') ?? 1) == 1,
          unitMatched: (row.readNullable<int>('unit_matched') ?? 1) == 1,
          createdAt: _readDateTime(row, 'created_at'),
        ),
    };
  }

  String _documentReversalStatus({
    required int reversedLineCount,
    required int totalLineCount,
  }) {
    if (reversedLineCount <= 0) {
      return '';
    }
    return reversedLineCount >= totalLineCount ? 'RETURNED' : 'PARTIAL RETURN';
  }

  String _firstReversalVoucherNo(Map<int, _PostedReturnLine> lines) {
    for (final line in lines.values) {
      if (line.voucherNo.trim().isNotEmpty) {
        return line.voucherNo;
      }
    }
    return '';
  }

  String _sourceTypeStorage(ReturnReversalSourceDocumentType type) {
    return switch (type) {
      ReturnReversalSourceDocumentType.salesInvoice => 'SALES_INVOICE',
      ReturnReversalSourceDocumentType.advanceBooking => 'ADVANCE_BOOKING',
      ReturnReversalSourceDocumentType.customerPurchase => 'CUSTOMER_PURCHASE',
    };
  }

  String _operationTypeStorage(ReturnReversalOperationType type) {
    return switch (type) {
      ReturnReversalOperationType.salesReturn => 'SALES_RETURN',
      ReturnReversalOperationType.bookingCancellation => 'BOOKING_CANCELLATION',
    };
  }

  String _categoryForMetal(String metalType) {
    final metal = _metalDisplayName(metalType).toLowerCase();
    if (metal.contains('silver')) {
      return 'Silver Jewellery';
    }
    if (metal.contains('diamond')) {
      return 'Diamond Jewellery';
    }
    if (metal.contains('platinum')) {
      return 'Platinum Jewellery';
    }
    return 'Gold Jewellery';
  }

  String _metalDisplayName(String metalType) {
    final clean = metalType.trim();
    if (clean.isEmpty) {
      return 'Gold';
    }
    return clean
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _normalizedUnitCode({
    required String storedUnit,
    required String metalType,
    required String itemName,
  }) {
    final stored = PosItemUnitProfile.fromStorageValue(storedUnit);
    final inferred = PosItemUnitProfile.infer(
      metal: _metalTypeFromLabel(metalType),
      itemName: itemName,
    );
    if (stored != null &&
        (stored.code != PosItemUnitCode.pieces ||
            inferred.code == PosItemUnitCode.pieces)) {
      return stored.shortName;
    }
    return inferred.shortName;
  }

  MetalType _metalTypeFromLabel(String metalType) {
    final normalized = metalType.trim().toUpperCase();
    if (normalized.contains('SILVER')) {
      return MetalType.silver;
    }
    if (normalized.contains('PLATINUM')) {
      return MetalType.platinum;
    }
    if (normalized.contains('DIAMOND')) {
      return MetalType.diamond;
    }
    return MetalType.gold;
  }

  double _purityPercent(String purity) {
    final normalized = purity.trim().toUpperCase();
    if (normalized.endsWith('KT') || normalized.endsWith('K')) {
      final karat = double.tryParse(
        normalized.replaceAll('KT', '').replaceAll('K', ''),
      );
      if (karat != null && karat > 0) {
        return karat / 24 * 100;
      }
    }
    return double.tryParse(normalized) ?? 0.0;
  }

  double _roundMoney(double value) => (value * 100).roundToDouble() / 100;

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-]'), '').trim();
  }

  String _joinAddress(String? line1, String? line2, String? city) {
    return [line1, line2, city]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(', ');
  }

  DateTime _readDateTime(drift.QueryRow row, String column) {
    try {
      final value = row.readNullable<DateTime>(column);
      if (value != null) {
        return value;
      }
    } catch (_) {
      // Drift custom queries can expose date columns as epoch milliseconds.
    }
    try {
      final millis = row.readNullable<int>(column);
      if (millis != null && millis > 0) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {}
    return DateTime.now();
  }

  double _readDouble(drift.QueryRow row, String column) {
    try {
      return row.readNullable<double>(column) ?? 0;
    } catch (_) {
      return (row.readNullable<int>(column) ?? 0).toDouble();
    }
  }

  double _allocatedDiscount({
    required double lineValue,
    required double billTotal,
    required double billDiscount,
  }) {
    if (lineValue <= 0 || billTotal <= 0 || billDiscount <= 0) {
      return 0;
    }
    return billDiscount * (lineValue / billTotal);
  }
}

class _PostedReturnLine {
  final String status;
  final String voucherNo;
  final String stockDisposition;
  final double receivedNetWeight;
  final double metalReturnAmount;
  final double makingReturnedAmount;
  final double lineReturnValue;
  final bool huidMatched;
  final bool unitMatched;
  final DateTime createdAt;

  const _PostedReturnLine({
    required this.status,
    required this.voucherNo,
    required this.stockDisposition,
    required this.receivedNetWeight,
    required this.metalReturnAmount,
    required this.makingReturnedAmount,
    required this.lineReturnValue,
    required this.huidMatched,
    required this.unitMatched,
    required this.createdAt,
  });

  bool get includeMakingCharge => makingReturnedAmount > 0.005;
}
