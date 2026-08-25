import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/logic/purchase/customer_metal_purchase_invoice_service.dart';
import 'package:lotus_erp/models/sales_orders/sales_pos_models/pos_invoice_model.dart';

void main() {
  test('builds customer metal purchase invoice PDF bytes', () async {
    final bytes =
        await CustomerMetalPurchaseInvoiceService.buildInvoiceBytesForData(
      CustomerMetalPurchaseInvoiceData(
        purchaseNo: 'AJ-PUR-2026-0004',
        sellerName: 'Reyansh Soni',
        sellerMobile: '9304479436',
        sellerAddress: 'Patna',
        sellerPanOrAadhaar: 'ABCDE1234F',
        payoutCommitmentDate: DateTime(2026, 8, 25),
        lineItems: const [
          CustomerMetalPurchaseInvoiceLine(
            metalName: 'GOLD',
            description: 'Old Gold Bangles',
            grossWeight: 10,
            lessWeight: 0.2,
            netWeight: 9.8,
            purity: 91.6,
            fineWeight: 8.977,
            rate: 6500,
            totalValue: 58350.5,
          ),
        ],
        grossPurchaseAmount: 58350.5,
        sellerPayable: 58350.5,
        cashPaid: 50000,
        upiPaid: 8350.5,
        cardPaid: 0,
        totalPaid: 58350.5,
        balanceDue: 0,
        hasPendingSellerPayout: false,
        hasSellerPayoutExcess: false,
      ),
      shopProfileOverride: _profile,
      invoiceDate: DateTime(2026, 8, 23),
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('builds all customer metal purchase document formats', () async {
    for (final format in PrintFormat.values) {
      final bytes =
          await CustomerMetalPurchaseInvoiceService.buildInvoiceBytesForData(
        _invoice,
        shopProfileOverride: _profile,
        invoiceDate: DateTime(2026, 8, 23),
        format: format,
      );

      expect(bytes.length, greaterThan(1000), reason: format.name);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: format.name);
    }
  });

  test('builds all customer metal purchase A4 invoice templates', () async {
    final lengths = <int>{};

    for (final template in PrintTemplateRegistry.forDocument(
      PrintTemplateDocumentType.purchaseVoucher,
    )) {
      final bytes =
          await CustomerMetalPurchaseInvoiceService.buildInvoiceBytesForData(
        _invoice,
        shopProfileOverride: _profile,
        invoiceDate: DateTime(2026, 8, 23),
        templateId: template.id,
        format: PrintFormat.a4,
      );

      lengths.add(bytes.length);
      expect(bytes.length, greaterThan(1000), reason: template.id);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: template.id);
    }

    expect(lengths.length, greaterThan(1));
  });

  test('builds purchase invoice print run with duplicate copies', () async {
    final bytes =
        await CustomerMetalPurchaseInvoiceService.buildInvoiceBytesForData(
      _invoice,
      shopProfileOverride: _profile,
      invoiceDate: DateTime(2026, 8, 23),
      copies: 2,
      includeDuplicateStamp: true,
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('rejects invoice generation without metal items', () async {
    expect(
      () => CustomerMetalPurchaseInvoiceService.buildInvoiceBytesForData(
        const CustomerMetalPurchaseInvoiceData(
          purchaseNo: 'AJ-PUR-2026-0005',
          sellerName: 'Walk-in Seller',
          sellerMobile: '',
          sellerAddress: '',
          sellerPanOrAadhaar: '',
          payoutCommitmentDate: null,
          lineItems: [],
          grossPurchaseAmount: 0,
          sellerPayable: 0,
          cashPaid: 0,
          upiPaid: 0,
          cardPaid: 0,
          totalPaid: 0,
          balanceDue: 0,
          hasPendingSellerPayout: false,
          hasSellerPayoutExcess: false,
        ),
        shopProfileOverride: _profile,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

const _invoice = CustomerMetalPurchaseInvoiceData(
  purchaseNo: 'AJ-PUR-2026-0004',
  sellerName: 'Reyansh Soni',
  sellerMobile: '9304479436',
  sellerAddress: 'Patna',
  sellerPanOrAadhaar: 'ABCDE1234F',
  payoutCommitmentDate: null,
  lineItems: [
    CustomerMetalPurchaseInvoiceLine(
      metalName: 'GOLD',
      description: 'Old Gold Bangles',
      grossWeight: 10,
      lessWeight: 0.2,
      netWeight: 9.8,
      purity: 91.6,
      fineWeight: 8.977,
      rate: 6500,
      totalValue: 58350.5,
    ),
  ],
  grossPurchaseAmount: 58350.5,
  sellerPayable: 58350.5,
  cashPaid: 50000,
  upiPaid: 8350.5,
  cardPaid: 0,
  totalPaid: 58350.5,
  balanceDue: 0,
  hasPendingSellerPayout: false,
  hasSellerPayoutExcess: false,
);

const _profile = ShopPrintDocumentProfile(
  tenantId: 'test-shop',
  fields: [
    ShopPrintDocumentField(
      id: 'shop_name',
      label: 'Shop Name',
      value: 'Anjali Jewellers',
      group: ShopPrintFieldGroup.identity,
    ),
    ShopPrintDocumentField(
      id: 'business_address',
      label: 'Business Address',
      value: 'Main Road, Patna, Bihar',
      group: ShopPrintFieldGroup.address,
    ),
    ShopPrintDocumentField(
      id: 'mobile_number',
      label: 'Business Mobile',
      value: '9304479436',
      group: ShopPrintFieldGroup.contact,
    ),
    ShopPrintDocumentField(
      id: 'gstin',
      label: 'GSTIN',
      value: '10ABCDE1234F1Z5',
      group: ShopPrintFieldGroup.statutory,
    ),
  ],
);
