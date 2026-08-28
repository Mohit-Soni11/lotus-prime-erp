import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/logic/purchase/customer_metal_purchase_invoice_service.dart';
import 'package:lotus_erp/models/setting/billing_setup/purchase_billing_model.dart';
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

  test('printable purchase header hides title while invoice details keep type',
      () {
    final document =
        CustomerMetalPurchaseInvoiceService.buildPrintableDocumentForTesting(
      _invoice,
      shopProfile: _profile,
      invoiceDate: DateTime(2026, 8, 23),
    );

    final labels =
        document.secondaryPanel.details.map((detail) => detail.label).toList();

    expect(labels, containsAll(['Invoice No', 'Date', 'Type']));
    expect(document.title, isEmpty);
    expect(document.subtitle, isEmpty);
  });

  test('printable purchase seller panel carries seller photo for print', () {
    final document =
        CustomerMetalPurchaseInvoiceService.buildPrintableDocumentForTesting(
      _invoiceWithSellerPhoto,
      shopProfile: _profile,
      invoiceDate: DateTime(2026, 8, 23),
    );

    expect(document.primaryPanel.photoPath, 'C:\\seller-proof.jpg');
    expect(document.primaryPanel.photoLabel, 'Seller Photo');
  });

  test('printable purchase shop header obeys business profile shop name toggle',
      () {
    final document =
        CustomerMetalPurchaseInvoiceService.buildPrintableDocumentForTesting(
      _invoice,
      shopProfile: _profileWithoutShopName,
      invoiceDate: DateTime(2026, 8, 23),
    );

    expect(document.shopProfile.primaryName, 'Anjali Jewellers');
    expect(document.shopProfile.invoiceHeaderName, isEmpty);
    expect(document.shopProfile.headerLines,
        contains('Legal Name: Anjali Jewellers'));
    expect(document.useFallbackShopName, isFalse);
  });

  test('printable purchase policies follow the scoped metal billing setup', () {
    final goldSettings = PurchaseBillingModel.defaultFor('gold').copyWith(
      sellerDeclarationText: 'Gold custom seller declaration',
      termsAndConditions: 'Gold custom terms',
      buybackPolicyText: 'Gold custom payout policy',
      returnPolicyText: 'Gold custom reclaim policy',
      footerMessage: 'Gold custom footer',
    );
    final silverSettings = PurchaseBillingModel.defaultFor('silver').copyWith(
      sellerDeclarationText: 'Silver custom seller declaration',
      termsAndConditions: 'Silver custom terms',
      buybackPolicyText: 'Silver custom payout policy',
      returnPolicyText: 'Silver custom reclaim policy',
      footerMessage: 'Silver custom footer',
    );

    final document =
        CustomerMetalPurchaseInvoiceService.buildPrintableDocumentForTesting(
      _mixedMetalInvoice,
      shopProfile: _profile,
      invoiceDate: DateTime(2026, 8, 23),
      displaySettings: {
        'gold': goldSettings,
        'silver': silverSettings,
      },
      metalScope: 'silver',
    );
    final policyCopy = document.policySections
        .map((section) => '${section.title}: ${section.body}')
        .join('\n');

    expect(document.itemTable.rows, hasLength(1));
    expect(document.itemTable.rows.single, contains('SILVER'));
    expect(policyCopy, contains('Silver custom seller declaration'));
    expect(policyCopy, contains('Silver custom terms'));
    expect(policyCopy, contains('Silver custom payout policy'));
    expect(policyCopy, contains('Silver custom reclaim policy'));
    expect(policyCopy, isNot(contains('Gold custom')));
    expect(document.footerMessage, 'Silver custom footer');
  });

  test('printable purchase display follows metal-wise billing field toggles',
      () {
    final goldSettings = PurchaseBillingModel.defaultFor('gold').copyWith(
      showGrossWeight: false,
      showLessWeight: false,
      showSupplierDetails: false,
      showPanNumber: false,
    );
    final silverSettings = PurchaseBillingModel.defaultFor('silver').copyWith(
      showGrossWeight: true,
      showLessWeight: true,
      showSupplierDetails: true,
      showPanNumber: true,
    );

    final document =
        CustomerMetalPurchaseInvoiceService.buildPrintableDocumentForTesting(
      _mixedMetalInvoice,
      shopProfile: _profile,
      invoiceDate: DateTime(2026, 8, 23),
      displaySettings: {
        'gold': goldSettings,
        'silver': silverSettings,
      },
      metalScope: 'gold',
    );

    expect(document.itemTable.rows, hasLength(1));
    expect(document.itemTable.rows.single, contains('GOLD'));
    expect(document.itemTable.headers, isNot(contains('Gross')));
    expect(document.itemTable.headers, isNot(contains('Less')));
    expect(document.itemTable.headers, containsAll(['Net', 'Purity', 'Fine']));
    expect(document.primaryPanel.details, isEmpty);

    final silverDocument =
        CustomerMetalPurchaseInvoiceService.buildPrintableDocumentForTesting(
      _mixedMetalInvoice,
      shopProfile: _profile,
      invoiceDate: DateTime(2026, 8, 23),
      displaySettings: {
        'gold': goldSettings,
        'silver': silverSettings,
      },
      metalScope: 'silver',
    );

    expect(silverDocument.itemTable.rows, hasLength(1));
    expect(silverDocument.itemTable.rows.single, contains('SILVER'));
    expect(silverDocument.itemTable.headers, containsAll(['Gross', 'Less']));
    expect(
      silverDocument.primaryPanel.details.map((detail) => detail.label),
      containsAll(['Seller Name', 'Mobile']),
    );
  });

  test('printable purchase policies obey metal-wise print visibility toggles',
      () {
    final settings = PurchaseBillingModel.defaultFor('gold').copyWith(
      printSellerDeclaration: false,
      printTermsAndConditions: false,
      printBuybackPolicy: true,
      printReturnPolicy: false,
      printFooterMessage: false,
      sellerDeclarationText: 'Hidden seller declaration',
      termsAndConditions: 'Hidden terms',
      buybackPolicyText: 'Visible payout policy',
      returnPolicyText: 'Hidden reclaim policy',
      footerMessage: 'Hidden footer',
    );

    final document =
        CustomerMetalPurchaseInvoiceService.buildPrintableDocumentForTesting(
      _invoice,
      shopProfile: _profile,
      invoiceDate: DateTime(2026, 8, 23),
      displaySettings: {'gold': settings},
      metalScope: 'gold',
    );
    final policyCopy = document.policySections
        .map((section) => '${section.title}: ${section.body}')
        .join('\n');

    expect(policyCopy, contains('Visible payout policy'));
    expect(policyCopy, isNot(contains('Hidden seller declaration')));
    expect(policyCopy, isNot(contains('Hidden terms')));
    expect(policyCopy, isNot(contains('Hidden reclaim policy')));
    expect(document.footerMessage, isEmpty);
  });

  test('scopes mixed metal invoice totals to selected metal', () {
    final scoped = _mixedMetalInvoice.scopedToMetal('silver');

    expect(scoped.lineItems, hasLength(1));
    expect(scoped.lineItems.single.metalKey, 'silver');
    expect(scoped.grossPurchaseAmount, 4000);
    expect(scoped.sellerPayable, 4000);
    expect(scoped.cashPaid, 2000);
    expect(scoped.upiPaid, 1000);
    expect(scoped.totalPaid, 3000);
    expect(scoped.balanceDue, 1000);
    expect(scoped.hasPendingSellerPayout, isTrue);
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

const _invoiceWithSellerPhoto = CustomerMetalPurchaseInvoiceData(
  purchaseNo: 'AJ-PUR-2026-0006',
  sellerName: 'Reyansh Soni',
  sellerMobile: '9304479436',
  sellerAddress: 'Patna',
  sellerPanOrAadhaar: 'ABCDE1234F',
  sellerPhotoPath: 'C:\\seller-proof.jpg',
  payoutCommitmentDate: null,
  lineItems: [
    CustomerMetalPurchaseInvoiceLine(
      metalKey: 'gold',
      metalName: 'GOLD',
      description: 'Old Gold Ring',
      grossWeight: 1,
      lessWeight: 0,
      netWeight: 1,
      purity: 100,
      fineWeight: 1,
      rate: 15000,
      totalValue: 15000,
    ),
  ],
  grossPurchaseAmount: 15000,
  sellerPayable: 15000,
  cashPaid: 15000,
  upiPaid: 0,
  cardPaid: 0,
  totalPaid: 15000,
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

const _profileWithoutShopName = ShopPrintDocumentProfile(
  tenantId: 'test-shop',
  fields: [
    ShopPrintDocumentField(
      id: 'legal_name',
      label: 'Legal Name',
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
  ],
);

const _mixedMetalInvoice = CustomerMetalPurchaseInvoiceData(
  purchaseNo: 'AJ-PUR-2026-0006',
  sellerName: 'Mixed Seller',
  sellerMobile: '9304479436',
  sellerAddress: 'Patna',
  sellerPanOrAadhaar: '',
  payoutCommitmentDate: null,
  lineItems: [
    CustomerMetalPurchaseInvoiceLine(
      metalKey: 'gold',
      metalName: 'GOLD',
      description: 'Old Gold Ring',
      grossWeight: 1,
      lessWeight: 0,
      netWeight: 1,
      purity: 100,
      fineWeight: 1,
      rate: 6000,
      totalValue: 6000,
    ),
    CustomerMetalPurchaseInvoiceLine(
      metalKey: 'silver',
      metalName: 'SILVER',
      description: 'Old Silver Anklet',
      grossWeight: 50,
      lessWeight: 0,
      netWeight: 50,
      purity: 100,
      fineWeight: 50,
      rate: 80,
      totalValue: 4000,
    ),
  ],
  grossPurchaseAmount: 10000,
  sellerPayable: 10000,
  cashPaid: 5000,
  upiPaid: 2500,
  cardPaid: 0,
  totalPaid: 7500,
  balanceDue: 2500,
  hasPendingSellerPayout: true,
  hasSellerPayoutExcess: false,
);
