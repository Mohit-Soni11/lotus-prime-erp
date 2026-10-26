import 'package:drift/native.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/contact_recovery_controller.dart';
import 'package:lotus_erp/models/girvi/contact_recovery_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_branding_snapshot.dart';
import 'package:lotus_erp/repositories/girvi/girvi_invoice_branding_repository.dart';
import 'package:lotus_erp/features/settings/billing_setup/shop_info/domain/shop_print_information.dart';
import 'package:lotus_erp/theme/girvi/girvi_theme.dart';
import 'package:lotus_erp/ui/girvi/contact_recovery/contact_recovery_screen.dart';

import 'fixtures/girvi_notice_case_fixture.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> showScreen(
    WidgetTester tester,
    _NoticeController controller, {
    Size viewport = const Size(1920, 1080),
    bool darkTheme = false,
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: darkTheme ? ThemeData.dark(useMaterial3: true) : null,
      home: ContactRecoveryScreen(
        initialTicketNo: controller.item.loan.ticketNo,
        controller: controller,
        brandingRepository: GirviInvoiceBrandingRepository(
          db: controller.database,
          shopSetupLoader: () async => const {
            'basic_info': {'brand_display_name': 'Test Jewellers'},
          },
          printProfileLoader: () async => ShopPrintDocumentProfile.empty,
        ),
        noticeDispatcher: (method, bytes, fileName, customerMobile) async =>
            '$method:$customerMobile',
        noticePdfBytesBuilder: () async => Uint8List.fromList([37, 80, 68, 70]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('case card remains readable on a compact window', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = _NoticeController(db, createNoticeCase());
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller, viewport: const Size(840, 900));
    expect(find.text('All Cases'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Loan Age'), findsOneWidget);
    expect(find.text('Interest Calculation Period'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a direct link without an invoice shows no account card',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = _NoticeController(db, createNoticeCase());
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await tester.pumpWidget(MaterialApp(
      home: ContactRecoveryScreen(controller: controller),
    ));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Select an invoice'), findsOneWidget);
    expect(find.text('Prepare Notice'), findsNothing);
    expect(find.text('All Cases'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one prepare action opens an English editor and sends its edits',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = _NoticeController(db, createNoticeCase(simple: false));
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller);
    expect(find.text('All Cases'), findsNothing);
    expect(find.text('Notice Queue'), findsNothing);
    expect(find.text('Net Exposure'), findsNothing);
    expect(find.text('Interest Calculation Period'), findsOneWidget);
    expect(find.text('Prepare Notice'), findsOneWidget);
    for (final retired in ['First Notice', 'Second Notice', 'Final Notice']) {
      expect(find.text(retired), findsNothing);
    }
    await tester.tap(find.text('Prepare Notice'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Formal Notice'), findsOneWidget);
    expect(find.textContaining('FINAL NOTICE: PLEDGE ACCOUNT'), findsWidgets);
    expect(find.text('Hindi'), findsNothing);
    expect(find.text('English'), findsNothing);
    await tester.tap(find.byTooltip('Edit notice text'));
    await tester.pump(const Duration(milliseconds: 350));
    final original = tester
        .widget<TextField>(
          find.byKey(const ValueKey('notice-text-editor')),
        )
        .controller!
        .text;
    final edited = '$original\nCustomer-specific English edit.';
    await tester.enterText(
        find.byKey(const ValueKey('notice-text-editor')), edited);
    await tester.tap(find.text('Send Notice'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('Download PDF'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.savedDocuments, isNotNull,
        reason: controller.inlineMessage);
    expect(controller.savedDocuments![GirviNoticeLanguage.english], edited);
    expect(controller.savedDocuments!.keys, {GirviNoticeLanguage.english});
    expect(controller.savedType, GirviNoticeType.formal);
    expect(
      GirviNoticeBrandingSnapshot.decode(controller.savedBrandingSnapshot)
          ?.printShopName,
      'Test Jewellers',
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('response days update approved notice text and saved deadline',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = _NoticeController(db, createNoticeCase(simple: false));
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller);
    await tester.tap(find.text('Prepare Notice'));
    await tester.pump(const Duration(milliseconds: 350));
    final daysField = find.byKey(const ValueKey('notice-response-days'));
    expect(tester.widget<TextField>(daysField).controller!.text, '7');
    await tester.enterText(daysField, '0');
    await tester.pump();
    expect(find.text('Enter 1 to 365 days.'), findsOneWidget);
    await tester.enterText(daysField, '14');
    await tester.pump();
    await tester.tap(find.byTooltip('Edit notice text'));
    await tester.pump(const Duration(milliseconds: 350));
    final noticeText = tester
        .widget<TextField>(
          find.byKey(const ValueKey('notice-text-editor')),
        )
        .controller!
        .text;
    expect(noticeText, contains('on or before 18 October 2026'));
    await tester.enterText(
      find.byKey(const ValueKey('notice-text-editor')),
      '$noticeText\nPlease bring the account receipt.',
    );
    await tester.enterText(daysField, '21');
    await tester.pump();
    final updatedText = tester
        .widget<TextField>(
          find.byKey(const ValueKey('notice-text-editor')),
        )
        .controller!
        .text;
    expect(updatedText, contains('on or before 25 October 2026'));
    expect(updatedText, contains('Please bring the account receipt.'));
    expect(updatedText, isNot(contains('on or before 18 October 2026')));
    await tester.tap(find.text('Send Notice'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('Download PDF'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.savedDays, 21);
    expect(
        controller.savedDocuments![GirviNoticeLanguage.english], updatedText);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notice period and action buttons stay legible in dark app theme',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = _NoticeController(db, createNoticeCase(simple: false));
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller, darkTheme: true);
    await tester.tap(find.text('Prepare Notice'));
    await tester.pump(const Duration(milliseconds: 350));
    final daysField = tester.widget<TextField>(
      find.byKey(const ValueKey('notice-response-days')),
    );
    expect(daysField.controller!.text, '7');
    expect(daysField.style!.color, GirviColors.textDark);
    final preview = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Preview PDF'),
    );
    expect(preview.style!.foregroundColor!.resolve({}), GirviColors.shellBg);
    final send = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Send Notice'),
    );
    expect(send.style!.backgroundColor!.resolve({}), GirviColors.shellBg);
    await tester.enterText(
      find.byKey(const ValueKey('notice-response-days')),
      '',
    );
    await tester.pump();
    final disabledPreview = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Preview PDF'),
    );
    expect(disabledPreview.onPressed, isNull);
    expect(
      disabledPreview.style!.foregroundColor!.resolve({WidgetState.disabled}),
      GirviColors.shellBorder,
    );
    final disabledSend = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Send Notice'),
    );
    expect(disabledSend.onPressed, isNull);
    expect(
      disabledSend.style!.foregroundColor!.resolve({WidgetState.disabled}),
      GirviColors.shellBorder,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('approved notice has one card and hides retired notice stages',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fixture = createNoticeCase();
    final approved = GirviNoticeAction(
        id: 10,
        girviId: fixture.loan.id,
        actionType: GirviNoticeActionTypes.noticePrepared,
        noticeStage: 1,
        actionAt: fixture.now,
        createdAt: fixture.now);
    final legacy = GirviNoticeAction(
        id: 2,
        girviId: fixture.loan.id,
        actionType: 'SECOND_NOTICE_PREPARED',
        noticeStage: 2,
        actionAt: fixture.now.subtract(const Duration(days: 30)),
        createdAt: fixture.now.subtract(const Duration(days: 30)));
    final item = ContactRecoveryCase(
        account: fixture.account,
        noticePeriodDays: 7,
        now: fixture.now,
        interestPeriodSnapshots: fixture.interestPeriodSnapshots,
        actionHistory: [approved, legacy]);
    final controller = _NoticeController(db, item);
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller);
    expect(find.text('Prepare Notice'), findsNothing);
    expect(find.text('Formal Notice'), findsOneWidget);
    expect(find.text('Earlier notice records (1)'), findsNothing);
    expect(find.text('Second Notice'), findsNothing);
    expect(find.text('1/3 Sent'), findsNothing);
    expect(find.text('Approved'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('notice card waits for PDF issue before delivery confirmation',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fixture = createNoticeCase();
    final approved = GirviNoticeAction(
      id: 10,
      girviId: fixture.loan.id,
      actionType: GirviNoticeActionTypes.noticePrepared,
      noticeStage: 1,
      noticeText: 'Compound Interest Breakdown',
      actionAt: fixture.now,
      createdAt: fixture.now,
    );
    final item = ContactRecoveryCase(
      account: fixture.account,
      noticePeriodDays: 7,
      now: fixture.now,
      interestPeriodSnapshots: fixture.interestPeriodSnapshots,
      actionHistory: [approved],
    );
    final controller = _NoticeController(db, item);
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller);
    expect(find.text('Settlement'), findsOneWidget);
    expect(find.text('Confirm Delivery'), findsNothing);
    expect(find.text('Notice prepared. PDF not issued yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('issued notice asks for delivery evidence before starting timer',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fixture = createNoticeCase();
    final approved = GirviNoticeAction(
      id: 10,
      girviId: fixture.loan.id,
      actionType: GirviNoticeActionTypes.noticePrepared,
      noticeStage: 1,
      noticeText: 'Compound Interest Breakdown',
      actionAt: fixture.now,
      createdAt: fixture.now,
    );
    final printed = GirviNoticeAction(
      id: 11,
      girviId: fixture.loan.id,
      actionType: GirviNoticeActionTypes.noticePdfPrinted,
      noticeActionId: approved.id,
      actionAt: fixture.now,
      createdAt: fixture.now,
    );
    final item = ContactRecoveryCase(
      account: fixture.account,
      noticePeriodDays: 7,
      now: fixture.now,
      actionHistory: [printed, approved],
    );
    final controller = _NoticeController(db, item);
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller, darkTheme: true);
    expect(find.text('Confirm Delivery'), findsOneWidget);
    expect(find.text('Confirm delivery to record a response'), findsOneWidget);
    await tester.tap(find.text('Confirm Delivery'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Confirm Customer Delivery'), findsOneWidget);
    expect(find.text('Printed copy'), findsOneWidget);
    expect(find.text('04 Oct 2026, 12:00 AM'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('NOTICE_PDF_ACTION_11'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final title = tester.widget<Text>(find.text('Confirm Customer Delivery'));
    expect(title.style!.color, GirviColors.textDark);
    final cancel = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Cancel'),
    );
    expect(cancel.style!.foregroundColor!.resolve({}), GirviColors.textDark);
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm Delivery'),
    );
    expect(confirm.style!.backgroundColor!.resolve({}), GirviColors.shellBg);
    final beforeConfirmation = DateTime.now();
    await tester.tap(find.text('Confirm Delivery').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.deliveryActionType,
        GirviNoticeActionTypes.noticeDeliveryRecorded);
    expect(controller.deliveryReference, 'NOTICE_PDF_ACTION_11');
    expect(controller.deliveryChannel, 'Printed copy');
    expect(controller.deliveredAt, isNotNull);
    expect(controller.deliveredAt!.isBefore(beforeConfirmation), isFalse);
    expect(controller.deliveredAt!.isAfter(DateTime.now()), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('delivery confirmation uses the latest saved notice method',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fixture = createNoticeCase();
    final prepared = GirviNoticeAction(
      id: 10,
      girviId: fixture.loan.id,
      actionType: GirviNoticeActionTypes.noticePrepared,
      noticeStage: 1,
      noticeText: 'Formal notice text',
      actionAt: fixture.now,
      createdAt: fixture.now,
    );
    final printedAt = fixture.now.add(const Duration(minutes: 1));
    final sharedAt = fixture.now.add(const Duration(minutes: 2));
    GirviNoticeAction output(int id, String type, DateTime at) =>
        GirviNoticeAction(
          id: id,
          girviId: fixture.loan.id,
          actionType: type,
          noticeActionId: prepared.id,
          actionAt: at,
          createdAt: at,
        );
    final item = ContactRecoveryCase(
      account: fixture.account,
      noticePeriodDays: 7,
      now: fixture.now,
      actionHistory: [
        output(11, GirviNoticeActionTypes.noticePdfPrinted, printedAt),
        output(12, GirviNoticeActionTypes.noticePdfShared, sharedAt),
        prepared,
      ],
    );
    final controller = _NoticeController(db, item);
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller, darkTheme: true);
    await tester.tap(find.text('Confirm Delivery'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('04 Oct 2026, 12:02 AM'), findsOneWidget);
    expect(find.text('NOTICE_PDF_ACTION_12'), findsOneWidget);
    final beforeConfirmation = DateTime.now();
    await tester.tap(find.text('Confirm Delivery').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.deliveryChannel, 'WhatsApp');
    expect(controller.deliveredAt, isNotNull);
    expect(controller.deliveredAt!.isBefore(beforeConfirmation), isFalse);
    expect(controller.deliveredAt!.isAfter(DateTime.now()), isFalse);
    expect(controller.deliveryReference, 'NOTICE_PDF_ACTION_12');
    expect(tester.takeException(), isNull);
  });

  testWidgets('older simple approval exposes a corrected compound notice',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fixture = createNoticeCase(simple: false);
    final original = GirviNoticeAction(
      id: 10,
      girviId: fixture.loan.id,
      actionType: GirviNoticeActionTypes.noticePrepared,
      noticeStage: 1,
      noticeText: 'Simple Interest Breakdown\nInterest Outstanding: ₹ 18,000',
      actionAt: fixture.now.subtract(const Duration(days: 1)),
      createdAt: fixture.now.subtract(const Duration(days: 1)),
    );
    final item = ContactRecoveryCase(
      account: fixture.account,
      noticePeriodDays: 7,
      now: fixture.now,
      interestPeriodSnapshots: fixture.interestPeriodSnapshots,
      paymentHistory: fixture.paymentHistory,
      actionHistory: [original],
    );
    final controller = _NoticeController(db, item);
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller);
    expect(item.requiresCorrectedFormalNotice, isTrue);
    expect(find.text('Prepare Corrected Notice'), findsOneWidget);
    await tester.tap(find.text('Prepare Corrected Notice'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Compound Interest Breakdown'), findsWidgets);
    await tester.tap(find.text('Send Notice'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('Download PDF'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.savedDocuments![GirviNoticeLanguage.english],
        contains('Compound Interest Breakdown'));
    expect(controller.savedDocuments![GirviNoticeLanguage.english],
        contains('GRV-DEMO-001-NOTICE-R2'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('legacy final notice can prepare a current English statement',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fixture = createNoticeCase(simple: false);
    final legacy = GirviNoticeAction(
      id: 21,
      girviId: fixture.loan.id,
      actionType: 'FINAL_NOTICE_PREPARED',
      noticeStage: 3,
      noticeText: 'पुरानी अंतिम सूचना',
      actionAt: fixture.now.subtract(const Duration(days: 3)),
      createdAt: fixture.now.subtract(const Duration(days: 3)),
    );
    final item = ContactRecoveryCase(
      account: fixture.account,
      noticePeriodDays: 7,
      now: fixture.now,
      interestPeriodSnapshots: fixture.interestPeriodSnapshots,
      paymentHistory: fixture.paymentHistory,
      actionHistory: [legacy],
    );
    final controller = _NoticeController(db, item);
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller);
    expect(find.text('Prepare Notice'), findsOneWidget);
    await tester.tap(find.text('Prepare Notice'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Compound Interest Breakdown'), findsWidgets);
    await tester.tap(find.text('Send Notice'));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.text('Download PDF'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.savedDocuments?[GirviNoticeLanguage.english],
        contains('Compound Interest Breakdown'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _NoticeController extends ContactRecoveryController {
  _NoticeController(AppDatabase db, this.item)
      : super(db: db, ticketNo: item.loan.ticketNo);
  final ContactRecoveryCase item;
  Map<GirviNoticeLanguage, String>? savedDocuments;
  GirviNoticeType? savedType;
  int? savedDays;
  String? deliveryReference;
  String? deliveryChannel;
  DateTime? deliveredAt;
  String? deliveryActionType;
  String? savedBrandingSnapshot;
  String? inlineMessage;

  @override
  ContactRecoveryState get state => ContactRecoveryState.initial().copyWith(
        allCases: [item],
        isLoading: false,
      );

  @override
  Future<void> load({bool keepInlineMessage = false}) async {}

  @override
  Future<bool> recordNoticePrepared(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    String noticeText, {
    int? noticePeriodDays,
    String? autoGeneratedText,
    Map<GirviNoticeLanguage, String>? noticeDocuments,
    Map<GirviNoticeLanguage, String>? autoGeneratedDocuments,
    String? brandingSnapshot,
    GirviNoticeLanguage primaryLanguage = GirviNoticeLanguage.english,
  }) async {
    savedDocuments = noticeDocuments;
    savedType = noticeType;
    savedDays = noticePeriodDays;
    savedBrandingSnapshot = brandingSnapshot;
    return true;
  }

  @override
  Future<bool> recordNoticeDeliveryProof({
    required ContactRecoveryCase item,
    required GirviNoticeType noticeType,
    required String noticeText,
    required String actionType,
    required String deliveryChannel,
    required String deliveryStatus,
    GirviNoticeLanguage? noticeLanguage,
    int? noticeActionId,
    String? deliveryReference,
    DateTime? deliveredAt,
  }) async {
    this.deliveryReference = deliveryReference;
    this.deliveryChannel = deliveryChannel;
    this.deliveredAt = deliveredAt;
    deliveryActionType = actionType;
    return true;
  }

  @override
  void showInlineMessage(String message) {
    inlineMessage = message;
  }
}
