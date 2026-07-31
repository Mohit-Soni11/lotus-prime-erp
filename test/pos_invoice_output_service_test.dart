import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/sales_pos/application/services/pos_invoice_output_service.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/sales_pos_models.dart';

void main() {
  group('PosInvoiceOutputService', () {
    const service = PosInvoiceOutputService();

    test('builds a clean export file name', () {
      final invoice = _invoice(
        customerName: 'Reyansh Soni & Sons',
        invoiceNumber: 'POS/001:26',
      );

      expect(
        service.buildExportFileName(invoice),
        'Reyansh_Soni_Sons_POS_001_26.pdf',
      );
    });

    test('builds WhatsApp invoice URI with Indian mobile normalization', () {
      final invoice = _invoice(
        customerName: 'Reyansh Soni',
        customerMobile: '9304479436',
        invoiceNumber: 'POS-001',
        grandTotal: 107320,
      );

      final uri = service.buildWhatsAppUri(invoice);
      final message = uri.queryParameters['text'] ?? '';

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919304479436');
      expect(message, contains('Dear Reyansh Soni,'));
      expect(
          message, contains('Thank you for shopping at *ANJALI JEWELLERS*!'));
      expect(message, contains('*Invoice No:* POS-001'));
      expect(message, contains('*Total Amount:* Rs 107320.00'));
    });

    test('uses the same professional message for invoice sharing', () {
      final invoice = _invoice(
        customerName: 'Reyansh Soni',
        invoiceNumber: 'POS-001',
        grandTotal: 107320,
      );

      final message = service.buildShareMessage(invoice);

      expect(message, contains('Dear Reyansh Soni,'));
      expect(message, contains('*Invoice No:* POS-001'));
      expect(message, contains('*Total Amount:* Rs 107320.00'));
    });

    test('keeps an international mobile number unchanged', () {
      final invoice = _invoice(customerMobile: '971501234567');

      expect(
        service.buildWhatsAppUri(invoice).path,
        '/971501234567',
      );
    });
  });
}

PosInvoiceModel _invoice({
  String customerName = 'Customer',
  String customerMobile = '9304479436',
  String invoiceNumber = 'POS-001',
  double grandTotal = 12000,
}) {
  return PosInvoiceModel(
    invoiceNumber: invoiceNumber,
    invoiceDate: DateTime(2026, 6, 26),
    billType: BillType.normal,
    billingMode: BillingMode.retail,
    shopName: 'ANJALI JEWELLERS',
    shopAddress: 'Patna',
    shopPhone: '9304479436',
    shopGstin: '',
    customerName: customerName,
    customerMobile: customerMobile,
    customerCity: 'Patna',
    customerPan: '',
    customerGstin: '',
    tradeInMode: TradeInAdjustMode.cashAdjust,
    saleItems: const <SaleItemModel>[],
    tradeInItems: const <TradeInItemModel>[],
    grossAmount: grandTotal,
    discountAmount: 0,
    taxableAmount: grandTotal,
    cgst: 0,
    sgst: 0,
    totalGst: 0,
    totalTradeInDeduction: 0,
    grandTotal: grandTotal,
    cashPaid: grandTotal,
    upiPaid: 0,
    cardPaid: 0,
    advancePaid: 0,
    balanceDue: 0,
    totalMakingCharge: 0,
  );
}
