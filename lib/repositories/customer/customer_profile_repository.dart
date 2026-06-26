// -----------------------------------------------------------------------------
// FILE: customer_profile_repository.dart
// MODULE: Customer -> Customer Profile
// -----------------------------------------------------------------------------

import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

import '../../models/customer/customer_profile/customer_profile_model.dart';
import '../../models/girvi/girvi_invoice_draft.dart';
import '../../core/logging/app_logger.dart';

class CustomerProfileRepository {
  final AppDatabase _db;

  CustomerProfileRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  Future<CustomerProfileModel?> fetchProfile(int customerId) async {
    try {
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

      final bills = billRows
          .map(
            (bill) => CustomerBillModel(
              id: bill.id,
              billNo: bill.billNo,
              totalAmount: bill.finalAmount,
              paidAmount: bill.paidAmount,
              status: bill.status,
              billDate: bill.billDate,
              sourceAdvanceOrderId: bill.sourceAdvanceOrderId,
              sourceAdvanceOrderNo: bill.sourceAdvanceOrderNo,
            ),
          )
          .toList();

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
        mobile: cust.mobile,
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
      final bill = await (_db.select(_db.bills)
            ..where(
                (t) => t.id.equals(billId) & t.customerId.equals(customerId)))
          .getSingleOrNull();
      if (bill == null) return null;

      final itemRows = await (_db.select(_db.billItems)
            ..where((t) => t.billId.equals(billId))
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get();

      final billModel = CustomerBillModel(
        id: bill.id,
        billNo: bill.billNo,
        totalAmount: bill.finalAmount,
        paidAmount: bill.paidAmount,
        status: bill.status,
        billDate: bill.billDate,
        sourceAdvanceOrderId: bill.sourceAdvanceOrderId,
        sourceAdvanceOrderNo: bill.sourceAdvanceOrderNo,
      );

      final items = itemRows
          .map(
            (item) => CustomerBillLineItemModel(
              itemName: item.itemName,
              huid: item.huid,
              purity: item.purity,
              grossWeight: item.grossWeight,
              netWeight: item.netWeight,
              rate: item.rate,
              makingCharge: item.makingCharge,
              itemTotal: item.itemTotal,
            ),
          )
          .toList();

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
        customerMobile: customer.mobile,
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

  List<CustomerDueModel> _buildDues(List<CustomerBillModel> bills) {
    return bills
        .where((bill) => !bill.isPaid && bill.dueAmount > 0)
        .map(
          (bill) => CustomerDueModel(
            billId: bill.id,
            billNo: bill.billNo,
            totalAmount: bill.totalAmount,
            paidAmount: bill.paidAmount,
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
      await (_db.update(_db.customers)..where((t) => t.id.equals(customerId)))
          .write(
        CustomersCompanion(
          name: Value(name.trim()),
          mobile: Value(mobile.trim()),
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

  Future<bool> deleteCustomer(int customerId) async {
    try {
      await (_db.delete(_db.customers)..where((t) => t.id.equals(customerId)))
          .go();
      return true;
    } catch (e) {
      AppLogger.error("Customer delete error: $e");
      return false;
    }
  }
}
