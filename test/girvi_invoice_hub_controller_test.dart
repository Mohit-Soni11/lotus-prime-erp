import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:lotus_erp/features/print_templates/domain/print_template_registry.dart';
import 'package:lotus_erp/logic/girvi/girvi_invoice_document_store.dart';
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
      documentStore: _SuccessfulDocumentStore(),
    );
    addTearDown(controller.dispose);

    await controller.generatePreview();

    expect(controller.state, GirviInvoiceHubState.ready);
    expect(controller.pdfBytes, isNotEmpty);
    expect(_draft.displayCustomerAddress, '--');
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
        'S.No',
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

    await controller.switchTemplate(PrintTemplateRegistry.lotusSignature.id);
    expect(
      controller.selectedTemplateId,
      PrintTemplateRegistry.lotusSignature.id,
    );
    expect(
      controller.invoiceSettings.selectedTemplate,
      PrintTemplateRegistry.lotusSignature.id,
    );

    await controller.switchFormat(GirviInvoiceFormat.compactA5);
    await controller.updatePrintOptions(copies: 2, duplicate: true);

    expect(controller.selectedFormat, GirviInvoiceFormat.compactA5);
    expect(controller.printCopies, 2);
    expect(controller.includeDuplicateStamp, isTrue);

    expect(await controller.finalizeIfNeeded(), isTrue);
    expect(await controller.finalizeIfNeeded(), isTrue);
    expect(finalizeCalls, 1);
  });

  test('Girvi invoice display setup is saved for future invoices', () async {
    var savedSettings = GirviBillingModel.defaults;
    final controller = GirviInvoiceHubController(
      draft: _draft,
      settingsLoader: () async => savedSettings,
      settingsSaver: (model) async {
        savedSettings = model;
        return true;
      },
      brandingLoader: () async => const GirviInvoiceBranding(
        shopName: 'Shree Balaji Jewellers',
        shopAddress: 'Main Road, Gaya, Bihar 823001',
        shopMobile: '9876543210',
      ),
      onFinalize: () async => true,
    );
    addTearDown(controller.dispose);

    await controller.generatePreview();
    await controller.setCombinedCustomization('photos', false);
    await controller.setDocumentCustomization('declaration', false);
    await controller.switchTemplate(PrintTemplateRegistry.lotusSignature.id);

    expect(await controller.saveInvoiceDisplaySetup(), isTrue);
    expect(
      savedSettings.settingsForMetal(GirviBillingMetal.gold).showItemPhotos,
      isFalse,
    );
    expect(
      savedSettings.settingsForMetal(GirviBillingMetal.silver).showItemPhotos,
      isFalse,
    );
    expect(savedSettings.printCustomerDeclaration, isFalse);
    expect(savedSettings.selectedTemplate,
        PrintTemplateRegistry.lotusSignature.id);

    final nextController = GirviInvoiceHubController(
      draft: _draft,
      settingsLoader: () async => savedSettings,
      settingsSaver: (model) async => true,
      brandingLoader: () async => const GirviInvoiceBranding(
        shopName: 'Shree Balaji Jewellers',
        shopAddress: 'Main Road, Gaya, Bihar 823001',
        shopMobile: '9876543210',
      ),
      onFinalize: () async => true,
    );
    addTearDown(nextController.dispose);

    await nextController.generatePreview();

    expect(nextController.selectedTemplateId,
        PrintTemplateRegistry.lotusSignature.id);
    expect(nextController.getCombinedCustomizationValue('photos'), isFalse);
    expect(
      nextController.getDocumentCustomizationValue('declaration'),
      isFalse,
    );
  });

  test(
      'failed original PDF save is reported and retried without recreating loan',
      () async {
    var finalizeCalls = 0;
    final store = _FlakyDocumentStore();
    final controller = GirviInvoiceHubController(
      draft: _draft,
      documentStore: store,
      onFinalize: () async {
        finalizeCalls++;
        return true;
      },
    );
    addTearDown(controller.dispose);
    await controller.generatePreview();

    expect(await controller.finalizeIfNeeded(), isFalse);
    expect(controller.errorMessage, contains('PDF was not saved'));
    expect(await controller.finalizeIfNeeded(), isTrue);
    expect(finalizeCalls, 1);
    expect(store.attempts, 2);
  });
}

class _SuccessfulDocumentStore extends GirviInvoiceDocumentStore {
  @override
  Future<File?> saveInvoice({
    required int? loanId,
    required String ticketNo,
    required Uint8List bytes,
  }) async =>
      File('test_invoice_saved.pdf');
}

class _FlakyDocumentStore extends GirviInvoiceDocumentStore {
  int attempts = 0;

  @override
  Future<File?> saveInvoice({
    required int? loanId,
    required String ticketNo,
    required Uint8List bytes,
  }) async {
    attempts++;
    return attempts == 1 ? null : File('test_invoice_saved.pdf');
  }
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
      huid: 'HUID123',
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
      huid: '',
    ),
  ],
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
