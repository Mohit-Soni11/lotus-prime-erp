// -----------------------------------------------------------------------------
// FILE: customer_profile_repository.dart
// MODULE: Customer -> Customer Profile
// -----------------------------------------------------------------------------

import 'package:drift/drift.dart';
import 'package:lotus_erp/database/db/app_database.dart';

import '../../features/customer/domain/services/customer_contact_value.dart';
import '../../features/finance/due_management/domain/services/bill_due_policy.dart';
import '../../models/customer/customer_profile/customer_profile_model.dart';
import '../../models/girvi/girvi_enums.dart';
import '../../models/girvi/girvi_invoice_draft.dart';
import '../../models/girvi/girvi_loan_model.dart';
import '../../models/girvi/girvi_recovery_disposition.dart';
import '../girvi/girvi_interest_payment_adjustments.dart';
import 'package:lotus_erp/core/logging/app_logger.dart';

part 'customer_profile_bill_queries.dart';
part 'customer_profile_girvi_queries.dart';
part 'customer_profile_account_queries.dart';

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

class CustomerProfileRepository
    with
        _CustomerProfileBillQueries,
        _CustomerProfileGirviQueries,
        _CustomerProfileAccountQueries {
  @override
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
      final girviIds = girviRows.map((loan) => loan.id).toList();
      final girviPayments = girviIds.isEmpty
          ? <GirviPayment>[]
          : await (_db.select(_db.girviPayments)
                ..where((payment) => payment.girviId.isIn(girviIds)))
              .get();
      final paymentsByLoan = <int, List<GirviPayment>>{};
      for (final payment in girviPayments) {
        paymentsByLoan.putIfAbsent(payment.girviId, () => []).add(payment);
      }

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
            recordedInterestOutstanding: _girviInterestOutstanding(
              loan,
              paymentsByLoan[loan.id] ?? const <GirviPayment>[],
            ),
          ),
      };
      final loans = loansByNumber.values.toList()..sort(_compareCustomerLoans);

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
        gender: CustomerGender.fromStored(cust.gender),
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
    } catch (error, stackTrace) {
      AppLogger.error(
        'Customer profile fetch failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  int _compareCustomerLoans(CustomerLoanModel a, CustomerLoanModel b) {
    if (a.isActive != b.isActive) return a.isActive ? -1 : 1;

    final ticketCompare =
        _ticketSerial(b.loanNo).compareTo(_ticketSerial(a.loanNo));
    if (ticketCompare != 0) return ticketCompare;

    final dateCompare = b.startDate.compareTo(a.startDate);
    if (dateCompare != 0) return dateCompare;

    return b.id.compareTo(a.id);
  }

  int _ticketSerial(String loanNo) {
    final match = RegExp(r'(\d+)$').firstMatch(loanNo.trim());
    return int.tryParse(match?.group(1) ?? '') ?? 0;
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
