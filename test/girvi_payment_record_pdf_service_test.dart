import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_payment_record_pdf_service.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_branding.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';

void main() {
  test('builds a branded payment record PDF with date-wise ledger rows',
      () async {
    final service = GirviPaymentRecordPdfService();
    final bytes = await service.build(
      account: _account(),
      payments: [
        GirviPaymentModel(
          id: 1,
          girviId: 1,
          paymentDate: DateTime(2026, 4, 12),
          amount: 2000,
          paymentType: GirviPaymentType.interest.dbValue,
          paymentMode: GirviPaymentMode.cash.dbValue,
          balanceAfter: 15000,
          interestComponent: 2000,
          monthsCovered: 1,
          interestFromDate: DateTime(2026, 3, 10),
          interestToDate: DateTime(2026, 4, 10),
          receiptNo: 'GIP-00001',
          notes: 'Monthly interest received',
          createdAt: DateTime(2026, 4, 12),
        ),
        GirviPaymentModel(
          id: 2,
          girviId: 1,
          paymentDate: DateTime(2026, 5, 12),
          amount: 5000,
          paymentType: GirviPaymentType.partialPrincipal.dbValue,
          paymentMode: GirviPaymentMode.upi.dbValue,
          balanceAfter: 10000,
          principalComponent: 5000,
          receiptNo: 'GIP-00002',
          createdAt: DateTime(2026, 5, 12),
        ),
      ],
      branding: const GirviInvoiceBranding(
        shopName: 'Lotus Jewellers',
        shopAddress: 'Main Road, Patna',
        shopMobile: '9876543210',
        shopGstin: '10ABCDE1234F1Z5',
      ),
    );

    expect(bytes.length, greaterThan(8000));

    final outputPath = Platform.environment['GIRVI_PAYMENT_RECORD_OUTPUT'];
    if (outputPath != null && outputPath.isNotEmpty) {
      await File(outputPath).writeAsBytes(bytes);
    }
  });

  test('builds a payment record PDF even when no payment exists', () async {
    final service = GirviPaymentRecordPdfService();
    final bytes = await service.build(
      account: _account(),
      payments: const [],
    );

    expect(bytes.length, greaterThan(6000));
  });
}

GirviLoanWithCustomer _account() {
  final startDate = DateTime(2026, 3, 10);
  return GirviLoanWithCustomer(
    loan: GirviLoanModel(
      id: 1,
      ticketNo: 'GRV-PAY-001',
      customerId: 1,
      itemDescription: 'Gold ring',
      itemCount: 1,
      metalType: 'Gold',
      metalPurity: '22K',
      grossWeight: 4,
      stoneWeight: 0,
      netWeight: 4,
      ratePerGram: 7800,
      totalValue: 31200,
      ltvPercent: 38.46,
      loanAmount: 12000,
      interestRate: 5,
      durationMonths: 12,
      disbursementMode: 'Cash',
      startDate: startDate,
      maturityDate: DateTime(2027, 3, 10),
      status: GirviStatus.active.dbValue,
      createdAt: startDate,
    ),
    customerName: 'Reyansh Soni',
    customerMobile: '9304479436',
    customerAddress: 'Patna',
    interestPaidTotal: 2000,
    principalPaidTotal: 5000,
  );
}
