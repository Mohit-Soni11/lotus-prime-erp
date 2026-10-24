import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/logic/girvi/contact_recovery_controller.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_generation_service.dart';
import 'package:lotus_erp/logic/girvi/girvi_notice_pdf_service.dart';
import 'package:lotus_erp/models/girvi/girvi_loan_model.dart';
import 'package:lotus_erp/models/girvi/girvi_interest_period_snapshot.dart';
import 'package:lotus_erp/models/girvi/girvi_notice_action_model.dart';
import 'package:lotus_erp/models/girvi/girvi_customer_response_model.dart';
import 'package:lotus_erp/models/girvi/contact_recovery_model.dart';
import 'package:lotus_erp/repositories/girvi/girvi_notice_action_repository.dart';
import 'package:lotus_erp/repositories/girvi/girvi_customer_response_repository.dart';
import 'package:lotus_erp/repositories/customer/defaulter_repository.dart';

void main() {
  group('ContactRecoveryController', () {
    test('dispose does not close the app database connection', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final controller = ContactRecoveryController(
        db: db,
        ticketNo: 'GRV-DISPOSE-TEST',
      );
      controller.dispose();

      await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Girvi Customer',
              mobile: '9000000000',
            ),
          );

      final customers = await db.select(db.customers).get();

      expect(customers, hasLength(1));
      expect(customers.single.name, 'Girvi Customer');
    });

    test(
        'case shows single notice workflow and calendar age in months and days',
        () {
      final now = DateTime(2026, 6, 24);
      final account = GirviLoanWithCustomer(
        loan: GirviLoanModel(
          id: 16,
          ticketNo: 'GRV-0016',
          customerId: 1,
          itemDescription: '#1 ring | Gold | 18KT | 1 pcs | Net 4.000 g',
          itemCount: 1,
          metalType: 'Gold',
          metalPurity: '18KT',
          grossWeight: 4,
          stoneWeight: 0,
          netWeight: 4,
          loanAmount: 12000,
          interestRate: 5,
          durationMonths: 6,
          disbursementMode: 'Cash',
          startDate: DateTime(2025, 3, 10),
          maturityDate: DateTime(2025, 9, 10),
          createdAt: DateTime(2025, 3, 10),
          status: 'OVERDUE',
        ),
        customerName: 'REYANSH SONI',
        customerMobile: '9304479436',
      );

      ContactRecoveryCase caseWith(List<GirviNoticeAction> actions,
              {DateTime? asOf}) =>
          ContactRecoveryCase(
            account: account,
            noticePeriodDays: 7,
            now: asOf ?? now,
            actionHistory: actions,
          );
      GirviNoticeAction notice({DateTime? deadline}) => GirviNoticeAction(
            id: 1,
            girviId: account.loan.id,
            actionType: GirviNoticeActionTypes.noticePrepared,
            noticeStage: 1,
            actionAt: now,
            createdAt: now,
            noticeDeadlineAt: deadline ?? now.add(const Duration(days: 7)),
          );
      final fresh = caseWith([]);
      expect(fresh.stage, ContactRecoveryStage.noticeRequired);
      expect(fresh.nextNoticeType, GirviNoticeType.formal);
      expect(fresh.noticeStatusLabel, 'Not prepared');
      expect(fresh.loanAgeMonthsDaysLabel, '15 months 14 days');
      expect(fresh.overdueAgeMonthsDaysLabel, '9 months 14 days');
      final pending = caseWith([notice()]);
      expect(pending.stage, ContactRecoveryStage.noticePending);
      expect(pending.nextNoticeType, isNull);
      expect(pending.canPrepareNotice, isFalse);
      expect(pending.noticeStatusLabel, 'Approved');
      expect(pending.preparedNoticeActions, hasLength(1));
      final deadline = now.add(const Duration(days: 7, hours: 12));
      final before = caseWith([notice(deadline: deadline)],
          asOf: deadline.subtract(const Duration(seconds: 1)));
      expect(before.canInitiateCollateralRecovery, isFalse);
      final ready = caseWith([notice(deadline: deadline)], asOf: deadline);
      expect(ready.stage, ContactRecoveryStage.noticePending);
      expect(ready.canInitiateCollateralRecovery, isFalse);
      final delivered = caseWith([
        notice(deadline: deadline),
        GirviNoticeAction(
          id: 4,
          girviId: account.loan.id,
          actionType: GirviNoticeActionTypes.noticeDeliveryRecorded,
          noticeActionId: 1,
          deliveryStatus: 'Delivered',
          actionAt: now,
          createdAt: now,
        ),
      ], asOf: deadline);
      expect(delivered.canInitiateCollateralRecovery, isTrue);
      expect(ready.canCloseDisposal, isFalse);
      final recovery = caseWith([
        notice(),
        GirviNoticeAction(
            id: 2,
            girviId: account.loan.id,
            actionType: GirviNoticeActionTypes.collateralRecoveryInitiated,
            actionAt: now,
            createdAt: now),
      ]);
      expect(recovery.canCloseDisposal, isTrue);
      expect(recovery.nextNoticeType, isNull);
      final closed = caseWith([
        GirviNoticeAction(
            id: 3,
            girviId: account.loan.id,
            actionType: GirviNoticeActionTypes.disposalSettled,
            actionAt: now,
            createdAt: now),
      ]);
      expect(closed.stage, ContactRecoveryStage.settled);
      expect(closed.nextNoticeType, isNull);
    });

    test('notice delivery proof persists without changing notice stage count',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Notice Customer',
              mobile: '9000000002',
            ),
          );
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-NOT-001',
              customerId: customerId,
              itemDescription: 'Gold ring',
              grossWeight: const drift.Value(6),
              netWeight: const drift.Value(6),
              loanAmount: const drift.Value(20000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(DateTime(2025, 9, 9)),
              maturityDate: drift.Value(DateTime(2026, 3, 9)),
              status: const drift.Value('OVERDUE'),
            ),
          );

      final repository = GirviNoticeActionRepository(db);
      await expectLater(
        repository.recordNoticeDeliveryProof(
          girviId: loanId,
          noticeType: GirviNoticeType.formal,
          noticeText: 'First notice text',
          actionType: GirviNoticeActionTypes.noticePdfSaved,
          deliveryChannel: 'PDF File',
          deliveryStatus: 'Saved',
        ),
        throwsA(isA<StateError>()),
      );
      await repository.recordNoticePrepared(
        girviId: loanId,
        noticeType: GirviNoticeType.formal,
        noticeText: 'First notice text',
        noticePeriodDays: 30,
      );
      await repository.recordNoticeDeliveryProof(
        girviId: loanId,
        noticeType: GirviNoticeType.formal,
        noticeText: 'First notice text',
        actionType: GirviNoticeActionTypes.noticePdfSaved,
        deliveryChannel: 'PDF File',
        deliveryStatus: 'Saved',
        deliveryReference: r'C:\notice\GRV-NOT-001.pdf',
      );

      await expectLater(
        repository.recordNoticeDeliveryProof(
          girviId: loanId,
          noticeType: GirviNoticeType.formal,
          noticeText: 'Edited after approval',
          actionType: GirviNoticeActionTypes.noticePdfPrinted,
          deliveryChannel: 'Printer',
          deliveryStatus: 'Printed',
        ),
        throwsA(isA<StateError>()),
      );

      final history = (await repository.actionsByGirviIds([loanId]))[loanId]!;
      final pdfActivity =
          history.firstWhere((action) => action.isNoticePdfActivity);
      expect(pdfActivity.deliveryStatus, 'Saved');
      expect(pdfActivity.deliveryChannel, 'PDF File');
      expect(pdfActivity.deliveryReference, r'C:\notice\GRV-NOT-001.pdf');
      expect(pdfActivity.deliveredAt, isNull);

      final account = GirviLoanWithCustomer(
        loan: GirviLoanModel(
          id: loanId,
          ticketNo: 'GRV-NOT-001',
          customerId: customerId,
          itemDescription: 'Gold ring',
          itemCount: 1,
          metalType: 'Gold',
          metalPurity: '18KT',
          grossWeight: 6,
          stoneWeight: 0,
          netWeight: 6,
          loanAmount: 20000,
          interestRate: 5,
          durationMonths: 6,
          disbursementMode: 'Cash',
          startDate: DateTime(2025, 9, 9),
          maturityDate: DateTime(2026, 3, 9),
          createdAt: DateTime(2025, 9, 9),
          status: 'OVERDUE',
        ),
        customerName: 'Notice Customer',
        customerMobile: '9000000002',
      );
      final noticeCase = ContactRecoveryCase(
        account: account,
        noticePeriodDays: 30,
        now: DateTime(2026, 6, 24),
        actionHistory: history,
      );

      expect(noticeCase.noticeStatusLabel, 'Approved');
      expect(noticeCase.preparedNoticeActions, hasLength(1));
      expect(noticeCase.noticeDeliveryProofActions, isEmpty);
      expect(noticeCase.noticePdfActivityActions, hasLength(1));
      expect(
        noticeCase.latestDeliveryProofForNotice(noticeCase.formalNoticeAction!),
        isNull,
      );
      expect(
        noticeCase
            .latestPdfActivityForNotice(noticeCase.formalNoticeAction!)
            ?.deliveryProofLabel,
        'Saved via PDF File',
      );
    });

    test('matured account appears before notice and remains after approval',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Monitoring Customer',
              mobile: '9000000011',
            ),
          );
      final now = DateTime.now();
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-MON-001',
              customerId: customerId,
              itemDescription: 'Gold ring',
              loanAmount: const drift.Value(10000),
              interestRate: const drift.Value(0),
              startDate: drift.Value(now.subtract(const Duration(days: 90))),
              maturityDate: drift.Value(now.subtract(const Duration(days: 1))),
              status: const drift.Value('OVERDUE'),
            ),
          );
      await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-MON-0012',
              customerId: customerId,
              itemDescription: 'Gold chain',
              loanAmount: const drift.Value(12000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(now.subtract(const Duration(days: 90))),
              maturityDate: drift.Value(now.subtract(const Duration(days: 1))),
              status: const drift.Value('OVERDUE'),
            ),
          );
      final controller = ContactRecoveryController(
        db: db,
        ticketNo: 'GRV-MON-001',
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.state.allCases, hasLength(1));
      expect(controller.state.allCases.single.loan.ticketNo, 'GRV-MON-001');
      expect(controller.state.allCases.single.canPrepareNotice, isTrue);

      final missingController = ContactRecoveryController(
        db: db,
        ticketNo: 'GRV-MON-0013',
      );
      addTearDown(missingController.dispose);
      await missingController.load();
      expect(missingController.state.allCases, isEmpty);

      await GirviNoticeActionRepository(db).recordNoticePrepared(
        girviId: loanId,
        noticeType: GirviNoticeType.formal,
        noticeText: 'Approved notice for monitoring customer',
        noticePeriodDays: 7,
      );
      await controller.load();
      expect(controller.state.allCases, hasLength(1));
      expect(controller.state.allCases.single.loan.id, loanId);
    });

    test(
        'recent interest payment keeps a matured monitoring ticket in notice workflow',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Monitoring Customer',
              mobile: '9000000012',
            ),
          );
      final now = DateTime.now();
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-0016',
              customerId: customerId,
              itemDescription: 'Gold ring',
              loanAmount: const drift.Value(5000),
              interestRate: const drift.Value(5),
              startDate: drift.Value(now.subtract(const Duration(days: 90))),
              maturityDate: drift.Value(now.subtract(const Duration(days: 30))),
              status: const drift.Value('OVERDUE'),
            ),
          );
      await db.into(db.girviPayments).insert(
            GirviPaymentsCompanion.insert(
              girviId: loanId,
              paymentType: 'INTEREST',
              amount: const drift.Value(250),
              paymentDate: drift.Value(now),
              interestComponent: const drift.Value(250),
              monthsCovered: const drift.Value(1),
            ),
          );

      final riskAccount = (await DefaulterRepository(db: db)
              .fetchAllDefaulters(syncStatuses: false))
          .single;
      expect(riskAccount.isPaymentMonitoring, isTrue);
      expect(riskAccount.isNoticeEligible, isTrue);
      expect(riskAccount.totalDue, greaterThan(0));

      final controller = ContactRecoveryController(
        db: db,
        ticketNo: 'GRV-0016',
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.state.allCases, hasLength(1));
      expect(controller.state.allCases.single.loan.ticketNo, 'GRV-0016');
      expect(controller.state.allCases.single.canPrepareNotice, isTrue);
      expect(
        controller.state.allCases.single.canInitiateCollateralRecovery,
        isFalse,
      );
    });

    test('generated notices do not include pledged valuation', () {
      final account = GirviLoanWithCustomer(
        loan: GirviLoanModel(
          id: 17,
          ticketNo: 'GRV-0017',
          customerId: 1,
          itemDescription: '#1 chain | Gold | 22KT | 1 pcs | Net 12.000 g',
          itemCount: 1,
          metalType: 'Gold',
          metalPurity: '22KT',
          grossWeight: 12,
          stoneWeight: 0,
          netWeight: 12,
          loanAmount: 100000,
          interestRate: 5,
          durationMonths: 6,
          disbursementMode: 'Cash',
          startDate: DateTime(2025, 1, 15),
          maturityDate: DateTime(2025, 7, 15),
          createdAt: DateTime(2025, 1, 15),
          status: 'OVERDUE',
        ),
        customerName: 'REYANSH SONI',
        customerMobile: '9304479436',
      );
      final recoveryCase = ContactRecoveryCase(
        account: account,
        noticePeriodDays: 30,
        now: DateTime(2026, 9, 29),
      );
      final service = GirviNoticeGenerationService(
        now: DateTime(2026, 9, 29),
      );

      for (final noticeType in GirviNoticeType.values) {
        final notices = service.buildAll(
          item: recoveryCase,
          noticeType: noticeType,
        );
        for (final noticeText in notices.values) {
          expect(noticeText, isNot(contains('Pledged Valuation')));
          expect(noticeText, isNot(contains('Pledged Value')));
          expect(noticeText, isNot(contains('Valuation:')));
          expect(noticeText, isNot(contains('गिरवी मूल्यांकन')));
          expect(noticeText, isNot(contains('गिरवी मूल्य')));
          expect(noticeText, isNot(contains('मूल्यांकन:')));
          expect(noticeText, isNot(contains('Notice Generator')));
          expect(noticeText, isNot(contains('notice generator')));
          expect(noticeText, isNot(contains('Verified Ledger')));
          expect(noticeText, isNot(contains('Source of Truth')));
          expect(noticeText, isNot(contains('Internal Record')));
          expect(noticeText, contains('GRV-0017'));
        }
      }
    });

    test('formal notice keeps financial sections and prior responses dynamic',
        () {
      final account = GirviLoanWithCustomer(
        loan: GirviLoanModel(
          id: 18,
          ticketNo: 'GRV-0018',
          customerId: 1,
          itemDescription: '#1 ring | Gold | 22KT | 1 pcs | Net 10.000 g',
          itemCount: 1,
          metalType: 'Gold',
          metalPurity: '22KT',
          grossWeight: 10,
          stoneWeight: 0,
          netWeight: 10,
          loanAmount: 100000,
          interestRate: 5,
          durationMonths: 6,
          disbursementMode: 'Cash',
          startDate: DateTime(2020, 6, 15),
          maturityDate: DateTime(2020, 12, 15),
          createdAt: DateTime(2020, 6, 15),
        ),
        customerName: 'REYANSH SONI',
        customerMobile: '9304479436',
      );
      final item = ContactRecoveryCase(
        account: account,
        noticePeriodDays: 30,
        now: DateTime(2026, 9, 29),
        interestPeriodSnapshots: [
          GirviInterestPeriodSnapshot(
            id: 1,
            girviId: account.loan.id,
            sequence: 1,
            periodFrom: DateTime(2020, 6, 15),
            periodTo: DateTime(2021, 6, 15),
            interestType: GirviInterestCalculationType.compound,
            openingAmount: 100000,
            monthlyRatePercent: 5,
            interestPerMonth: 5000,
            chargeableMonths: 12,
            periodInterest: 60000,
            closingAmount: 160000,
            finalized: true,
            source: 'TEST',
          ),
        ],
        customerResponses: [
          GirviCustomerResponse(
            id: 1,
            girviId: account.loan.id,
            noticeStage: 1,
            kind: GirviCustomerResponseKind.willVisit,
            channel: GirviContactChannel.phoneCall,
            responseText: 'I will visit the shop on Friday.',
            status: GirviPromiseStatus.open,
            promiseDueAt: DateTime(2026, 9, 26),
            receivedAt: DateTime(2026, 9, 20),
            createdAt: DateTime(2026, 9, 20),
          ),
        ],
      );
      final service = GirviNoticeGenerationService(now: item.now);

      final text = service.build(
        item: item,
        noticeType: GirviNoticeType.formal,
        language: GirviNoticeLanguage.english,
      );
      expect(text, contains('FINAL NOTICE: PLEDGE ACCOUNT GRV-0018'));
      expect(text, contains('GRV-0018-NOTICE'));
      expect(text, contains('Pledge Account and Duration'));
      expect(text, contains('Compound Interest Breakdown'));
      expect(text, contains('Monthly Interest Rate: 5.00%'));
      expect(text, contains('Account Summary'));
      expect(text, isNot(contains('Previous Contact and Customer Response')));
      expect(text, isNot(contains('I will visit the shop on Friday.')));
      expect(text, contains('on or before 29 October 2026'));
      expect(text, isNot(contains('FIRST PLEDGE')));
      expect(text, isNot(contains('SECOND PLEDGE')));
      expect(text, isNot(contains('FINAL PLEDGE')));
      expect(text, isNot(contains('earlier notices')));
      expect(text, isNot(contains('Valuation')));
    });

    test('notice schema safety upgrades a legacy action table', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customStatement('DROP TABLE IF EXISTS girvi_notice_actions');
      await db.customStatement('''
        CREATE TABLE girvi_notice_actions (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          girvi_id INTEGER NOT NULL,
          action_type TEXT NOT NULL,
          notice_text TEXT,
          action_note TEXT,
          action_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER
        )
      ''');

      await db.ensureGirviNoticeActionSchema();

      final columns = await db
          .customSelect(
            "PRAGMA table_info('girvi_notice_actions')",
          )
          .get();
      final names = columns.map((row) => row.data['name']).toSet();

      expect(names, contains('notice_stage'));
      expect(names, contains('document_hash'));
      expect(names, contains('performed_by'));
      expect(names, contains('approved_by'));
      expect(names, contains('approved_at'));
      expect(names, contains('notice_deadline_at'));
      expect(names, contains('pledged_valuation'));
      expect(names, contains('delivery_channel'));
      expect(names, contains('delivery_status'));
      expect(names, contains('delivery_reference'));
      expect(names, contains('delivered_at'));
    });

    test(
        'cash recovery closes atomically with finance and customer surplus audit',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Recovery Customer',
              mobile: '9000000003',
            ),
          );
      final now = DateTime(2026, 6, 24);
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-REC-001',
              customerId: customerId,
              itemDescription: 'Gold chain',
              grossWeight: const drift.Value(10),
              netWeight: const drift.Value(10),
              loanAmount: const drift.Value(20000),
              interestRate: const drift.Value(0),
              startDate: drift.Value(now.subtract(const Duration(days: 90))),
              maturityDate: drift.Value(now.subtract(const Duration(days: 30))),
              status: const drift.Value('OVERDUE'),
            ),
          );
      await db.into(db.girviLoanItems).insert(
            GirviLoanItemsCompanion.insert(
              girviId: loanId,
              serialNo: 1,
              itemName: 'Gold chain',
              metalType: 'Gold',
              purity: '22KT',
            ),
          );
      final auditRepository = GirviNoticeActionRepository(db);
      await auditRepository.recordAction(
        girviId: loanId,
        actionType: GirviNoticeType.formal.actionType,
        noticeStage: 1,
        noticeText: 'Approved final notice',
        actionAt: now.subtract(const Duration(days: 31)),
        noticeDeadlineAt: now.subtract(const Duration(days: 1)),
      );
      await auditRepository.recordAction(
        girviId: loanId,
        actionType: GirviNoticeActionTypes.collateralRecoveryInitiated,
      );
      final account = GirviLoanWithCustomer(
        loan: GirviLoanModel(
          id: loanId,
          ticketNo: 'GRV-REC-001',
          customerId: customerId,
          itemDescription: 'Gold chain',
          itemCount: 1,
          metalType: 'Gold',
          metalPurity: '22KT',
          grossWeight: 10,
          stoneWeight: 0,
          netWeight: 10,
          loanAmount: 20000,
          interestRate: 0,
          durationMonths: 2,
          disbursementMode: 'Cash',
          startDate: now.subtract(const Duration(days: 90)),
          maturityDate: now.subtract(const Duration(days: 30)),
          createdAt: now.subtract(const Duration(days: 90)),
          status: 'OVERDUE',
        ),
        customerName: 'Recovery Customer',
        customerMobile: '9000000003',
      );
      final recoveryCase = ContactRecoveryCase(
        account: account,
        noticePeriodDays: 30,
        now: now,
        actionHistory: [
          GirviNoticeAction(
            id: 2,
            girviId: loanId,
            actionType: GirviNoticeActionTypes.collateralRecoveryInitiated,
            actionAt: now,
            createdAt: now,
          ),
          GirviNoticeAction(
            id: 1,
            girviId: loanId,
            actionType: GirviNoticeType.formal.actionType,
            noticeStage: 1,
            actionAt: now.subtract(const Duration(days: 31)),
            createdAt: now.subtract(const Duration(days: 31)),
          ),
        ],
      );

      final controller = ContactRecoveryController(
        db: db,
        ticketNo: 'GRV-REC-001',
      );
      addTearDown(controller.dispose);
      final riskRepository = DefaulterRepository(db: db);
      final activeRecovery = await riskRepository.fetchAllDefaulters(
        syncStatuses: false,
      );
      expect(activeRecovery.single.isCollateralRecovery, isTrue);
      expect(activeRecovery.single.isRecoverySettled, isFalse);
      await (db.update(db.girviLoans)..where((loan) => loan.id.equals(loanId)))
          .write(const GirviLoansCompanion(loanAmount: drift.Value(19000)));
      final staleAmountClosed = await controller.closeDisposalSettlement(
        item: recoveryCase,
        pledgedValuation: 70000,
        recoveredAmount: 22000,
        penaltyAmount: 0,
        note: 'Stale amount must be rejected.',
      );
      expect(staleAmountClosed, isFalse);
      expect(await db.select(db.cashTransactions).get(), isEmpty);
      await (db.update(db.girviLoans)..where((loan) => loan.id.equals(loanId)))
          .write(const GirviLoansCompanion(
        loanAmount: drift.Value(20000),
        status: drift.Value('RELEASED'),
      ));
      final closedLoanSettled = await controller.closeDisposalSettlement(
        item: recoveryCase,
        pledgedValuation: 70000,
        recoveredAmount: 22000,
        penaltyAmount: 0,
        note: 'Closed account must be rejected.',
      );
      expect(closedLoanSettled, isFalse);
      expect(await db.select(db.cashTransactions).get(), isEmpty);
      await (db.update(db.girviLoans)..where((loan) => loan.id.equals(loanId)))
          .write(const GirviLoansCompanion(status: drift.Value('OVERDUE')));
      final closed = await controller.closeDisposalSettlement(
        item: recoveryCase,
        pledgedValuation: 70000,
        recoveredAmount: 22000,
        penaltyAmount: 0,
        note: 'Verified auction recovery.',
      );

      expect(closed, isTrue);
      final cashEntries = await db.select(db.cashTransactions).get();
      expect(cashEntries, hasLength(1));
      expect(cashEntries.single.amount, 22000);
      expect(cashEntries.single.referenceType, 'GIRVI_RECOVERY');
      final ledgerEntries = await db.select(db.customerAccountLedger).get();
      expect(ledgerEntries, hasLength(1));
      expect(ledgerEntries.single.entryType, 'CREDIT');
      expect(ledgerEntries.single.amount, 2000);
      final actions = await db.select(db.girviNoticeActions).get();
      expect(
        actions.where(
            (row) => row.actionType == GirviNoticeActionTypes.disposalSettled),
        hasLength(1),
      );
      final savedLoan = await (db.select(db.girviLoans)
            ..where((loan) => loan.id.equals(loanId)))
          .getSingle();
      expect(savedLoan.status, 'AUCTIONED');
      final recoveryRegister = await riskRepository.fetchAllDefaulters(
        syncStatuses: false,
      );
      expect(recoveryRegister, hasLength(1));
      expect(recoveryRegister.single.isRecoverySettled, isTrue);
      expect(recoveryRegister.single.recoveredAmount, 22000);
      expect(recoveryRegister.single.recoverySurplus, 2000);
      expect(await riskRepository.fetchDefaulterCount(), 0);
      final pledgedItems = await (db.select(db.girviLoanItems)
            ..where((item) => item.girviId.equals(loanId)))
          .get();
      expect(pledgedItems.single.recoveryDispositionStatus, 'DISPOSED');
      expect(
        pledgedItems.single.recoveryDispositionReference,
        'GIRVI-RECOVERY-GRV-REC-001',
      );
    });

    test(
        'customer follow-ups require an approved notice and preserve resolution audit',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final customerId = await db.into(db.customers).insert(
            CustomersCompanion.insert(
              name: 'Promise Customer',
              mobile: '9000000008',
            ),
          );
      final loanId = await db.into(db.girviLoans).insert(
            GirviLoansCompanion.insert(
              ticketNo: 'GRV-RESPONSE-001',
              customerId: customerId,
              itemDescription: 'Gold chain',
              loanAmount: const drift.Value(10000),
              startDate: drift.Value(DateTime(2025, 1, 1)),
              maturityDate: drift.Value(DateTime(2025, 7, 1)),
              status: const drift.Value('OVERDUE'),
            ),
          );
      final responses = GirviCustomerResponseRepository(db);
      await expectLater(
        responses.record(
          girviId: loanId,
          noticeStage: 1,
          kind: GirviCustomerResponseKind.willVisit,
          channel: GirviContactChannel.phoneCall,
          responseText: 'I will visit in two days.',
          promiseDueAt: DateTime(2026, 10, 7),
        ),
        throwsA(isA<StateError>()),
      );

      final notices = GirviNoticeActionRepository(db);
      final noticeId = await notices.recordNoticePrepared(
        girviId: loanId,
        noticeType: GirviNoticeType.formal,
        noticeText: 'Approved first notice',
        noticePeriodDays: 7,
      );
      await notices.recordNoticeDeliveryProof(
        girviId: loanId,
        noticeType: GirviNoticeType.formal,
        noticeActionId: noticeId,
        noticeText: 'Approved first notice',
        actionType: GirviNoticeActionTypes.noticePdfPrinted,
        deliveryChannel: 'Printer',
        deliveryStatus: 'Printed',
        deliveryReference: 'PRINT-$noticeId',
      );
      await notices.recordNoticeDeliveryProof(
        girviId: loanId,
        noticeType: GirviNoticeType.formal,
        noticeActionId: noticeId,
        noticeText: 'Approved first notice',
        actionType: GirviNoticeActionTypes.noticeDeliveryRecorded,
        deliveryChannel: 'In person',
        deliveryStatus: 'Delivered',
        deliveryReference: 'ACK-$noticeId',
      );
      final responseId = await responses.record(
        girviId: loanId,
        noticeActionId: noticeId,
        kind: GirviCustomerResponseKind.extensionRequest,
        channel: GirviContactChannel.whatsapp,
        responseText: 'I need more time until Friday.',
        promiseDueAt: DateTime.now().add(const Duration(days: 2)),
      );
      await responses.resolve(
        responseId: responseId,
        status: GirviPromiseStatus.fulfilled,
        resolutionNote: 'Customer attended and the follow-up was completed.',
      );

      final saved = (await responses.byGirviIds([loanId]))[loanId]!.single;
      expect(saved.noticeActionId, noticeId);
      expect(saved.noticeStage, 1);
      expect(saved.status, GirviPromiseStatus.fulfilled);
      expect(
        saved.resolutionNote,
        'Customer attended and the follow-up was completed.',
      );
      await expectLater(
        responses.resolve(
          responseId: responseId,
          status: GirviPromiseStatus.missed,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('stored notice PDF renders an immutable saved notice source',
        () async {
      final bytes = await GirviNoticePdfService().buildStoredNotice(
        ticketNo: 'GRV-PDF-001',
        noticeType: GirviNoticeType.formal,
        noticeLanguage: GirviNoticeLanguage.english,
        savedAt: DateTime(2026, 10, 15),
        noticeText: '''FIRST PLEDGE ACCOUNT NOTICE
Notice Number: GRV-PDF-001-N01
Notice Date: 15 October 2026
Pledge Reference: GRV-PDF-001

Subject: Reminder for Pending Pledge Account Settlement

Dear PDF Customer,
Please contact the branch to settle the verified outstanding amount.

Required Action
Please settle the account before the stated deadline.''',
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
