import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/contact_recovery_controller.dart';
import 'package:lotus_erp/models/girvi/contact_recovery_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_history.dart';
import 'package:lotus_erp/ui/girvi/contact_recovery/contact_recovery_screen.dart';

import 'fixtures/girvi_notice_case_fixture.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> showScreen(
      WidgetTester tester, _NoticeController controller) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: ContactRecoveryScreen(controller: controller),
    ));
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('one prepare action opens an English editor and saves its edits',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final controller = _NoticeController(db, createNoticeCase(simple: false));
    addTearDown(controller.dispose);
    addTearDown(db.close);
    await showScreen(tester, controller);
    expect(find.text('Prepare Notice'), findsOneWidget);
    for (final retired in ['First Notice', 'Second Notice', 'Final Notice']) {
      expect(find.text(retired), findsNothing);
    }
    await tester.tap(find.text('Prepare Notice'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Formal Notice'), findsOneWidget);
    expect(find.text('PLEDGE ACCOUNT NOTICE'), findsOneWidget);
    expect(find.text('Hindi'), findsNothing);
    expect(find.text('English'), findsNothing);
    await tester.tap(find.byTooltip('Edit notice text'));
    await tester.pump(const Duration(milliseconds: 350));
    const edited = 'PLEDGE ACCOUNT NOTICE\nCustomer-specific English edit.';
    await tester.enterText(
        find.byKey(const ValueKey('notice-text-editor')), edited);
    await tester.tap(find.text('Approve & Save Notice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.savedDocuments![GirviNoticeLanguage.english], edited);
    expect(controller.savedDocuments!.keys, {GirviNoticeLanguage.english});
    expect(controller.savedType, GirviNoticeType.formal);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('approved notice has one card and hides old notices in history',
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
        actionType: GirviNoticeHistory.secondPrepared,
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
    expect(find.text('Earlier notice records (1)'), findsOneWidget);
    expect(find.text('Second Notice'), findsNothing);
    expect(find.text('1/3 Sent'), findsNothing);
    expect(find.text('Approved'), findsOneWidget);
    await tester.tap(find.text('Earlier notice records (1)'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Second Notice'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
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
    await tester.tap(find.text('Approve & Save Notice'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(controller.savedDocuments![GirviNoticeLanguage.english],
        contains('Compound Interest Breakdown'));
    expect(controller.savedDocuments![GirviNoticeLanguage.english],
        contains('GRV-DEMO-001-NOTICE-R2'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _NoticeController extends ContactRecoveryController {
  _NoticeController(AppDatabase db, this.item) : super(db: db);
  final ContactRecoveryCase item;
  Map<GirviNoticeLanguage, String>? savedDocuments;
  GirviNoticeType? savedType;

  @override
  ContactRecoveryState get state => ContactRecoveryState.initial().copyWith(
        allCases: [item],
        visibleCases: [item],
        isLoading: false,
      );

  @override
  Future<void> load({bool keepInlineMessage = false}) async {}

  @override
  Future<bool> recordNoticePrepared(
    ContactRecoveryCase item,
    GirviNoticeType noticeType,
    String noticeText, {
    String? autoGeneratedText,
    Map<GirviNoticeLanguage, String>? noticeDocuments,
    Map<GirviNoticeLanguage, String>? autoGeneratedDocuments,
    GirviNoticeLanguage primaryLanguage = GirviNoticeLanguage.english,
  }) async {
    savedDocuments = noticeDocuments;
    savedType = noticeType;
    return true;
  }
}
