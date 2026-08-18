import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/reports/gst_report/domain/gst_report_models.dart';
import 'package:lotus_erp/features/reports/gst_report/presentation/exports/gst_report_pdf_builder.dart';
import 'package:lotus_erp/features/reports/gst_report/presentation/exports/gst_report_portal_pack_builder.dart';

void main() {
  test('portal pack builds section-wise GSTR files for offline utility review',
      () async {
    final snapshot = GstReportSnapshot(
      period: GstReportPeriod.forMonth(DateTime(2026, 8)),
      identity: const GstReportShopIdentity(
        shopName: 'Anjali Jewellers',
        gstin: '10ABCDE1234F1Z5',
        stateCode: '10',
        stateName: 'Bihar',
      ),
      dashboard: const GstReportDashboardSummary(
        gstInvoiceCount: 2,
        taxableSales: 11000,
        cgstAmount: 150,
        sgstAmount: 150,
        igstAmount: 30,
        totalGst: 330,
        gstInvoiceValue: 11330,
      ),
      gstr1B2bInvoices: [
        GstInvoiceRow(
          billId: 1,
          invoiceNo: 'TAX-AJ-001',
          invoiceDate: DateTime(2026, 8, 6),
          customerName: 'Soni Traders',
          customerGstin: '10AAAAA0000A1Z5',
          placeOfSupply: 'Bihar',
          placeOfSupplyStateCode: '10',
          shopStateCode: '10',
          billType: 'GST',
          taxableAmount: 10000,
          cgstAmount: 150,
          sgstAmount: 150,
          igstAmount: 0,
          gstAmount: 300,
          roundOffAmount: 0,
          invoiceValue: 10300,
          isGst: true,
        ),
      ],
      gstr1B2cInvoices: [
        GstInvoiceRow(
          billId: 2,
          invoiceNo: 'INV-AJ-003',
          invoiceDate: DateTime(2026, 8, 7),
          customerName: 'Walk-in',
          customerGstin: '',
          placeOfSupply: 'Maharashtra',
          placeOfSupplyStateCode: '27',
          shopStateCode: '10',
          supplyType: 'INTER_STATE',
          billType: 'GST',
          taxableAmount: 1000,
          cgstAmount: 0,
          sgstAmount: 0,
          igstAmount: 30,
          gstAmount: 30,
          roundOffAmount: 0,
          invoiceValue: 1030,
          isGst: true,
        ),
      ],
      hsnSummary: const [
        GstHsnSummaryRow(
          hsnCode: '7113',
          description: 'Gold Jewellery',
          gstRate: 3,
          invoiceType: 'B2B',
          invoiceCount: 1,
          lineCount: 1,
          quantity: 1,
          taxableAmount: 10000,
          cgstAmount: 150,
          sgstAmount: 150,
          igstAmount: 0,
          gstAmount: 300,
          invoiceValue: 10300,
        ),
        GstHsnSummaryRow(
          hsnCode: '7113',
          description: 'Gold Jewellery',
          gstRate: 3,
          invoiceType: 'B2C',
          invoiceCount: 1,
          lineCount: 1,
          quantity: 1,
          taxableAmount: 1000,
          cgstAmount: 0,
          sgstAmount: 0,
          igstAmount: 30,
          gstAmount: 30,
          invoiceValue: 1030,
        ),
      ],
      rateSummary: const [],
      gstr3b: const Gstr3bSummary(
        outwardTaxableValue: 11000,
        outwardCgst: 150,
        outwardSgst: 150,
        outwardIgst: 30,
      ),
      auditFindings: const [],
    );

    final documents = GstReportPortalPackBuilder.documents(snapshot);

    expect(
      documents.map((doc) => doc.fileName),
      isNot(contains('00-read-me-2026-08.csv')),
    );
    expect(
      documents.map((doc) => doc.fileName),
      contains('01-gstr1-b2b-invoices-2026-08.csv'),
    );
    expect(
      documents.map((doc) => doc.fileName),
      contains('05-gstr1-hsn-b2c-table12-2026-08.csv'),
    );
    expect(
      documents.map((doc) => doc.fileName),
      isNot(contains('02-gstr1-b2cl-invoices-2026-08.csv')),
    );
    expect(
      documents.map((doc) => doc.fileName),
      contains('06-gstr1-documents-issued-2026-08.csv'),
    );

    final b2bCsv = documents
        .singleWhere((doc) => doc.fileName.startsWith('01-gstr1-b2b'))
        .contents;
    expect(b2bCsv, contains('GSTIN/UIN of Recipient'));
    expect(b2bCsv, contains('10AAAAA0000A1Z5'));
    expect(b2bCsv, contains('06-Aug-26'));
    expect(b2bCsv, contains('Regular B2B'));
    expect(b2bCsv, contains('10-Bihar'));

    final b2cCsv = documents
        .singleWhere((doc) => doc.fileName.startsWith('03-gstr1-b2cs'))
        .contents;
    expect(
      b2cCsv,
      contains(
        'Type,Place Of Supply,Rate,Applicable % of Tax Rate,Taxable Value,Cess Amount,E-Commerce GSTIN',
      ),
    );
    expect(b2cCsv, contains('OE'));

    final hsnB2cCsv = documents
        .singleWhere((doc) => doc.fileName.startsWith('05-gstr1-hsn-b2c'))
        .contents;
    expect(hsnB2cCsv, contains('Integrated Tax Amount'));
    expect(hsnB2cCsv, contains('PCS-PIECES'));
    expect(hsnB2cCsv, contains('30.00'));

    final documentsCsv = documents
        .singleWhere((doc) => doc.fileName.startsWith('06-gstr1-documents'))
        .contents;
    expect(
      documentsCsv,
      contains(
        'Nature of Document,Sr. No. From,Sr. No. To,Total Number,Cancelled',
      ),
    );
    expect(documentsCsv, contains('Invoices for outward supply'));
    expect(documentsCsv, contains('INV-AJ-003,INV-AJ-003,1,0'));
    expect(documentsCsv, contains('TAX-AJ-001,TAX-AJ-001,1,0'));
    expect(documentsCsv, isNot(contains('TAX-AJ-001,INV-AJ-003,2')));
    expect(documentsCsv, isNot(contains('Net Issued')));

    final b2cPack = GstReportPortalPackBuilder.documents(
      snapshot,
      segment: GstFilingSegment.b2c,
    );
    expect(
      b2cPack.map((doc) => doc.fileName),
      isNot(contains('01-gstr1-b2b-invoices-2026-08.csv')),
    );
    expect(
      b2cPack.map((doc) => doc.fileName),
      isNot(contains('04-gstr1-hsn-b2b-table12-2026-08.csv')),
    );
    expect(
      b2cPack.map((doc) => doc.fileName),
      contains('03-gstr1-b2cs-summary-2026-08.csv'),
    );
    expect(
      b2cPack.map((doc) => doc.fileName),
      isNot(contains('02-gstr1-b2cl-invoices-2026-08.csv')),
    );
    expect(
      b2cPack.map((doc) => doc.fileName),
      isNot(contains('06-gstr1-documents-issued-2026-08.csv')),
    );

    final b2bPack = GstReportPortalPackBuilder.documents(
      snapshot,
      segment: GstFilingSegment.b2b,
    );
    expect(
      b2bPack.map((doc) => doc.fileName),
      contains('01-gstr1-b2b-invoices-2026-08.csv'),
    );
    expect(
      b2bPack.map((doc) => doc.fileName),
      isNot(contains('03-gstr1-b2cs-summary-2026-08.csv')),
    );
    expect(
      b2bPack.map((doc) => doc.fileName),
      isNot(contains('06-gstr1-documents-issued-2026-08.csv')),
    );

    final guidePdf = await GstReportPdfBuilder.buildFilingGuide(snapshot);
    expect(String.fromCharCodes(guidePdf.take(4)), '%PDF');
  });
}
