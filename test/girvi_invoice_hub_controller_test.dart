import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_invoice_hub_controller.dart';
import 'package:lotus_erp/logic/girvi/girvi_invoice_pdf_service.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_draft.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_branding.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';

void main() {
  test('Girvi invoice hub generates preview and finalizes only once', () async {
    var finalizeCalls = 0;
    final controller = GirviInvoiceHubController(
      draft: _draft,
      settingsLoader: () async => GirviBillingModel.defaults.withMetalSettings(
        GirviBillingMetal.gold,
        GirviBillingModel.defaults
            .settingsForMetal(GirviBillingMetal.gold)
            .copyWith(
              showHuid: false,
              showItemPhotos: false,
            ),
      ),
      brandingLoader: () async => const GirviInvoiceBranding(
        shopName: 'Shree Balaji Jewellers',
        shopAddress: 'Main Road, Gaya, Bihar 823001',
        shopMobile: '9876543210',
      ),
      onFinalize: () async {
        finalizeCalls++;
        return true;
      },
    );
    addTearDown(controller.dispose);

    await controller.generatePreview();

    expect(controller.state, GirviInvoiceHubState.ready);
    expect(controller.pdfBytes, isNotEmpty);
    expect(controller.invoiceBranding.shopName, 'Shree Balaji Jewellers');
    expect(
      controller.invoiceBranding.contactLine,
      'Main Road, Gaya, Bihar 823001  |  Mobile: 9876543210',
    );
    expect(
      controller.presentMetals,
      [GirviBillingMetal.gold, GirviBillingMetal.silver],
    );
    expect(controller.effectiveActiveMetal, GirviBillingMetal.gold);
    expect(
      controller.getMetalCustomizationValue(
        GirviBillingMetal.gold,
        'huid',
      ),
      isFalse,
    );
    expect(
      GirviInvoicePdfService.customerItemHeaders,
      const [
        'S/N',
        'Metal',
        'Item',
        'Pcs',
        'HUID',
        'Purity',
        'Gross Wt.',
        'Less Wt.',
        'Net Wt.',
      ],
    );
    expect(
      GirviInvoicePdfService.customerItemHeaders,
      isNot(contains('Val. Purity')),
    );
    expect(
      GirviInvoicePdfService.customerItemHeaders,
      isNot(contains('Rate / g')),
    );
    expect(
      GirviInvoicePdfService.customerItemHeaders,
      isNot(contains('Value')),
    );

    await controller.setMetalCustomization(
      GirviBillingMetal.gold,
      'huid',
      true,
    );
    expect(
      controller.getMetalCustomizationValue(
        GirviBillingMetal.gold,
        'huid',
      ),
      isTrue,
    );
    await controller.setMetalCustomization(
      GirviBillingMetal.gold,
      'valuationAmount',
      true,
    );
    expect(
      controller.getMetalCustomizationValue(
        GirviBillingMetal.gold,
        'valuationAmount',
      ),
      isTrue,
    );
    expect(
      controller.getCombinedCustomizationValue('valuationAmount'),
      isFalse,
    );
    await controller.setCombinedCustomization('valuationAmount', true);
    expect(
      controller.getCombinedCustomizationValue('valuationAmount'),
      isTrue,
    );
    expect(
      controller.getMetalCustomizationValue(
        GirviBillingMetal.silver,
        'valuationAmount',
      ),
      isTrue,
    );

    await controller.setDocumentCustomization('terms', true);
    await controller.setDocumentCustomization('declaration', false);
    await controller.setDocumentCustomization('kycDetails', true);
    expect(controller.getDocumentCustomizationValue('terms'), isTrue);
    expect(
      controller.getDocumentCustomizationValue('declaration'),
      isFalse,
    );
    expect(controller.getDocumentCustomizationValue('kycDetails'), isTrue);

    controller.setActivePrintMetal(GirviBillingMetal.silver);
    expect(controller.effectiveActiveMetal, GirviBillingMetal.silver);

    await controller.switchFormat(GirviInvoiceFormat.compactA5);
    await controller.updatePrintOptions(copies: 2, duplicate: true);

    expect(controller.selectedFormat, GirviInvoiceFormat.compactA5);
    expect(controller.printCopies, 2);
    expect(controller.includeDuplicateStamp, isTrue);

    expect(await controller.finalizeIfNeeded(), isTrue);
    expect(await controller.finalizeIfNeeded(), isTrue);
    expect(finalizeCalls, 1);
  });
}

final _draft = GirviInvoiceDraft(
  ticketNo: 'GRV/2026/00001',
  createdAt: DateTime(2026, 6, 9),
  customerName: 'Test Customer',
  customerMobile: '9999999999',
  customerCity: 'Kolkata',
  items: const [
    GirviInvoiceItemDraft(
      serialNo: 1,
      metal: 'Gold',
      description: 'Gold ring',
      purity: '22K',
      pieces: 1,
      grossWeight: 8.25,
      lessWeight: 0.25,
      netWeight: 8,
      valuationPurity: '91.6%',
      fineWeight: 7.328,
      ratePerGram: 6823,
      huid: 'HUID123',
      value: 50000,
    ),
    GirviInvoiceItemDraft(
      serialNo: 2,
      metal: 'Silver',
      description: 'Silver anklet',
      purity: '925',
      pieces: 2,
      grossWeight: 102,
      lessWeight: 2,
      netWeight: 100,
      valuationPurity: '92.5%',
      fineWeight: 92.5,
      ratePerGram: 95,
      huid: '',
      value: 9500,
    ),
  ],
  totalValue: 50000,
  loanAmount: 25000,
  interestRate: 2,
  durationMonths: 12,
  startDate: DateTime(2026, 6, 9),
  maturityDate: DateTime(2027, 6, 9),
  monthlyInterest: 500,
  totalInterest: 6000,
  totalDue: 31000,
  payments: const [
    GirviInvoicePayment(label: 'Cash', amount: 10000),
    GirviInvoicePayment(label: 'UPI', amount: 15000),
  ],
  disbursementSummary: 'Cash Rs 10,000.00 + UPI Rs 15,000.00',
);
