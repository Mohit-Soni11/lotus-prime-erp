import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/domain/services/pos_invoice_series_formatter.dart';

void main() {
  test('builds separate regular and tax invoice series from dynamic shop code',
      () {
    final shopCode = PosInvoiceSeriesFormatter.businessCode(
      'Anjali Jewellers',
    );

    expect(shopCode, 'AJ');
    expect(
      PosInvoiceSeriesFormatter.build(
        businessCode: shopCode,
        documentCode: PosInvoiceSeriesFormatter.salesInvoiceCode,
        financialYearToken: '26',
        sequence: 1,
      ),
      'AJ-SI-26-001',
    );
    expect(
      PosInvoiceSeriesFormatter.build(
        businessCode: shopCode,
        documentCode: PosInvoiceSeriesFormatter.taxInvoiceCode,
        financialYearToken: '26',
        sequence: 1,
      ),
      'AJ-TI-26-001',
    );
  });

  test('continues to parse compact historical invoice numbers as legacy', () {
    final parsed = PosInvoiceSeriesFormatter.parse('AJ-26-042');

    expect(parsed, isNotNull);
    expect(parsed!.isLegacy, isTrue);
    expect(parsed.documentCode, isNull);
    expect(parsed.sequence, 42);
  });
}
