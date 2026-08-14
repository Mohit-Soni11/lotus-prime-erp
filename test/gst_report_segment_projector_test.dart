import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/reports/gst_report/application/gst_report_segment_projector.dart';
import 'package:lotus_erp/features/reports/gst_report/domain/gst_report_models.dart';

void main() {
  test('project keeps B2B and B2C GST workspaces isolated', () {
    final period = GstReportPeriod.forMonth(DateTime(2026, 8));
    final snapshot = GstReportSnapshot(
      period: period,
      identity: const GstReportShopIdentity(gstin: '10ABCDE1234F1Z5'),
      dashboard: const GstReportDashboardSummary(
        totalInvoices: 3,
        gstInvoiceCount: 2,
        nonGstInvoiceCount: 1,
        taxableSales: 11200,
        cgstAmount: 150,
        sgstAmount: 150,
        igstAmount: 36,
        totalGst: 336,
        nonGstSalesEstimate: 5000,
      ),
      gstr1B2bInvoices: [
        _invoice(
          billId: 1,
          invoiceNo: 'TAX-B2B-1',
          customerGstin: '10AAAAA0000A1Z5',
          taxableAmount: 10000,
          cgstAmount: 150,
          sgstAmount: 150,
          gstAmount: 300,
          invoiceValue: 10300,
        ),
      ],
      gstr1B2cInvoices: [
        _invoice(
          billId: 2,
          invoiceNo: 'TAX-B2C-1',
          customerGstin: '',
          taxableAmount: 1200,
          igstAmount: 36,
          gstAmount: 36,
          invoiceValue: 1236,
        ),
      ],
      hsnSummary: const [
        GstHsnSummaryRow(
          hsnCode: '7113',
          description: 'Jewellery',
          gstRate: 3,
          invoiceType: 'B2B',
          invoiceCount: 1,
          lineCount: 1,
          quantity: 2,
          taxableAmount: 10000,
          cgstAmount: 150,
          sgstAmount: 150,
          igstAmount: 0,
          gstAmount: 300,
          invoiceValue: 10300,
        ),
        GstHsnSummaryRow(
          hsnCode: '7113',
          description: 'Jewellery',
          gstRate: 3,
          invoiceType: 'B2C',
          invoiceCount: 1,
          lineCount: 1,
          quantity: 1,
          taxableAmount: 1200,
          cgstAmount: 0,
          sgstAmount: 0,
          igstAmount: 36,
          gstAmount: 36,
          invoiceValue: 1236,
        ),
      ],
      rateSummary: const [],
      gstr3b: const Gstr3bSummary(),
      auditFindings: const [
        GstAuditFinding(
          severity: GstAuditSeverity.warning,
          title: 'Place of Supply Missing',
          message: 'Set place of supply.',
          invoiceNo: 'TAX-B2C-1',
        ),
      ],
    );

    final b2b = GstReportSegmentProjector.project(
      snapshot,
      GstFilingSegment.b2b,
    );
    final b2c = GstReportSegmentProjector.project(
      snapshot,
      GstFilingSegment.b2c,
    );

    expect(b2b.gstr1B2bInvoices, hasLength(1));
    expect(b2b.gstr1B2cInvoices, isEmpty);
    expect(b2b.dashboard.taxableSales, 10000);
    expect(b2b.dashboard.totalGst, 300);
    expect(b2b.dashboard.nonGstSalesEstimate, 0);
    expect(b2b.hsnSummary.single.invoiceType, 'B2B');
    expect(b2b.auditFindings.single.severity, GstAuditSeverity.info);

    expect(b2c.gstr1B2bInvoices, isEmpty);
    expect(b2c.gstr1B2cInvoices, hasLength(1));
    expect(b2c.dashboard.taxableSales, 1200);
    expect(b2c.dashboard.totalGst, 36);
    expect(b2c.dashboard.nonGstSalesEstimate, 5000);
    expect(b2c.hsnSummary.single.invoiceType, 'B2C');
    expect(b2c.auditFindings.single.invoiceNo, 'TAX-B2C-1');
  });
}

GstInvoiceRow _invoice({
  required int billId,
  required String invoiceNo,
  required String customerGstin,
  required double taxableAmount,
  double cgstAmount = 0,
  double sgstAmount = 0,
  double igstAmount = 0,
  required double gstAmount,
  required double invoiceValue,
}) {
  return GstInvoiceRow(
    billId: billId,
    invoiceNo: invoiceNo,
    invoiceDate: DateTime(2026, 8, billId),
    customerName: customerGstin.isEmpty ? 'Walk-in Customer' : 'Soni Traders',
    customerGstin: customerGstin,
    placeOfSupply: 'Bihar',
    billType: 'GST',
    taxableAmount: taxableAmount,
    cgstAmount: cgstAmount,
    sgstAmount: sgstAmount,
    igstAmount: igstAmount,
    gstAmount: gstAmount,
    roundOffAmount: 0,
    invoiceValue: invoiceValue,
    isGst: true,
  );
}
