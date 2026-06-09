// -----------------------------------------------------------------------------
// FILE: customer_profile_repository.dart
// MODULE: Customer -> Customer Profile
// -----------------------------------------------------------------------------

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lotus_erp/database/db/app_database.dart';

import '../../models/customer/customer_profile/customer_profile_model.dart';

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
            status: loan.status,
          ),
      };
      final loans = loansByNumber.values.toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

      final advanceOrders = await _fetchAdvanceOrders(customerId);
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
        bills: bills,
        loans: loans,
        advanceOrders: advanceOrders,
        dues: dues,
        initials: CustomerProfileModel.buildInitials(cust.name),
      );
    } catch (e) {
      debugPrint("Customer profile fetch error: $e");
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
      debugPrint("Customer bill details fetch error: $e");
      return null;
    }
  }

  Future<List<CustomerAdvanceOrderModel>> _fetchAdvanceOrders(
    int customerId,
  ) async {
    try {
      final orderRows = await (_db.select(_db.salesOrders)
            ..where((t) => t.customerId.equals(customerId))
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
      debugPrint("Customer advance orders fetch error: $e");
      return [];
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
          ),
        )
        .toList();
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
      debugPrint("Customer update error: $e");
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
      debugPrint("Customer credit limit save error: $e");
      return false;
    }
  }

  Future<bool> deleteCustomer(int customerId) async {
    try {
      await (_db.delete(_db.customers)..where((t) => t.id.equals(customerId)))
          .go();
      return true;
    } catch (e) {
      debugPrint("Customer delete error: $e");
      return false;
    }
  }
}
