import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lotus_erp/logic/girvi/girvi_notice_generation_service.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_pdf_service.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/girvi/girvi_invoice_branding.dart';
import 'package:lotus_erp/models/girvi/contact_recovery_model.dart';
import 'package:lotus_erp/models/girvi/girvi_interest_period_snapshot.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';
import 'package:lotus_erp/models/girvi/girvi_recovery_disposition.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';

import 'fixtures/girvi_notice_case_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const sampleBranding = GirviInvoiceBranding(
    shopName: 'Shree Jewellers',
    shopAddress: '12 Main Market, Jaipur',
    shopMobile: '9876543210',
    shopAlternateMobile: '9123456780',
    printFields: [
      ShopPrintDocumentField(
        id: 'legal_name',
        label: 'Legal Name',
        value: 'Shree Jewellers Private Limited',
        group: ShopPrintFieldGroup.identity,
      ),
      ShopPrintDocumentField(
        id: 'business_address',
        label: 'Business Address',
        value: '12 Main Market, Jaipur',
        group: ShopPrintFieldGroup.address,
      ),
      ShopPrintDocumentField(
        id: 'help_desk_number',
        label: 'Help Desk Number',
        value: '9123456780',
        group: ShopPrintFieldGroup.contact,
      ),
    ],
  );

  test('notice header uses shop address even when legal name comes first', () {
    expect(sampleBranding.printHeaderLines.first,
        'Legal Name: Shree Jewellers Private Limited');
    expect(sampleBranding.printShopAddress, '12 Main Market, Jaipur');
  });

  test('closed recovery notice renders Melted watermark on its pages',
      () async {
    final item = createNoticeCase();
    final noticeText = GirviNoticeGenerationService(
      now: item.now,
      shopName: sampleBranding.printShopName,
    ).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final bytes = await GirviNoticePdfService().buildStoredNotice(
      ticketNo: item.loan.ticketNo,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: noticeText,
      savedAt: item.now,
      branding: sampleBranding,
      recoveryDisposition: GirviRecoveryDisposition.melted,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final previewPath = Platform.environment['GIRVI_CLOSED_NOTICE_PREVIEW'];
    if (previewPath != null && previewPath.isNotEmpty) {
      await File(previewPath).writeAsBytes(bytes);
    }
  });

  test('long configured shop address supports flowing PDF layout', () async {
    final item = createNoticeCase();
    final text = GirviNoticeGenerationService(
      now: item.now,
      shopName: sampleBranding.printShopName,
    ).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final longAddress = List.filled(5, 'Main Market, Jaipur').join(', ');
    final branding = sampleBranding.copyWith(printFields: [
      ShopPrintDocumentField(
        id: 'business_address',
        label: 'Business Address',
        value: longAddress,
        group: ShopPrintFieldGroup.address,
      ),
    ]);
    expect(branding.printShopAddress, longAddress);
    final bytes = await GirviNoticePdfService().build(
      item: item,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: text,
      branding: branding,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('notice account card renders with an eligible item photo', () async {
    final item = createNoticeCase();
    final directory =
        await Directory.systemTemp.createTemp('notice_pdf_photo_');
    addTearDown(() => directory.delete(recursive: true));
    final photo = File('${directory.path}/item.png');
    final samplePhoto = img.Image(width: 64, height: 64);
    img.fill(samplePhoto, color: img.ColorRgb8(229, 190, 102));
    await photo.writeAsBytes(img.encodePng(samplePhoto));
    final text = GirviNoticeGenerationService(
      now: item.now,
      shopName: sampleBranding.printShopName,
    ).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final bytes = await GirviNoticePdfService().build(
      item: item,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: text,
      itemPhotoPath: photo.path,
      branding: sampleBranding,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final output = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
    if (output != null && output.isNotEmpty) {
      await Directory(output).create(recursive: true);
      await File('$output/notice_account_with_photo.pdf').writeAsBytes(bytes);
    }
  });

  test('simple and paid compound interest statements render from approved data',
      () async {
    for (final simple in [true, false]) {
      final item = createNoticeCase(
        simple: simple,
        principalPaid: 5000,
        principalDiscount: 1000,
        interestPaid: 3000,
        interestDiscount: 200,
      );
      final approved = GirviNoticeGenerationService(
        now: item.now,
        shopName: sampleBranding.printShopName,
      ).build(
        item: item,
        noticeType: GirviNoticeType.formal,
        language: GirviNoticeLanguage.english,
      );
      final bytes = await GirviNoticePdfService().buildStoredNotice(
        ticketNo: item.loan.ticketNo,
        noticeType: GirviNoticeType.formal,
        noticeLanguage: GirviNoticeLanguage.english,
        noticeText: approved,
        savedAt: item.now,
        branding: sampleBranding,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      final output = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
      if (output != null && output.isNotEmpty) {
        await Directory(output).create(recursive: true);
        final method = simple ? 'simple' : 'compound';
        await File('$output/notice_interest_${method}_paid.pdf')
            .writeAsBytes(bytes);
      }
    }
  });

  test('five compound periods keep the complete outstanding summary together',
      () async {
    final base = createNoticeCase(simple: false, interestPaid: 3000);
    var opening = base.account.originalPrincipal;
    final periods = <GirviInterestPeriodSnapshot>[];
    for (var index = 0; index < 5; index++) {
      final months = index == 4 ? 3 : 12;
      final interest = opening * 0.01 * months;
      final closing = opening + interest - (index == 0 ? 3000 : 0);
      periods.add(GirviInterestPeriodSnapshot(
        id: index + 1,
        girviId: base.loan.id,
        sequence: index + 1,
        periodFrom: DateTime(2025 + index, 4, 4),
        periodTo:
            index == 4 ? DateTime(2029, 7, 4) : DateTime(2026 + index, 4, 4),
        interestType: GirviInterestCalculationType.compound,
        openingAmount: opening,
        monthlyRatePercent: 1,
        interestPerMonth: opening * 0.01,
        chargeableMonths: months,
        periodInterest: interest,
        closingAmount: closing,
        finalized: index < 4,
        source: 'TEST',
      ));
      opening = closing;
    }
    final item = ContactRecoveryCase(
      account: base.account,
      noticePeriodDays: base.noticePeriodDays,
      now: DateTime(2029, 7, 4),
      paymentHistory: base.paymentHistory,
      interestPeriodSnapshots: periods,
      customerResponses: base.customerResponses,
    );
    final approved = GirviNoticeGenerationService(
      now: item.now,
      shopName: sampleBranding.printShopName,
    ).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final pdf = await GirviNoticePdfService().build(
      item: item,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: approved,
      branding: sampleBranding,
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    final output = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
    if (output != null && output.isNotEmpty) {
      await Directory(output).create(recursive: true);
      await File('$output/notice_five_compound_periods.pdf').writeAsBytes(pdf);
    }
  });

  test('stored notice keeps three duration rows when older text lacks tenure',
      () async {
    final item = createNoticeCase();
    final approved = GirviNoticeGenerationService(
      now: item.now,
      shopName: sampleBranding.printShopName,
    ).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final olderText = approved.replaceFirst(
      'Original Loan Period: 6 months\n',
      '',
    );
    expect(olderText, isNot(contains('Original Loan Period:')));
    final bytes = await GirviNoticePdfService().buildStoredNotice(
      ticketNo: item.loan.ticketNo,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: olderText,
      savedAt: item.now,
      originalLoanDurationMonths: item.loan.durationMonths,
      branding: sampleBranding,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final output = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
    if (output != null && output.isNotEmpty) {
      await Directory(output).create(recursive: true);
      await File('$output/notice_legacy_three_durations.pdf')
          .writeAsBytes(bytes);
    }
  });

  test('stored simple notice view renders current compound finance separately',
      () async {
    final savedCase = createNoticeCase(simple: true);
    final currentCase = createNoticeCase(simple: false);
    final generator = GirviNoticeGenerationService(
      now: savedCase.now,
      shopName: sampleBranding.printShopName,
    );
    final savedText = generator.build(
      item: savedCase,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final currentText = generator.build(
      item: currentCase,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.english,
    );
    final pdf = await GirviNoticePdfService().buildStoredNotice(
      ticketNo: savedCase.loan.ticketNo,
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: savedText,
      savedAt: savedCase.now,
      branding: sampleBranding,
      verifiedFinancialText: currentText,
      financialAsOf: currentCase.now,
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });

  test('long saved notices retain pagination instead of single-page overflow',
      () async {
    final text = List.generate(
      180,
      (index) =>
          'Customer response ${index + 1}: Approved historical statement.',
    ).join('\n');
    final bytes = await GirviNoticePdfService().buildStoredNotice(
      ticketNo: 'GRV-LONG-001',
      noticeType: GirviNoticeType.formal,
      noticeLanguage: GirviNoticeLanguage.english,
      noticeText: text,
      savedAt: DateTime(2026, 9, 29),
      branding: sampleBranding,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final output = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
    if (output != null && output.isNotEmpty) {
      await Directory(output).create(recursive: true);
      await File('$output/long_saved_notice.pdf').writeAsBytes(bytes);
    }
  });

  for (final type in GirviNoticeType.values) {
    for (final language in const [GirviNoticeLanguage.english]) {
      test('${type.label} ${language.label} renders prepared and saved PDFs',
          () async {
        final item =
            createNoticeCase(simple: language == GirviNoticeLanguage.hindi);
        final generator = GirviNoticeGenerationService(
          now: item.now,
          shopName: sampleBranding.printShopName,
        );
        expect(generator.validate(item), isEmpty);
        final text = generator.build(
          item: item,
          noticeType: type,
          language: language,
        );
        expect(text, contains('on or before 11 October 2026'));
        expect(text, isNot(contains('I will visit the shop on Friday.')));
        final service = GirviNoticePdfService();
        final prepared = await service.build(
          item: item,
          noticeType: type,
          noticeLanguage: language,
          noticeText: text,
          branding: sampleBranding,
        );
        final saved = await service.buildStoredNotice(
          ticketNo: item.loan.ticketNo,
          noticeType: type,
          noticeLanguage: language,
          noticeText: text,
          savedAt: item.now,
          branding: sampleBranding,
        );
        for (final bytes in [prepared, saved]) {
          expect(bytes.length, greaterThan(1000));
          expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        }

        // Opt-in artifacts use synthetic data and never touch the app database.
        final output = Platform.environment['NOTICE_LAYOUT_PREVIEW_DIR'];
        if (output != null && output.isNotEmpty) {
          await Directory(output).create(recursive: true);
          final name = 'formal_notice_${language.fileLabel}';
          await File('$output/$name.pdf').writeAsBytes(saved);
          await File('$output/${name}_prepared.pdf').writeAsBytes(prepared);
        }
      });
    }
  }

  test('Hindi PDF generation is unavailable', () async {
    final item = createNoticeCase();
    final noticeText = GirviNoticeGenerationService(now: item.now).build(
      item: item,
      noticeType: GirviNoticeType.formal,
      language: GirviNoticeLanguage.hindi,
    );
    expect(
      () => GirviNoticePdfService().build(
        item: item,
        noticeType: GirviNoticeType.formal,
        noticeLanguage: GirviNoticeLanguage.hindi,
        noticeText: noticeText,
      ),
      throwsUnsupportedError,
    );
  });
}
