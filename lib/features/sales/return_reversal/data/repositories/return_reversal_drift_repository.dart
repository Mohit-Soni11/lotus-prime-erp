import 'package:drift/drift.dart' as drift;

import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_operation_type.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_process.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_source_document.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/models/return_reversal_transaction_summary.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/repositories/return_reversal_repository.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/services/return_reversal_valuation_service.dart';
import 'package:lotus_erp/features/sales/return_reversal/domain/services/return_reversal_source_snapshot_policy.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_item_unit_profile.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

import 'booking_cancellation_eligibility_sql.dart';

part 'return_reversal_source_queries.dart';
part 'return_reversal_posting_guards.dart';
part 'return_reversal_stock_posting.dart';
part 'return_reversal_ledger_posting.dart';
part 'return_reversal_repository_utilities.dart';

const _maxVoucherPostAttempts = 3;
const _weightTolerance = 0.0001;
const _valuationService = ReturnReversalValuationService();
const _sourceSnapshotPolicy = ReturnReversalSourceSnapshotPolicy();

class ReturnReversalDriftRepository implements ReturnReversalRepository {
  final AppDatabase _database;

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
      WHERE $cancellableBookingPredicate
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
  Future<ReturnReversalLookupResult> findCustomerHistoryByName(
    String name,
  ) async {
    await _database.ensureReturnReversalSchema();
    final customerName = name.trim();
    if (customerName.isEmpty) {
      return const ReturnReversalLookupResult.empty();
    }

    final namePattern = _containsPattern(customerName);
    final salesInvoices = await _findSalesInvoicesByCustomerName(namePattern);
    final advanceBookings = await _findAdvanceBookingsByCustomerName(
      namePattern,
    );
    final customerPurchases = await _findCustomerPurchasesByCustomerName(
      namePattern,
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
    var refundPayableAmount = 0.0;
    var makingReturnedAmount = 0.0;

    await _database.transaction(() async {
      await _assertSourceSnapshotCurrent(request.sourceDocument);
      if (request.operationType.isBookingCancellation) {
        await _assertBookingStillCancellable(request.sourceDocument.id);
      }
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
      refundPayableAmount = _roundMoney(returnValue - dueAdjustedAmount);

      await _insertReturnVoucher(
        request: request,
        voucherNo: voucherNo,
        sourceType: sourceType,
        returnValue: returnValue,
        dueAdjustedAmount: dueAdjustedAmount,
        refundPayableAmount: refundPayableAmount,
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
      await _postRefundPayableLedger(
        request: request,
        voucherNo: voucherNo,
        payableAmount: refundPayableAmount,
        now: now,
      );
    });

    return ReturnReversalProcessResult(
      voucherId: voucherId,
      voucherNo: voucherNo,
      processedLineCount: request.lines.length,
      returnValue: returnValue,
      dueAdjustedAmount: dueAdjustedAmount,
      refundPayableAmount: refundPayableAmount,
      status: 'POSTED',
    );
  }
}
