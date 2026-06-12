import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/logic/girvi/girvi_invoice_pdf_service.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_branding.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_draft.dart';
import 'package:lotus_erp/models/setting/billing_setup/girvi_billing_model.dart';

void main() {
  test('Girvi receipt uses professional original and reissued labels', () {
    expect(
      GirviInvoicePdfService.documentCopyLabel(
        reissued: false,
        copyIndex: 0,
      ),
      'ORIGINAL BILL',
    );
    expect(
      GirviInvoicePdfService.documentCopyLabel(
        reissued: true,
        copyIndex: 0,
      ),
      'REISSUED BILL',
    );
    expect(
      GirviInvoicePdfService.documentCopyLabel(
        reissued: true,
        copyIndex: 1,
      ),
      'ADDITIONAL COPY',
    );
  });

  test('Girvi receipt detects duplicate issue and start dates', () {
    expect(
      GirviInvoicePdfService.sameCalendarDate(
        DateTime(2026, 6, 11, 9),
        DateTime(2026, 6, 11, 18),
      ),
      isTrue,
    );
    expect(
      GirviInvoicePdfService.sameCalendarDate(
        DateTime(2026, 6, 11),
        DateTime(2026, 6, 12),
      ),
      isFalse,
    );
  });

  test('Girvi bilingual terms preserve one condition per line', () {
    final rows = GirviInvoicePdfService.pairBilingualLines(
      'First English term.\nSecond English term.',
      'पहली हिंदी शर्त।\nदूसरी हिंदी शर्त।',
    );

    expect(rows, hasLength(2));
    expect(rows.first.english, 'First English term.');
    expect(rows.first.hindi, 'पहली हिंदी शर्त।');
    expect(rows.last.english, 'Second English term.');
    expect(rows.last.hindi, 'दूसरी हिंदी शर्त।');
  });

  test('Girvi customer invoice renders a populated premium layout', () async {
    final photoPath = _previewPhotoPath();
    final outputPath = Platform.environment['GIRVI_PREVIEW_OUTPUT'];
    final photos = photoPath == null ? <String>[] : [photoPath];
    final draft = GirviInvoiceDraft(
      ticketNo: 'GRV-2026-00128',
      createdAt: DateTime(2026, 6, 9),
      customerName: 'Rahul Kumar Sharma',
      customerMobile: '98765 43210',
      customerCity: 'Kolkata, West Bengal',
      customerAddress:
          '22 Park Street, Near City Market, Kolkata, West Bengal 700016',
      items: [
        GirviInvoiceItemDraft(
          serialNo: 1,
          metal: 'Gold',
          description: 'Traditional bridal necklace with pendant',
          purity: '22K',
          pieces: 1,
          grossWeight: 38.75,
          lessWeight: 2.15,
          netWeight: 36.60,
          valuationPurity: '91.60%',
          fineWeight: 33.52,
          ratePerGram: 6823,
          huid: '6H8K2P',
          value: 228700,
          photoPaths: photos,
        ),
        GirviInvoiceItemDraft(
          serialNo: 2,
          metal: 'Gold',
          description: 'Pair of designer bangles',
          purity: '22K',
          pieces: 2,
          grossWeight: 24.50,
          lessWeight: 0.80,
          netWeight: 23.70,
          valuationPurity: '91.60%',
          fineWeight: 21.71,
          ratePerGram: 6823,
          huid: '8B4M7Q',
          value: 148100,
          photoPaths: photos,
        ),
        GirviInvoiceItemDraft(
          serialNo: 3,
          metal: 'Gold',
          description: 'Ladies ring with stone setting',
          purity: '18K',
          pieces: 1,
          grossWeight: 6.35,
          lessWeight: 0.65,
          netWeight: 5.70,
          valuationPurity: '75.00%',
          fineWeight: 4.28,
          ratePerGram: 5585,
          huid: '',
          value: 23880,
          photoPaths: photos,
        ),
        const GirviInvoiceItemDraft(
          serialNo: 4,
          metal: 'Silver',
          description: 'Silver anklet pair',
          purity: '92.5',
          pieces: 2,
          grossWeight: 118.40,
          lessWeight: 1.20,
          netWeight: 117.20,
          valuationPurity: '92.50%',
          fineWeight: 108.41,
          ratePerGram: 95,
          huid: '-',
          value: 10299,
        ),
      ],
      totalValue: 410979,
      loanAmount: 250000,
      interestRate: 1.50,
      durationMonths: 12,
      startDate: DateTime(2026, 6, 9),
      maturityDate: DateTime(2027, 6, 9),
      monthlyInterest: 3750,
      totalInterest: 45000,
      totalDue: 295000,
      payments: const [
        GirviInvoicePayment(label: 'Cash', amount: 100000),
        GirviInvoicePayment(label: 'UPI', amount: 150000),
      ],
      disbursementSummary: 'Cash + UPI',
      idProofType: 'Aadhaar Card',
      idProofNumber: 'XXXX-XXXX-4182',
      idProofImagePath: photoPath,
      notes: 'Customer requested that all pledged item photos remain attached.',
    );
    final settings = GirviBillingModel.defaults
        .withMetalSettings(
          GirviBillingMetal.gold,
          GirviBillingModel.defaults
              .settingsForMetal(GirviBillingMetal.gold)
              .copyWith(
                showValuationPurity: true,
                showFineWeight: true,
                showRatePerGram: true,
                showValuationAmount: true,
              ),
        )
        .withMetalSettings(
          GirviBillingMetal.silver,
          GirviBillingModel.defaults
              .settingsForMetal(GirviBillingMetal.silver)
              .copyWith(
                showValuationPurity: true,
                showFineWeight: true,
                showRatePerGram: true,
                showValuationAmount: true,
              ),
        )
        .copyWith(
          showDuration: true,
          showStartDate: true,
          showMaturityDate: true,
          showMonthlyInterest: true,
          showTotalInterest: true,
          showTotalDue: true,
          showTotalValue: true,
          showDisbursementDetails: true,
          showKycDetails: true,
          showKycPhoto: true,
          showNotes: true,
          printTermsAndConditions: true,
          printFooterMessage: true,
          termsAndConditions:
              'Interest is charged monthly.\nKeep this receipt for release.',
          termsAndConditionsHindi:
              'ब्याज प्रति माह लिया जाएगा।\nऋण छुड़ाते समय यह रसीद साथ रखें।',
          customerDeclaration:
              'I have verified the pledged items and accepted the loan terms.',
          customerDeclarationHindi:
              'मैंने गिरवी वस्तुओं की जांच कर ली है और ऋण की शर्तें स्वीकार की हैं।',
          printCustomerDeclaration: true,
          footerMessage: 'Please keep this Girvi receipt safely.',
        );

    expect(settings.showCustomerCity, isTrue);
    final bytes = await GirviInvoicePdfService().build(
      draft: draft,
      format: GirviInvoiceFormat.a4,
      settings: settings,
      branding: GirviInvoiceBranding(
        shopName: 'Shree Balaji Jewellers',
        shopAddress: 'Main Road, Gaya, Bihar 823001',
        shopMobile: '9876543210',
        shopAlternateMobile: '9123456789',
        shopGstin: '10ABCDE1234F1Z5',
        logoPath: photoPath,
        logoShape: 'square',
      ),
    );

    expect(bytes, isNotEmpty);
    if (outputPath != null && outputPath.isNotEmpty) {
      await File(outputPath).writeAsBytes(bytes);
    }
  });

  test('Girvi invoice keeps table and photo flow stable across pages',
      () async {
    final photoPath = _previewPhotoPath();
    final outputPath = Platform.environment['GIRVI_STRESS_OUTPUT'];
    final a5OutputPath = Platform.environment['GIRVI_STRESS_A5_OUTPUT'];
    final items = List.generate(
      28,
      (index) => GirviInvoiceItemDraft(
        serialNo: index + 1,
        metal: index % 6 == 0 ? 'Silver' : 'Gold',
        description:
            'Pledged jewellery item ${index + 1} with detailed description',
        purity: index % 4 == 0 ? '18K' : '22K',
        pieces: (index % 3) + 1,
        grossWeight: 5.25 + index,
        lessWeight: 0.15 + (index % 4) * 0.10,
        netWeight: 5.10 + index - (index % 4) * 0.10,
        valuationPurity: '91.60%',
        fineWeight: 4.75 + index,
        ratePerGram: 6823,
        huid: index % 5 == 0 ? '' : 'HUID${1000 + index}',
        value: 25000 + index * 1200,
        photoPaths: photoPath != null && index < 8 ? [photoPath] : const [],
      ),
    );
    final draft = GirviInvoiceDraft(
      ticketNo: 'GRV-2026-00999',
      createdAt: DateTime(2026, 6, 9),
      customerName: 'Multipage Layout Test Customer',
      customerMobile: '99999 99999',
      customerCity: 'Kolkata, West Bengal',
      items: items,
      totalValue: 850000,
      loanAmount: 500000,
      interestRate: 1.75,
      durationMonths: 12,
      startDate: DateTime(2026, 6, 9),
      maturityDate: DateTime(2027, 6, 9),
      monthlyInterest: 8750,
      totalInterest: 105000,
      totalDue: 605000,
      payments: const [],
      disbursementSummary: '',
    );
    final service = GirviInvoicePdfService();

    final a4Bytes = await service.build(
      draft: draft,
      format: GirviInvoiceFormat.a4,
    );
    final a5Bytes = await service.build(
      draft: draft,
      format: GirviInvoiceFormat.compactA5,
    );

    expect(a4Bytes, isNotEmpty);
    expect(a5Bytes, isNotEmpty);
    expect(
      GirviInvoiceFormat.compactA5.pageFormat.width,
      greaterThan(GirviInvoiceFormat.compactA5.pageFormat.height),
    );
    if (outputPath != null && outputPath.isNotEmpty) {
      await File(outputPath).writeAsBytes(a4Bytes);
    }
    if (a5OutputPath != null && a5OutputPath.isNotEmpty) {
      await File(a5OutputPath).writeAsBytes(a5Bytes);
    }
  });

  test('Girvi final flow supports long terms, A5 and duplicate copies',
      () async {
    final photoPath = _previewPhotoPath();
    final photoPaths = photoPath == null ? <String>[] : [photoPath];
    final englishTerms = List.generate(
      10,
      (index) =>
          '${index + 1}. This condition remains readable when its text wraps '
          'across multiple lines on the printed Girvi customer receipt.',
    ).join('\n');
    final defaultHindiLines =
        GirviBillingModel.defaults.termsAndConditionsHindi.split('\n');
    final hindiTerms = List.generate(
      10,
      (index) => defaultHindiLines[index % defaultHindiLines.length],
    ).join('\n');
    final draft = GirviInvoiceDraft(
      ticketNo: 'GRV-2026-LONG',
      createdAt: DateTime(2026, 6, 11),
      customerName: 'Long Terms Layout Customer',
      customerMobile: '90000 00000',
      customerCity: 'Gaya, Bihar',
      items: List.generate(
        6,
        (index) => GirviInvoiceItemDraft(
          serialNo: index + 1,
          metal: index.isEven ? 'Gold' : 'Silver',
          description: 'Pledged jewellery item ${index + 1}',
          purity: index.isEven ? '22K' : '92.5',
          pieces: 1,
          grossWeight: 10 + index.toDouble(),
          lessWeight: 0.25,
          netWeight: 9.75 + index,
          valuationPurity: index.isEven ? '91.60%' : '92.50%',
          fineWeight: 9 + index.toDouble(),
          ratePerGram: index.isEven ? 6800 : 95,
          huid: index.isEven ? 'HUID-${index + 1}' : '-',
          value: 50000 + index * 5000,
          photoPaths: photoPaths,
        ),
      ),
      totalValue: 375000,
      loanAmount: 200000,
      interestRate: 1.5,
      durationMonths: 12,
      startDate: DateTime(2026, 6, 11),
      maturityDate: DateTime(2027, 6, 11),
      monthlyInterest: 3000,
      totalInterest: 36000,
      totalDue: 236000,
      payments: const [
        GirviInvoicePayment(label: 'Cash', amount: 100000),
        GirviInvoicePayment(label: 'UPI', amount: 100000),
      ],
      disbursementSummary: 'Cash + UPI',
      notes: 'Long-content print-flow verification.',
    );
    final settings = GirviBillingModel.defaults.copyWith(
      showNotes: true,
      printTermsAndConditions: true,
      termsAndConditions: englishTerms,
      termsAndConditionsHindi: hindiTerms,
      printCustomerDeclaration: true,
      printFooterMessage: true,
      footerMessage: 'Please keep this Girvi receipt safely.',
    );
    final service = GirviInvoicePdfService();

    final duplicateA4 = await service.build(
      draft: draft,
      format: GirviInvoiceFormat.a4,
      settings: settings,
      copies: 2,
      duplicateStamp: true,
    );
    final compactA5 = await service.build(
      draft: draft,
      format: GirviInvoiceFormat.compactA5,
      settings: settings,
    );

    expect(duplicateA4.length, greaterThan(10000));
    expect(compactA5.length, greaterThan(10000));

    final duplicateOutput =
        Platform.environment['GIRVI_DUPLICATE_PREVIEW_OUTPUT'];
    if (duplicateOutput != null && duplicateOutput.isNotEmpty) {
      await File(duplicateOutput).writeAsBytes(duplicateA4);
    }
    final compactOutput = Platform.environment['GIRVI_A5_PREVIEW_OUTPUT'];
    if (compactOutput != null && compactOutput.isNotEmpty) {
      await File(compactOutput).writeAsBytes(compactA5);
    }
  });
}

String? _previewPhotoPath() {
  final requested = Platform.environment['GIRVI_PREVIEW_PHOTO'];
  if (requested != null && File(requested).existsSync()) return requested;

  final bundledSample = File('lib/logo/gold.jpeg');
  return bundledSample.existsSync() ? bundledSample.absolute.path : null;
}
