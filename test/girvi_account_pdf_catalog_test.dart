import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/models/girvi/girvi_account_pdf_catalog.dart';
import 'package:lotus_erp/models/girvi/girvi_enums.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';

void main() {
  test('account offers the same document set as Interest Entry', () {
    expect(
      GirviAccountPdfCatalog.available(
        account: _account(GirviStatus.auctioned),
        hasFormalNotice: true,
      ),
      [GirviAccountPdfKind.documentSet, GirviAccountPdfKind.formalNotice],
    );
  });

  test('saved original invoice is available beside the current document set',
      () {
    expect(
      GirviAccountPdfCatalog.available(
        account: _account(
          GirviStatus.released,
          deliveredAt: DateTime(2026, 10, 22),
          invoiceGenerated: true,
        ),
        hasFormalNotice: false,
      ),
      [
        GirviAccountPdfKind.documentSet,
        GirviAccountPdfKind.originalInvoice,
      ],
    );
  });
}

GirviLoanWithCustomer _account(GirviStatus status,
    {DateTime? deliveredAt, bool invoiceGenerated = false}) {
  final startDate = DateTime(2026, 1, 1);
  return GirviLoanWithCustomer(
    loan: GirviLoanModel(
      id: 1,
      ticketNo: 'GRV-PDF-001',
      customerId: 1,
      itemDescription: 'Ring',
      itemCount: 1,
      metalType: 'Gold',
      metalPurity: '22K',
      grossWeight: 5,
      stoneWeight: 0,
      netWeight: 5,
      loanAmount: 1000,
      interestRate: 5,
      durationMonths: 6,
      disbursementMode: 'Cash',
      startDate: startDate,
      deliveredAt: deliveredAt,
      invoiceGenerated: invoiceGenerated,
      status: status.dbValue,
      createdAt: startDate,
    ),
    customerName: 'Test Customer',
    customerMobile: '9000000000',
  );
}
