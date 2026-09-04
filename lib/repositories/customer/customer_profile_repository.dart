// -----------------------------------------------------------------------------
// FILE: customer_profile_repository.dart
// MODULE: Customer -> Customer Profile
// -----------------------------------------------------------------------------

import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

import '../../features/customer/domain/services/customer_contact_value.dart';
import '../../models/customer/customer_profile/customer_profile_model.dart';
import '../../models/girvi/girvi_invoice_draft.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

class CustomerDeleteResult {
  final bool deleted;
  final String? message;

  const CustomerDeleteResult._({
    required this.deleted,
    this.message,
  });

  const CustomerDeleteResult.success() : this._(deleted: true);

  const CustomerDeleteResult.blocked(String message)
      : this._(deleted: false, message: message);

  const CustomerDeleteResult.failed([String? message])
      : this._(
          deleted: false,
          message: message ?? 'Failed to delete customer.',
        );
}

class CustomerProfileRepository {
  final AppDatabase _db;

  CustomerProfileRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<CustomerProfileModel?> fetchProfile(int customerId) async {
    try {
      await _db.ensureReturnReversalSchema();
      final cust = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(customerId)))
          .getSingleOrNull();
      if (cust == null) return null;

      final billRows = await (_db.select(_db.bills)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.billDate, mode: OrderingMode.desc)
            ]))
          .get();

      final billIds = billRows.map((bill) => bill.id).toList(growable: false);
      final returnMarkers = await _fetchBillReturnMarkers(billIds);
      final lineCounts = await _fetchBillLineCounts(billIds);
      final linkedDocuments = await _fetchBillLinkedDocuments(billIds);
      final bills = billRows.map(
        (bill) {
          final returnMarker = returnMarkers[bill.id];
          return CustomerBillModel(
            id: bill.id,
            billNo: bill.billNo,
            totalAmount: bill.finalAmount,
            paidAmount: bill.paidAmount,
            recordedDueAmount: _authoritativeBillDueAmount(bill),
            status: bill.status,
            paymentStatus: bill.paymentStatus,
            billDate: bill.billDate,
            sourceAdvanceOrderId: bill.sourceAdvanceOrderId,
            sourceAdvanceOrderNo: bill.sourceAdvanceOrderNo,
            lineCount: lineCounts[bill.id] ?? 0,
            returnedLineCount: returnMarker?.lineCount ?? 0,
            returnedAmount: returnMarker?.amount ?? 0,
            returnVoucherNo: returnMarker?.voucherNo ?? '',
            isModified: bill.updatedAt != null,
            grossAmount: bill.totalAmount,
            discountAmount: bill.discount,
            taxableAmount: bill.taxableAmount,
            cgstAmount: bill.cgstAmount,
            sgstAmount: bill.sgstAmount,
            igstAmount: bill.igstAmount,
            gstAmount: bill.gstAmount,
            makingTotal: bill.makingTotal,
            roundOffAmount: bill.roundOffAmount,
            tradeInDeduction: bill.tradeInDeduction,
            cashPaid: bill.cashPaid,
            upiPaid: bill.upiPaid,
            cardPaid: bill.cardPaid,
            advancePaid: bill.advancePaid,
            billingMode: bill.billingMode,
            documentType: bill.documentType,
            gstPricingMode: bill.gstPricingMode,
            taxTreatment: bill.taxTreatment,
            placeOfSupply: bill.placeOfSupplySnapshot ?? '',
            linkedDocuments: linkedDocuments[bill.id] ?? const [],
          );
        },
      ).toList();

      final outstanding = bills
          .where((bill) => !bill.isPaid)
          .fold(0.0, (sum, bill) => sum + bill.dueAmount);

      final girviRows = await (_db.select(_db.girviLoans)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([
              (t) => OrderingTerm(
                    expression: t.startDate,
                    mode: OrderingMode.desc,
                  )
            ]))
          .get();

      final legacyLoanRows = await (_db.select(_db.loans)
            ..where((t) => t.customerId.equals(customerId)))
          .get();

      final loansByNumber = <String, CustomerLoanModel>{
        for (final loan in legacyLoanRows)
          loan.loanNo: CustomerLoanModel(
            id: loan.id,
            loanNo: loan.loanNo,
            itemDesc: loan.itemDesc,
            grossWeight: loan.grossWeight,
            loanAmount: loan.loanAmount,
            interestRate: loan.interestRate,
            startDate: loan.startDate,
            status: loan.status,
          ),
        for (final loan in girviRows)
          loan.ticketNo: CustomerLoanModel(
            id: loan.id,
            loanNo: loan.ticketNo,
            itemDesc: loan.itemDescription,
            grossWeight: loan.grossWeight,
            loanAmount: loan.loanAmount,
            interestRate: loan.interestRate,
            startDate: loan.startDate,
            lastInterestPaidDate: loan.lastInterestPaidDate,
            status: loan.status,
          ),
      };
      final loans = loansByNumber.values.toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

      final advanceOrders = await _fetchAdvanceOrders(customerId);
      final accountCreditBalance =
          await _fetchCustomerAccountCreditBalance(customerId);
      final dues = _buildDues(bills);

      return CustomerProfileModel(
        id: cust.id,
        name: cust.name,
        mobile: CustomerContactValue.displayMobile(cust.mobile),
        whatsapp: cust.whatsapp ?? "",
        city: cust.city ?? "",
        type: cust.type,
        createdAt: cust.createdAt,
        creditLimit: cust.creditLimit,
        outstanding: outstanding,
        accountCreditBalance: accountCreditBalance,
        bills: bills,
        loans: loans,
        advanceOrders: advanceOrders,
        dues: dues,
        initials: CustomerProfileModel.buildInitials(cust.name),
      );
    } catch (e) {
      AppLogger.error("Customer profile fetch error: $e");
      return null;
    }
  }

  Future<CustomerBillDetailModel?> fetchBillDetails({
    required int customerId,
    required int billId,
  }) async {
    try {
      await _db.ensureReturnReversalSchema();
      final bill = await (_db.select(_db.bills)
            ..where(
                (t) => t.id.equals(billId) & t.customerId.equals(customerId)))
          .getSingleOrNull();
      if (bill == null) return null;

      final itemRows = await (_db.select(_db.billItems)
            ..where((t) => t.billId.equals(billId))
            ..orderBy([(t) => OrderingTerm(expression: t.lineNo)]))
          .get();

      final returnMarkers = await _fetchBillReturnMarkers([bill.id]);
      final returnMarker = returnMarkers[bill.id];
      final linkedDocuments = await _fetchBillLinkedDocuments([bill.id]);
      final billModel = CustomerBillModel(
        id: bill.id,
        billNo: bill.billNo,
        totalAmount: bill.finalAmount,
        paidAmount: bill.paidAmount,
        recordedDueAmount: _authoritativeBillDueAmount(bill),
        status: bill.status,
        paymentStatus: bill.paymentStatus,
        billDate: bill.billDate,
        sourceAdvanceOrderId: bill.sourceAdvanceOrderId,
        sourceAdvanceOrderNo: bill.sourceAdvanceOrderNo,
        lineCount: itemRows.length,
        returnedLineCount: returnMarker?.lineCount ?? 0,
        returnedAmount: returnMarker?.amount ?? 0,
        returnVoucherNo: returnMarker?.voucherNo ?? '',
        isModified: bill.updatedAt != null,
        grossAmount: bill.totalAmount,
        discountAmount: bill.discount,
        taxableAmount: bill.taxableAmount,
        cgstAmount: bill.cgstAmount,
        sgstAmount: bill.sgstAmount,
        igstAmount: bill.igstAmount,
        gstAmount: bill.gstAmount,
        makingTotal: bill.makingTotal,
        roundOffAmount: bill.roundOffAmount,
        tradeInDeduction: bill.tradeInDeduction,
        cashPaid: bill.cashPaid,
        upiPaid: bill.upiPaid,
        cardPaid: bill.cardPaid,
        advancePaid: bill.advancePaid,
        billingMode: bill.billingMode,
        documentType: bill.documentType,
        gstPricingMode: bill.gstPricingMode,
        taxTreatment: bill.taxTreatment,
        placeOfSupply: bill.placeOfSupplySnapshot ?? '',
        linkedDocuments: linkedDocuments[bill.id] ?? const [],
      );

      final returnLineMarkers = await _fetchBillReturnLineMarkers(bill.id);
      final items = itemRows.map(
        (item) {
          final marker = returnLineMarkers[item.lineNo];
          return CustomerBillLineItemModel(
            lineNo: item.lineNo,
            metalType: item.metalType,
            itemName: item.itemName,
            hsnCode: item.hsnCode ?? '',
            huid: item.huid,
            purity: item.purity,
            quantity: item.quantity,
            quantityUnitCode: item.quantityUnitCode,
            grossWeight: item.grossWeight,
            lessWeight: item.lessWeight,
            netWeight: item.netWeight,
            rate: item.rate,
            makingChargeType: item.makingChargeType,
            makingChargeInput: item.makingChargeInput,
            makingCharge: item.makingCharge,
            itemTotal: item.itemTotal,
            taxableAmount: item.taxableAmountSnapshot,
            gstRate: item.gstRateSnapshot,
            cgstAmount: item.cgstAmountSnapshot,
            sgstAmount: item.sgstAmountSnapshot,
            igstAmount: item.igstAmountSnapshot,
            gstAmount: item.gstAmountSnapshot,
            invoiceValue: item.invoiceValueSnapshot,
            isReturned: marker != null,
            returnVoucherNo: marker?.voucherNo ?? '',
            returnedValue: marker?.amount ?? 0,
          );
        },
      ).toList();
      final existingLineNumbers = itemRows.map((item) => item.lineNo).toSet();
      items.addAll(
        await _fetchRecoveredBillItemsFromReturnLines(
          billId: bill.id,
          existingLineNumbers: existingLineNumbers,
        ),
      );
      items.sort((a, b) => a.lineNo.compareTo(b.lineNo));

      return CustomerBillDetailModel(
        bill: billModel,
        customerName: bill.customerName ?? 'Walk-in Customer',
        customerMobile: bill.mobile ?? '',
        items: items,
      );
    } catch (e) {
      AppLogger.error("Customer bill details fetch error: $e");
      return null;
    }
  }

  Future<GirviInvoiceDraft?> fetchGirviInvoiceDraft({
    required int customerId,
    required int loanId,
  }) async {
    try {
      final loan = await (_db.select(_db.girviLoans)
            ..where(
              (t) => t.id.equals(loanId) & t.customerId.equals(customerId),
            ))
          .getSingleOrNull();
      if (loan == null) return null;

      final customer = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(customerId)))
          .getSingleOrNull();
      if (customer == null) return null;

      final itemRows = await (_db.select(_db.girviLoanItems)
            ..where((t) => t.girviId.equals(loanId))
            ..orderBy([(t) => OrderingTerm(expression: t.serialNo)]))
          .get();

      final itemIds = itemRows.map((item) => item.id).toList(growable: false);
      final photoRows = itemIds.isEmpty
          ? const <GirviItemPhoto>[]
          : await (_db.select(_db.girviItemPhotos)
                ..where((t) => t.itemId.isIn(itemIds))
                ..orderBy([
                  (t) => OrderingTerm(expression: t.itemId),
                  (t) => OrderingTerm(expression: t.sortOrder),
                ]))
              .get();

      final photosByItem = <int, List<String>>{};
      for (final photo in photoRows) {
        photosByItem.putIfAbsent(photo.itemId, () => []).add(photo.filePath);
      }

      final disbursementRows = await (_db.select(_db.girviDisbursements)
            ..where((t) => t.girviId.equals(loanId))
            ..orderBy([(t) => OrderingTerm(expression: t.sequenceNo)]))
          .get();

      final monthlyInterest = loan.loanAmount * loan.interestRate / 100;
      final totalInterest = monthlyInterest * loan.durationMonths;
      final maturityDate = loan.maturityDate ??
          DateTime(
            loan.startDate.year,
            loan.startDate.month + loan.durationMonths,
            loan.startDate.day,
          );

      final payments = disbursementRows
          .map(
            (entry) => GirviInvoicePayment(
              label: entry.displayLabel,
              amount: entry.amount,
            ),
          )
          .toList(growable: false);

      final disbursementSummary = payments.isEmpty
          ? loan.disbursementMode
          : payments
              .map(
                (entry) =>
                    '${entry.label} Rs ${entry.amount.toStringAsFixed(2)}',
              )
              .join(' + ');

      return GirviInvoiceDraft(
        ticketNo: loan.ticketNo,
        createdAt: loan.createdAt,
        customerName: customer.name,
        customerMobile: CustomerContactValue.displayMobile(customer.mobile),
        customerCity: customer.city ?? '',
        customerAddress: _formatCustomerAddress(customer),
        items: itemRows
            .map(
              (item) => GirviInvoiceItemDraft(
                serialNo: item.serialNo,
                metal: item.metalType,
                description: item.itemName,
                purity: item.purity,
                pieces: item.pieces,
                grossWeight: item.grossWeight,
                lessWeight: item.lessWeight,
                netWeight: item.netWeight,
                valuationPurity:
                    item.valuationPurityPercent?.toStringAsFixed(2) ?? '',
                fineWeight: item.fineWeight,
                ratePerGram: item.ratePerGram,
                huid: item.huidNumber ?? '',
                value: item.valuationAmount,
                photoPaths:
                    List.unmodifiable(photosByItem[item.id] ?? const []),
              ),
            )
            .toList(growable: false),
        totalValue: loan.totalValue,
        loanAmount: loan.loanAmount,
        interestRate: loan.interestRate,
        durationMonths: loan.durationMonths,
        startDate: loan.startDate,
        maturityDate: maturityDate,
        monthlyInterest: monthlyInterest,
        totalInterest: totalInterest,
        totalDue: loan.loanAmount + totalInterest,
        payments: List.unmodifiable(payments),
        disbursementSummary: disbursementSummary,
        idProofType: loan.idProofType,
        idProofNumber: loan.idProofNumber,
        idProofImagePath: loan.idProofImagePath,
        notes: loan.notes,
      );
    } catch (e) {
      AppLogger.error("Customer girvi invoice draft fetch error: $e");
      return null;
    }
  }

  Future<List<CustomerAdvanceOrderModel>> _fetchAdvanceOrders(
    int customerId,
  ) async {
    try {
      final orderRows = await (_db.select(_db.salesOrders)
            ..where(
              (t) =>
                  t.customerId.equals(customerId) &
                  (t.status.equals('PENDING') | t.status.equals('READY')),
            )
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
            ]))
          .get();

      final List<CustomerAdvanceOrderModel> result = [];

      for (final order in orderRows) {
        final advances = await (_db.select(_db.orderAdvances)
              ..where((t) => t.orderId.equals(order.id)))
            .get();

        final totalAdvancePaid =
            advances.fold(0.0, (sum, advance) => sum + advance.amountPaid);

        final estimatedTotal = order.bookingType == 'LOCKED'
            ? order.approxWeight * order.lockedRate
            : 0.0;

        result.add(
          CustomerAdvanceOrderModel(
            id: order.id,
            orderNo: order.orderNo,
            itemName: order.itemName,
            metalType: order.metalType,
            purity: order.purity,
            approxWeight: order.approxWeight,
            lockedRate: order.lockedRate,
            bookingType: order.bookingType,
            status: AdvanceOrderStatus.fromString(order.status),
            deliveryDate: order.deliveryDate,
            notes: order.notes,
            totalAdvancePaid: totalAdvancePaid,
            estimatedTotal: estimatedTotal,
            createdAt: order.createdAt,
          ),
        );
      }

      return result;
    } catch (e) {
      AppLogger.error("Customer advance orders fetch error: $e");
      return [];
    }
  }

  Future<double> _fetchCustomerAccountCreditBalance(int customerId) async {
    try {
      final rows = await (_db.select(_db.customerAccountLedger)
            ..where(
              (t) => t.customerId.equals(customerId) & t.isVoided.equals(false),
            ))
          .get();

      return rows.fold<double>(0.0, (sum, entry) {
        final amount = entry.amount;
        if (entry.entryType.toUpperCase() == 'DEBIT') {
          return sum - amount;
        }
        return sum + amount;
      });
    } catch (e) {
      AppLogger.error("Customer account credit fetch error: $e");
      return 0.0;
    }
  }

  Future<Map<int, _BillReturnMarker>> _fetchBillReturnMarkers(
    List<int> billIds,
  ) async {
    if (billIds.isEmpty) {
      return const {};
    }
    try {
      final placeholders = List.filled(billIds.length, '?').join(', ');
      final rows = await _db.customSelect(
        '''
        SELECT
          l.source_id,
          COUNT(DISTINCT l.source_line_no) AS returned_line_count,
          COALESCE(SUM(l.line_return_value), 0.0) AS returned_amount,
          COALESCE(MIN(v.voucher_no), '') AS voucher_no
        FROM return_voucher_lines l
        INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
        WHERE l.source_type = 'SALES_INVOICE'
          AND l.source_id IN ($placeholders)
          AND l.status <> 'VOIDED'
          AND v.status <> 'VOIDED'
        GROUP BY l.source_id
        ''',
        variables: [
          for (final billId in billIds) Variable.withInt(billId),
        ],
      ).get();

      return {
        for (final row in rows)
          row.read<int>('source_id'): _BillReturnMarker(
            lineCount: row.read<int>('returned_line_count'),
            amount: _readDouble(row, 'returned_amount'),
            voucherNo: row.readNullable<String>('voucher_no') ?? '',
          ),
      };
    } catch (e) {
      AppLogger.error("Customer bill return marker fetch error: $e");
      return const {};
    }
  }

  Future<Map<int, int>> _fetchBillLineCounts(List<int> billIds) async {
    if (billIds.isEmpty) {
      return const {};
    }
    try {
      final placeholders = List.filled(billIds.length, '?').join(', ');
      final rows = await _db.customSelect(
        '''
        SELECT bill_id, COUNT(*) AS line_count
        FROM bill_items
        WHERE bill_id IN ($placeholders)
        GROUP BY bill_id
        ''',
        variables: [
          for (final billId in billIds) Variable.withInt(billId),
        ],
      ).get();

      return {
        for (final row in rows)
          row.read<int>('bill_id'): row.read<int>('line_count'),
      };
    } catch (e) {
      AppLogger.error("Customer bill line count fetch error: $e");
      return const {};
    }
  }

  Future<Map<int, List<CustomerLinkedDocumentModel>>> _fetchBillLinkedDocuments(
    List<int> billIds,
  ) async {
    if (billIds.isEmpty) {
      return const {};
    }
    try {
      final placeholders = List.filled(billIds.length, '?').join(', ');
      final rows = await _db.customSelect(
        '''
        SELECT
          v.source_id,
          v.id,
          v.voucher_no,
          v.operation_type,
          v.source_type,
          v.source_number,
          v.status,
          v.created_at,
          v.return_value,
          v.making_returned_amount,
          v.due_adjusted_amount,
          v.customer_credit_amount,
          COUNT(DISTINCT l.source_line_no) AS line_count,
          COALESCE(SUM(l.received_net_weight), 0.0) AS net_weight
        FROM return_vouchers v
        LEFT JOIN return_voucher_lines l
          ON l.return_voucher_id = v.id
          AND l.status <> 'VOIDED'
        WHERE v.source_type = 'SALES_INVOICE'
          AND v.source_id IN ($placeholders)
          AND v.status <> 'VOIDED'
        GROUP BY
          v.source_id,
          v.id,
          v.voucher_no,
          v.operation_type,
          v.source_type,
          v.source_number,
          v.status,
          v.created_at,
          v.return_value,
          v.making_returned_amount,
          v.due_adjusted_amount,
          v.customer_credit_amount
        ORDER BY v.created_at ASC, v.id ASC
        ''',
        variables: [
          for (final billId in billIds) Variable.withInt(billId),
        ],
      ).get();

      final result = <int, List<CustomerLinkedDocumentModel>>{};
      for (final row in rows) {
        final sourceId = row.read<int>('source_id');
        final document = CustomerLinkedDocumentModel(
          id: row.read<int>('id'),
          documentNo: row.readNullable<String>('voucher_no') ?? '',
          operationType: row.readNullable<String>('operation_type') ?? '',
          sourceType: row.readNullable<String>('source_type') ?? '',
          sourceNumber: row.readNullable<String>('source_number') ?? '',
          status: row.readNullable<String>('status') ?? '',
          createdAt: _readEpochDateTime(row, 'created_at'),
          lineCount: row.read<int>('line_count'),
          netWeight: _readDouble(row, 'net_weight'),
          returnValue: _readDouble(row, 'return_value'),
          makingReturnedAmount: _readDouble(row, 'making_returned_amount'),
          dueAdjustedAmount: _readDouble(row, 'due_adjusted_amount'),
          customerCreditAmount: _readDouble(row, 'customer_credit_amount'),
        );
        result.putIfAbsent(sourceId, () => []).add(document);
      }
      return result;
    } catch (e) {
      AppLogger.error("Customer bill linked document fetch error: $e");
      return const {};
    }
  }

  Future<Map<int, _BillReturnLineMarker>> _fetchBillReturnLineMarkers(
    int billId,
  ) async {
    try {
      final rows = await _db.customSelect(
        '''
        SELECT
          l.source_line_no,
          COALESCE(MIN(v.voucher_no), '') AS voucher_no,
          COALESCE(SUM(l.line_return_value), 0.0) AS returned_amount
        FROM return_voucher_lines l
        INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
        WHERE l.source_type = 'SALES_INVOICE'
          AND l.source_id = ?
          AND l.status <> 'VOIDED'
          AND v.status <> 'VOIDED'
        GROUP BY l.source_line_no
        ''',
        variables: [Variable.withInt(billId)],
      ).get();

      return {
        for (final row in rows)
          row.read<int>('source_line_no'): _BillReturnLineMarker(
            voucherNo: row.readNullable<String>('voucher_no') ?? '',
            amount: _readDouble(row, 'returned_amount'),
          ),
      };
    } catch (e) {
      AppLogger.error("Customer bill return line marker fetch error: $e");
      return const {};
    }
  }

  Future<List<CustomerBillLineItemModel>>
      _fetchRecoveredBillItemsFromReturnLines({
    required int billId,
    required Set<int> existingLineNumbers,
  }) async {
    try {
      final rows = await _db.customSelect(
        '''
        SELECT
          l.source_line_no,
          COALESCE(MIN(v.voucher_no), '') AS voucher_no,
          COALESCE(MAX(l.metal_type), '') AS metal_type,
          COALESCE(MAX(l.item_description), '') AS item_description,
          COALESCE(MAX(l.huid), '') AS huid,
          COALESCE(MAX(l.quantity), 1) AS quantity,
          COALESCE(MAX(l.quantity_unit_code), 'PCS') AS quantity_unit_code,
          COALESCE(MAX(l.purity), '') AS purity,
          COALESCE(MAX(l.sold_net_weight), 0.0) AS sold_net_weight,
          COALESCE(MAX(l.rate), 0.0) AS rate,
          COALESCE(MAX(l.sold_item_value), 0.0) AS sold_item_value,
          COALESCE(MAX(l.available_making_amount), 0.0) AS making_amount,
          COALESCE(SUM(l.line_return_value), 0.0) AS returned_amount
        FROM return_voucher_lines l
        INNER JOIN return_vouchers v ON v.id = l.return_voucher_id
        WHERE l.source_type = 'SALES_INVOICE'
          AND l.source_id = ?
          AND l.status <> 'VOIDED'
          AND v.status <> 'VOIDED'
        GROUP BY l.source_line_no
        ORDER BY l.source_line_no ASC
        ''',
        variables: [Variable.withInt(billId)],
      ).get();

      final recovered = <CustomerBillLineItemModel>[];
      for (final row in rows) {
        final lineNo = row.read<int>('source_line_no');
        if (existingLineNumbers.contains(lineNo)) continue;
        final itemTotal = _readDouble(row, 'sold_item_value');
        final netWeight = _readDouble(row, 'sold_net_weight');
        recovered.add(
          CustomerBillLineItemModel(
            lineNo: lineNo,
            metalType: row.readNullable<String>('metal_type') ?? 'GOLD',
            itemName:
                row.readNullable<String>('item_description') ?? 'Invoice Item',
            hsnCode: '',
            huid: row.readNullable<String>('huid'),
            purity: row.readNullable<String>('purity'),
            quantity: row.readNullable<int>('quantity') ?? 1,
            quantityUnitCode:
                row.readNullable<String>('quantity_unit_code') ?? 'PCS',
            grossWeight: netWeight,
            netWeight: netWeight,
            rate: _readDouble(row, 'rate'),
            makingCharge: _readDouble(row, 'making_amount'),
            itemTotal: itemTotal,
            invoiceValue: itemTotal,
            isReturned: true,
            returnVoucherNo: row.readNullable<String>('voucher_no') ?? '',
            returnedValue: _readDouble(row, 'returned_amount'),
          ),
        );
      }
      return recovered;
    } catch (e) {
      AppLogger.error("Recovered returned bill item fetch error: $e");
      return const [];
    }
  }

  double _readDouble(QueryRow row, String column) {
    try {
      return row.readNullable<double>(column) ?? 0;
    } catch (_) {
      return (row.readNullable<int>(column) ?? 0).toDouble();
    }
  }

  DateTime _readEpochDateTime(QueryRow row, String column) {
    final value = row.readNullable<int>(column);
    if (value == null || value <= 0) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  double? _authoritativeBillDueAmount(Bill bill) {
    final paymentStatus = bill.paymentStatus.trim().toUpperCase();
    if (bill.dueAmount > 0.005 ||
        paymentStatus == 'PAID' ||
        paymentStatus == 'SETTLED' ||
        paymentStatus == 'COMPLETE' ||
        paymentStatus == 'COMPLETED' ||
        paymentStatus == 'PARTIAL' ||
        paymentStatus == 'DUE' ||
        paymentStatus == 'UNPAID') {
      return bill.dueAmount;
    }
    return null;
  }

  List<CustomerDueModel> _buildDues(List<CustomerBillModel> bills) {
    return bills
        .where((bill) => !bill.isPaid && bill.dueAmount > 0)
        .map(
          (bill) => CustomerDueModel(
            billId: bill.id,
            billNo: bill.billNo,
            totalAmount: bill.totalAmount,
            paidAmount: bill.paidAmount,
            recordedDueAmount: bill.dueAmount,
            billDate: bill.billDate,
            sourceAdvanceOrderId: bill.sourceAdvanceOrderId,
            sourceAdvanceOrderNo: bill.sourceAdvanceOrderNo,
          ),
        )
        .toList();
  }

  String _formatCustomerAddress(Customer customer) {
    final parts = <String>[
      customer.addressLine1 ?? '',
      customer.addressLine2 ?? '',
      customer.city ?? '',
      customer.state ?? '',
      customer.pincode ?? '',
      customer.country.trim().toLowerCase() == 'india' ? '' : customer.country,
    ];
    final cleanParts = <String>[];
    for (final part in parts) {
      final value = part.trim();
      if (value.isNotEmpty && !cleanParts.contains(value)) {
        cleanParts.add(value);
      }
    }
    return cleanParts.join(', ');
  }

  Future<bool> updateCustomer({
    required int customerId,
    required String name,
    required String mobile,
    required String city,
    required String type,
    String? whatsapp,
    String? email,
    String? addressLine1,
    String? state,
    String? pincode,
  }) async {
    try {
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      var storageMobile = CustomerContactValue.storageMobile(cleanMobile);

      if (cleanMobile.isNotEmpty) {
        final duplicate = await (_db.select(_db.customers)
              ..where((row) =>
                  row.mobile.equals(cleanMobile) &
                  row.id.equals(customerId).not())
              ..limit(1))
            .getSingleOrNull();
        if (duplicate != null) return false;
      } else {
        final existing = await (_db.select(_db.customers)
              ..where((row) => row.id.equals(customerId))
              ..limit(1))
            .getSingleOrNull();
        if (existing != null &&
            CustomerContactValue.isInternalWalkInKey(existing.mobile)) {
          storageMobile = existing.mobile;
        }
      }

      await (_db.update(_db.customers)..where((t) => t.id.equals(customerId)))
          .write(
        CustomersCompanion(
          name: Value(name.trim()),
          mobile: Value(storageMobile),
          city: Value(city.trim().isEmpty ? null : city.trim()),
          type: Value(type),
          whatsapp: whatsapp != null
              ? Value(whatsapp.trim().isEmpty ? null : whatsapp.trim())
              : const Value.absent(),
          email: email != null
              ? Value(email.trim().isEmpty ? null : email.trim())
              : const Value.absent(),
          addressLine1: addressLine1 != null
              ? Value(addressLine1.trim().isEmpty ? null : addressLine1.trim())
              : const Value.absent(),
          state: state != null
              ? Value(state.trim().isEmpty ? null : state.trim())
              : const Value.absent(),
          pincode: pincode != null
              ? Value(pincode.trim().isEmpty ? null : pincode.trim())
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return true;
    } catch (e) {
      AppLogger.error("Customer update error: $e");
      return false;
    }
  }

  Future<bool> saveCreditLimit(int customerId, double limit) async {
    try {
      await (_db.update(_db.customers)..where((t) => t.id.equals(customerId)))
          .write(
        CustomersCompanion(
          creditLimit: Value(limit),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return true;
    } catch (e) {
      AppLogger.error("Customer credit limit save error: $e");
      return false;
    }
  }

  Future<CustomerDeleteResult> deleteCustomer(int customerId) async {
    try {
      final blockers = <String>[];
      final billCount = await _countCustomerRows('bills', customerId);
      final girviCount = await _countCustomerRows('girvi_loans', customerId);
      final legacyLoanCount = await _countCustomerRows('loans', customerId);
      final salesOrderCount =
          await _countCustomerRows('sales_orders', customerId);
      final accountLedgerCount =
          await _countCustomerRows('customer_account_ledger', customerId);

      if (billCount > 0) {
        blockers.add('$billCount sales invoice${billCount == 1 ? '' : 's'}');
      }
      if (girviCount > 0 || legacyLoanCount > 0) {
        final totalGirvi = girviCount + legacyLoanCount;
        blockers.add('$totalGirvi girvi ticket${totalGirvi == 1 ? '' : 's'}');
      }
      if (salesOrderCount > 0) {
        blockers.add(
          '$salesOrderCount advance order${salesOrderCount == 1 ? '' : 's'}',
        );
      }
      if (accountLedgerCount > 0) {
        blockers.add(
          '$accountLedgerCount account ledger entr${accountLedgerCount == 1 ? 'y' : 'ies'}',
        );
      }

      if (blockers.isNotEmpty) {
        return CustomerDeleteResult.blocked(
          'Cannot delete this customer because linked ${blockers.join(', ')} exist. Keep the profile for audit history.',
        );
      }

      await (_db.delete(_db.customers)..where((t) => t.id.equals(customerId)))
          .go();
      return const CustomerDeleteResult.success();
    } catch (e) {
      AppLogger.error("Customer delete error: $e");
      return const CustomerDeleteResult.failed();
    }
  }

  Future<int> _countCustomerRows(String tableName, int customerId) async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS count FROM "$tableName" WHERE "customer_id" = ?',
      variables: [Variable<int>(customerId)],
    ).getSingle();
    return result.read<int>('count');
  }
}

class _BillReturnMarker {
  final int lineCount;
  final double amount;
  final String voucherNo;

  const _BillReturnMarker({
    required this.lineCount,
    required this.amount,
    required this.voucherNo,
  });
}

class _BillReturnLineMarker {
  final String voucherNo;
  final double amount;

  const _BillReturnLineMarker({
    required this.voucherNo,
    required this.amount,
  });
}
