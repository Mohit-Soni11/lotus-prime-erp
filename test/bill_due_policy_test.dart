import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/features/finance/due_management/domain/services/bill_due_policy.dart';

void main() {
  group('BillDuePolicy', () {
    test('treats settled payment statuses as clear', () {
      final bill = _bill(
        paymentStatus: 'PAID',
        finalAmount: 1000,
        paidAmount: 500,
        dueAmount: 500,
      );

      expect(BillDuePolicy.financeDue(bill), 0);
      expect(BillDuePolicy.customerDue(bill), 0);
      expect(BillDuePolicy.authoritativeCustomerDueSnapshot(bill), 500);
    });

    test('uses finance visibility tolerance for collection screens', () {
      final bill = _bill(
        paymentStatus: 'OPEN',
        finalAmount: 1000,
        paidAmount: 999.75,
        dueAmount: 0.25,
      );

      expect(BillDuePolicy.financeDue(bill), 0.25);
      expect(BillDuePolicy.isVisibleFinanceDue(bill), isFalse);
    });

    test('keeps customer account due precision below finance tolerance', () {
      final bill = _bill(
        paymentStatus: 'OPEN',
        finalAmount: 1000,
        paidAmount: 999.75,
        dueAmount: 0.25,
      );

      expect(BillDuePolicy.customerDue(bill), 0.25);
      expect(BillDuePolicy.isVisibleCustomerDue(bill), isTrue);
    });

    test('prefers recorded due for open payment statuses', () {
      final bill = _bill(
        paymentStatus: 'PARTIAL',
        finalAmount: 1000,
        paidAmount: 400,
        dueAmount: 250,
      );

      expect(BillDuePolicy.financeDue(bill), 250);
      expect(BillDuePolicy.customerDue(bill), 250);
    });
  });
}

Bill _bill({
  required String paymentStatus,
  required double finalAmount,
  required double paidAmount,
  required double dueAmount,
}) {
  final now = DateTime(2026, 1, 1);
  return Bill(
    id: 1,
    createdAt: now,
    billNo: 'INV-1',
    billingMode: 'STANDARD',
    billType: 'SALE',
    documentType: 'INVOICE',
    gstPricingMode: 'EXCLUSIVE',
    taxTreatment: 'TAXABLE',
    paymentStatus: paymentStatus,
    totalAmount: finalAmount,
    discount: 0,
    taxableAmount: finalAmount,
    cgstAmount: 0,
    sgstAmount: 0,
    igstAmount: 0,
    gstAmount: 0,
    gstExclusiveSalesAmount: finalAmount,
    gstInclusiveSalesAmount: finalAmount,
    outputGstLiabilitySnapshot: 0,
    makingTotal: 0,
    roundOffAmount: 0,
    finalAmount: finalAmount,
    paidAmount: paidAmount,
    cashPaid: paidAmount,
    upiPaid: 0,
    cardPaid: 0,
    advancePaid: 0,
    dueAmount: dueAmount,
    tradeInDeduction: 0,
    tradeInMode: 'NONE',
    billDate: now,
    status: 'ACTIVE',
  );
}
