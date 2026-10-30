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
import 'customer_media_store.dart';

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
  final CustomerMediaStore _mediaStore;

  CustomerProfileRepository({AppDatabase? db, CustomerMediaStore? mediaStore})
      : _db = db ?? AppDatabase(),
        _mediaStore = mediaStore ?? CustomerMediaStore();

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
      final fundedGirviIds = girviIds.isEmpty
          ? <int>{}
          : (await (_db.select(_db.girviDisbursements)
                    ..where((entry) => entry.girviId.isIn(girviIds)))
                  .get())
              .map((entry) => entry.girviId)
              .toSet();
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
          loan.ticketNo: _projectGirviLoan(
            loan,
            paymentsByLoan[loan.id] ?? const <GirviPayment>[],
            canEditGirvi: !loan.invoiceGenerated &&
                loan.status == 'ACTIVE' &&
                !fundedGirviIds.contains(loan.id),
          ),
      };
      final loans = loansByNumber.values.toList()..sort(_compareCustomerLoans);

      final advanceOrders = await _fetchAdvanceOrders(customerId);
      final dues = _buildDues(bills);

      return CustomerProfileModel(
        id: cust.id,
        name: cust.name,
        mobile: CustomerContactValue.displayMobile(cust.mobile),
        whatsapp: cust.whatsapp ?? "",
        city: cust.city ?? "",
        addressLine1: cust.addressLine1 ?? '',
        addressLine2: cust.addressLine2 ?? '',
        state: cust.state ?? '',
        pincode: cust.pincode ?? '',
        country: cust.country,
        type: cust.type,
        gender: CustomerGender.fromStored(cust.gender),
        createdAt: cust.createdAt,
        outstanding: outstanding,
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

  CustomerLoanModel _projectGirviLoan(
    GirviLoan loan,
    List<GirviPayment> payments, {
    required bool canEditGirvi,
  }) {
    var legacyPrincipalRepaid = 0.0;
    var releasePrincipalSettled = 0.0;
    var interestPaymentCount = 0;
    DateTime? lastInterestPaymentAt;
    for (final payment in payments) {
      final type = GirviPaymentType.fromDb(payment.paymentType);
      if (type == GirviPaymentType.partialPrincipal) {
        legacyPrincipalRepaid += payment.amount;
      } else if (type == GirviPaymentType.interest ||
          type == GirviPaymentType.partialInterest) {
        legacyPrincipalRepaid += payment.principalComponent;
        if (payment.amount > 0.005) {
          interestPaymentCount++;
          if (lastInterestPaymentAt == null ||
              payment.paymentDate.isAfter(lastInterestPaymentAt)) {
            lastInterestPaymentAt = payment.paymentDate;
          }
        }
      } else if (type == GirviPaymentType.fullRelease) {
        releasePrincipalSettled +=
            payment.principalComponent + payment.principalDiscountComponent;
      }
    }
    return CustomerLoanModel(
      id: loan.id,
      loanNo: loan.ticketNo,
      itemDesc: loan.itemDescription,
      grossWeight: loan.grossWeight,
      loanAmount: loan.loanAmount,
      originalPrincipalAmount: loan.loanAmount + legacyPrincipalRepaid,
      principalOutstandingAmount: (loan.loanAmount - releasePrincipalSettled)
          .clamp(0.0, double.infinity)
          .toDouble(),
      interestRate: loan.interestRate,
      startDate: loan.startDate,
      lastInterestPaidDate: loan.lastInterestPaidDate,
      lastInterestPaymentAt: lastInterestPaymentAt,
      interestPaymentCount: interestPaymentCount,
      isManagedGirvi: true,
      canEditGirvi: canEditGirvi,
      status: loan.status,
      recordedInterestOutstanding: _girviInterestOutstanding(loan, payments),
    );
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

  Future<CustomerDeleteResult> deleteCustomer(int customerId) async {
    try {
      final blockers = <String>[];
      final billCount = await _countCustomerRows('bills', customerId);
      final girviCount = await _countCustomerRows('girvi_loans', customerId);
      final legacyLoanCount = await _countCustomerRows('loans', customerId);
      final salesOrderCount =
          await _countCustomerRows('sales_orders', customerId);
      final refundPayableCount =
          await _countCustomerRows('customer_refund_payables', customerId);

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
      if (refundPayableCount > 0) {
        blockers.add(
          '$refundPayableCount refund payable entr${refundPayableCount == 1 ? 'y' : 'ies'}',
        );
      }

      if (blockers.isNotEmpty) {
        return CustomerDeleteResult.blocked(
          'Cannot delete this customer because linked ${blockers.join(', ')} exist. Keep the profile for audit history.',
        );
      }

      final customer = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(customerId)))
          .getSingleOrNull();
      if (customer == null) return const CustomerDeleteResult.failed();
      await (_db.delete(_db.customers)..where((t) => t.id.equals(customerId)))
          .go();
      try {
        await _mediaStore.deleteIfOwned(customer.profileImagePath);
        await _mediaStore.deleteIfOwned(customer.idProofDocPath);
      } catch (error) {
        AppLogger.error('Customer media cleanup failed: $error');
      }
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
