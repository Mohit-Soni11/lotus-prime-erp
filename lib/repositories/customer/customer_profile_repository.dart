// -----------------------------------------------------------------------------
// FILE: customer_profile_repository.dart
// MODULE: Customer → Customer Profile
// CHANGE LOG:
//   - fetchProfile: now also fetches SalesOrders + OrderAdvances + Dues
//   - Added: _fetchAdvanceOrders() — SalesOrders JOIN OrderAdvances
//   - Added: _buildDues() — derived from unpaid bills
//   - saveCreditLimit: now writes to actual creditLimit column in Customers
// -----------------------------------------------------------------------------

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import '../../models/customer/customer_profile/customer_profile_model.dart';

class CustomerProfileRepository {
  final AppDatabase _db;
  CustomerProfileRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  // ── FETCH FULL PROFILE ────────────────────────────────────────────────
  Future<CustomerProfileModel?> fetchProfile(int customerId) async {
    try {
      // 1. Customer row
      final cust = await (_db.select(_db.customers)
        ..where((t) => t.id.equals(customerId))
      ).getSingleOrNull();
      if (cust == null) return null;

      // 2. Bills — latest first
      final billRows = await (_db.select(_db.bills)
        ..where((t) => t.customerId.equals(customerId))
        ..orderBy([(t) => OrderingTerm(
            expression: t.billDate, mode: OrderingMode.desc)])
      ).get();

      final bills = billRows.map((b) => CustomerBillModel(
        id: b.id,
        billNo: b.billNo,
        totalAmount: b.finalAmount,
        paidAmount: b.paidAmount,
        status: b.status,
        billDate: b.billDate,
      )).toList();

      // 3. Outstanding = sum of non-PAID bills due amount
      final outstanding = bills
          .where((b) => !b.isPaid)
          .fold(0.0, (sum, b) => sum + b.dueAmount);

      // 4. Loans (Girvi) — latest first
      final loanRows = await (_db.select(_db.loans)
        ..where((t) => t.customerId.equals(customerId))
        ..orderBy([(t) => OrderingTerm(
            expression: t.startDate, mode: OrderingMode.desc)])
      ).get();

      final loans = loanRows.map((l) => CustomerLoanModel(
        id: l.id,
        loanNo: l.loanNo,
        itemDesc: l.itemDesc,
        grossWeight: l.grossWeight,
        loanAmount: l.loanAmount,
        interestRate: l.interestRate,
        startDate: l.startDate,
        status: l.status,
      )).toList();

      // 5. Advance Orders ✅ NEW
      final advanceOrders = await _fetchAdvanceOrders(customerId);

      // 6. Dues — derived from unpaid bills ✅ NEW
      final dues = _buildDues(bills);

      return CustomerProfileModel(
        id: cust.id,
        name: cust.name,
        mobile: cust.mobile,
        city: cust.city ?? "",
        type: cust.type ?? "Regular",
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
      debugPrint("❌ Profile fetch error: $e");
      return null;
    }
  }

  // ── FETCH ADVANCE ORDERS ─────────────────────────────────────────────  ✅ NEW
  Future<List<CustomerAdvanceOrderModel>> _fetchAdvanceOrders(
      int customerId) async {
    try {
      // Fetch sales orders for this customer (active ones)
      final orderRows = await (_db.select(_db.salesOrders)
        ..where((t) => t.customerId.equals(customerId))
        ..orderBy([(t) => OrderingTerm(
            expression: t.createdAt, mode: OrderingMode.desc)])
      ).get();

      final List<CustomerAdvanceOrderModel> result = [];

      for (final order in orderRows) {
        // For each order, sum up advance payments
        final advances = await (_db.select(_db.orderAdvances)
          ..where((t) => t.orderId.equals(order.id))
        ).get();

        final totalAdvancePaid =
            advances.fold(0.0, (sum, a) => sum + a.amountPaid);

        // Estimate total: approxWeight * lockedRate (if locked), else 0
        final estimatedTotal = order.bookingType == 'LOCKED'
            ? order.approxWeight * order.lockedRate
            : 0.0;

        result.add(CustomerAdvanceOrderModel(
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
        ));
      }

      return result;
    } catch (e) {
      debugPrint("❌ Advance orders fetch error: $e");
      return [];
    }
  }

  // ── BUILD DUES FROM UNPAID BILLS ─────────────────────────────────────  ✅ NEW
  List<CustomerDueModel> _buildDues(List<CustomerBillModel> bills) {
    return bills
        .where((b) => !b.isPaid && b.dueAmount > 0)
        .map((b) => CustomerDueModel(
              billId: b.id,
              billNo: b.billNo,
              totalAmount: b.totalAmount,
              paidAmount: b.paidAmount,
              billDate: b.billDate,
            ))
        .toList();
  }

  // ── SAVE CUSTOMER EDITS ───────────────────────────────────────────────
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
      await (_db.update(_db.customers)
        ..where((t) => t.id.equals(customerId))
      ).write(CustomersCompanion(
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
      ));
      return true;
    } catch (e) {
      debugPrint("❌ Update error: $e");
      return false;
    }
  }

  // ── SAVE CREDIT LIMIT ─────────────────────────────────────────────────
  Future<bool> saveCreditLimit(int customerId, double limit) async {
    try {
      await (_db.update(_db.customers)
        ..where((t) => t.id.equals(customerId))
      ).write(CustomersCompanion(
        creditLimit: Value(limit),
        updatedAt: Value(DateTime.now()),
      ));
      return true;
    } catch (e) {
      debugPrint("❌ Credit limit save error: $e");
      return false;
    }
  }

  // ── DELETE CUSTOMER ───────────────────────────────────────────────────
  Future<bool> deleteCustomer(int customerId) async {
    try {
      await (_db.delete(_db.customers)
        ..where((t) => t.id.equals(customerId))
      ).go();
      return true;
    } catch (e) {
      debugPrint("❌ Delete error: $e");
      return false;
    }
  }
}